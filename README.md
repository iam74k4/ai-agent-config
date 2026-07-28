# AI Agent Config

![License](https://img.shields.io/github/license/iam74k4/ai-agent-config)

Shared rules and local bootstrap tooling for Cursor, Claude Code, and GitHub Copilot.

## Quick start

Clone the repository anywhere, then run the setup command for your platform.

```bash
git clone https://github.com/iam74k4/ai-agent-config.git
cd ai-agent-config
./scripts/setup.sh
```

```powershell
git clone https://github.com/iam74k4/ai-agent-config.git
Set-Location ai-agent-config
.\scripts\setup.ps1
```

Setup creates a local MCP configuration, optionally installs MarkItDown, and generates a `<repository>.code-workspace` file. Open that workspace in Cursor. Re-run setup whenever sibling repositories change.

## Requirements

| Feature | Requirement | Behavior when unavailable |
|---|---|---|
| Core setup | Git | Setup stops because Git is required |
| Workspace and draw.io MCP | Node.js 20+ | draw.io is omitted from local MCP config |
| MarkItDown MCP | Python 3.10+ | MarkItDown is skipped with a warning |
| GitHub MCP | `GITHUB_MCP_PAT` | GitHub MCP is omitted until a token is provided |
| Higher Context7 limits | `CONTEXT7_API_KEY` | Context7 uses anonymous access |

`GITHUB_PAT` and `GITHUB_TOKEN` are accepted as compatibility aliases. Tokens are read from the environment and written only to the gitignored `.cursor/mcp.json`.

## Commands

| Command | Purpose |
|---|---|
| `./scripts/setup.sh` | macOS/Linux bootstrap |
| `.\scripts\setup.ps1` | Windows PowerShell bootstrap |
| `./scripts/doctor.sh` | Non-destructive macOS/Linux diagnostic |
| `.\scripts\doctor.ps1` | Non-destructive Windows diagnostic |
| `node scripts/sync-rules.mjs` | Regenerate tool-specific rule adapters |
| `node scripts/sync-rules.mjs --check` | Fail if generated adapters have drifted |

Useful setup options are `--no-venv`, `--no-mcp`, and `--no-workspace` for Bash; PowerShell equivalents use `-NoVenv`, `-NoMcp`, and `-NoWorkspace`. Use `--force` or `-Force` only to replace an existing local MCP config.

## Rule model

```mermaid
flowchart TD
  canonical[Canonical_rules] --> generated[Generated_adapters]
  generated --> cursor[Cursor_MDC]
  generated --> claude[Claude_rules]
  generated --> copilot[Copilot_instructions]
  common[AGENTS_md] --> cursor
  common --> claude
  common --> copilot
```

- `AGENTS.md` contains minimal repository-wide behavior.
- `rules/` is the source of shared, path-aware rules.
- `.cursor/rules/generated/`, `.claude/rules/`, and `.github/instructions/` are generated; edit `rules/`, then run the sync command.
- Tool-specific MCP instructions stay in `.cursor/rules/mcp/`.

## Workspace

The generated workspace includes this repository and every Git repository beside it. It also generates matching `Git: fetch all workspaces` and `Git: status all workspaces` tasks, preventing folder/task drift.

## Documentation

- `.cursor/README.md`: Cursor-specific index
- `.cursor/docs/mcp.md`: local MCP configuration and security
- `.cursor/scripts/README.md`: legacy Cursor helper scripts
- `docs/release-policy.md`: release and historical-tag policy
- `rules/`: common rule sources

## License

[MIT](LICENSE)
