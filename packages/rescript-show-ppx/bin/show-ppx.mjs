#!/usr/bin/env node

import fs from "fs";
import path from "path";
import { spawnSync } from "child_process";

const isResFile = filePath => filePath.endsWith(".res");

const collectResFiles = targetPath => {
  const absolute = path.resolve(process.cwd(), targetPath);
  if (!fs.existsSync(absolute)) {
    return [];
  }

  const stat = fs.statSync(absolute);
  if (stat.isFile()) {
    return isResFile(absolute) ? [absolute] : [];
  }

  let files = [];
  for (const entry of fs.readdirSync(absolute, { withFileTypes: true })) {
    if (entry.name === "node_modules" || entry.name === ".git" || entry.name === ".rescript") {
      continue;
    }
    files = files.concat(collectResFiles(path.join(absolute, entry.name)));
  }
  return files;
};

const skipWhitespace = (source, index) => {
  let i = index;
  while (i < source.length && /\s/.test(source[i])) {
    i += 1;
  }
  return i;
};

const isFallbackPattern = pattern => pattern === "_" || pattern === "None";

const parsePayloadPattern = pattern => {
  const match = pattern.match(/^([#A-Za-z_][A-Za-z0-9_\.]*)\(([_A-Za-z][_A-Za-z0-9]*)\)$/);
  if (!match) {
    return null;
  }
  return { ctor: match[1], name: match[2] };
};

const isSimpleValuePattern = pattern => {
  if (isFallbackPattern(pattern)) {
    return false;
  }

  if (/^"[\s\S]*"$/.test(pattern) || /^'[\s\S]*'$/.test(pattern)) {
    return true;
  }

  if (/^-?\d+(\.\d+)?$/.test(pattern)) {
    return true;
  }

  if (pattern === "true" || pattern === "false") {
    return true;
  }

  return /^[#A-Za-z_][A-Za-z0-9_\.]*$/.test(pattern);
};

const parseSwitchCases = block => {
  const cases = [];
  let i = 0;

  while (i < block.length) {
    i = skipWhitespace(block, i);
    if (i >= block.length) {
      break;
    }

    if (block[i] !== "|") {
      return null;
    }

    i += 1;
    const patternStart = i;

    let roundDepth = 0;
    let squareDepth = 0;
    let curlyDepth = 0;
    let stringQuote = null;

    while (i < block.length) {
      const ch = block[i];
      const prev = i > 0 ? block[i - 1] : "";

      if (stringQuote !== null) {
        if (ch === stringQuote && prev !== "\\") {
          stringQuote = null;
        }
        i += 1;
        continue;
      }

      if (ch === '"' || ch === "'" || ch === "`") {
        stringQuote = ch;
        i += 1;
        continue;
      }

      if (ch === "(") {
        roundDepth += 1;
        i += 1;
        continue;
      }

      if (ch === ")") {
        roundDepth -= 1;
        i += 1;
        continue;
      }

      if (ch === "[") {
        squareDepth += 1;
        i += 1;
        continue;
      }

      if (ch === "]") {
        squareDepth -= 1;
        i += 1;
        continue;
      }

      if (ch === "{") {
        curlyDepth += 1;
        i += 1;
        continue;
      }

      if (ch === "}") {
        if (curlyDepth > 0) {
          curlyDepth -= 1;
        }
        i += 1;
        continue;
      }

      if (ch === "=" && block[i + 1] === ">" && roundDepth === 0 && squareDepth === 0 && curlyDepth === 0) {
        break;
      }

      i += 1;
    }

    if (i >= block.length || block[i] !== "=" || block[i + 1] !== ">") {
      return null;
    }

    const pattern = block.slice(patternStart, i).trim();
    i += 2;

    const exprStart = i;
    roundDepth = 0;
    squareDepth = 0;
    curlyDepth = 0;
    stringQuote = null;

    while (i < block.length) {
      const ch = block[i];
      const prev = i > 0 ? block[i - 1] : "";

      if (stringQuote !== null) {
        if (ch === stringQuote && prev !== "\\") {
          stringQuote = null;
        }
        i += 1;
        continue;
      }

      if (ch === '"' || ch === "'" || ch === "`") {
        stringQuote = ch;
        i += 1;
        continue;
      }

      if (ch === "(") {
        roundDepth += 1;
        i += 1;
        continue;
      }

      if (ch === ")") {
        roundDepth -= 1;
        i += 1;
        continue;
      }

      if (ch === "[") {
        squareDepth += 1;
        i += 1;
        continue;
      }

      if (ch === "]") {
        squareDepth -= 1;
        i += 1;
        continue;
      }

      if (ch === "{") {
        curlyDepth += 1;
        i += 1;
        continue;
      }

      if (ch === "}") {
        if (curlyDepth > 0) {
          curlyDepth -= 1;
        }
        i += 1;
        continue;
      }

      if (ch === "|" && roundDepth === 0 && squareDepth === 0 && curlyDepth === 0) {
        const lineStart = block.lastIndexOf("\n", i - 1) + 1;
        const beforePipe = block.slice(lineStart, i);
        if (/^\s*$/.test(beforePipe)) {
          break;
        }
      }

      i += 1;
    }

    const expr = block.slice(exprStart, i).trim();
    cases.push({ pattern, expr });
  }

  return cases.length > 0 ? cases : null;
};

const buildShowOption = ({ expr, valueName, someExpr, fallbackExpr, indent }) =>
  `${indent}<SolidJSX.ShowOption when_={${expr}} fallback={${fallbackExpr}}>\n${indent}  {${valueName} => ${someExpr}}\n${indent}</SolidJSX.ShowOption>`;

const buildShowOptionFromSwitch = ({ expr, ctor, valueName, someExpr, fallbackExpr, indent }) => {
  const lifted = `switch ${expr} {\n${indent}  | ${ctor}(${valueName}) => Some(${valueName})\n${indent}  | _ => None\n${indent}}`;
  return buildShowOption({ expr: lifted, valueName, someExpr, fallbackExpr, indent });
};

const buildSwitchMatch = ({ expr, valueCases, fallbackExpr, indent }) => {
  const fallbackProp = fallbackExpr === null ? "" : ` fallback_={${fallbackExpr}}`;
  const lines = [`${indent}<SolidJSX.Switch.make${fallbackProp}>`];

  for (const valueCase of valueCases) {
    lines.push(
      `${indent}  <SolidJSX.Match.make when_={${expr} == ${valueCase.pattern}}>${valueCase.expr}</SolidJSX.Match.make>`,
    );
  }

  lines.push(`${indent}</SolidJSX.Switch.make>`);
  return lines.join("\n");
};

const parseShowSwitch = (source, startIndex) => {
  let i = startIndex + "@show".length;
  i = skipWhitespace(source, i);

  if (!source.startsWith("switch", i)) {
    return null;
  }

  i += "switch".length;
  i = skipWhitespace(source, i);

  const exprStart = i;
  let roundDepth = 0;
  let squareDepth = 0;
  let curlyDepth = 0;
  let stringQuote = null;

  while (i < source.length) {
    const ch = source[i];
    const prev = i > 0 ? source[i - 1] : "";

    if (stringQuote !== null) {
      if (ch === stringQuote && prev !== "\\") {
        stringQuote = null;
      }
      i += 1;
      continue;
    }

    if (ch === '"' || ch === "'" || ch === "`") {
      stringQuote = ch;
      i += 1;
      continue;
    }

    if (ch === "(") {
      roundDepth += 1;
      i += 1;
      continue;
    }

    if (ch === ")") {
      roundDepth -= 1;
      i += 1;
      continue;
    }

    if (ch === "[") {
      squareDepth += 1;
      i += 1;
      continue;
    }

    if (ch === "]") {
      squareDepth -= 1;
      i += 1;
      continue;
    }

    if (ch === "{") {
      if (roundDepth === 0 && squareDepth === 0 && curlyDepth === 0) {
        break;
      }
      curlyDepth += 1;
      i += 1;
      continue;
    }

    if (ch === "}") {
      if (curlyDepth > 0) {
        curlyDepth -= 1;
      }
      i += 1;
      continue;
    }

    i += 1;
  }

  if (i >= source.length || source[i] !== "{") {
    return null;
  }

  const expr = source.slice(exprStart, i).trim();
  const blockStart = i;
  i += 1;

  let blockDepth = 1;
  stringQuote = null;

  while (i < source.length && blockDepth > 0) {
    const ch = source[i];
    const prev = i > 0 ? source[i - 1] : "";

    if (stringQuote !== null) {
      if (ch === stringQuote && prev !== "\\") {
        stringQuote = null;
      }
      i += 1;
      continue;
    }

    if (ch === '"' || ch === "'" || ch === "`") {
      stringQuote = ch;
      i += 1;
      continue;
    }

    if (ch === "{") {
      blockDepth += 1;
      i += 1;
      continue;
    }

    if (ch === "}") {
      blockDepth -= 1;
      i += 1;
      continue;
    }

    i += 1;
  }

  if (blockDepth !== 0) {
    return null;
  }

  const endIndex = i;
  const block = source.slice(blockStart + 1, endIndex - 1);
  const cases = parseSwitchCases(block);
  if (cases === null) {
    return null;
  }

  const lineStart = source.lastIndexOf("\n", startIndex) + 1;
  const prefix = source.slice(lineStart, startIndex);
  const indentMatch = prefix.match(/^\s*/);
  const indent = indentMatch ? indentMatch[0] : "";

  if (cases.length === 2) {
    const firstPayload = parsePayloadPattern(cases[0].pattern);
    const secondPayload = parsePayloadPattern(cases[1].pattern);
    const firstFallback = isFallbackPattern(cases[0].pattern);
    const secondFallback = isFallbackPattern(cases[1].pattern);

    if (firstPayload?.ctor === "Some" && secondFallback) {
      return {
        endIndex,
        replacement: buildShowOption({
          expr,
          valueName: firstPayload.name,
          someExpr: cases[0].expr,
          fallbackExpr: cases[1].expr,
          indent,
        }),
      };
    }

    if (secondPayload?.ctor === "Some" && firstFallback) {
      return {
        endIndex,
        replacement: buildShowOption({
          expr,
          valueName: secondPayload.name,
          someExpr: cases[1].expr,
          fallbackExpr: cases[0].expr,
          indent,
        }),
      };
    }

    if (firstPayload && secondFallback) {
      return {
        endIndex,
        replacement: buildShowOptionFromSwitch({
          expr,
          ctor: firstPayload.ctor,
          valueName: firstPayload.name,
          someExpr: cases[0].expr,
          fallbackExpr: cases[1].expr,
          indent,
        }),
      };
    }

    if (secondPayload && firstFallback) {
      return {
        endIndex,
        replacement: buildShowOptionFromSwitch({
          expr,
          ctor: secondPayload.ctor,
          valueName: secondPayload.name,
          someExpr: cases[1].expr,
          fallbackExpr: cases[0].expr,
          indent,
        }),
      };
    }
  }

  const fallbackCase = cases.find(item => item.pattern === "_");
  const valueCases = cases.filter(item => item.pattern !== "_");
  if (valueCases.length >= 1 && valueCases.every(item => isSimpleValuePattern(item.pattern))) {
    return {
      endIndex,
      replacement: buildSwitchMatch({
        expr,
        valueCases,
        fallbackExpr: fallbackCase ? fallbackCase.expr : null,
        indent,
      }),
    };
  }

  return null;
};

const parseDefer = (source, startIndex) => {
  let i = startIndex + "@defer".length;
  i = skipWhitespace(source, i);

  if (i >= source.length || source[i] !== "{") {
    return null;
  }

  const blockStart = i;
  i += 1;

  let depth = 1;
  let stringQuote = null;

  while (i < source.length && depth > 0) {
    const ch = source[i];
    const prev = i > 0 ? source[i - 1] : "";

    if (stringQuote !== null) {
      if (ch === stringQuote && prev !== "\\") {
        stringQuote = null;
      }
      i += 1;
      continue;
    }

    if (ch === '"' || ch === "'" || ch === "`") {
      stringQuote = ch;
      i += 1;
      continue;
    }

    if (ch === "{") {
      depth += 1;
      i += 1;
      continue;
    }

    if (ch === "}") {
      depth -= 1;
      i += 1;
      continue;
    }

    i += 1;
  }

  if (depth !== 0) {
    return null;
  }

  const endIndex = i;
  const body = source.slice(blockStart + 1, endIndex - 1);
  const replacement = `Solid.createMemo(() => {${body}})()`;
  return { endIndex, replacement };
};

const findNextDirective = (source, fromIndex) => {
  const showAt = source.indexOf("@show", fromIndex);
  const deferAt = source.indexOf("@defer", fromIndex);

  if (showAt === -1 && deferAt === -1) {
    return null;
  }

  if (showAt === -1) {
    return { kind: "defer", index: deferAt };
  }

  if (deferAt === -1) {
    return { kind: "show", index: showAt };
  }

  if (showAt < deferAt) {
    return { kind: "show", index: showAt };
  }

  return { kind: "defer", index: deferAt };
};

const transformSource = source => {
  let index = 0;
  let output = "";
  let transformed = false;

  while (index < source.length) {
    const directive = findNextDirective(source, index);
    if (directive === null) {
      output += source.slice(index);
      break;
    }

    const at = directive.index;

    output += source.slice(index, at);
    const parsed =
      directive.kind === "show"
        ? parseShowSwitch(source, at)
        : parseDefer(source, at);

    if (parsed === null) {
      const token = directive.kind === "show" ? "@show" : "@defer";
      output += token;
      index = at + token.length;
      continue;
    }

    output += parsed.replacement;
    index = parsed.endIndex;
    transformed = true;
  }

  return { output, transformed };
};

const collectTransforms = roots => {
  const files = roots.flatMap(collectResFiles);
  if (files.length === 0) {
    return [];
  }

  const updates = [];
  for (const filePath of files) {
    const source = fs.readFileSync(filePath, "utf8");
    const result = transformSource(source);
    if (!result.transformed) {
      continue;
    }
    updates.push({ filePath, original: source, transformed: result.output });
  }

  return updates;
};

const writeTransforms = updates => {
  for (const update of updates) {
    fs.writeFileSync(update.filePath, update.transformed, "utf8");
  }
};

const restoreTransforms = updates => {
  for (const update of updates) {
    fs.writeFileSync(update.filePath, update.original, "utf8");
  }
};

const usage = () => {
  console.log("Usage:");
  console.log("  rescript-show-ppx rewrite [roots...]");
  console.log("  rescript-show-ppx run [roots...] -- <command> [args...]");
};

const args = process.argv.slice(2);
const mode = args[0] ?? "rewrite";

if (mode !== "rewrite" && mode !== "run") {
  usage();
  process.exit(1);
}

if (mode === "rewrite") {
  const roots = args.slice(1);
  const targets = roots.length > 0 ? roots : ["src"];
  const updates = collectTransforms(targets);

  if (updates.length === 0) {
    console.log("rescript-show-ppx: no @show rewrites applied");
    process.exit(0);
  }

  writeTransforms(updates);
  console.log(`rescript-show-ppx: rewrote ${updates.length} file(s)`);
  process.exit(0);
}

const separator = args.indexOf("--");
if (separator === -1 || separator === args.length - 1) {
  usage();
  process.exit(1);
}

const roots = args.slice(1, separator);
const targets = roots.length > 0 ? roots : ["src"];
const command = args.slice(separator + 1);

const updates = collectTransforms(targets);
if (updates.length === 0) {
  const result = spawnSync(command[0], command.slice(1), {
    stdio: "inherit",
    cwd: process.cwd(),
  });
  process.exit(result.status ?? 1);
}

writeTransforms(updates);

let status = 0;
try {
  const result = spawnSync(command[0], command.slice(1), {
    stdio: "inherit",
    cwd: process.cwd(),
  });
  status = result.status ?? 1;
} finally {
  restoreTransforms(updates);
}

process.exit(status);
