# MCP setup

Run the repository bootstrap script after cloning:

```bash
./scripts/setup.sh
```

```powershell
.\scripts\setup.ps1
```

It generates `.cursor/mcp.json`, which is intentionally ignored because it can contain secrets and absolute paths.

## Servers

| Server | Default behavior | Enablement |
|---|---|---|
| Context7 | Included without a key | Set `CONTEXT7_API_KEY` for higher rate limits |
| GitHub | Omitted by default | Set `GITHUB_MCP_PAT`, then rerun setup with `--force` / `-Force` |
| MarkItDown | Included after its local venv is ready | Installed by setup when Python 3.10+ is available |
| draw.io | Included when Node.js 20+ is available | Uses the repository wrapper, which frees its ports first |

The secret-free reference format is [`.cursor/mcp.example.json`](../mcp.example.json). Do not copy its placeholder values into `.cursor/mcp.json`.

## Security

- Treat GitHub tokens and Context7 keys as passwords.
- Use fine-grained, least-privilege GitHub tokens.
- Never commit `.cursor/mcp.json` or paste a token into a prompt.
- Setup writes `.cursor/mcp.json` with owner-only permissions; `doctor` reports when other accounts can read it.
- Prefer `GITHUB_MCP_PAT` over `GITHUB_TOKEN`, which CI systems set automatically and which setup would otherwise write to disk.
- MarkItDown runs as the current OS user. Only pass it files and URLs that the current task is allowed to expose.
- Keep local HTTP MCP services bound to localhost.

## Verify

```bash
./scripts/doctor.sh
```

```powershell
.\scripts\doctor.ps1
```

Restart Cursor completely after changing MCP configuration, then check server status in Cursor Settings.
