# Changelog

All notable changes to Agentic Playwright are documented here. Entries are listed in reverse chronological order (newest first).

---

## v1.0.2 -- Template Payload Excludes Repo-Only CI -- 2026-09-21

- **Scaffolded projects no longer inherit repo-only CI.** `prepack.js` now excludes `.github/workflows/template-smoke.yml`, `.github/workflows/release.yml`, and `.github/FUNDING.yml` from the bundled template. Projects created with 1.0.1 shipped the template smoke workflow, which fails on every push because it expects `packages/create-agentic-playwright/` — delete those two workflow files in an existing project to fix it.
- **New `Lint` workflow** (`.github/workflows/lint.yml`) runs `tsc`, ESLint, and Prettier on the repository itself, so formatting drift from web-UI edits fails with an obvious name. Ships with scaffolded projects too. The generated `packages/create-agentic-playwright/template/` directory is now excluded from `tsconfig.json` and ESLint, so a local `npm pack` no longer doubles the lint surface.
- **Release workflow is idempotent.** Re-pushing an already-published tag skips `npm publish` instead of failing with "cannot publish over the previously published versions".
- **Prettier-version-agnostic skill examples.** `type-safety` code fences no longer use `{ /* ... */ }` object bodies, which Prettier 3.8 and 3.9 format differently and would have broken the template smoke gate on the next Prettier bump.

## v1.0.1 -- Silence dotenv v17 Banners -- 2026-08-13

- **dotenv v17 promotional banners silenced.** `dotenv.config()` now passes `quiet: true` — v17 (pulled in via dependency updates) prints "injected env" lines with rotating sponsor ads into every Playwright run.
- Release workflow runs on Node 24 (`npm@latest` no longer supports Node 20).

## v1.0.0 -- Initial Public Release -- 2026-08-13

The first public release of **Agentic Playwright** — a production-grade Playwright + TypeScript scaffold for agentic testing, with a harness for all major AI coding agents baked in.

### What's included

- **Scaffold core** — dependency-injected page objects, API testing with runtime-validated Zod contracts, test data factories (Faker + Zod), static boundary/invalid datasets, enums as the single source of truth for endpoints, routes, and messages.
- **AI harness** — a Constitution (`CLAUDE.md`) plus 17 detailed skills covering selectors, page objects, fixtures, test standards, type safety, data strategy, API testing, debugging, refactoring, PR review, and an 8-phase AI-native workflow with a confidence gate.
- **Multi-agent support** — parallel rule trees for Claude Code (`.claude/`), Cursor (`.cursor/`), and GitHub Copilot (`.github/`), kept consistent by lint and cross-reference gates.
- **Exploration-first UI testing** — mandatory live-app exploration via `playwright-cli` before any page object or selector is generated.
- **Constitution enforcement hook** — write-time guard that checks generated code against the scaffold's forbidden patterns.
- **PR review skill** — reviews a branch against the scaffold's own rules: routed skills, verification (ESLint / Prettier / tsc / affected tests), tiered findings with confidence.
- **Quality gates** — skill linting, cross-reference checks, rules-drift detection, and version single-sourcing, wired into CI and husky hooks.
- **Dev Container** — pre-warmed browser and npm caches for near-instant onboarding.
