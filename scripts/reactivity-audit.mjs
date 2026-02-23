import fs from "fs";
import path from "path";

const ROOT = process.cwd();
const SKIP_DIRS = new Set([
  ".git",
  ".turbo",
  "node_modules",
  "dist",
  ".rescript",
  ".bun",
  "lib",
]);

const REACTIVE_SOURCES = [
  "useParams",
  "useLocation",
  "useSearchParams",
  "useMatch",
  "useIsRouting",
];

const ACCESSOR_SOURCES = [
  "createSignal",
  "createMemo",
  "createResource",
  "createAsync",
];

const isMjsSource = filePath =>
  filePath.endsWith(".mjs") && filePath.includes(`${path.sep}src${path.sep}`);

const walk = dir => {
  let results = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.isDirectory()) {
      if (SKIP_DIRS.has(entry.name)) continue;
      results = results.concat(walk(path.join(dir, entry.name)));
      continue;
    }
    const fullPath = path.join(dir, entry.name);
    if (isMjsSource(fullPath)) results.push(fullPath);
  }
  return results;
};

const scanFile = filePath => {
  const content = fs.readFileSync(filePath, "utf8");
  const lines = content.split(/\r?\n/);
  const reactiveObjects = new Set();
  const accessors = new Set();
  const issues = [];

  const sourceRegex = new RegExp(
    `\\b(const|let)\\s+(\\w+)\\s*=\\s*.*\\b(${REACTIVE_SOURCES.join(
      "|",
    )})\\s*\\(`,
  );

  const accessorRegex = new RegExp(
    `\\b(const|let)\\s+(\\w+)\\s*=\\s*.*\\b(${ACCESSOR_SOURCES.join(
      "|",
    )})\\s*\\(`,
  );

  for (let i = 0; i < lines.length; i += 1) {
    const line = lines[i];
    const sourceMatch = line.match(sourceRegex);
    if (sourceMatch) reactiveObjects.add(sourceMatch[2]);

    const accessorMatch = line.match(accessorRegex);
    if (accessorMatch) {
      accessors.add(accessorMatch[2]);
      continue;
    }

    for (const obj of reactiveObjects) {
      const propRead = new RegExp(
        `\\b(const|let)\\s+\\w+\\s*=\\s*${obj}\\.`,
      );
      const indexRead = new RegExp(
        `\\b(const|let)\\s+\\w+\\s*=\\s*${obj}\\[`,
      );
      if (propRead.test(line) || indexRead.test(line)) {
        issues.push({
          filePath,
          line: i + 1,
          kind: "early-read",
          detail: `derived value from ${obj} stored in local`,
        });
      }
    }

    for (const accessor of accessors) {
      const callRead = new RegExp(
        `\\b(const|let)\\s+\\w+\\s*=\\s*${accessor}\\s*\\(\\s*\\)`,
      );
      if (callRead.test(line)) {
        issues.push({
          filePath,
          line: i + 1,
          kind: "frozen-accessor",
          detail: `value read from ${accessor}() stored in local`,
        });
      }
    }
  }

  return issues;
};

const files = walk(ROOT);
if (files.length === 0) {
  console.log("No compiled .mjs sources found under src/. Run rescript build first.");
  process.exit(0);
}

const allIssues = files.flatMap(scanFile);
if (allIssues.length === 0) {
  console.log("No early reactive reads detected.");
  process.exit(0);
}

for (const issue of allIssues) {
  const relative = path.relative(ROOT, issue.filePath);
  console.log(`${relative}:${issue.line} ${issue.kind} ${issue.detail}`);
}

console.log(`\nFound ${allIssues.length} potential issue(s).`);
