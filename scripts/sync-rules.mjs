#!/usr/bin/env node
/**
 * Render canonical rules into the metadata formats understood by Cursor,
 * Claude Code, and GitHub Copilot.
 *
 * Usage:
 *   node scripts/sync-rules.mjs
 *   node scripts/sync-rules.mjs --check
 */
import { readFile, readdir, mkdir, writeFile } from "node:fs/promises";
import { relative, resolve, dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import process from "node:process";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const sourceDirectory = join(root, "rules");
const checkOnly = process.argv.includes("--check");

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

function parseRule(sourcePath, source) {
  const match = source.match(/^---\n([\s\S]*?)\n---\n\n?([\s\S]*)$/);
  if (!match) throw new Error(`${relative(root, sourcePath)} has no frontmatter`);

  const metadata = {};
  for (const line of match[1].split("\n")) {
    const separator = line.indexOf(":");
    if (separator === -1) continue;
    const key = line.slice(0, separator).trim();
    const value = line.slice(separator + 1).trim().replace(/^"|"$/g, "");
    metadata[key] = value;
  }

  if (!metadata.id || !metadata.description) {
    throw new Error(`${relative(root, sourcePath)} needs id and description`);
  }
  return { metadata, body: match[2].trimEnd() };
}

function cursorRule({ metadata, body }) {
  const frontmatter = [
    `description: ${metadata.description}`,
    metadata.globs ? `globs: ${metadata.globs}` : null,
    `alwaysApply: ${metadata.alwaysApply ?? "false"}`,
  ]
    .filter(Boolean)
    .join("\n");
  return `---\n${frontmatter}\n---\n\n<!-- Generated from rules; do not edit directly. -->\n\n${body}\n`;
}

function claudeRule({ metadata, body }) {
  const frontmatter = metadata.globs
    ? `---\npaths:\n  - ${metadata.globs}\n---\n\n`
    : "";
  return `${frontmatter}<!-- Generated from rules; do not edit directly. -->\n\n${body}\n`;
}

function copilotRule({ metadata, body }) {
  if (!metadata.globs) return null;
  return `---\napplyTo: ${metadata.globs}\n---\n\n<!-- Generated from rules; do not edit directly. -->\n\n${body}\n`;
}

async function ensureContents(path, expected) {
  try {
    const actual = await readFile(path, "utf8");
    if (actual === expected) return true;
  } catch {
    // This is reported as a drift below.
  }

  if (checkOnly) {
    console.error(`Generated file is out of date: ${relative(root, path)}`);
    return false;
  }

  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, expected);
  console.log(`Wrote ${relative(root, path)}`);
  return true;
}

let valid = true;
for (const sourcePath of await filesIn(sourceDirectory)) {
  const rule = parseRule(sourcePath, await readFile(sourcePath, "utf8"));
  const cursorValid = await ensureContents(
    join(root, ".cursor", "rules", "generated", `${rule.metadata.id}.mdc`),
    cursorRule(rule),
  );
  valid &&= cursorValid;
  const claudeValid = await ensureContents(
    join(root, ".claude", "rules", `${rule.metadata.id}.md`),
    claudeRule(rule),
  );
  valid &&= claudeValid;

  const copilot = copilotRule(rule);
  if (copilot) {
    const copilotValid = await ensureContents(
      join(root, ".github", "instructions", `${rule.metadata.id}.instructions.md`),
      copilot,
    );
    valid &&= copilotValid;
  }
}

if (!valid) process.exitCode = 1;
