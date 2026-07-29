#!/usr/bin/env bash
# Start drawio-mcp-server after clearing stale instances.
#
# Cursor does not always stop the server when it exits, and the leftover
# process keeps ports 3000 (HTTP) and 3333 (WebSocket) bound.
set -euo pipefail

STOPPED=0

stop_pid() {
  local pid=$1 attempt
  [[ "$pid" == "$$" ]] && return 0
  kill "$pid" 2>/dev/null || return 0
  STOPPED=1
  # Give the process a chance to shut down before forcing it.
  for attempt in 1 2 3 4 5; do
    kill -0 "$pid" 2>/dev/null || return 0
    sleep 0.2
  done
  kill -9 "$pid" 2>/dev/null || true
}

if command -v pgrep >/dev/null 2>&1; then
  for pid in $(pgrep -f "drawio-mcp-server" 2>/dev/null || true); do
    stop_pid "$pid"
  done
fi

# Only stop drawio-related listeners, so other applications on port 3000 survive.
if command -v lsof >/dev/null 2>&1; then
  for port in 3000 3333; do
    for pid in $(lsof -nti:"$port" 2>/dev/null || true); do
      if ps -p "$pid" -o command= 2>/dev/null | grep -q drawio-mcp; then
        stop_pid "$pid"
      fi
    done
  done
fi

# Wait for the ports to be released.
if [[ $STOPPED -eq 1 ]]; then
  sleep 2
fi

exec npx -y drawio-mcp-server --editor --http-port 3000
