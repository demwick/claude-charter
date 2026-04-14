# Example: a good commit

A realistic commit from a fictional codebase, annotated to explain
what makes it a good reference.

## The commit message

```
fix(auth): prevent race condition in session refresh

When two concurrent requests both found an expired session, each
would trigger its own refresh against the identity provider, burning
a rate-limit slot and sometimes issuing conflicting new tokens.

The fix introduces a per-user mutex around the refresh path, held
only for the duration of the IdP call. The second caller now waits
and re-reads the refreshed session from the shared store.

Verified against the reproduction added in
`auth/session_refresh_test.py::test_concurrent_refresh_single_idp_call`.
```

## What makes this good

1. **Conventional commit format** — `fix(auth): ...` tells the reader
   the type, scope, and summary at a glance.
2. **Imperative mood** — *"prevent"* reads like a command the commit
   gives the codebase. *"prevented"* or *"prevents"* would be weaker.
3. **Under 70 characters** on the summary line.
4. **Body explains WHY, not WHAT.** The diff already shows what
   changed. The commit explains the motivation (rate limits,
   conflicting tokens) and the mechanism (per-user mutex).
5. **Points to evidence.** Names the test that proves the fix works.
6. **No noise.** No "fix typo", no "address review comments", no
   mention of the reviewer.

## What a bad version of this commit would look like

```
fix: updated session code
```

- No scope.
- No motivation.
- "Updated" is vague — what changed? Why?
- No evidence.
- Not actionable if the fix regresses in six months.

---

<!-- Replace this example with a real commit from your project that
     you would be happy to see copied as a pattern. -->
