# Scripts

Index of helper scripts under `.cursor/scripts/`.

## Prerequisites

- Scripts in this directory may be referenced directly by Cursor.
- `drawio-mcp.sh` uses `bash`, `pkill`, `lsof`, and `ps`.
- On Windows, it assumes an environment such as WSL or Git Bash with Unix-style commands available.
- `markitdown-mcp.ps1` uses PowerShell and a local `.venv-markitdown` virtual environment.

## Available Scripts

| Script | Purpose |
|--------|---------|
| `drawio-mcp.sh` | Stops existing processes before starting draw.io MCP to avoid port conflicts |
| `markitdown-mcp.ps1` | Starts the MarkItDown MCP server from the local Python virtual environment |

## Related Documents

- See `../README.md` for the main `.cursor` index.
- See `../Document/MCP.md` for MCP setup and server details.
- See `../rules/MCP/drawio-rules.mdc` for draw.io-specific rules.
