#!/usr/bin/env bash
#
# Detect whether the software-engineer-agent plugin is installed
# alongside this claude-charter workspace. Prints a single line:
#
#   plugin=sea version=<version>   (if detected via .sea/state.json)
#   plugin=sea version=unknown     (if .sea/ exists without state)
#   plugin=none                    (if no plugin signature found)
#
# Exit code:
#   0 — plugin detected
#   1 — no plugin detected

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "$REPO_ROOT/.sea/state.json" ]]; then
  if command -v jq >/dev/null 2>&1; then
    version=$(jq -r '.schema_version // "unknown"' "$REPO_ROOT/.sea/state.json" 2>/dev/null)
  else
    version="unknown"
  fi
  printf 'plugin=sea version=%s\n' "$version"
  exit 0
fi

if [[ -d "$REPO_ROOT/.sea" ]]; then
  printf 'plugin=sea version=unknown\n'
  exit 0
fi

printf 'plugin=none\n'
exit 1
