---
description: Run the claude-charter 12-point self-audit against this workspace.
---

# workspace:health

You are running the claude-charter self-audit. Execute the audit
script and report the results in a clean, scannable format.

## Procedure

1. Run the health script:

   ```bash
   bash scripts/health.sh
   ```

2. Read the output. For each of the 12 checks, note:
   - `PASS` checks — list them briefly.
   - `FAIL` checks — explain what would fix each one.

3. If any `last_verified` dates are older than 30 days with
   `decay_risk: high`, call them out as specific items to re-verify.

4. If the `software-engineer-agent` plugin is detected
   (`.sea/` exists), suggest that `/software-engineer-agent:diagnose`
   can provide a richer runtime-state audit in addition to this one.

## Report format

```
charter version: <from .claude/VERSION>
checks passed: X / 12

failed checks:
  - <check name>: <one-line remediation>
  - <check name>: <one-line remediation>

stale context files:
  - <path>: last_verified <date>, <N> days old

next step: <the single most important thing to fix>
```

Keep the report under 15 lines. If everything passes, say so in one
sentence.
