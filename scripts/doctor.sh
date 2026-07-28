#!/usr/bin/env bash
# Non-destructive local setup diagnostics.
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_NAME="$(basename "$REPO_ROOT")"
MCP_FILE="$REPO_ROOT/.cursor/mcp.json"
WORKSPACE_FILE="${WORKSPACE_FILE:-$REPO_ROOT/$REPO_NAME.code-workspace}"
VENV_DIR="${MARKITDOWN_MCP_VENV:-$REPO_ROOT/.cursor/venv-markitdown}"

PASS=0
WARN=0
FAIL=0

ok() {
  printf '  PASS  %s\n' "$1"
  PASS=$((PASS + 1))
}

warn() {
  printf '  WARN  %s\n' "$1"
  WARN=$((WARN + 1))
}

fail() {
  printf '  FAIL  %s\n' "$1"
  FAIL=$((FAIL + 1))
}

check_command() {
  local command=$1
  if command -v "$command" >/dev/null 2>&1; then
    ok "$command: $(command -v "$command")"
  else
    warn "$command is not available"
  fi
}

validate_json() {
  local path=$1 label=$2
  if node -e 'JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"))' "$path" >/dev/null 2>&1; then
    ok "$label is valid JSON"
  else
    fail "$label is not valid JSON"
  fi
}

validate_jsonc() {
  local path=$1 label=$2
  if node -e '
const fs = require("fs");
let source = fs.readFileSync(process.argv[1], "utf8");
source = source.replace(/\/\*[\s\S]*?\*\//g, "").replace(/(^|[^:])\/\/.*$/gm, "$1");
JSON.parse(source);
' "$path" >/dev/null 2>&1; then
    ok "$label is valid JSONC"
  else
    fail "$label is not valid JSONC"
  fi
}

printf 'Diagnosing %s\n\n' "$REPO_ROOT"
printf '==> Commands\n'
check_command git
check_command node
check_command python3

printf '\n==> Repository files\n'
if [[ -f "$REPO_ROOT/AGENTS.md" ]]; then
  ok "AGENTS.md exists"
else
  fail "AGENTS.md is missing"
fi
if [[ -f "$REPO_ROOT/CLAUDE.md" ]]; then
  ok "CLAUDE.md exists"
else
  warn "CLAUDE.md is missing; Claude Code project instructions are unavailable"
fi
if [[ -f "$REPO_ROOT/.github/copilot-instructions.md" ]]; then
  ok "Copilot instructions exist"
else
  warn "Copilot instructions are missing"
fi

printf '\n==> Generated files\n'
if [[ -f "$WORKSPACE_FILE" ]]; then
  if command -v node >/dev/null 2>&1; then
    validate_jsonc "$WORKSPACE_FILE" "$(basename "$WORKSPACE_FILE")"
  else
    warn "cannot validate workspace JSONC without Node.js"
  fi
else
  warn "$(basename "$WORKSPACE_FILE") is missing; run scripts/setup.sh"
fi

if [[ -f "$MCP_FILE" ]]; then
  if command -v node >/dev/null 2>&1; then
    validate_json "$MCP_FILE" ".cursor/mcp.json"
  else
    warn "cannot validate MCP JSON without Node.js"
  fi
  if rg -q 'YOUR_[A-Z_]*KEY|YOUR_GITHUB_PAT|__REPO_ROOT__' "$MCP_FILE"; then
    fail ".cursor/mcp.json contains an unresolved placeholder"
  fi
else
  warn ".cursor/mcp.json is missing; run scripts/setup.sh"
fi

printf '\n==> Optional MCP dependencies\n'
if [[ -x "$VENV_DIR/bin/markitdown-mcp" ]]; then
  ok "MarkItDown venv is ready"
elif command -v markitdown-mcp >/dev/null 2>&1; then
  ok "markitdown-mcp is available on PATH"
else
  warn "MarkItDown is unavailable; run scripts/setup.sh or install it manually"
fi

if command -v node >/dev/null 2>&1; then
  node_major="$(node -e 'process.stdout.write(process.versions.node.split(".")[0])')"
  if [[ "$node_major" -ge 20 ]]; then
    ok "Node.js $node_major supports draw.io MCP"
  else
    warn "Node.js $node_major is older than the draw.io MCP recommendation (20)"
  fi
else
  warn "draw.io MCP is unavailable without Node.js"
fi

printf '\nSummary: %d passed, %d warning(s), %d failure(s)\n' "$PASS" "$WARN" "$FAIL"
[[ $FAIL -eq 0 ]]
