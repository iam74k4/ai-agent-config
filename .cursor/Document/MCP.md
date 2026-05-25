# MCP Usage Guide

## Overview

MCP (Model Context Protocol) is an open protocol that gives AI access to external tools and data sources. In Cursor, MCP tools are available when running in Agent mode.

## Quick Start

1. Configure the servers you need in `.cursor/mcp.json` or `~/.cursor/mcp.json`.
2. Fully restart Cursor so it reloads MCP.
3. Check server status in `Cursor Settings > MCP`.
4. Refer to the sections below for server-specific usage requirements.

## Recommended Setup

If you are starting from scratch, these three options usually provide the best value first.

1. **GitHub MCP**  
   Useful for issues, pull requests, comments, and review support in daily development.
2. **Context7**  
   Best for up-to-date library and framework documentation.
3. **Browser / Web tools**  
   Useful for page checks, form input, and lightweight UI verification.

### Minimal Practical Set

- Code management: GitHub MCP
- Current documentation lookup: Context7
- UI checks and lightweight E2E flows: Browser / Web tools

Browser / Web tools are often enabled through plugins, so they may not require `mcp.json`.

## Related Files

| Path | Purpose |
|------|---------|
| `.cursor/README.md` | Main index for the `.cursor/` directory |
| `.cursor/scripts/README.md` | Helper script index |
| `.cursor/rules/MCP/context7-rules.mdc` | Rules for using Context7 |
| `.cursor/rules/MCP/drawio-rules.mdc` | Rules for using draw.io MCP |

## Configuration Paths

| Item | Path |
|------|------|
| Global config | `~/.cursor/mcp.json` |
| Project config | `.cursor/mcp.json` |
| Scripts | `.cursor/scripts/` |

## Active MCP Servers

### 1. Context7

Provides current library documentation and code examples to the AI.

| Item | Value |
|------|-------|
| Connection | Remote (URL) |
| Node.js | Not required |
| Free tier | 1,000 API calls per month |

**Usage**: Add `use context7` to your prompt.

**Best for**: library APIs, setup instructions, and implementation examples.

```text
How do I invalidate queries in React Query? use context7
use context7 with /vercel/next.js for app router setup
```

---

### 2. GitHub

Used for creating, managing, and searching issues and pull requests.

| Item | Value |
|------|-------|
| Connection | Remote (recommended) |
| Authentication | GitHub PAT with the required scopes |
| Authorization format | `Bearer YOUR_GITHUB_PAT` |

**Common tools**: `issue_create`, `issue_update`, `issue_list`, `issue_search`, `issue_comment`, `create_pull_request`

**Best for**: issue management, PR review, comment review, and development support.

**Recommended setup**: configure GitHub MCP in `.cursor/mcp.json`, store the PAT only in a local file, and keep `.cursor/mcp.json` out of version control.

```json
{
  "mcpServers": {
    "github": {
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "Authorization": "Bearer YOUR_GITHUB_PAT"
      }
    }
  }
}
```

1. Create a Personal Access Token in GitHub.
2. Replace `YOUR_GITHUB_PAT` in `.cursor/mcp.json`.
3. Fully restart Cursor.

If you plan to use `repo`-level operations, make sure the PAT includes the necessary repository permissions.

**Local check**

```powershell
$config = Get-Content -Raw .\.cursor\mcp.json | ConvertFrom-Json
$config.mcpServers.github.url
$config.mcpServers.github.headers.Authorization.StartsWith("Bearer ")
```

The final command should return `True`. Do not print or commit the token value.

---

### 3. draw.io

Lets the AI create and edit diagrams in draw.io (diagrams.net).

| Item | Value |
|------|-------|
| Connection | Local, via wrapper script |
| Node.js | v20 or later |
| OS | macOS / Linux, or Windows with WSL / Git Bash |
| Editor URL | http://localhost:3000/ |

**Usage**

1. Restart Cursor so MCP loads the server.
2. Open http://localhost:3000/ in your browser.
3. Ask the agent to create or edit diagrams.

**Rule file**: `.cursor/rules/MCP/drawio-rules.mdc`

---

### 4. MarkItDown

Converts documents and other supported files to Markdown for LLM-friendly analysis.

| Item | Value |
|------|-------|
| Connection | Local, via PowerShell wrapper script |
| Python | 3.10 or later |
| Virtual environment | `.venv-markitdown` |
| Tool | `convert_to_markdown(uri)` |

**Usage**

1. Restart Cursor so MCP loads the server.
2. Ask the agent to convert a local `file:` URI, `http:`, `https:`, or `data:` URI to Markdown.
3. For command-line use, run `markitdown <input-file> -o <output-file>` from `.venv-markitdown`.

**Referenced from `mcp.json`**: use `.cursor/scripts/markitdown-mcp.ps1` in the MarkItDown `command` field.

**Security note**: MarkItDown runs with the privileges of the current user. Only convert trusted local files or trusted URIs, and keep HTTP/SSE transports bound to `127.0.0.1` if you enable them manually.

**Audio note**: Audio conversion may require `ffmpeg` or `avconv` to be installed separately on the system.

---

## Plugin-Based MCP

These do not require `mcp.json` and are enabled through plugin installation.

| Server | Purpose |
|--------|---------|
| Figma | Read design files and support Code Connect |
| cursor-ide-browser | Navigation, clicks, form input, and screenshots |

`cursor-ide-browser` is useful when you want Cursor to inspect pages or perform lightweight browser interactions.

---

## Scripts

### drawio-mcp.sh

**Path**: `.cursor/scripts/drawio-mcp.sh`

**Purpose**: Stops existing draw.io MCP processes before startup to avoid port conflicts.

`drawio-mcp.sh` uses `bash`, `pkill`, `lsof`, and `ps`, so on Windows it assumes an environment such as WSL or Git Bash with Unix-style commands available.

It performs the following steps:

1. Stops `drawio-mcp-server` with `pkill`
2. Terminates draw.io-related processes on ports 3000 and 3333 only
3. Waits for 2 seconds
4. Starts `drawio-mcp-server`

**Referenced from `mcp.json`**: use this script in the draw.io `command` field in `~/.cursor/mcp.json`.

See `.cursor/scripts/README.md` for the script index.

### markitdown-mcp.ps1

**Path**: `.cursor/scripts/markitdown-mcp.ps1`

**Purpose**: Starts `markitdown-mcp` from the local `.venv-markitdown` virtual environment.

It performs the following steps:

1. Resolves the repository root from the script location
2. Checks that `.venv-markitdown\Scripts\markitdown-mcp.exe` exists
3. Starts the MarkItDown MCP server over STDIO

**Referenced from `mcp.json`**: use this script in the MarkItDown `command` field in `.cursor/mcp.json`.

---

## Environment

| Item | Value |
|------|-------|
| Node.js | v20 or later (LTS recommended) |
| Python | 3.10 or later for MarkItDown |
| Version management | `nvm` recommended |

---

## Troubleshooting

### MCP server does not start

1. Fully quit and restart Cursor.
2. Check status in `Cursor Settings > MCP`.
3. Refresh the tool list.
4. If the issue is with GitHub MCP, review the PAT configuration in `.cursor/mcp.json` and verify that `Authorization` starts with `Bearer `.
5. If the issue is with MarkItDown MCP, verify `.venv-markitdown` exists and `markitdown-mcp.ps1` can find `markitdown-mcp.exe`.

### draw.io returns errors

1. **Check the error manually**
   ```bash
   npx -y drawio-mcp-server --editor --http-port 3000
   ```
2. **When using `nvm`**: add `env.PATH` to the draw.io entry in `mcp.json` so it points to the correct Node path.
3. **Fallback**: use Mermaid diagrams in Markdown if draw.io is not available.

### `npx` is not found

```bash
node -v
npx -v
```

If you use `nvm`, run these commands in a fresh terminal session.

### MarkItDown command is not found

```powershell
& .\.venv-markitdown\Scripts\markitdown.exe --help
& .\.venv-markitdown\Scripts\markitdown-mcp.exe --help
```

If either command fails, recreate `.venv-markitdown` and reinstall `markitdown[all]` and `markitdown-mcp`.

If you see an `ffmpeg` or `avconv` warning, MarkItDown is installed but audio conversion may not work until one of those tools is installed.

---

## References

- [Context7](https://context7.com/docs/overview)
- [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers)
- [lgazo/drawio-mcp-server](https://github.com/lgazo/drawio-mcp-server)
- [microsoft/markitdown](https://github.com/microsoft/markitdown)
