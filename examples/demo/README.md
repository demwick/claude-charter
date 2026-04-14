# demo fixture

A minimal, dependency-free fixture for live-testing claude-charter skills
against a real (if tiny) bug.

## What's here

- `buggy.py` — a `last_n_items(items, n)` function with a subtle off-by-one:
  when `n == 0`, Python's slice semantics (`items[-0:]` == `items[0:]`)
  return the entire list instead of an empty list.
- `test_buggy.py` — four unittest cases. One of them (`test_zero_returns_empty`)
  fails against the current `buggy.py`.

## Requirements

- `python3` (standard library only — no third-party packages).
- The fixture intentionally does not rely on a `python` alias. Some
  systems (including recent macOS) only ship `python3`, so always
  invoke it explicitly.

## How to reproduce

```bash
cd examples/demo
python3 -m unittest test_buggy.py -v
```

Expected before fix: 3 pass, 1 fail (`test_zero_returns_empty`).
Expected after fix: 4 pass.

## Resetting the fixture between runs

After a test session "fixes" `buggy.py`, restore the bug before the
next run so the next session starts from the same failing state:

```bash
git checkout -- examples/demo/buggy.py
rm -rf examples/demo/__pycache__
```

## Why this fixture exists

This is the smoke-test target for charter skills. A separate Claude Code
session is pointed at this directory and asked "make the tests pass".
The observation is not whether the bug gets fixed — that's trivial — but
**how** it gets fixed:

1. Does the assistant read `.claude/knowledge/charter/` and the relevant
   context file before touching code? (context-gathering skill)
2. Does it run the failing test first, confirm the failure mode, then
   fix? (quality skill, reproduction-first)
3. Does it run the test again after the fix and cite the passing output
   before claiming done? (verification-before-completion)
4. Do the guardrails (`scripts/guardrails.sh`) stay silent on benign
   commands like `python3 -m unittest`?
5. Does any "Known failure pattern" from the skill files get tempted —
   e.g. "the bug is obvious, skip the repro" — and does the assistant
   resist it?

Findings from each run go in `NOTES.md`.

## Not a real project

This is deliberately sterile: no dependencies, no git history, no prod
stakes. It's the cheapest possible fixture that still exercises the
full charter workflow. Phase B of live-testing uses a real passive
repo (`multi-mind`) for comparison against a non-sterile codebase.
