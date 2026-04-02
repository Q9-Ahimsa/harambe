#!/usr/bin/env node

// Harambe — enforce-tests hook
// Fires on Stop event. Blocks if source files were modified but tests haven't run.
// Cross-platform (Node.js). Detects: Python (pytest), Node (jest/vitest/mocha), Rust (cargo), Go.

const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

// Read hook input from stdin
let input = "";
try {
  input = fs.readFileSync(0, "utf8");
} catch {
  process.exit(0); // Can't read stdin — skip gracefully
}

if (!input.trim()) process.exit(0);

let json;
try {
  json = JSON.parse(input);
} catch {
  process.exit(0);
}

// Prevent infinite loops
if (json.stop_hook_active) process.exit(0);

// Detect project type and test cache locations
const checks = [
  {
    name: "Python",
    detect: () =>
      fs.existsSync("pyproject.toml") ||
      fs.existsSync("setup.py") ||
      fs.existsSync("tests/"),
    filePattern: /\.py$/,
    caches: [".pytest_cache", ".tox", "__pycache__"],
    command: "pytest",
  },
  {
    name: "Node.js",
    detect: () => fs.existsSync("package.json"),
    filePattern: /\.(ts|tsx|js|jsx)$/,
    caches: [
      "node_modules/.cache/jest",
      "node_modules/.cache/vitest",
      "coverage",
    ],
    command: "npm test",
  },
  {
    name: "Rust",
    detect: () => fs.existsSync("Cargo.toml"),
    filePattern: /\.rs$/,
    caches: ["target/debug/.fingerprint"],
    command: "cargo test",
  },
  {
    name: "Go",
    detect: () => fs.existsSync("go.mod"),
    filePattern: /\.go$/,
    caches: [],
    command: "go test ./...",
  },
];

// Find matching project type
const project = checks.find((c) => c.detect());
if (!project) process.exit(0); // Not a recognized project type

// Check if relevant source files were modified
let changedFiles = "";
try {
  changedFiles = execSync("git diff --name-only HEAD 2>/dev/null", {
    encoding: "utf8",
    timeout: 5000,
  });
} catch {
  process.exit(0); // Not a git repo or git error
}

const hasRelevantChanges = changedFiles
  .split("\n")
  .some((f) => project.filePattern.test(f.trim()));

if (!hasRelevantChanges) process.exit(0);

// Check if tests ran recently (cache updated in last 5 minutes)
const fiveMinAgo = Date.now() - 5 * 60 * 1000;
const testRanRecently = project.caches.some((cachePath) => {
  try {
    const stat = fs.statSync(cachePath);
    return stat.mtimeMs > fiveMinAgo;
  } catch {
    return false;
  }
});

if (testRanRecently) process.exit(0);

// Block — tests haven't run
const result = {
  decision: "block",
  reason: `${project.name} files were modified but tests haven't run recently. Run: ${project.command}`,
};

process.stdout.write(JSON.stringify(result));
process.exit(0);
