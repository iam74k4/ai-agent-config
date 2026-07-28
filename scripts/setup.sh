#!/usr/bin/env bash
# Bootstrap this repository after a fresh clone.
#
# Generates the multi-root workspace file, .cursor/mcp.json, and the MarkItDown venv
# so that a clone is usable without editing machine-specific paths by hand.
# Windows without WSL/Git Bash: use scripts/setup.ps1 instead.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
# Some POSIX shells preserve a leading `//`; normalize it without requiring
# GNU coreutils (macOS does not ship `realpath` in every supported release).
if [[ "$REPO_ROOT" == //* ]]; then
  REPO_ROOT="/${REPO_ROOT#//}"
fi
REPO_NAME="$(basename "$REPO_ROOT")"
PARENT_DIR="$(dirname "$REPO_ROOT")"

TEMPLATE="$REPO_ROOT/templates/workspace.code-workspace.template"
WORKSPACE_FILE="${WORKSPACE_FILE:-$REPO_ROOT/$REPO_NAME.code-workspace}"
MCP_FILE="$REPO_ROOT/.cursor/mcp.json"
VENV_DIR="${MARKITDOWN_MCP_VENV:-$REPO_ROOT/.cursor/venv-markitdown}"

FORCE=0
DRY_RUN=0
DO_VENV=1
DO_MCP=1
DO_WORKSPACE=1
WARN_COUNT=0
WARN_MESSAGES=""

usage() {
  cat <<'EOF'
Usage: scripts/setup.sh [options]

Options:
  --force          Overwrite .cursor/mcp.json even if it already exists
  --dry-run        Print what would change without writing files
  --no-venv        Skip creating the MarkItDown virtual environment
  --no-mcp         Skip generating .cursor/mcp.json
  --no-workspace   Skip generating the workspace file
  -h, --help       Show this help

Environment:
  WORKSPACE_FILE        Output path for the generated workspace file
  MARKITDOWN_MCP_VENV   Location of the MarkItDown virtual environment
  CONTEXT7_API_KEY      Added to the Context7 MCP entry when set (optional)
  GITHUB_MCP_PAT        GitHub PAT for the GitHub MCP entry
                        (GITHUB_PAT / GITHUB_TOKEN are also accepted)

The workspace file is a derived artifact and is regenerated on every run; edit
templates/workspace.code-workspace.template instead. .cursor/mcp.json may hold
secrets, so it is only written when missing or when --force is passed.
EOF
}

log() { printf '  %s\n' "$1"; }
step() { printf '\n==> %s\n' "$1"; }
warn() {
  printf '  ! %s\n' "$1"
  WARN_COUNT=$((WARN_COUNT + 1))
  WARN_MESSAGES="${WARN_MESSAGES}  - $1"$'\n'
}

require_git() {
  if command -v git >/dev/null 2>&1; then
    log "Git: $(git --version)"
    return 0
  fi

  printf 'Git is required. Install Git and run this script again.\n' >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --no-venv) DO_VENV=0 ;;
    --no-mcp) DO_MCP=0 ;;
    --no-workspace) DO_WORKSPACE=0 ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

# Escape a value for use inside a JSON string.
json_escape() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  printf '%s' "$s"
}

write_file() {
  local path=$1 content=$2
  if [[ $DRY_RUN -eq 1 ]]; then
    log "would write $path"
    return 0
  fi
  mkdir -p "$(dirname "$path")"
  printf '%s' "$content" >"$path"
  log "wrote $path"
}

node_major() {
  command -v node >/dev/null 2>&1 || return 1
  node -e 'process.stdout.write(String(process.versions.node.split(".")[0]))' 2>/dev/null || return 1
}

python_bin() {
  local candidate
  for candidate in python3 python; do
    if command -v "$candidate" >/dev/null 2>&1 &&
      "$candidate" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)' 2>/dev/null; then
      printf '%s' "$candidate"
      return 0
    fi
  done
  return 1
}

# --- workspace file -----------------------------------------------------------

# Sibling directories that are Git repositories, so the folder list and the Git
# tasks stay in sync automatically when repositories are added or removed.
collect_folders() {
  local dir name
  FOLDER_NAMES=("$REPO_NAME")
  FOLDER_PATHS=(".")
  for dir in "$PARENT_DIR"/*; do
    [[ -e "$dir/.git" ]] || continue
    dir="$(cd "$dir" && pwd -P)"
    if [[ "$dir" == //* ]]; then
      dir="/${dir#//}"
    fi
    [[ "$dir" != "$REPO_ROOT" ]] || continue
    name="$(basename "$dir")"
    FOLDER_NAMES+=("$name")
    FOLDER_PATHS+=("../$name")
  done
}

render_folders() {
  local i out=""
  for i in "${!FOLDER_NAMES[@]}"; do
    [[ -n "$out" ]] && out+=$',\n'
    out+="    {"$'\n'
    out+="      \"name\": \"$(json_escape "${FOLDER_NAMES[$i]}")\","$'\n'
    out+="      \"path\": \"$(json_escape "${FOLDER_PATHS[$i]}")\""$'\n'
    out+="    }"
  done
  printf '[\n%s\n  ]' "$out"
}

render_repo_task() {
  local label=$1 command=$2 folder=$3
  printf '      {\n'
  printf '        "label": "%s",\n' "$label"
  printf '        "type": "shell",\n'
  printf '        "command": "%s",\n' "$command"
  printf '        "options": {\n'
  printf '          "cwd": "${workspaceFolder:%s}"\n' "$folder"
  printf '        },\n'
  printf '        "problemMatcher": [],\n'
  printf '        "presentation": {\n'
  printf '          "reveal": "silent",\n'
  printf '          "panel": "shared"\n'
  printf '        }\n'
  printf '      }'
}

render_tasks() {
  local name escaped fetch_deps="" status_deps="" per_repo="" out=""
  for name in "${FOLDER_NAMES[@]}"; do
    escaped="$(json_escape "$name")"
    [[ -n "$fetch_deps" ]] && fetch_deps+=$',\n'
    fetch_deps+="          \"Git: fetch ($escaped)\""
    [[ -n "$status_deps" ]] && status_deps+=$',\n'
    status_deps+="          \"Git: status ($escaped)\""

    per_repo+=$',\n'
    per_repo+="$(render_repo_task "Git: fetch ($escaped)" "git fetch --all --prune" "$escaped")"
    per_repo+=$',\n'
    per_repo+="$(render_repo_task "Git: status ($escaped)" "echo '=== $escaped ===' && git status -sb" "$escaped")"
  done

  out+="["$'\n'
  out+="      {"$'\n'
  out+="        \"label\": \"Git: fetch all workspaces\","$'\n'
  out+="        \"dependsOn\": ["$'\n'
  out+="$fetch_deps"$'\n'
  out+="        ],"$'\n'
  out+="        \"dependsOrder\": \"parallel\","$'\n'
  out+="        \"problemMatcher\": [],"$'\n'
  out+="        \"group\": {"$'\n'
  out+="          \"kind\": \"build\","$'\n'
  out+="          \"isDefault\": true"$'\n'
  out+="        },"$'\n'
  out+="        \"presentation\": {"$'\n'
  out+="          \"reveal\": \"always\","$'\n'
  out+="          \"panel\": \"shared\","$'\n'
  out+="          \"showReuseMessage\": false,"$'\n'
  out+="          \"clear\": false"$'\n'
  out+="        }"$'\n'
  out+="      },"$'\n'
  out+="      {"$'\n'
  out+="        \"label\": \"Git: status all workspaces\","$'\n'
  out+="        \"dependsOn\": ["$'\n'
  out+="$status_deps"$'\n'
  out+="        ],"$'\n'
  out+="        \"dependsOrder\": \"sequence\","$'\n'
  out+="        \"problemMatcher\": [],"$'\n'
  out+="        \"presentation\": {"$'\n'
  out+="          \"reveal\": \"always\","$'\n'
  out+="          \"panel\": \"shared\","$'\n'
  out+="          \"showReuseMessage\": true,"$'\n'
  out+="          \"clear\": true"$'\n'
  out+="        }"$'\n'
  out+="      }"
  out+="$per_repo"$'\n'
  out+="    ]"
  printf '%s' "$out"
}

generate_workspace() {
  step "Workspace file"
  if [[ ! -f "$TEMPLATE" ]]; then
    warn "template not found: $TEMPLATE"
    return 0
  fi

  collect_folders
  log "folders: ${FOLDER_NAMES[*]}"
  if [[ ${#FOLDER_NAMES[@]} -eq 1 ]]; then
    log "no sibling Git repositories found next to $REPO_NAME; add them later and re-run this script"
  fi

  local content
  content="$(cat "$TEMPLATE")"
  content="${content//__REPO_NAME__/$(json_escape "$REPO_NAME")}"
  content="${content/__FOLDERS__/$(render_folders)}"
  content="${content/__TASKS__/$(render_tasks)}"
  write_file "$WORKSPACE_FILE" "$content"$'\n'
}

# --- MCP config ---------------------------------------------------------------

generate_mcp() {
  step "MCP config"
  if [[ -f "$MCP_FILE" && $FORCE -ne 1 ]]; then
    log "keeping existing $MCP_FILE (use --force to regenerate)"
    return 0
  fi

  local body="" major entry
  add_entry() {
    [[ -n "$body" ]] && body+=$',\n'
    body+="$1"
  }

  entry='    "context7": {'$'\n'
  entry+='      "url": "https://mcp.context7.com/mcp"'
  if [[ -n "${CONTEXT7_API_KEY:-}" ]]; then
    entry+=','$'\n'
    entry+='      "headers": {'$'\n'
    entry+="        \"CONTEXT7_API_KEY\": \"$(json_escape "$CONTEXT7_API_KEY")\""$'\n'
    entry+='      }'$'\n'
    log "context7: enabled with API key from CONTEXT7_API_KEY"
  else
    entry+=$'\n'
    log "context7: enabled without API key (set CONTEXT7_API_KEY for higher rate limits)"
  fi
  entry+='    }'
  add_entry "$entry"

  local pat="${GITHUB_MCP_PAT:-${GITHUB_PAT:-${GITHUB_TOKEN:-}}}"
  if [[ -n "$pat" ]]; then
    entry='    "github": {'$'\n'
    entry+='      "url": "https://api.githubcopilot.com/mcp/",'$'\n'
    entry+='      "headers": {'$'\n'
    entry+="        \"Authorization\": \"Bearer $(json_escape "$pat")\""$'\n'
    entry+='      }'$'\n'
    entry+='    }'
    add_entry "$entry"
    log "github: enabled using a token from the environment"
  else
    log "github: skipped (set GITHUB_MCP_PAT and re-run with --force to enable)"
  fi

  if [[ -x "$VENV_DIR/bin/markitdown-mcp" ]] || command -v markitdown-mcp >/dev/null 2>&1; then
    entry='    "markitdown": {'$'\n'
    entry+="      \"command\": \"$(json_escape "$REPO_ROOT/.cursor/scripts/markitdown-mcp.sh")\","$'\n'
    entry+='      "args": []'$'\n'
    entry+='    }'
    add_entry "$entry"
    log "markitdown: enabled"
  else
    log "markitdown: skipped (no venv and no markitdown-mcp on PATH)"
  fi

  if major="$(node_major)" && [[ -n "$major" ]] && [[ "$major" -ge 20 ]]; then
    entry='    "drawio": {'$'\n'
    entry+="      \"command\": \"$(json_escape "$REPO_ROOT/.cursor/scripts/drawio-mcp.sh")\","$'\n'
    entry+='      "args": []'$'\n'
    entry+='    }'
    add_entry "$entry"
    log "drawio: enabled (Node.js $major)"
  else
    log "drawio: skipped (needs Node.js 20 or later)"
  fi

  write_file "$MCP_FILE" "{"$'\n'"  \"mcpServers\": {"$'\n'"$body"$'\n'"  }"$'\n'"}"$'\n'
}

# --- MarkItDown venv ----------------------------------------------------------

setup_venv() {
  step "MarkItDown virtual environment"
  local py
  if ! py="$(python_bin)"; then
    warn "Python 3.10+ not found; skipping MarkItDown setup"
    return 0
  fi

  if [[ -x "$VENV_DIR/bin/markitdown-mcp" ]]; then
    log "already installed at $VENV_DIR"
    return 0
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    log "would create $VENV_DIR and install markitdown-mcp"
    return 0
  fi

  if [[ ! -d "$VENV_DIR" ]] && ! "$py" -m venv "$VENV_DIR"; then
    warn "could not create $VENV_DIR (on Debian/Ubuntu install python3-venv)"
    return 0
  fi

  log "installing markitdown-mcp (downloads packages)"
  if ! "$VENV_DIR/bin/python" -m pip install --quiet --upgrade pip markitdown-mcp; then
    warn "markitdown-mcp installation failed; re-run this script or install it manually"
    return 0
  fi
  log "installed $VENV_DIR/bin/markitdown-mcp"
}

# --- run ----------------------------------------------------------------------

printf 'Setting up %s\n' "$REPO_ROOT"
if [[ $DRY_RUN -eq 1 ]]; then
  printf 'Dry run: no files will be written\n'
fi

step "Required tools"
require_git

if [[ $DO_VENV -eq 1 ]]; then
  setup_venv
fi
if [[ $DO_MCP -eq 1 ]]; then
  generate_mcp
fi
if [[ $DO_WORKSPACE -eq 1 ]]; then
  generate_workspace
fi

step "Next steps"
log "1. Open $(basename "$WORKSPACE_FILE") in Cursor"
log "2. Restart Cursor completely so it loads .cursor/mcp.json"
log "3. Verify the result with scripts/doctor.sh"

if [[ $WARN_COUNT -gt 0 ]]; then
  printf '\nCompleted with %d warning(s):\n%s' "$WARN_COUNT" "$WARN_MESSAGES"
fi
