# Contributing to Agentic Playwright

Thanks for your interest in improving Agentic Playwright!

## Before you start

This repository is unusual in one important way: **the AI rule trees are part of the product.** The Constitution (`AGENTS.md`), the skills (`.claude/skills/`) and their generated copy for Codex, Cursor and GitHub Copilot (`.agents/skills/`) define how AI coding agents behave inside a generated project. Changes to code and changes to rules usually travel together.

That means contributions are checked by more gates than a typical repo:

1. **ESLint + Prettier + `tsc --noEmit`** — standard code quality.
2. **Skill gates (`npm run check:skills`)** — eight gates over the rules layer: the `AGENTS.md` budget and Skills Index, skill shape, vendored-skill hashes, and drift between the Constitution, the skills and the hook.
3. **Cross-reference and sync gates** — part of the same eight: skills reference each other and the Constitution, and the gates fail if a rename or rule change leaves a dangling reference or lets the generated `.agents/skills/` drift from `.claude/skills/`.
4. **Version single-sourcing (`npm run check:version`)** — `VERSION`, `package.json`, and the latest `CHANGELOG.md` heading must agree.

Run everything locally before pushing:

```bash
npm ci
npx tsc --noEmit && npx eslint . && npx prettier --check .
npm run check:skills && npm run check:version
npx playwright test        # requires env/.env.dev — see README "Environment Variables"
```

Working in a git worktree? It starts without `env/.env.dev`, `node_modules` and the husky hooks. Seed it from the main checkout with `sh .claude/orca/orca-worktree-setup.sh` — see README "Git Worktrees (Orca)".

## Ground rules for changes

- **Follow the Constitution.** The rules in `AGENTS.md` apply to contributed test code too: fixtures over manual instantiation, web-first assertions, no hard waits, no `any`, `z.strictObject()` for API schemas, one tag per test.
- **Edit the canonical tree only.** Change a skill under `.claude/skills/`, run `npm run skills:sync`, and commit both trees; `npm run check:skills` fails otherwise.
- **Vendored skills are off-limits for direct edits.** `skill-creator` and `playwright-cli` are tracked in `skills-lock.json` and synced from upstream; local edits get overwritten. Open an issue instead.
- **New behavior needs an example.** A new pattern (fixture type, data tier, selector rule) should come with a small example file demonstrating it.

## Changing a rule

A rule is written in more than one place. Change them in this order; the gates catch some of what you miss, the last step catches the rest.

1. **The Constitution row** in `AGENTS.md`. The file is capped at 800 words and 100 lines.
2. **Adding, removing or renaming a rule**: the row list in `scripts/check-rules-drift.sh` and the rule counts in `README.md`.
3. **The owning skill's Critical block** in `.claude/skills/<skill>/SKILL.md` (250 words at most), then the examples in that skill's `references/`. `scripts/rules-manifest.txt` maps each rule to its skill through a literal token; update the token when the literal changes.
4. **The reviewer copies**: `.claude/skills/pr-reviewer/references/constitution-checklist.md`, `.github/prompts/pr-reviewer.prompt.md` and `.claude/skills/common-tasks/references/verification-checklist.md`; then the skill evals whose expected behaviour names the rule (`.claude/skills/*/evals/evals.json`).
5. **The human docs**: `AI-WORKFLOWS.md`, the README section that shows the rule, and the comments in the example code under `pages/` and `tests/`.
6. **A mechanical rule** also lives in `eslint.config.mts` and in `.claude/scripts/enforce_constitution.py`. The hook is a protected path: an agent drafts that change, a human applies it.
7. `npm run skills:sync`, then `npm run check:skills` and `npm run lint`. A failing gate names the file.
8. Search for what is left: `git grep -n '<old wording>' -- . ':!.agents' ':!CHANGELOG.md'`. A rule written as a list spans several lines, and no one-line pattern finds it: search for each term it names as well.
9. A `CHANGELOG.md` entry when the change alters what an agent does.

## Sign-off (DCO)

This project uses the [Developer Certificate of Origin](https://developercertificate.org/). Every commit must be signed off:

```bash
git commit -s -m "your message"
```

The sign-off certifies you have the right to submit the contribution under the project's MIT license.

## Pull requests

1. Fork, branch from `main`, keep PRs focused on one change. Open an issue before a large or design-level change.
2. Fill in the PR template; explain the _why_, not just the _what_.
3. All CI checks must pass; a maintainer reviews after that.

## Questions / ideas

Open a [discussion or issue](https://github.com/idavidov13/agentic-playwright/issues) — issues are welcome for bugs, feature requests, and rule-quality reports (e.g. "my agent misread rule X").
