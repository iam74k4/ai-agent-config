# Scripts

Languages: [English](README.md) | [日本語](README.ja.md)

Index of helper scripts under `.cursor/scripts/`.

## Prerequisites

- Scripts in this directory may be referenced directly by Cursor.
- `drawio-mcp.sh` uses `bash`, `pkill`, `lsof`, and `ps`.
- On Windows, it assumes an environment such as WSL or Git Bash with Unix-style commands available.
- `markitdown-mcp.sh` uses `bash` and can use `.cursor/venv-markitdown`.
- `markitdown-mcp.ps1` uses PowerShell and a local `.venv-markitdown` virtual environment.

## Available Scripts

| Script | Purpose |
|--------|---------|
| `drawio-mcp.sh` | Stops existing processes before starting draw.io MCP to avoid port conflicts |
| `markitdown-mcp.sh` | Runs `markitdown-mcp` from `.cursor/venv-markitdown` if present, otherwise from `PATH` (`MARKITDOWN_MCP_VENV` overrides the venv path) |
| `markitdown-mcp.ps1` | Starts the MarkItDown MCP server from the local Python virtual environment |

## Related Documents

- See `../README.md` for the main `.cursor` index.
- See `../docs/mcp.md` for MCP setup and server details.
- See `../rules/mcp/drawio-rules.mdc` for draw.io-specific rules.
- See `../rules/mcp/markitdown-rules.mdc` for MarkItDown MCP usage.