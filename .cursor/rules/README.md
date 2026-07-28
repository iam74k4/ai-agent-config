# Cursor rules

## Generated shared rules

`generated/` is produced from the canonical files in `../../rules/`.

```bash
node scripts/sync-rules.mjs
node scripts/sync-rules.mjs --check
```

Do not edit generated files directly.

## Cursor-specific rules

`mcp/` contains instructions for MCP servers that are configured only in Cursor. They are intentionally separate from cross-tool rules because server availability and authentication are local concerns.
