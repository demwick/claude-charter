# claude-charter

> Treat your project's AI instructions not as copy, but as a **versioned, layered contract** between you and the agent. Every rule has its own clause. Every clause has precedence. Every violation is verifiable.

`claude-charter` is an opinionated, self-auditing scaffold for the `.claude/` directory. It turns the principles from the [Unofficial Claude Code Prompt Playbook](https://github.com/kropdx/unofficial-claude-code-prompt-playbook) into a runnable starter kit — layered policy, trust boundaries, procedure-based skills, anti-rationalization rules, and a built-in adversarial verifier.

Works **standalone**. Composes with [`@demwick/software-engineer-agent`](https://github.com/demwick/software-engineer-agent) when you want full autonomous workflows.

---

## Why

Most `CLAUDE.md` files are a single text blob: *"you are helpful, do X, don't do Y."* That works until the agent starts inventing tools, skipping tests, or mixing user input with policy. Production-grade AI instructions are not copy — they are **layered instruction architectures**: static policy core, trusted runtime context, retrieved evidence, and user input, each with explicit trust and precedence.

`claude-charter` gives you that architecture out of the box.

## What you get

| Layer | Location | Purpose | Trust |
|---|---|---|---|
| Policy core | `CLAUDE.md` | role, operating policy, tool policy, output contract, known failure patterns | highest |
| Charter doctrine | `.claude/knowledge/charter/` | non-negotiables, principles | highest |
| Runtime context | `.claude/knowledge/context/` | architecture, glossary, constraints (dated) | trusted |
| Evidence | `.claude/knowledge/evidence/` | research notes, external docs | untrusted |
| Examples | `.claude/knowledge/examples/` | realistic few-shot references | trusted |
| Skills | `.claude/skills/*/SKILL.md` | procedure-based behavior rules | high |
| Commands | `.claude/commands/` | `/health`, `/verify`, `/adr`, `/deploy` | — |
| Hooks | `.claude/hooks/hooks.json` | `PreToolUse` guardrails that ask before destructive actions | enforced |
| ADR | `.claude/knowledge/adr/` | architectural decision records | — |

## Install (GitHub template)

1. Click **Use this template → Create a new repository** on GitHub, or:
2. One-liner with [`degit`](https://github.com/Rich-Harris/degit):

   ```bash
   npx degit demwick/claude-charter my-project
   cd my-project
   ```
3. Fill in the templates marked `TODO` inside `.claude/knowledge/charter/` and `.claude/knowledge/context/`.
4. Run the self-audit:

   ```bash
   bash scripts/health.sh
   ```
5. Open Claude Code — `CLAUDE.md` is loaded automatically.

## Core patterns

### 1. Layered, versioned policy

`CLAUDE.md` uses explicit XML sections (`<role>`, `<operating_policy>`, `<tool_policy>`, `<risk_policy>`, `<channel_contract>`, `<output_contract>`, `<known_failure_patterns>`) and is **versioned** via `.claude/VERSION`. Prompt changes are diffable; precedence is explicit.

### 2. Trust boundary

`knowledge/charter/` is policy. `knowledge/context/` is trusted runtime facts (with `last_verified` dates). `knowledge/evidence/` is untrusted — the agent is told to never treat evidence as policy. This is structural defense against prompt injection from retrieved content.

### 3. Procedure-based skills

Skills don't say *"follow TDD"*. They say:

> 1. Reproduce the bug with a failing test.
> 2. Implement the minimal fix.
> 3. Run the test. Observe pass.
> 4. Run adjacent tests.
> 5. Report: exact command, observed output, verdict.

Plus a **Known failure patterns** block naming the likely shortcuts.

### 4. Adversarial verifier

`/verify` is a separate role whose job is to **try to break** the last change, not approve it. Returns `VERDICT: PASS | FAIL | PARTIAL` with command + output as evidence.

### 5. Self-auditing

`/health` runs a 12-point checklist:
- policy sections present
- trust layers separated
- skills have known-failure blocks
- guardrails hook registered
- `knowledge/context/` frontmatter dates aren't stale
- charter version matches CLAUDE.md

### 6. Guardrails hook

`.claude/hooks/hooks.json` registers a `PreToolUse` hook (`scripts/guardrails.sh`) that asks before destructive actions: `rm -rf`, `git push --force` on main, `.env` reads, `curl | sh`, and more. **Ask, don't silently block.**

## Composing with `software-engineer-agent`

If the [`software-engineer-agent` plugin](https://github.com/demwick/software-engineer-agent) is installed, `claude-charter` detects it and defers verification to the plugin's `/software-engineer-agent:` commands when present. Without the plugin, every charter feature still works — `/verify`, `/health`, and the guardrails hook are fully self-contained.

```
plugin = engine (autonomous agents, state machine, auto-QA)
charter = culture   (policy, procedures, trust boundaries, audits)
```

## Credits

- **Unofficial Claude Code Prompt Playbook** — the theoretical foundation. This project is a concrete implementation of patterns described there. https://github.com/kropdx/unofficial-claude-code-prompt-playbook
- **Anthropic** — for publishing `CLAUDE.md`, skills, hooks, and subagent APIs as first-class primitives.

## License

MIT. Copy the `.claude/` directory into any project, public or private, and adapt freely.
