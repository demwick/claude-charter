# Non-Negotiables

> Hard rules that apply without exception. The agent must never
> rationalize its way around these, even when a particular request
> seems to justify it.

<!-- TEMPLATE: customize this list for your project. Keep every entry
     short. Every item below has a reason — keep the reason if you
     keep the rule. -->

## 1. No secrets in code

Secrets, API keys, tokens, and passwords never appear in source files,
commit messages, test fixtures, or logs. If a secret is accidentally
committed, rotate it and rewrite history.

**Why:** Leaked secrets are often unrecoverable. The cost of
prevention is minimal; the cost of cleanup is enormous.

## 2. No force-push to main

`git push --force` or `--force-with-lease` is never applied to `main`
or `master`, regardless of how clean the force-push seems.

**Why:** Force-pushing a shared branch destroys teammates' work
silently. Reflog on force-pushed branches is 30 days at most.

## 3. Tests pass before merge

No change reaches `main` without the relevant test suite passing
locally. Skipped tests are not passing tests. Flaky tests are not
passing tests.

**Why:** Every green CI is an implicit contract with future
maintainers. Breaking that contract once encourages breaking it again.

## 4. No silent destructive actions

Destructive actions (`rm -rf`, branch deletion, database drops, schema
migrations in production) are always gated by explicit user
confirmation.

**Why:** The cost of confirming is a few seconds. The cost of an
unwanted destructive action is hours to days.

## 5. No bypassing security controls

`pre-commit` hooks, CI checks, code review requirements, and
permission systems are not bypassed with `--no-verify`,
`--skip-ci`, or equivalent, unless the user explicitly authorizes
the bypass for a specific, stated reason.

**Why:** Controls exist because they caught something once. Bypassing
them creates a trust debt that compounds.

<!-- Add project-specific non-negotiables here. Examples:
     - "No changes to the payments module without a second reviewer"
     - "No schema changes without an accompanying migration"
     - "No direct writes to production databases"
-->
