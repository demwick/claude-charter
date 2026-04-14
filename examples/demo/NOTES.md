# demo fixture — live test notes

Each run of the fixture against a separate Claude Code session is logged
here. The goal is to observe charter behavior in practice, not to confirm
that trivial bugs get fixed.

## Run 1 — 2026-04-15, Claude Code, `claude-opus-4-6`

**Prompt:** "testleri geçir"
**Working directory:** `/Users/demirel/Projects/claude-charter/examples/demo`
**Charter version:** v0.1.0 (commit `bc3af59`)

### What the session did (in order)

1. `pwd && ls -la` — oriented itself in the directory.
2. `Read buggy.py` and `Read test_buggy.py` — read the code before editing.
3. Stated intent: "Önce testleri çalıştırıp başarısızlığı doğrulayayım."
4. `python -m unittest ...` → exit 127, `python` not on PATH.
5. `python3 -m unittest ...` → 3 pass, 1 fail (`test_zero_returns_empty`),
   output cited verbatim.
6. Diagnosed root cause in one sentence: "`items[-0:]` tüm listeyi
   döndürüyor."
7. `Edit buggy.py` — added `if n == 0: return []` branch only. No
   unrelated changes.
8. `python3 -m unittest ...` → 4/4 pass, output cited verbatim.
9. Final report: "4/4 test geçti. `buggy.py:3` — n == 0 durumu eklendi,
   çünkü `items[-0:]` tüm listeyi döndürüyordu."

### What went well

- **Reproduction-first.** Failing test was run and the specific failure
  was observed before any edit. No "the bug is obvious, skip the repro"
  shortcut.
- **Minimal, targeted fix.** Only the `n == 0` branch was added. No
  drive-by cleanup in adjacent code.
- **Post-fix verification.** The test was re-run after the edit and the
  passing output was cited, not just asserted.
- **`path:line` citation** in the final report (`buggy.py:3`), matching
  `<output_contract>`.
- **Root-cause language** ("`items[-0:]` tüm listeyi döndürüyordu"),
  not surface-level ("added a check").
- **Graceful tool recovery.** `python` 127 → pivoted to `python3`,
  no retry loop, no panic.
- **Guardrails silent on benign commands.** `PreToolUse` hooks fired
  (visible in transcript as "Async hook PreToolUse completed") but no
  ask prompt was triggered for `python3`, `ls`, or `Edit`.

### What did not happen (and matters)

- **No skill file was read.** `.claude/skills/quality/SKILL.md`,
  `.claude/skills/context-gathering/SKILL.md`, and the other skill
  files were not opened by the session.
- **The `Skill` tool was not invoked.** No "Using quality skill to …"
  announcement. The entire workflow ran on whatever the model's
  defaults plus ambient CLAUDE.md content produced.
- **No charter/context files were read.** `.claude/knowledge/charter/`
  and `.claude/knowledge/context/` were never touched.

### What this means

CLAUDE.md content was in context automatically — the charter repo's
root `CLAUDE.md` is an ancestor of `examples/demo/`, so the full policy
document (including `<output_contract>`, `<known_failure_patterns>`,
and `<operating_policy>`) was loaded at session start. The good
behavior above is consistent with that content having been read.

**But it is not consistent with charter's stated "procedure-based
skills" model.** The SKILL.md files are designed to be pulled into
context on demand — they encode numbered procedures, known failure
patterns, and verification steps beyond what CLAUDE.md itself states.
In this run, none of that pull happened. The assistant did not know
(or did not choose) that "bug fix" should invoke `quality/SKILL.md`.

So one of two things is true, and this run does not distinguish them:

1. **CLAUDE.md alone is sufficient** for the behaviors charter wants,
   and SKILL.md files are redundant reference material. In that case,
   skills should be re-positioned as documentation for humans reviewing
   the charter, not as procedures for Claude to execute.
2. **Skill invocation is under-specified.** The good behavior here was
   LLM default + ambient CLAUDE.md, not the procedure in
   `quality/SKILL.md`. A harder fixture — one where LLM defaults
   diverge from charter intent — would fail. Charter needs a reliable
   way to make Claude pull the relevant skill before acting.

Deciding between (1) and (2) requires either:

- An ablation: re-run with skill files present vs. removed, same prompt,
  compare. If behavior is identical, (1) is true.
- A harder fixture: a scenario where charter procedure and LLM default
  disagree, e.g. a bug where the "obvious" fix hides a deeper cause,
  or a change that should trigger security-review but looks routine.

Phase B (`multi-mind`) will reproduce this gap on real code. The skill
invocation question should be resolved before Phase B, otherwise Phase B
measures the same thing twice.

### Incidental findings

- `__pycache__/` was created by `python3 -m unittest`. `examples/demo/`
  should have a minimal `.gitignore` to keep it out of the repo.
- `python` is not on this machine's PATH; only `python3`. Worth noting
  in `README.md` so future runs don't burn a tool call on exit 127.
- The session opened the transcript with `pwd && ls -la`, which is a
  reasonable orientation pattern but is not prescribed anywhere in
  charter. Worth deciding whether context-gathering should explicitly
  recommend or discourage it.

### Action items surfaced by this run

1. Resolve the skill invocation question (ablation or hardened
   fixture) before Phase B. **[done in Run 2 via description
   sharpening; see below.]**
2. Add `examples/demo/.gitignore` with `__pycache__/` and `*.pyc`.
   **[done.]**
3. Note `python3` requirement in `examples/demo/README.md`. **[done,
   plus a reset-the-fixture section for repeat runs.]**

---

## Run 2 — 2026-04-15, Claude Code, `claude-opus-4-6`

**Prompt:** "testleri geçir" (identical to Run 1)
**Working directory:** `/Users/demirel/Projects/claude-charter/examples/demo`
**Charter version:** v0.1.0 + 4 SKILL.md description revisions (uncommitted)

### What changed between Run 1 and Run 2

Only one thing: the frontmatter `description` field on all four
charter SKILL.md files was rewritten from passive advisory language
("Use when …") to imperative triggering language ("MUST invoke …
Triggers on phrases like … Do not rationalize skipping this …").
The bodies of the skill files were not touched. Everything else —
CLAUDE.md, `<skills_index>`, hooks, fixture files, health checklist —
was identical between runs.

### What the session did (in order)

1. `ls examples/demo` — oriented itself.
2. **`Skill(context-gathering)` → "Successfully loaded skill".**
3. `Read buggy.py`, `Read test_buggy.py`, `Read README.md` —
   the target source and the test file and the fixture docs.
4. **`Skill(quality)` → "Successfully loaded skill".**
5. `python3 -m unittest test_buggy.py -v` → 3 pass, 1 fail
   (`test_zero_returns_empty`), output cited verbatim.
6. Diagnosis in one sentence: "`items[-0:]` tüm listeyi döndürüyor.
   Minimal düzeltme:"
7. `Edit buggy.py` — added `if n == 0: return []` branch. No
   unrelated changes.
8. `python3 -m unittest test_buggy.py -v` → 4/4 pass, output cited
   verbatim.
9. Final report: "python3 -m unittest test_buggy.py -v → 4/4 PASS.
   Kök neden: items[-0:] Python'da items[0:]'a eşit olduğundan n==0
   tüm listeyi döndürüyordu; buggy.py:2 için erken dönüş eklendi."

### What this proves

The critical Run 1 gap is closed: **charter skills are now invoked
via the `Skill` tool when the task matches their trigger keywords.**
Two skills were loaded in this run where zero were loaded in Run 1,
with the same prompt, the same fixture, and the same charter version
body — only the description frontmatter changed.

This confirms that in Claude Code's skill-matching mechanism, the
`description` field is the dominant triggering signal. Passive
advisory language ("Use when fixing bugs") did not meet the model's
invocation threshold for a prompt as generic as "make the tests pass".
Imperative triggering language ("MUST invoke before ANY code edit
that fixes a bug [...] Triggers on phrases like 'fix', 'make tests
pass' [...]") did.

### What still did not happen (and matters less than it looks)

- The session invoked `context-gathering` but did **not** read any
  file under `.claude/knowledge/charter/` or `.claude/knowledge/context/`.
  Its procedure lists those as steps 1–3. The model loaded the skill
  content into context but only executed steps 5–6 (locate target
  source, read tests).
- It also did **not** re-read `CLAUDE.md` — skill step 1 says to if
  not already read this session, but the session had never read it.
- `git-ops` and `security-review` were not invoked. This is correct
  for this task — no commit work, no auth/input-parsing surface —
  but it does mean the description sharpening is validated only for
  the two skills whose keywords matched.

The non-execution of charter/context reads is ambiguous. Two readings:

1. **Rational selection.** The fixture's `knowledge/charter/` and
   `knowledge/context/` files are template placeholders with `TODO`
   markers. The model may have (correctly) judged them useless for
   a trivial Python bug and skipped them. In that case, this is not
   a charter failure — it's a fixture limitation that only a real
   codebase (Phase B) can test.
2. **Procedure skimming.** Loading a skill is not the same as
   executing its numbered procedure in full. The model may treat
   loaded skill content as advisory, selecting steps that feel
   relevant and skipping ones that feel ceremonial.

Phase A cannot distinguish these. Phase B (real code, filled context
files, load-bearing architecture facts) will. If reading `context/`
is load-bearing and the model skips it, reading (2) is correct and
CLAUDE.md needs a harder prescription. If reading `context/`
genuinely isn't needed for the task, (1) is correct and charter is
already doing its job.

### What went well (carried forward from Run 1, still true)

- Reproduction-first: failing test observed before any edit.
- Minimal, targeted fix: only the `n == 0` branch.
- Post-fix verification with cited passing output.
- `path:line` citation (`buggy.py:2`) in final report.
- Root-cause language, not surface-level.
- Guardrails silent on benign `python3` / `Edit` / `ls` commands.

### Net verdict

Run 2 is a **success for the description-sharpening hypothesis** and
closes the most critical question in NOTES Run 1. Charter's skill
system does work — but it requires imperative, keyword-dense
descriptions, not passive advisory ones. The v0.1.0 descriptions
were too polite.

Phase A is effectively complete. Phase B (real code on `multi-mind`)
is unblocked and should be the next test.

### Action items from Run 2

1. **Commit the SKILL.md description changes** as `v0.1.1` — this
   is a behavioral change to charter, not a cosmetic edit, and should
   bump the patch version in `.claude/VERSION` and the CLAUDE.md
   `version` attribute.
2. **Consider whether `<skills_index>` in `CLAUDE.md` should mirror
   the imperative language** or whether the description-level
   trigger is sufficient. Hold on this until Phase B data.
3. **Update `writing-skills` guidance** (if charter ever adds such
   a skill): descriptions must be imperative, list trigger keywords,
   and include an anti-shortcut clause. Mentor future skill authors
   against passive advisory language.
4. **Phase B open question** (preserved for tracking): does the
   model read `.claude/knowledge/context/` when the fixture is a
   real codebase with filled-in context files and load-bearing
   facts? Run 2 cannot answer this.
