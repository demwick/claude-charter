# Example: a good pull request

A realistic PR from a fictional codebase, annotated to show the
pattern.

## The title

> `fix(auth): prevent race condition in session refresh`

Imperative, under 70 characters, would fit in a changelog line.

## The description

```markdown
## Why

When two concurrent requests found an expired session simultaneously,
each one triggered its own refresh against our IdP. This burned
rate-limit slots and occasionally produced conflicting tokens that
would then fail validation, surfacing as intermittent 401s that were
hard to reproduce.

We saw this spike to ~0.3% of sessions during our 2026-03-20 traffic
burst. The fix was requested by the infra team after the incident.

## What changed

- Added a per-user mutex around the session refresh path.
- The mutex is held only for the duration of the IdP call.
- The second concurrent caller now waits for the mutex, then
  re-reads the refreshed session from the shared store.
- No API changes. No database changes.

## How to test

- [ ] `pytest auth/session_refresh_test.py -k concurrent`
- [ ] Manually: open two browser tabs, let the session expire, then
      refresh both within a few seconds. Network tab should show
      exactly one `POST /oauth/token` request, not two.

## Risks

- The mutex introduces serial behavior for refreshes to the same user.
  In practice this is ~50ms and only during session rollover, so the
  user-facing impact is negligible.
- If the mutex implementation deadlocks, the current behavior degrades
  to a timeout on the second caller rather than a failed refresh.

## Out of scope

- The broader question of whether session refresh should be
  pre-emptive (before expiry) is tracked in issue #482.
```

## What makes this good

1. **Why first.** Motivation before mechanics. A reviewer who only
   reads the first section already knows whether to care.
2. **Concrete numbers.** "~0.3% of sessions", "50ms" — anchors the
   discussion in reality instead of vibes.
3. **Test plan is actionable.** Checkboxes the reviewer can run.
4. **Risks stated explicitly.** A PR without risks is either trivial
   or hiding them.
5. **Scope discipline.** "Out of scope" prevents review drift into
   adjacent questions.
6. **No generated summary of the diff.** The reviewer can read the
   diff; the PR body adds the context the diff cannot.

---

<!-- Replace this example with a real PR description from your
     project that you would be happy to see copied as a pattern. -->
