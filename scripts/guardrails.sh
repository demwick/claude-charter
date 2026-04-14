#!/usr/bin/env bash
#
# claude-charter PreToolUse guardrails
#
# Claude Code runs this script before every Bash tool call. Stdin is a
# JSON object describing the tool call. We inspect the command and
# decide one of:
#
#   - allow (exit 0 with no output)
#   - ask the user to confirm (decision: "ask")
#   - block with an explanation (decision: "deny")
#
# Decision format documented at:
#   https://docs.claude.com/en/docs/claude-code/hooks
#
# This is an "ask, don't silently block" guardrail. It never blocks
# without explanation. Users can always override with their own
# approval. The goal is to catch the obviously-destructive before the
# agent runs it.

set -euo pipefail

input="$(cat)"

# Extract the command string. jq is preferred; if unavailable, fall
# back to a best-effort grep that reads the "command" field from a
# single-line JSON payload.
if command -v jq >/dev/null 2>&1; then
  cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""')"
else
  cmd="$(printf '%s' "$input" | grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"command"[[:space:]]*:[[:space:]]*"(.*)"/\1/')"
fi

if [[ -z "${cmd:-}" ]]; then
  exit 0
fi

ask() {
  local reason="$1"
  # Escape double quotes for JSON.
  local safe="${reason//\"/\\\"}"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "$safe"
  exit 0
}

# --- Destructive filesystem operations ---------------------------------------

if [[ "$cmd" =~ rm[[:space:]]+(-[a-zA-Z]*[rRfF][a-zA-Z]*|--recursive|--force)[[:space:]] ]]; then
  ask "Recursive/forced rm detected. Confirm the target is intended: $cmd"
fi

if [[ "$cmd" =~ rm[[:space:]]+-rf?[[:space:]]*/([[:space:]]|$) ]]; then
  ask "rm -rf targeting / — this would wipe the filesystem. Confirm."
fi

if [[ "$cmd" =~ rm[[:space:]]+.*\.git([[:space:]]|/|$) ]]; then
  ask "Command targets a .git directory. This will destroy repo history. Confirm."
fi

# --- Git danger zone ----------------------------------------------------------

if [[ "$cmd" =~ git[[:space:]]+push[[:space:]]+.*(--force|--force-with-lease|[[:space:]]-f([[:space:]]|$)) ]]; then
  if [[ "$cmd" =~ (main|master) ]]; then
    ask "Force-push targeting main/master. Confirm this is intentional: $cmd"
  else
    ask "Force-push detected. Confirm the target branch is not shared with teammates: $cmd"
  fi
fi

if [[ "$cmd" =~ git[[:space:]]+reset[[:space:]]+--hard ]]; then
  ask "git reset --hard discards uncommitted work. Confirm."
fi

if [[ "$cmd" =~ git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*f ]]; then
  ask "git clean -f deletes untracked files. Confirm the target directory."
fi

if [[ "$cmd" =~ git[[:space:]]+(checkout|restore)[[:space:]]+--[[:space:]]*\. ]]; then
  ask "This discards local changes. Confirm."
fi

if [[ "$cmd" =~ git[[:space:]]+commit[[:space:]]+.*--no-verify ]]; then
  ask "--no-verify bypasses pre-commit hooks. Fix the underlying issue instead, or confirm the bypass is intentional."
fi

if [[ "$cmd" =~ git[[:space:]]+branch[[:space:]]+-D ]]; then
  ask "git branch -D force-deletes a branch. Confirm."
fi

# --- Secrets and sensitive files ----------------------------------------------

if [[ "$cmd" =~ (cat|less|more|head|tail|bat)[[:space:]]+.*(\.env($|[[:space:]])|\.env\.|\.key($|[[:space:]])|credentials|id_rsa|id_ed25519) ]]; then
  ask "Command reads what looks like a secret file. Confirm."
fi

# --- Network / shell-pipes ----------------------------------------------------

if [[ "$cmd" =~ (curl|wget).*\|[[:space:]]*(sh|bash|zsh) ]]; then
  ask "curl | sh pattern detected. This executes untrusted remote code. Confirm the source is trusted."
fi

# --- Publishing / deployment --------------------------------------------------

if [[ "$cmd" =~ npm[[:space:]]+publish ]]; then
  ask "npm publish is irreversible. Confirm."
fi

if [[ "$cmd" =~ (pip|pypi)[[:space:]]+upload ]]; then
  ask "PyPI upload is irreversible. Confirm."
fi

# --- Overly broad permissions -------------------------------------------------

if [[ "$cmd" =~ chmod[[:space:]]+(-R[[:space:]]+)?777 ]]; then
  ask "chmod 777 is almost always wrong. Confirm this is intentional."
fi

# Allow.
exit 0
