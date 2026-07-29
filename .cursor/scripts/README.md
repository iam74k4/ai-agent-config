# Scripts

Index of helper scripts under `.cursor/scripts/`. `scripts/setup.sh` and
`scripts/setup.ps1` reference these from the generated `.cursor/mcp.json`.

## Prerequisites

- `drawio-mcp.sh` uses `bash` and, when available, `pgrep`, `lsof`, and `ps`.
- `drawio-mcp.ps1` uses PowerShell, `Get-CimInstance`, and `Get-NetTCPConnection`.
- `markitdown-mcp.sh` and `markitdown-mcp.ps1` use `.cursor/venv-markitdown`, or `markitdown-mcp` on `PATH`.
- `MARKITDOWN_MCP_VENV` overrides the virtual environment path for both MarkItDown wrappers.

## Available Scripts

| Script | Purpose |
|--------|---------|
| `drawio-mcp.sh` | Stops stale processes and frees ports before starting draw.io MCP |
| `drawio-mcp.ps1` | Windows equivalent of `drawio-mcp.sh` |
| `markitdown-mcp.sh` | Runs `markitdown-mcp` from the local venv, otherwise from `PATH` |
| `markitdown-mcp.ps1` | Windows equivalent of `markitdown-mcp.sh` |

## Related Documents

- See `../README.md` for the main `.cursor` index.
- See `../docs/mcp.md` for MCP setup and server details.
- See `../rules/mcp/drawio-rules.mdc` for draw.io-specific rules.
- See `../rules/mcp/markitdown-rules.mdc` for MarkItDown MCP instructions.
- Run `../../scripts/doctor.sh` after setup to verify local prerequisites.
