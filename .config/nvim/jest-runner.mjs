#!/usr/bin/env node

import { existsSync, readFileSync } from "node:fs";
import path from "node:path";
import { spawn } from "node:child_process";

function splitShellWords(input) {
  const tokens = [];
  let current = "";
  let quote = null;
  let escaped = false;

  for (const char of input) {
    if (escaped) {
      current += char;
      escaped = false;
      continue;
    }

    if (quote) {
      if (char === quote) {
        quote = null;
      } else if (char === "\\" && quote === '"') {
        escaped = true;
      } else {
        current += char;
      }
      continue;
    }

    if (/\s/.test(char)) {
      if (current !== "") {
        tokens.push(current);
        current = "";
      }
      continue;
    }

    if (char === "'" || char === '"') {
      quote = char;
      continue;
    }

    if (char === "\\") {
      escaped = true;
      continue;
    }

    current += char;
  }

  if (escaped || quote) {
    throw new Error("Unsupported test script quoting in package.json");
  }

  if (current !== "") {
    tokens.push(current);
  }

  return tokens;
}

function isEnvAssignment(token) {
  return /^[A-Za-z_][A-Za-z0-9_]*=/.test(token);
}

function parseEnvAssignments(tokens) {
  const env = {};
  let index = 0;

  while (index < tokens.length && isEnvAssignment(tokens[index])) {
    const token = tokens[index];
    const separator = token.indexOf("=");
    env[token.slice(0, separator)] = token.slice(separator + 1);
    index += 1;
  }

  return { env, commandTokens: tokens.slice(index) };
}

function getRunnerCommand(runner) {
  if (runner === "vitest") {
    return "vitest";
  }

  if (runner === "playwright") {
    return "playwright";
  }

  return "jest";
}

function stripLeadingDoubleDash(args) {
  return args[0] === "--" ? args.slice(1) : args;
}

function isRunnerToken(token, runner) {
  return path.basename(token) === getRunnerCommand(runner);
}

function resolveScriptToRunner(scripts, scriptName, runner, seen = new Set()) {
  if (!scripts || !scripts[scriptName] || seen.has(scriptName)) {
    return null;
  }

  seen.add(scriptName);

  let tokens;
  try {
    tokens = splitShellWords(scripts[scriptName]);
  } catch {
    return null;
  }

  const { env, commandTokens } = parseEnvAssignments(tokens);
  if (commandTokens.length === 0) {
    return null;
  }

  const [command, ...rest] = commandTokens;

  if (isRunnerToken(command, runner)) {
    return { env, args: rest };
  }

  if (["pnpm", "npm", "yarn", "bun"].includes(command)) {
    if (rest[0] === "run" && rest[1]) {
      const resolved = resolveScriptToRunner(scripts, rest[1], runner, seen);
      return resolved && { env: { ...env, ...resolved.env }, args: resolved.args };
    }

    if ((command === "yarn" || command === "pnpm") && rest[0] && scripts[rest[0]]) {
      const resolved = resolveScriptToRunner(scripts, rest[0], runner, seen);
      return resolved && { env: { ...env, ...resolved.env }, args: resolved.args };
    }

    if (isRunnerToken(rest[0], runner)) {
      return { env, args: rest.slice(1) };
    }

    if (rest[0] === "exec" && isRunnerToken(rest[1], runner)) {
      return { env, args: stripLeadingDoubleDash(rest.slice(2)) };
    }
  }

  return null;
}

function findUp(startDir, relativePath) {
  let dir = path.resolve(startDir);

  while (true) {
    const candidate = path.join(dir, relativePath);
    if (existsSync(candidate)) {
      return candidate;
    }

    const parent = path.dirname(dir);
    if (parent === dir) {
      return null;
    }

    dir = parent;
  }
}

function findPackageRoot(startDir) {
  const packageJson = findUp(startDir, "package.json");
  return packageJson ? path.dirname(packageJson) : null;
}

function loadPackageJson(packageRoot) {
  return JSON.parse(readFileSync(path.join(packageRoot, "package.json"), "utf8"));
}

function inferTestType(testFile) {
  const match = path.basename(testFile).match(/\.(\w+)\.test\.[jt]sx?$/);
  return match ? match[1] : null;
}

function findRunnerBinary(startDir, runner) {
  const command = getRunnerCommand(runner);
  return findUp(startDir, path.join("node_modules", ".bin", command)) || command;
}

function inferConfigArgs(packageRoot, runner, testType) {
  if (runner === "vitest") {
    const candidates = [
      "vitest.config.ts",
      "vitest.config.js",
      "vitest.config.mts",
      "vitest.config.mjs",
      "vitest.config.cts",
      "vitest.config.cjs",
    ];

    for (const candidate of candidates) {
      if (existsSync(path.join(packageRoot, candidate))) {
        return ["--config", candidate];
      }
    }

    return [];
  }

  if (runner === "playwright") {
    const candidates = [
      "playwright.config.ts",
      "playwright.config.js",
      "playwright.config.mts",
      "playwright.config.mjs",
      "playwright.config.cts",
      "playwright.config.cjs",
    ];

    for (const candidate of candidates) {
      if (existsSync(path.join(packageRoot, candidate))) {
        return ["-c", candidate];
      }
    }

    return [];
  }

  const candidates = [];
  const extensions = ["ts", "js", "cjs", "mjs"];

  if (testType) {
    for (const extension of extensions) {
      candidates.push(`jest.config.${testType}.${extension}`);
    }
  }

  for (const extension of extensions) {
    candidates.push(`jest.config.${extension}`);
  }

  for (const candidate of candidates) {
    if (existsSync(path.join(packageRoot, candidate))) {
      return ["--config", candidate];
    }
  }

  return [];
}

function findTestFile(args) {
  for (let index = args.length - 1; index >= 0; index -= 1) {
    const value = args[index];
    if (!value || value === "--") {
      continue;
    }

    const resolved = path.resolve(value);
    if (existsSync(resolved)) {
      return resolved;
    }
  }

  return null;
}

function packageHasDependency(packageJson, name) {
  return Boolean(packageJson.dependencies?.[name] || packageJson.devDependencies?.[name]);
}

function detectRunner(packageJson, testFile) {
  const explicitRunner = process.env.NVIM_TEST_RUNNER;
  if (explicitRunner) {
    return explicitRunner;
  }

  const hasJest = packageHasDependency(packageJson, "jest");
  const hasVitest = packageHasDependency(packageJson, "vitest");
  const hasPlaywright = packageHasDependency(packageJson, "@playwright/test");
  const normalizedFile = testFile ? testFile.replace(/\\/g, "/") : "";
  const basename = testFile ? path.basename(testFile) : "";

  if (hasPlaywright && (normalizedFile.includes("/playwright/") || /\.spec\.[jt]sx?$/.test(basename))) {
    return "playwright";
  }

  if (hasJest) {
    return "jest";
  }

  if (hasVitest) {
    return "vitest";
  }

  if (hasPlaywright) {
    return "playwright";
  }

  return "jest";
}

function getScriptCandidates(runner, testType) {
  if (runner === "playwright") {
    return ["test:e2e", "test"];
  }

  const candidates = [];
  if (testType) {
    candidates.push(`test:${testType}`);
  }

  if (!testType || testType === "unit") {
    candidates.push("test:unit");
  }

  candidates.push("test");

  if (runner === "vitest") {
    candidates.push("test:watch");
  }

  return [...new Set(candidates)];
}

const rawArgs = process.argv.slice(2);
const contextFile = process.env.NVIM_TEST_FILE ? path.resolve(process.env.NVIM_TEST_FILE) : null;
const testFile = findTestFile(rawArgs) || (contextFile && existsSync(contextFile) ? contextFile : null);
const packageRoot = findPackageRoot(testFile ? path.dirname(testFile) : process.cwd());

if (!packageRoot) {
  console.error("Could not find a package.json for this Jest run.");
  process.exit(1);
}

const packageJson = loadPackageJson(packageRoot);
const runner = detectRunner(packageJson, testFile);
const testType = testFile ? inferTestType(testFile) : null;
const scriptCandidates = getScriptCandidates(runner, testType);

let resolvedScript = null;
for (const candidate of scriptCandidates) {
  resolvedScript = resolveScriptToRunner(packageJson.scripts, candidate, runner);
  if (resolvedScript) {
    break;
  }
}

const runnerBinary = findRunnerBinary(packageRoot, runner);
const commandArgs = [
  ...(resolvedScript ? resolvedScript.args : inferConfigArgs(packageRoot, runner, testType)),
  ...rawArgs,
];
const env = {
  ...process.env,
  ...(resolvedScript ? resolvedScript.env : {}),
};

const child = spawn(runnerBinary, commandArgs, {
  cwd: packageRoot,
  env,
  stdio: "inherit",
});

child.on("exit", (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal);
    return;
  }

  process.exit(code ?? 1);
});
