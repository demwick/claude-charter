---
name: quality
description: MUST invoke before ANY code edit that fixes a bug, adds a feature, makes a failing test pass, implements behavior, or refactors logic. Triggers on phrases like "fix", "add", "implement", "make it work", "make tests pass", "resolve", "get rid of the error". Enforces reproduction-first debugging and real-command verification after the change. Do not rationalize skipping this for "trivial" or "obvious" changes — obvious bugs regress silently without a reproduction test.
---

# Quality & Testing

Your job is to deliver changes that are **verified**, not just written.
Follow the procedures below exactly. Do not invent shortcuts.

## Procedure: Fixing a bug

1. **Reproduce.** Write a failing test (or a minimal reproduction script)
   that exercises the bug. Run it. Observe the failure. Record the exact
   command and the exact output.
2. **Locate.** Read the relevant source files. Identify the single
   smallest change that would fix the observed behavior.
3. **Implement.** Make the minimal change. Do not refactor surrounding
   code. Do not rename unrelated identifiers.
4. **Verify.** Run the reproduction test again. Observe that it now
   passes. Run adjacent tests in the same module. Observe they still pass.
5. **Report.** In the final response, include: the exact command used,
   the observed output (PASS/FAIL and count), and a one-sentence
   description of the root cause.

## Procedure: Adding a feature

1. **Read the contract.** Find the nearest existing code that does
   something similar. Read it. Match its conventions for error handling,
   naming, file layout, and test style.
2. **Plan in one sentence.** Before the first edit, state what you will
   change and in which files.
3. **Write a test first** if the codebase has tests for the affected
   layer. Otherwise, write the test immediately after the implementation
   but before reporting success.
4. **Implement.** Make the change. Do not exceed the stated scope.
5. **Verify.** Run the new test. Run the full test suite for the
   affected module.
6. **Report** as above.

## Procedure: Before reporting any change complete

Run the cheapest meaningful verification available, in this order:
1. The specific test that covers the change.
2. The module's linter or type checker, if fast.
3. A broader test suite only if the change touches shared code.

If none of these exist in the project, say so explicitly. Do not
fabricate a verification step.

## Numeric anchors

- Write at most **one** reproduction test per bug. More is noise.
- Keep the minimal fix under **20 lines** of diff unless the root cause
  genuinely requires more.
- Final response: **lead with verification status**, then the fix
  summary. Maximum 5 sentences unless the user asks for depth.

## Known failure patterns to avoid

- **Do not** claim a fix works based only on reading the code. Run the
  test.
- **Do not** treat a passing unit test as proof that the end-to-end
  workflow works.
- **Do not** skip the reproduction test "because the bug is obvious".
  Obvious bugs still regress without a test.
- **Do not** clean up unrelated code while "already in there". Scope
  creep turns a reviewable fix into an unreviewable one.
- **Do not** add defensive try/catch blocks or input validation for
  scenarios that cannot happen inside trusted internal code.
- **Do not** mark the task complete without running the verification
  step. Running it after reporting success does not count.

## Rule with reason format

Every rule above exists for a reason. If you find an edge case where
the rule seems to cost more than it saves, **surface the edge case to
the user before deviating** — do not silently skip.
