#!/usr/bin/env bash
# install-to.sh — copy claude-charter policy, skills, hooks, and scripts
# into a target project directory. Idempotent: running twice is safe.
#
# Usage:
#   scripts/install-to.sh <target-dir> [--dry-run] [--force] [--merge-claude-md]
#
# Default conflict policy: existing target files are backed up to
# <file>.bak.<timestamp> before being replaced. --force skips backup.
#
# By default the target's existing CLAUDE.md is preserved and charter
# policy is appended/refreshed inside a managed block. Pass
# --replace-claude-md to overwrite it instead.

set -euo pipefail

usage() {
  cat >&2 <<EOF
Usage: $0 <target-dir> [--dry-run] [--force] [--replace-claude-md]

  <target-dir>         Project to install charter into. Must exist.
  --dry-run            Show what would happen; write nothing.
  --force              Overwrite conflicting files without backup.
  --replace-claude-md  Overwrite target's CLAUDE.md instead of merging
                       charter policy into a managed block (the default).
EOF
  exit 2
}

SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET=""
DRY_RUN=0
FORCE=0
MERGE_CLAUDE_MD=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)             DRY_RUN=1;         shift ;;
    --force)               FORCE=1;           shift ;;
    --replace-claude-md)   MERGE_CLAUDE_MD=0; shift ;;
    --merge-claude-md)     MERGE_CLAUDE_MD=1; shift ;;  # back-compat no-op
    -h|--help) usage ;;
    -*)        echo "unknown flag: $1" >&2; usage ;;
    *)
      if [[ -z "$TARGET" ]]; then TARGET="$1"; shift
      else usage; fi
      ;;
  esac
done

[[ -z "$TARGET" ]] && usage
[[ -d "$TARGET" ]] || { echo "target not a directory: $TARGET" >&2; exit 1; }
TARGET="$(cd "$TARGET" && pwd)"

if [[ "$TARGET" == "$SOURCE" ]]; then
  echo "refusing to install claude-charter into itself" >&2
  exit 1
fi

say() { printf '[install-to] %s\n' "$*"; }

# Items to copy, relative to SOURCE. Order matters only for readability.
ITEMS=(
  "CLAUDE.md"
  ".claude/VERSION"
  ".claude/knowledge/charter"
  ".claude/knowledge/context"
  ".claude/knowledge/evidence"
  ".claude/knowledge/examples"
  ".claude/knowledge/adr"
  ".claude/skills"
  ".claude/commands"
  ".claude/hooks"
  "scripts/prompt-router.sh"
  "scripts/guardrails.sh"
  "scripts/health.sh"
  "scripts/detect-plugin.sh"
)

CHARTER_BEGIN="<!-- BEGIN claude-charter (managed block — do not edit by hand) -->"
CHARTER_END="<!-- END claude-charter -->"

merge_claude_md() {
  local src="$SOURCE/CLAUDE.md"
  local dst="$TARGET/CLAUDE.md"
  local version
  version="$(cat "$SOURCE/.claude/VERSION" 2>/dev/null || echo "charter-unknown")"

  if [[ ! -e "$src" ]]; then
    say "SKIP  missing source: CLAUDE.md"
    return
  fi

  local block_tmp; block_tmp="$(mktemp)"
  {
    printf '%s\n' "$CHARTER_BEGIN"
    printf '<!-- charter version: %s -->\n' "$version"
    cat "$src"
    printf '%s\n' "$CHARTER_END"
  } > "$block_tmp"

  if [[ ! -e "$dst" ]]; then
    if (( DRY_RUN )); then
      say "DRY   would create CLAUDE.md with managed block"
      rm -f "$block_tmp"
    else
      mkdir -p "$(dirname "$dst")"
      mv "$block_tmp" "$dst"
      say "WRITE CLAUDE.md (new file, managed block only)"
    fi
    return
  fi

  local stripped_tmp; stripped_tmp="$(mktemp)"
  awk -v b="$CHARTER_BEGIN" -v e="$CHARTER_END" '
    $0 == b { skip=1; next }
    $0 == e { skip=0; next }
    !skip
  ' "$dst" > "$stripped_tmp"

  # trim trailing blank lines from stripped (so we control spacing)
  local cleaned_tmp; cleaned_tmp="$(mktemp)"
  awk 'NF { for (i=0;i<blank;i++) print ""; print; blank=0; next } { blank++ }' \
    "$stripped_tmp" > "$cleaned_tmp"

  local candidate_tmp; candidate_tmp="$(mktemp)"
  if [[ -s "$cleaned_tmp" ]]; then
    cat "$cleaned_tmp" > "$candidate_tmp"
    printf '\n' >> "$candidate_tmp"
    cat "$block_tmp" >> "$candidate_tmp"
  else
    cat "$block_tmp" > "$candidate_tmp"
  fi

  rm -f "$stripped_tmp" "$cleaned_tmp" "$block_tmp"

  if diff -q "$candidate_tmp" "$dst" >/dev/null 2>&1; then
    rm -f "$candidate_tmp"
    say "SAME  CLAUDE.md (managed block already current)"
    return
  fi

  if (( DRY_RUN )); then
    rm -f "$candidate_tmp"
    if grep -qF "$CHARTER_BEGIN" "$dst"; then
      say "DRY   would refresh managed block in CLAUDE.md"
    else
      say "DRY   would append managed block to CLAUDE.md"
    fi
  else
    mv "$candidate_tmp" "$dst"
    say "MERGE CLAUDE.md (managed block written)"
  fi
}

copy_item() {
  local rel="$1"

  if [[ "$rel" == "CLAUDE.md" ]] && (( MERGE_CLAUDE_MD )); then
    merge_claude_md
    return
  fi

  local src="$SOURCE/$rel"
  local dst="$TARGET/$rel"

  if [[ ! -e "$src" ]]; then
    say "SKIP  missing source: $rel"
    return
  fi

  if [[ -e "$dst" ]]; then
    if diff -qr "$src" "$dst" >/dev/null 2>&1; then
      say "SAME  $rel"
      return
    fi
    local bak="${dst}.bak.$(date +%Y%m%d%H%M%S)"
    if (( DRY_RUN )); then
      if (( FORCE )); then say "DRY   would overwrite: $rel"
      else                 say "DRY   would back up:   $rel -> ${bak##*/}"
      fi
    else
      if (( FORCE )); then
        rm -rf "$dst"
        say "RM    $rel (force)"
      else
        mv "$dst" "$bak"
        say "BAK   $rel -> ${bak##*/}"
      fi
    fi
  fi

  if (( DRY_RUN )); then
    say "DRY   would write: $rel"
  else
    mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"
    say "WRITE $rel"
  fi
}

mode="live"
(( DRY_RUN ))            && mode="dry-run"
(( FORCE ))              && mode="${mode}+force"
(( ! MERGE_CLAUDE_MD ))  && mode="${mode}+replace-claude-md"

say "source: $SOURCE"
say "target: $TARGET"
say "mode:   $mode"

for item in "${ITEMS[@]}"; do
  copy_item "$item"
done

say "done."
if (( ! DRY_RUN )); then
  cat <<EOF

Next:
  cd "$TARGET"
  claude                       # charter policy + skills will activate

Re-run this installer anytime to pull charter updates. Diffs will be
backed up as <file>.bak.<timestamp> unless you pass --force.
EOF
fi
