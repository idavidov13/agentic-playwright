# Contributing to Agentic Playwright

Thanks for your interest in improving Agentic Playwright!

## Before you start

This repository is unusual in one important way: **the AI rule trees are part of the product.** The Constitution (`CLAUDE.md`), the skills (`.claude/skills/`), and their mirrors for Cursor (`.cursor/`) and GitHub Copilot (`.github/`) define how AI coding agents behave inside a generated project. Changes to code and changes to rules usually travel together.

That means contributions are checked by more gates than a typical repo:

1. **ESLint + Prettier + `tsc --noEmit`** — standard code quality.
2. **Skill lint (`npm run lint:skills`)** — structural checks on every `SKILL.md`.
3. **Cross-reference and drift gates** — skills reference each other and the Constitution; the gates fail if a rename or rule change leaves a dangling reference or lets the Claude/Cursor/Copilot trees drift apart.
4. **Version single-sourcing (`npm run check:version`)** — `VERSION`, `package.json`, and the latest `CHANGELOG.md` heading must agree.

Run everything locally before pushing:

```bash
npm ci
npx tsc --noEmit && npx eslint . && npx prettier --check .
npm run lint:skills && npm run check:version
npx playwright test        # requires env/.env.dev — see README "Environment Variables"
```

## Ground rules for changes

- **Follow the Constitution.** The rules in `CLAUDE.md` apply to contributed test code too: fixtures over manual instantiation, web-first assertions, no hard waits, no `any`, `z.strictObject()` for API schemas, one tag per test.
- **Rules and mirrors move together.** If you change a skill under `.claude/skills/`, update the matching `.cursor/` and `.github/` files in the same PR.
- **Vendored skills are off-limits for direct edits.** `skill-creator` and `playwright-cli` are tracked in `skills-lock.json` and synced from upstream; local edits get overwritten. Open an issue instead.
- **New behavior needs an example.** A new pattern (fixture type, data tier, selector rule) should come with a small example file demonstrating it.

## Sign-off (DCO)

This project uses the [Developer Certificate of Origin](https://developercertificate.org/). Every commit must be signed off:

```bash
git commit -s -m "your message"
```

The sign-off certifies you have the right to submit the contribution under the project's MIT license.

## Pull requests

1. Fork, branch from `main`, keep PRs focused on one change.
2. Fill in the PR template; explain the _why_, not just the _what_.
3. All CI checks must pass; a maintainer reviews after that.

## Questions / ideas

Open a [discussion or issue](https://github.com/idavidov13/agentic-playwright/issues) — issues are welcome for bugs, feature requests, and rule-quality reports (e.g. "my agent misread rule X").
