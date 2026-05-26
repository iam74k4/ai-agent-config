# Agents

Languages: [English](README.md) | [日本語](README.ja.md)

`.cursor/agents/` is the place for workspace-specific agent definitions and supporting files.

## Purpose

- Add project-specific agent definitions here.
- Use this directory for execution roles that are too specific to express only with rule files.
- Keep referenced documents and supporting files close to the agents that use them.

## Guidelines

- Split files or subdirectories by role.
- Avoid creating agents whose purpose is unclear from the name alone.
- Keep persistent behavior rules under `rules/` via `../rules/README.md`; keep execution-focused intent in agent files.
- MCP-specific behavior (GitHub, Context7, draw.io, MarkItDown, etc.): see `../rules/mcp/` and `../docs/mcp.md`.
- If an agent depends on MCP or scripts, include references to `../docs/mcp.md` or `../scripts/README.md`.

## Related

- Main index: `../README.md`
- MCP guide: `../docs/mcp.md`
- Shared rules: `../rules/README.md`
- Helper scripts: `../scripts/README.md`
