#!/usr/bin/env node
/**
 * Render canonical rules into the metadata formats understood by Cursor,
 * Claude Code, and GitHub Copilot.
 *
 * Adapters under .cursor/rules/generated/, .claude/rules/, and
 * .github/instructions/ are written as whole files. AGENTS.md and
 * .github/copilot-instructions.md keep hand-written content and only have the
 * always-applied rules spliced between their generated markers.
 *
 * Usage:
 *   node scripts/sync-rules.mjs
 *   node scripts/sync-rules.mjs --check
 */
import { readFile, readdir, mkdir, unlink, writeFile } from "node:fs/promises";
import { relative, resolve, dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import process from "node:process";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const sourceDirectory = join(root, "rules");
const checkOnly = process.argv.includes("--check");

const generatedMarker = "Generated from rules; do not edit directly.";
const sectionStart = "<!-- generated:rules:start -->";
const sectionEnd = "<!-- generated:rules:end -->";
// Rule ids become file names, so keep them to a slug that cannot escape the
// target directory.
const idPattern = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

function show(path) {
  return relative(root, path);
}

async function filesIn(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const nested = await Promise.all(
    entries
      .sort((left, right) => left.name.localeCompare(right.name))
      .map(async (entry) => {
        const path = join(directory, entry.name);
        if (entry.isDirectory()) return filesIn(path);
        return entry.isFile() && entry.name.endsWith(".md") ? [path] : [];
      }),
  );
  return nested.flat();
}

async function generatedFilesIn(directory, extension) {
  try {
    const entries = await readdir(directory, { withFileTypes: true });
    const nested = await Promise.all(
      entries.map(async (entry) => {
        const path = join(directory, entry.name);
        if (entry.isDirectory()) return generatedFilesIn(path, extension);
        return entry.isFile() && entry.name.endsWith(extension) ? [path] : [];
      }),
    );
    return nested.flat();
  } catch (error) {
    if (error.code === "ENOENT") return [];
    throw error;
  }
}

function parseRule(sourcePath, source) {
  const match = source.match(/^---\n([\s\S]*?)\n---\n\n?([\s\S]*)$/);
  if (!match) throw new Error(`${show(sourcePath)} has no frontmatter`);

  const metadata = {};
  for (const line of match[1].split("\n")) {
    const separator = line.indexOf(":");
    if (separator === -1) continue;
    const key = line.slice(0, separator).trim();
    const value = line.slice(separator + 1).trim().replace(/^"|"$/g, "");
    metadata[key] = value;
  }

  if (!metadata.id || !metadata.description) {
    throw new Error(`${show(sourcePath)} needs id and description`);
  }
  if (!idPattern.test(metadata.id)) {
    throw new Error(
      `${show(sourcePath)} has an invalid id "${metadata.id}"; use lowercase letters, digits, and hyphens`,
    );
  }
  return { sourcePath, metadata, body: match[2].trimEnd() };
}

function cursorRule({ metadata, body }) {
  const frontmatter = [
    `description: ${metadata.description}`,
    metadata.globs ? `globs: ${metadata.globs}` : null,
    `alwaysApply: ${metadata.alwaysApply ?? "false"}`,
  ]
    .filter(Boolean)
    .join("\n");
  return `---\n${frontmatter}\n---\n\n<!-- ${generatedMarker} -->\n\n${body}\n`;
}

function claudeRule({ metadata, body }) {
  // Claude Code loads every file in .claude/rules/ regardless of frontmatter,
  // so state the scope in prose the agent actually reads.
  const frontmatter = metadata.globs
    ? `---\npaths:\n  - ${metadata.globs}\n---\n\n`
    : "";
  const scope = metadata.globs
    ? `<!-- Advisory scope: apply when the change touches ${metadata.globs}. -->\n`
    : "";
  return `${frontmatter}<!-- ${generatedMarker} -->\n${scope}\n${body}\n`;
}

function copilotRule({ metadata, body }) {
  if (!metadata.globs) return null;
  return `---\napplyTo: ${metadata.globs}\n---\n\n<!-- ${generatedMarker} -->\n\n${body}\n`;
}

// Always-applied rules are shared verbatim by AGENTS.md and the Copilot
// repository instructions, which are otherwise hand-written.
function sharedSection(rules) {
  const bodies = rules.map(({ body }) => body.replace(/^# /, "## "));
  return `\n<!-- ${generatedMarker} Edit rules/ and run: node scripts/sync-rules.mjs -->\n\n${bodies.join("\n\n")}\n\n`;
}

async function ensureContents(path, expected) {
  try {
    const actual = await readFile(path, "utf8");
    if (actual === expected) return true;
  } catch {
    // This is reported as a drift below.
  }

  if (checkOnly) {
    console.error(`Generated file is out of date: ${show(path)}`);
    return false;
  }

  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, expected);
  console.log(`Wrote ${show(path)}`);
  return true;
}

async function ensureSection(path, section) {
  let current;
  try {
    current = await readFile(path, "utf8");
  } catch {
    console.error(`Missing file: ${show(path)}`);
    return false;
  }

  const start = current.indexOf(sectionStart);
  const end = current.indexOf(sectionEnd);
  if (start === -1 || end === -1 || end < start) {
    console.error(`${show(path)} is missing the ${sectionStart} / ${sectionEnd} markers`);
    return false;
  }

  const expected =
    current.slice(0, start) + sectionStart + section + sectionEnd + current.slice(end + sectionEnd.length);
  if (expected === current) return true;

  if (checkOnly) {
    console.error(`Generated section is out of date: ${show(path)}`);
    return false;
  }

  await writeFile(path, expected);
  console.log(`Updated ${show(path)}`);
  return true;
}

const rules = [];
const seenIds = new Map();
for (const sourcePath of await filesIn(sourceDirectory)) {
  const rule = parseRule(sourcePath, await readFile(sourcePath, "utf8"));
  const previous = seenIds.get(rule.metadata.id);
  if (previous) {
    throw new Error(
      `duplicate rule id "${rule.metadata.id}" in ${show(previous)} and ${show(sourcePath)}`,
    );
  }
  seenIds.set(rule.metadata.id, sourcePath);
  rules.push(rule);
}

let valid = true;
const expectedPaths = new Set();
const targets = [
  { directory: join(root, ".cursor", "rules", "generated"), extension: ".mdc" },
  { directory: join(root, ".claude", "rules"), extension: ".md" },
  { directory: join(root, ".github", "instructions"), extension: ".instructions.md" },
];

for (const rule of rules) {
  const cursorPath = join(root, ".cursor", "rules", "generated", `${rule.metadata.id}.mdc`);
  expectedPaths.add(cursorPath);
  valid &&= await ensureContents(cursorPath, cursorRule(rule));

  const claudePath = join(root, ".claude", "rules", `${rule.metadata.id}.md`);
  expectedPaths.add(claudePath);
  valid &&= await ensureContents(claudePath, claudeRule(rule));

  const copilot = copilotRule(rule);
  if (copilot) {
    const copilotPath = join(root, ".github", "instructions", `${rule.metadata.id}.instructions.md`);
    expectedPaths.add(copilotPath);
    valid &&= await ensureContents(copilotPath, copilot);
  }
}

const section = sharedSection(rules.filter((rule) => rule.metadata.alwaysApply === "true"));
valid &&= await ensureSection(join(root, "AGENTS.md"), section);
valid &&= await ensureSection(join(root, ".github", "copilot-instructions.md"), section);

for (const target of targets) {
  for (const path of await generatedFilesIn(target.directory, target.extension)) {
    if (expectedPaths.has(path)) continue;
    const content = await readFile(path, "utf8");
    if (!content.includes(generatedMarker)) continue;

    if (checkOnly) {
      console.error(`Stale generated file: ${show(path)}`);
      valid = false;
    } else {
      await unlink(path);
      console.log(`Removed ${show(path)}`);
    }
  }
}

if (!valid) process.exitCode = 1;
