# Cursor configuration

Cursor-specific files live under `.cursor/`. Run `scripts/setup.sh` or `scripts/setup.ps1` after cloning to generate the ignored local MCP configuration and workspace file.

## Directories

| Path | Purpose |
|---|---|
| `rules/generated/` | Generated shared Cursor rules; do not edit |
| `rules/mcp/` | Cursor-specific MCP usage guidance |
| `agents/` | Cursor-specific agent definitions |
| `docs/mcp.md` | Local MCP configuration and security guidance |
| `scripts/` | Cursor MCP wrapper scripts |
| `mcp.example.json` | Secret-free MCP reference configuration |

## Rules

Edit canonical rules in `../rules/`, then run:

```bash
node scripts/sync-rules.mjs
```

`AGENTS.md` contains the repository-wide rules that Cursor also reads.
