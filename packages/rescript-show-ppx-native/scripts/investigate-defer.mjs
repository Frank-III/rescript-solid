import { spawnSync } from "node:child_process";
import os from "node:os";
import path from "node:path";
import process from "node:process";

const root = path.resolve(process.cwd(), "..", "..");
const bsc = path.join(root, "node_modules", "@rescript", "darwin-arm64", "bin", "bsc.exe");
const ppx = path.join(
  root,
  "packages",
  "rescript-show-ppx-native",
  "_build",
  "default",
  "bin",
  "show_ppx_native.exe",
);

const compileFixture = (name) => {
  const source = path.join(root, "packages", "rescript-show-ppx-native", "fixtures", `${name}.res`);
  const out = path.join(os.tmpdir(), `rescript-show-ppx-native-${name}.ast`);

  const result = spawnSync(
    bsc,
    [
      "-ppx",
      `${ppx} --as-ppx`,
      "-bs-jsx",
      "4",
      "-bs-jsx-module",
      "Solid",
      "-bs-jsx-preserve",
      "-I",
      path.join(root, "packages", "rescript-solid", "src"),
      "-bs-ast",
      "-o",
      out,
      source,
    ],
    { encoding: "utf8" },
  );

  return {
    name,
    status: result.status ?? 1,
    error: result.error ? String(result.error) : "",
    stdout: result.stdout ?? "",
    stderr: result.stderr ?? "",
  };
};

const inspectFixtureSource = (name, enableDeferRewrite) => {
  const source = path.join(root, "packages", "rescript-show-ppx-native", "fixtures", `${name}.res`);
  const out = path.join(
    os.tmpdir(),
    `rescript-show-ppx-native-source-${name}-${enableDeferRewrite ? "defer-on" : "defer-off"}.ast`,
  );

  const result = spawnSync(
    bsc,
    [
      "-ppx",
      `${ppx} --as-ppx`,
      "-bs-jsx",
      "4",
      "-bs-jsx-module",
      "Solid",
      "-bs-jsx-preserve",
      "-I",
      path.join(root, "packages", "rescript-solid", "src"),
      "-dparsetree",
      "-bs-ast",
      "-o",
      out,
      source,
    ],
    {
      encoding: "utf8",
      env: {
        ...process.env,
        ...(enableDeferRewrite ? { RESCRIPT_SHOW_PPX_NATIVE_DEFER: "1" } : {}),
      },
    },
  );

  return {
    name: `source_${name}_${enableDeferRewrite ? "defer_on" : "defer_off"}`,
    status: result.status ?? 1,
    error: result.error ? String(result.error) : "",
    stdout: result.stdout ?? "",
    stderr: result.stderr ?? "",
    output: `${result.stdout ?? ""}\n${result.stderr ?? ""}`,
  };
};

const evaluateSourceCheck = ({ check, includes = [], excludes = [] }) => {
  const output = check.output;
  const hasIncludes = includes.every((token) => output.includes(token));
  const hasExcludes = excludes.every((token) => !output.includes(token));
  const ok = check.status === 0 && hasIncludes && hasExcludes;

  return {
    name: check.name,
    ok,
    details:
      check.status !== 0
        ? (check.error || check.stderr || check.stdout).trim()
        : `includes=[${includes.join(", ")}], excludes=[${excludes.join(", ")}]`,
  };
};

const compileRouterBindingsAudit = (enableDeferRewrite) => {
  const out = path.join(
    os.tmpdir(),
    enableDeferRewrite ? "router_defer_on.ast" : "router_defer_off.ast",
  );

  const result = spawnSync(
    bsc,
    [
      "-ppx",
      `${ppx} --as-ppx`,
      "-bs-jsx",
      "4",
      "-bs-jsx-module",
      "Solid",
      "-bs-jsx-preserve",
      "-absname",
      "-bs-ast",
      "-o",
      out,
      "../../src/BindingsAudit.res",
    ],
    {
      cwd: path.join(root, "examples", "router", "lib", "ocaml"),
      encoding: "utf8",
      env: {
        ...process.env,
        ...(enableDeferRewrite ? { RESCRIPT_SHOW_PPX_NATIVE_DEFER: "1" } : {}),
      },
    },
  );

  return {
    name: enableDeferRewrite ? "router_defer_on" : "router_defer_off",
    status: result.status ?? 1,
    error: result.error ? String(result.error) : "",
    stdout: result.stdout ?? "",
    stderr: result.stderr ?? "",
  };
};

const runRouterBuildProbe = (enableDeferRewrite) => {
  const clean = spawnSync("bun", ["run", "-F", "solid-examples-router", "res:clean"], {
    cwd: root,
    encoding: "utf8",
  });

  if ((clean.status ?? 1) !== 0) {
    return {
      name: enableDeferRewrite ? "router_build_defer_on" : "router_build_defer_off",
      status: clean.status ?? 1,
      error: clean.error ? String(clean.error) : "",
      stdout: clean.stdout ?? "",
      stderr: clean.stderr ?? "",
    };
  }

  const result = spawnSync(
    "bun",
    ["run", "-F", "solid-examples-router", "res:build"],
    {
      cwd: root,
      encoding: "utf8",
      env: {
        ...process.env,
        ...(enableDeferRewrite ? { RESCRIPT_SHOW_PPX_NATIVE_DEFER: "1" } : {}),
      },
    },
  );

  return {
    name: enableDeferRewrite ? "router_build_defer_on" : "router_build_defer_off",
    status: result.status ?? 1,
    error: result.error ? String(result.error) : "",
    stdout: result.stdout ?? "",
    stderr: result.stderr ?? "",
  };
};

const checks = [
  compileFixture("defer_explicit"),
  compileFixture("defer_attribute"),
  compileFixture("defer_jsx_explicit"),
  compileFixture("defer_jsx_attribute"),
  compileFixture("defer_jsx_child"),
  compileRouterBindingsAudit(false),
  compileRouterBindingsAudit(true),
];

checks.push(runRouterBuildProbe(false));
checks.push(runRouterBuildProbe(true));

const sourceChecks = [
  evaluateSourceCheck({
    check: inspectFixtureSource("defer_attribute", false),
    excludes: ['"SolidJSX.ppxDefer"'],
  }),
  evaluateSourceCheck({
    check: inspectFixtureSource("defer_attribute", true),
    includes: ['"SolidJSX.ppxDefer"'],
  }),
  evaluateSourceCheck({
    check: inspectFixtureSource("defer_jsx_child", true),
    excludes: ['"SolidJSX.ppxDefer"'],
  }),
];

for (const check of checks) {
  const ok = check.status === 0;
  console.log(`${ok ? "PASS" : "FAIL"} ${check.name}`);
  if (!ok) {
    const message = (check.error || check.stderr || check.stdout).trim();
    console.log(message);
  }
}

for (const check of sourceChecks) {
  console.log(`${check.ok ? "PASS" : "FAIL"} ${check.name}`);
  if (!check.ok) {
    console.log(check.details);
  }
}

const explicit = checks.find((c) => c.name === "defer_explicit");
const attribute = checks.find((c) => c.name === "defer_attribute");
const jsxExplicit = checks.find((c) => c.name === "defer_jsx_explicit");
const jsxAttribute = checks.find((c) => c.name === "defer_jsx_attribute");
const jsxChild = checks.find((c) => c.name === "defer_jsx_child");
const routerDeferOff = checks.find((c) => c.name === "router_defer_off");
const routerDeferOn = checks.find((c) => c.name === "router_defer_on");
const routerBuildDeferOff = checks.find((c) => c.name === "router_build_defer_off");
const routerBuildDeferOn = checks.find((c) => c.name === "router_build_defer_on");
const sourceAttributeDeferOff = sourceChecks.find((c) => c.name === "source_defer_attribute_defer_off");
const sourceAttributeDeferOn = sourceChecks.find((c) => c.name === "source_defer_attribute_defer_on");
const sourceJsxChildDeferOn = sourceChecks.find((c) => c.name === "source_defer_jsx_child_defer_on");

if (
  explicit?.status === 0 &&
  attribute?.status === 0 &&
  jsxExplicit?.status === 0 &&
  jsxAttribute?.status !== 0
) {
  console.log("\nDefer investigation reproduces JSX-specific failure profile.");
  process.exit(0);
}

if (
  explicit?.status === 0 &&
  attribute?.status === 0 &&
  jsxExplicit?.status === 0 &&
  jsxAttribute?.status === 0 &&
  jsxChild?.status === 0 &&
  routerDeferOff?.status === 0 &&
  routerDeferOn?.status === 0 &&
  routerBuildDeferOff?.status === 0 &&
  routerBuildDeferOn?.status === 0 &&
  sourceAttributeDeferOff?.ok === true &&
  sourceAttributeDeferOn?.ok === true &&
  sourceJsxChildDeferOn?.ok === true
) {
  console.log("\nAll defer probes compile in both modes.");
  process.exit(0);
}

if (routerBuildDeferOff?.status === 0 && routerBuildDeferOn?.status !== 0) {
  console.log("\nRouter full-build probe reproduces defer rewrite failure when RESCRIPT_SHOW_PPX_NATIVE_DEFER=1.");
  process.exit(0);
}

if (routerDeferOff?.status === 0 && routerDeferOn?.status !== 0) {
  console.log("\nRouter probe reproduces defer rewrite failure when RESCRIPT_SHOW_PPX_NATIVE_DEFER=1.");
  process.exit(0);
}

console.log("\nMixed defer investigation result. See output above.");
process.exit(0);
