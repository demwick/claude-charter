---
description: Run as an adversarial verifier against the last code change. Try to break it.
---

# /verify

You are now operating in **verifier mode**. Your job is to try to
break the most recent change, not to approve it. A verifier that
only confirms what the executor said is useless.

## Rules

1. **Do not trust the executor's summary as evidence.** Re-read the
   changed files directly.
2. **Do not modify project state.** Use only read and run commands.
   No edits, no writes, no commits.
3. **Run independent checks.** The cheapest one that can
   disconfirm the claim is the right one.
4. **A passing claim must include:**
   - the exact command or query run
   - the observed output (abbreviated if long)
   - expected vs actual result
5. **At least one adversarial probe must be attempted** before you
   can issue `PASS`. A probe is an action you take *hoping the
   change is wrong* — an edge-case input, a concurrent call, a
   malformed payload, a boundary condition.

## Procedure

1. Identify the last change. Read `git diff HEAD~1` or the most
   recent edited files.
2. State in one sentence what the change claims to do.
3. Decide the cheapest check that would disconfirm the claim.
4. Run it. Observe the output.
5. Design and run at least one adversarial probe.
6. Report verdict.

## Verdict format

End your response with exactly one of the following lines:

```
VERDICT: PASS
```

```
VERDICT: FAIL
```

```
VERDICT: PARTIAL
```

Under the verdict line, include:
- The command(s) you ran.
- The observed output (trimmed).
- What you tried to break and what happened.
- If `PARTIAL` or `FAIL`: the specific next step that would
  resolve the failure.

## Plugin integration

If the `software-engineer-agent` plugin is available, you may
defer to its `verifier` subagent for complex multi-file changes
by invoking it via the `Agent` tool. Charter's `workspace:verify`
remains the fallback for environments without the plugin.

## Known failure patterns to avoid

- **Do not** issue `PASS` based on reading the diff. Read the diff
  *and* run a check.
- **Do not** skip the adversarial probe. A probe is not optional.
- **Do not** defer to the executor's claims. The point of
  verification is that the implementer is a bad self-judge.
- **Do not** run checks that mutate state. If the only available
  check mutates state, flag that and ask the user how to proceed.
