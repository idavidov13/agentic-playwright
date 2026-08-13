# Troubleshooting — Common Agent Failure Modes

## The agent generated something that doesn't follow the scaffold's conventions

**Cause:** The relevant specialized skill wasn't loaded — the agent worked from generic Playwright knowledge.
**Fix:** Name the skill explicitly in the prompt ("use the `api-testing` skill"). The skill will load and the Critical block will catch what was missed.

## The agent is asking too many questions; I just want it to do the work

**Cause:** Audit-then-edit is the default. It's deliberate for non-trivial work.
**Fix:** Say "just do it" once. The agent switches to direct mode for the rest of the session for trivial work. For substantive changes, audit-then-edit is the right default — turning it off uniformly leads to drift.

## The agent invented a folder name / enum value / env-var name

**Cause:** Critical rule violated — the agent should have stopped and asked.
**Fix:** Direct it to re-check via `ls` (paths), `playwright-cli` (UI text), `env/.env.example` (env vars), or the OpenAPI doc (API contracts). If still unknown, the agent must stop and ask the human.

## The agent skipped exploration and invented selectors

**Cause:** Forbidden by Critical (`page-objects`, `selectors`, `CLAUDE.md` "No Substitute UI Exploration").
**Fix:** Reject the output. Re-prompt requiring `playwright-cli` exploration. Ship nothing until selectors come from observed UI.

## The agent loaded five skills' Critical blocks and is overwhelmed

**Cause:** Skill stacking. Specialized skills load on demand, not all at once.
**Fix:** Load one entry-point skill (the routing table's "First skill" column). It chains to deeper skills only as needed. If you genuinely need three skills' rules at once, the work is too big for one task — split it.

## The agent's commit message says only "Update tests"

**Cause:** Phase 8 skipped.
**Fix:** Reject the message; require a body that names the _why_ and the substantive changes. The orchestrator's commit history (`Refine X skill ...`, `Sync CLAUDE.md ...`, `Add debugging skill ...`) is the reference shape.

## The agent wants to run `npm test` after every micro-change

**Cause:** Misreading "run the affected tests" as "run the full suite".
**Fix:** Re-read Phase 7 — affected tests, not the full suite. `npx playwright test <file>` is the default; `npm test` only at the end of a logical change.

## The agent suppressed a test failure (raised timeout, added `try/catch`, removed an assertion)

**Cause:** Critical rule violation — `debugging` Critical forbids suppression.
**Fix:** Reject the change. Re-load `debugging` and follow Phase 4 (right tool) + Phase 5 (root-cause fix table). For genuine API mismatches, `api-testing` Phase 7 (`test.skip` + `// FIXME:`).

## The agent skipped Phase 4 (Plan + Confidence) and started editing

**Cause:** Treated audit-then-edit as optional.
**Fix:** Reject the diff. Require a Phase 4 proposal block with confidence + unknowns before any edit. The only exception is direct-mode trivial work (one-line fix, typo, single import).
