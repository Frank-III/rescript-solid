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

const buildEnv = (enableDeferRewrite, enableDeferJsxRewrite) => ({
  ...process.env,
  ...(enableDeferRewrite ? { RESCRIPT_SHOW_PPX_NATIVE_DEFER: "1" } : {}),
  ...(enableDeferJsxRewrite ? { RESCRIPT_SHOW_PPX_NATIVE_DEFER_JSX: "1" } : {}),
});

const modeLabel = (enableDeferRewrite, enableDeferJsxRewrite) => {
  if (!enableDeferRewrite) {
    return "defer_off";
  }

  if (enableDeferJsxRewrite) {
    return "defer_on_jsx";
  }

  return "defer_on";
};

const compileFixture = (name, enableDeferRewrite = false, enableDeferJsxRewrite = false) => {
  const source = path.join(root, "packages", "rescript-show-ppx-native", "fixtures", `${name}.res`);
  const out = path.join(os.tmpdir(), `rescript-show-ppx-native-${name}.ast`);
  const mode = modeLabel(enableDeferRewrite, enableDeferJsxRewrite);

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
    {
      encoding: "utf8",
      env: buildEnv(enableDeferRewrite, enableDeferJsxRewrite),
    },
  );

  return {
    name: mode === "defer_off" ? name : `${name}_${mode}`,
    status: result.status ?? 1,
    error: result.error ? String(result.error) : "",
    stdout: result.stdout ?? "",
    stderr: result.stderr ?? "",
  };
};

const inspectFixtureSource = (name, enableDeferRewrite, enableDeferJsxRewrite = false) => {
  const source = path.join(root, "packages", "rescript-show-ppx-native", "fixtures", `${name}.res`);
  const mode = modeLabel(enableDeferRewrite, enableDeferJsxRewrite);
  const out = path.join(
    os.tmpdir(),
    `rescript-show-ppx-native-source-${name}-${mode}.ast`,
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
      env: buildEnv(enableDeferRewrite, enableDeferJsxRewrite),
    },
  );

  return {
    name: `source_${name}_${mode}`,
    status: result.status ?? 1,
    error: result.error ? String(result.error) : "",
    stdout: result.stdout ?? "",
    stderr: result.stderr ?? "",
    output: `${result.stdout ?? ""}\n${result.stderr ?? ""}`,
  };
};

const countOccurrences = (text, token) =>
  token.length === 0 ? 0 : text.split(token).length - 1;

const evaluateSourceCheck = ({ check, includes = [], excludes = [], counts = [] }) => {
  const output = check.output;
  const hasIncludes = includes.every((token) => output.includes(token));
  const hasExcludes = excludes.every((token) => !output.includes(token));
  const hasCounts = counts.every(({ token, equals }) => countOccurrences(output, token) === equals);
  const ok = check.status === 0 && hasIncludes && hasExcludes && hasCounts;

  return {
    name: check.name,
    ok,
    details:
      check.status !== 0
        ? (check.error || check.stderr || check.stdout).trim()
        : `includes=[${includes.join(", ")}], excludes=[${excludes.join(", ")}], counts=[${counts.map(({ token, equals }) => `${token}:${equals}`).join(", ")}]`,
  };
};

const compileRouterBindingsAudit = (enableDeferRewrite, enableDeferJsxRewrite = false) => {
  const mode = modeLabel(enableDeferRewrite, enableDeferJsxRewrite);
  const out = path.join(
    os.tmpdir(),
    `router_${mode}.ast`,
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
      env: buildEnv(enableDeferRewrite, enableDeferJsxRewrite),
    },
  );

  return {
    name: `router_${mode}`,
    status: result.status ?? 1,
    error: result.error ? String(result.error) : "",
    stdout: result.stdout ?? "",
    stderr: result.stderr ?? "",
  };
};

const runRouterBuildProbe = (enableDeferRewrite, enableDeferJsxRewrite = false) => {
  const mode = modeLabel(enableDeferRewrite, enableDeferJsxRewrite);
  const clean = spawnSync("bun", ["run", "-F", "solid-examples-router", "res:clean"], {
    cwd: root,
    encoding: "utf8",
  });

  if ((clean.status ?? 1) !== 0) {
    return {
      name: `router_build_${mode}`,
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
      env: buildEnv(enableDeferRewrite, enableDeferJsxRewrite),
    },
  );

  return {
    name: `router_build_${mode}`,
    status: result.status ?? 1,
    error: result.error ? String(result.error) : "",
    stdout: result.stdout ?? "",
    stderr: result.stderr ?? "",
  };
};

const checks = [
  compileFixture("defer_explicit"),
  compileFixture("defer_attribute"),
  compileFixture("defer_switch_nonjsx"),
  compileFixture("defer_switch_nonjsx", true),
  compileFixture("defer_jsx_explicit"),
  compileFixture("defer_jsx_attribute"),
  compileFixture("defer_jsx_child"),
  compileFixture("defer_jsx_child", true, true),
  compileRouterBindingsAudit(false),
  compileRouterBindingsAudit(true),
  compileRouterBindingsAudit(true, true),
];

checks.push(runRouterBuildProbe(false));
checks.push(runRouterBuildProbe(true));
checks.push(runRouterBuildProbe(true, true));

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
  evaluateSourceCheck({
    check: inspectFixtureSource("defer_jsx_child", true, true),
    includes: ['"SolidJSX.ppxDefer"', "arity:1"],
  }),
  evaluateSourceCheck({
    check: inspectFixtureSource("defer_switch_nonjsx", false),
    excludes: ['"SolidJSX.ppxDefer"'],
    counts: [{ token: 'Pexp_ident "probeSwitchCallOnce"', equals: 1 }],
  }),
  evaluateSourceCheck({
    check: inspectFixtureSource("defer_switch_nonjsx", true),
    includes: ['"SolidJSX.ppxDefer"'],
    counts: [{ token: 'Pexp_ident "probeSwitchCallOnce"', equals: 1 }],
  }),
  evaluateSourceCheck({
    check: inspectFixtureSource("defer_switch_nonjsx", true, true),
    includes: ['"SolidJSX.ppxDefer"'],
    counts: [{ token: 'Pexp_ident "probeSwitchCallOnce"', equals: 1 }],
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
const switchNonJsx = checks.find((c) => c.name === "defer_switch_nonjsx");
const switchNonJsxDeferOn = checks.find((c) => c.name === "defer_switch_nonjsx_defer_on");
const jsxExplicit = checks.find((c) => c.name === "defer_jsx_explicit");
const jsxAttribute = checks.find((c) => c.name === "defer_jsx_attribute");
const jsxChild = checks.find((c) => c.name === "defer_jsx_child");
const jsxChildDeferOnJsx = checks.find((c) => c.name === "defer_jsx_child_defer_on_jsx");
const routerDeferOff = checks.find((c) => c.name === "router_defer_off");
const routerDeferOn = checks.find((c) => c.name === "router_defer_on");
const routerDeferOnJsx = checks.find((c) => c.name === "router_defer_on_jsx");
const routerBuildDeferOff = checks.find((c) => c.name === "router_build_defer_off");
const routerBuildDeferOn = checks.find((c) => c.name === "router_build_defer_on");
const routerBuildDeferOnJsx = checks.find((c) => c.name === "router_build_defer_on_jsx");
const sourceAttributeDeferOff = sourceChecks.find((c) => c.name === "source_defer_attribute_defer_off");
const sourceAttributeDeferOn = sourceChecks.find((c) => c.name === "source_defer_attribute_defer_on");
const sourceJsxChildDeferOn = sourceChecks.find((c) => c.name === "source_defer_jsx_child_defer_on");
const sourceJsxChildDeferOnJsx = sourceChecks.find((c) => c.name === "source_defer_jsx_child_defer_on_jsx");
const sourceSwitchNonJsxDeferOff = sourceChecks.find((c) => c.name === "source_defer_switch_nonjsx_defer_off");
const sourceSwitchNonJsxDeferOn = sourceChecks.find((c) => c.name === "source_defer_switch_nonjsx_defer_on");
const sourceSwitchNonJsxDeferOnJsx = sourceChecks.find((c) => c.name === "source_defer_switch_nonjsx_defer_on_jsx");

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
  switchNonJsx?.status === 0 &&
  switchNonJsxDeferOn?.status === 0 &&
  jsxExplicit?.status === 0 &&
  jsxAttribute?.status === 0 &&
  jsxChild?.status === 0 &&
  jsxChildDeferOnJsx?.status === 0 &&
  routerDeferOff?.status === 0 &&
  routerDeferOn?.status === 0 &&
  routerDeferOnJsx?.status === 0 &&
  routerBuildDeferOff?.status === 0 &&
  routerBuildDeferOn?.status === 0 &&
  routerBuildDeferOnJsx?.status === 0 &&
  sourceAttributeDeferOff?.ok === true &&
  sourceAttributeDeferOn?.ok === true &&
  sourceJsxChildDeferOn?.ok === true &&
  sourceJsxChildDeferOnJsx?.ok === true &&
  sourceSwitchNonJsxDeferOff?.ok === true &&
  sourceSwitchNonJsxDeferOn?.ok === true &&
  sourceSwitchNonJsxDeferOnJsx?.ok === true
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
