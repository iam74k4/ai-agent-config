# .cursor Index

Languages: [English](README.md) | [日本語](README.ja.md)

Entry point for rules, documents, and helper scripts under `.cursor/`.

## Workspace

The multi-root workspace file lives at the repository root: `Cursor.code-workspace`. Which folders are included is documented in the root **`README.md` → Workspace** section—update both places together when adding or removing a sibling repo.

## Agents

| Path | Purpose |
|------|---------|
| `agents/README.md` | Where to place agent definitions and how to organize them |

## Documents

| Path | Purpose |
|------|---------|
| `docs/mcp.md` | MCP setup, active servers, and troubleshooting |

## Rules

| Path | Purpose |
|------|---------|
| `rules/README.md` | Index of shared rules |
| `rules/git/git-rules.mdc` | Git workflow, Conventional Commits, and tag policy |
| `rules/docs/readme-rules.mdc` | README structure, writing rules, and Markdown diagram guidance |
| `rules/mcp/context7-rules.mdc` | Rules for when to use Context7 |
| `rules/mcp/drawio-rules.mdc` | Helper rules for draw.io MCP usage |
| `rules/mcp/github-rules.mdc` | Helper rules for GitHub MCP usage |
| `rules/mcp/markitdown-rules.mdc` | Helper rules for MarkItDown MCP usage |

## Scripts

| Path | Purpose |
|------|---------|
| `scripts/README.md` | Script index and prerequisites |
| `scripts/drawio-mcp.sh` | Wrapper with cleanup before starting draw.io MCP |
| `scripts/markitdown-mcp.sh` | Prefer local venv then PATH for `markitdown-mcp` |

## Quick Start

1. Start with the repository root `README.md` for the workspace overview.
2. Check `agents/README.md` before adding agent definitions.
3. Read `docs/mcp.md` before configuring or using MCP servers.
4. Use `rules/README.md` as the entry point for shared rules.
5. Read `scripts/README.md` before using helper scripts.
