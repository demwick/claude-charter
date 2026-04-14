# Example: a good ADR

A realistic Architectural Decision Record, annotated.

## The ADR

```markdown
# 0007: Use per-user mutex for session refresh

- **Status:** Accepted
- **Date:** 2026-03-21
- **Deciders:** @auth-team, @infra-team

## Context

The session refresh path runs whenever an access token expires. Two
concurrent requests that both find an expired token will each trigger
a full OAuth refresh against the IdP. This produced:

1. Doubled IdP rate-limit usage during traffic bursts.
2. Occasional conflicting tokens causing intermittent 401s.

The incident on 2026-03-20 made the problem visible: ~0.3% of
sessions experienced the conflict during a traffic spike.

## Decision

Introduce a per-user mutex around the session refresh path. The
mutex is keyed by user ID and held only for the duration of the IdP
call. A second concurrent refresh waits for the mutex and then
re-reads the refreshed session from the shared session store
instead of issuing its own IdP call.

## Consequences

**Positive**
- Eliminates duplicate IdP calls during concurrent refresh.
- Reduces IdP rate-limit pressure by ~50% during traffic bursts.
- Fixes the intermittent 401 class of bugs.

**Negative**
- Serializes refreshes for the same user. Measured overhead: ~50ms
  worst case, only during session rollover.
- Adds a dependency on the shared mutex implementation; if it
  misbehaves, refreshes for one user can hang until timeout.

**Neutral**
- No API changes. No database changes. No schema migrations.

## Alternatives considered

1. **Pre-emptive refresh (refresh before expiry).**
   Rejected for V1: requires redesigning how tokens are tracked and
   introduces a new class of bugs around clock skew. Tracked as a
   V2 option in issue #482.

2. **Distributed mutex via Redis.**
   Rejected: we already run a per-process mutex and the race is
   dominated by within-process concurrency, not cross-process. Adds
   a hard dependency on Redis availability for login.

3. **Deduplicate IdP calls at the HTTP client layer.**
   Rejected: too coarse — would also deduplicate unrelated token
   requests.
```

## What makes this good

1. **The decision is atomic.** One decision per ADR. Don't pack
   multiple unrelated choices into one record.
2. **Context explains the pain, not the solution.** The reader knows
   why the status quo was not acceptable.
3. **Consequences section is honest about downsides.** An ADR that
   only lists upsides is marketing, not engineering.
4. **Alternatives considered with reasons.** Future readers can
   evaluate whether the rejected alternatives have become viable.
5. **Dated and signed.** Six months from now, the reader can
   evaluate whether the decision's assumptions still hold.

---

<!-- Replace this with a real ADR from your project when you have
     one. Use 0000-template.md as the starting point for new ADRs. -->
