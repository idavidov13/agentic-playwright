# Conversation Contract

For predictable, repeatable AI collaboration the human and agent follow these patterns.

## Audit-then-Edit (default for non-trivial work)

1. The user states the goal in plain language.
2. The agent loads the relevant specialized skill(s) and **proposes scope** — what will change, in which files, why, with the trade-offs, plus a 1-10 confidence + rationale + unknowns block (see `SKILL.md` Phase 4).
3. The user **approves, modifies, or rejects** the scope.
4. The agent applies the change.
5. The agent reports what landed (files, line counts, lint status) and asks whether to commit.

## Direct Mode (for trivial work)

- One-line fixes, obvious typos, single-import additions: the agent does it and reports back.
- The user can say "just do it" once to opt out of audit-then-edit for the rest of a session for trivial work.
- Substantive changes still go through audit-then-edit, regardless of "just do it".

## When the Agent Must Stop and Ask

- **Primary input missing** for the task (URL for a page object, OpenAPI / spec for an API test, field list for a factory, area folder name for any path-bound work). Ask before producing a Phase 4 proposal — the confidence thresholds (including the < 5 → ASK floor) live canonically in `SKILL.md` "Phase 4 — Confidence-Gate Format" and are not restated here.
- Path or folder name unknown (always `ls` first; if still unclear, ask).
- Enum value, message text, or endpoint path unknown (always `playwright-cli` for UI text or check OpenAPI for API; ask if neither is available).
- Two valid approaches with meaningful trade-offs (architectural decisions belong to the human).
- The Critical rule of any skill conflicts with the user's request (raise it; don't silently bypass).

## When the Agent Must Refuse

- Placeholder selectors / guessed UI text — refuse and re-explore.
- Hardcoded credentials, URLs, or endpoint paths — refuse and route to `config` / `enums` / `process.env.*`.
- Suppressed test failures (`try/catch` on `expect`, raised timeouts, silent `.skip`) — refuse and route to `debugging` + `api-testing` Phase 7.
- `z.object()` instead of `z.strictObject()`, `any` types, XPath selectors, `page.waitForTimeout(...)` — refuse and route to the matching Critical rule.

## After Rejection

When the human rejects a proposal, the agent re-enters Phase 3 (Explore) with the stated gap as the new evidence target. The agent does **not** retry Phase 4 with the same plan dressed differently.
