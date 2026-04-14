#!/usr/bin/env bash
#
# claude-charter 12-point self-audit.
#
# Checks the structural integrity of a claude-charter installation.
# Exits 0 if all checks pass, 1 otherwise. Prints a scannable report.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

PASS=0
FAIL=0
WARN=0
FAILED_CHECKS=()
STALE_FILES=()

check() {
  local name="$1"
  local status="$2"
  local detail="${3:-}"
  if [[ "$status" == "pass" ]]; then
    printf "  \033[32m✓\033[0m %s\n" "$name"
    PASS=$((PASS + 1))
  elif [[ "$status" == "warn" ]]; then
    printf "  \033[33m!\033[0m %s — %s\n" "$name" "$detail"
    WARN=$((WARN + 1))
  else
    printf "  \033[31m✗\033[0m %s — %s\n" "$name" "$detail"
    FAIL=$((FAIL + 1))
    FAILED_CHECKS+=("$name: $detail")
  fi
}

printf "claude-charter health check\n"
printf "charter version: %s\n\n" "$(cat .claude/VERSION 2>/dev/null || echo 'UNKNOWN')"

# 1. CLAUDE.md exists and has the expected top-level sections.
if [[ -f CLAUDE.md ]]; then
  missing=()
  for section in "<role>" "<operating_policy>" "<tool_policy>" "<risk_policy>" "<channel_contract>" "<output_contract>" "<known_failure_patterns>"; do
    if ! grep -qF "$section" CLAUDE.md; then
      missing+=("$section")
    fi
  done
  if [[ ${#missing[@]} -eq 0 ]]; then
    check "1.  CLAUDE.md has all required policy sections" pass
  else
    check "1.  CLAUDE.md has all required policy sections" fail "missing: ${missing[*]}"
  fi
else
  check "1.  CLAUDE.md exists" fail "file not found"
fi

# 2. Instruction precedence block exists.
if grep -qF "<instruction_precedence>" CLAUDE.md 2>/dev/null; then
  check "2.  CLAUDE.md has <instruction_precedence> block" pass
else
  check "2.  CLAUDE.md has <instruction_precedence> block" fail "missing"
fi

# 3. Charter directory exists and is non-empty.
if [[ -f .claude/knowledge/charter/principles.md && -f .claude/knowledge/charter/non-negotiables.md ]]; then
  check "3.  .claude/knowledge/charter/ has principles + non-negotiables" pass
else
  check "3.  .claude/knowledge/charter/ has principles + non-negotiables" fail "missing required file"
fi

# 4. Trust layers are separated (charter / context / evidence).
if [[ -d .claude/knowledge/charter && -d .claude/knowledge/context && -d .claude/knowledge/evidence ]]; then
  check "4.  trust layers separated (charter / context / evidence)" pass
else
  check "4.  trust layers separated (charter / context / evidence)" fail "one or more subdirectories missing"
fi

# 5. Every skill has a "Known failure patterns" section.
missing_kfp=()
while IFS= read -r -d '' skill; do
  if ! grep -qiE "known failure patterns" "$skill"; then
    missing_kfp+=("$(basename "$(dirname "$skill")")")
  fi
done < <(find .claude/skills -name 'SKILL.md' -print0 2>/dev/null)

if [[ ${#missing_kfp[@]} -eq 0 ]]; then
  check "5.  every skill has a 'Known failure patterns' section" pass
else
  check "5.  every skill has a 'Known failure patterns' section" fail "missing in: ${missing_kfp[*]}"
fi

# 6. Guardrails hook is registered.
if [[ -f .claude/hooks/hooks.json ]] && grep -q "guardrails.sh" .claude/hooks/hooks.json; then
  check "6.  guardrails hook registered in hooks.json" pass
else
  check "6.  guardrails hook registered in hooks.json" fail "hooks.json missing or does not reference guardrails.sh"
fi

# 7. Guardrails script is executable.
if [[ -x scripts/guardrails.sh ]]; then
  check "7.  scripts/guardrails.sh is executable" pass
else
  check "7.  scripts/guardrails.sh is executable" fail "run: chmod +x scripts/guardrails.sh"
fi

# 8. Commands exist.
missing_cmds=()
for cmd in health verify adr deploy; do
  if [[ ! -f ".claude/commands/${cmd}.md" ]]; then
    missing_cmds+=("$cmd")
  fi
done
if [[ ${#missing_cmds[@]} -eq 0 ]]; then
  check "8.  workspace commands defined (health, verify, adr, deploy)" pass
else
  check "8.  workspace commands defined (health, verify, adr, deploy)" fail "missing: ${missing_cmds[*]}"
fi

# 9. At least one example is present and non-TODO.
if [[ -d .claude/knowledge/examples ]] && find .claude/knowledge/examples -name '*.md' -print -quit 2>/dev/null | grep -q .; then
  check "9.  knowledge/examples/ has at least one example" pass
else
  check "9.  knowledge/examples/ has at least one example" fail "no examples found"
fi

# 10. ADR template exists.
if [[ -f .claude/knowledge/adr/0000-template.md ]]; then
  check "10. ADR template present" pass
else
  check "10. ADR template present" fail "missing .claude/knowledge/adr/0000-template.md"
fi

# 11. knowledge/context/ frontmatter freshness.
stale_found=0
if [[ -d .claude/knowledge/context ]]; then
  today_epoch=$(date +%s)
  for ctx in .claude/knowledge/context/*.md; do
    [[ -f "$ctx" ]] || continue
    last_verified=$(awk '/^last_verified:/ {print $2; exit}' "$ctx")
    decay_risk=$(awk '/^decay_risk:/ {print $2; exit}' "$ctx")
    [[ -z "$last_verified" ]] && continue
    # macOS/BSD date and GNU date have different flags. Try GNU first.
    if file_epoch=$(date -d "$last_verified" +%s 2>/dev/null); then
      :
    elif file_epoch=$(date -j -f "%Y-%m-%d" "$last_verified" +%s 2>/dev/null); then
      :
    else
      continue
    fi
    age_days=$(( (today_epoch - file_epoch) / 86400 ))
    if [[ "$decay_risk" == "high" && $age_days -gt 30 ]]; then
      stale_found=1
      STALE_FILES+=("$ctx (${age_days}d old, decay_risk: high)")
    fi
  done
fi
if [[ $stale_found -eq 0 ]]; then
  check "11. no stale high-decay-risk context files" pass
else
  check "11. no stale high-decay-risk context files" warn "see list below"
fi

# 12. Version tag matches between .claude/VERSION and CLAUDE.md.
file_version=$(cat .claude/VERSION 2>/dev/null | tr -d '[:space:]')
md_version=$(grep -oE 'version="[^"]+"' CLAUDE.md 2>/dev/null | head -1 | sed 's/version="//; s/"//')
if [[ -n "$file_version" && -n "$md_version" && "$file_version" == "$md_version" ]]; then
  check "12. .claude/VERSION matches CLAUDE.md version tag" pass
else
  check "12. .claude/VERSION matches CLAUDE.md version tag" fail ".claude/VERSION='$file_version', CLAUDE.md='$md_version'"
fi

printf "\nsummary: %d passed, %d failed, %d warnings\n" "$PASS" "$FAIL" "$WARN"

if [[ ${#STALE_FILES[@]} -gt 0 ]]; then
  printf "\nstale context files:\n"
  for f in "${STALE_FILES[@]}"; do
    printf "  - %s\n" "$f"
  done
fi

# Plugin detection.
if [[ -d .sea || -f .sea/state.json ]]; then
  printf "\nplugin: software-engineer-agent runtime state detected (.sea/)\n"
  printf "        for a richer runtime-state audit, try /software-engineer-agent:diagnose\n"
fi

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
exit 0
