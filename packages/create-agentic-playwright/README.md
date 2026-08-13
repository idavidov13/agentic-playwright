# create-agentic-playwright

> **Stop teaching your AI how to write tests. Hand it the rulebook.**

Scaffold a production-grade Playwright + TypeScript test framework with a harness for
all major AI coding agents baked in — one command, first test run green in minutes.

```bash
npm create agentic-playwright my-tests
```

## Presets

```bash
npm create agentic-playwright my-tests -- --demo   # zero questions: demo API, all AI rule trees, smoke run
npm create agentic-playwright my-tests -- --bare   # your own app URLs, no demo smoke run
npm create agentic-playwright my-tests             # interactive — 3 questions
```

Other flags: `--yes`, `--skip-install`, `--skip-browsers`, `--skip-git`, `--skip-smoke`.

## What you get

- **Scaffold core** — dependency-injected page objects, API testing with runtime-validated
  Zod contracts, Faker + Zod data factories, enums as the single source of truth.
- **AI harness** — a Constitution plus 17 detailed skills for Claude Code, with parallel
  rule trees for Cursor and GitHub Copilot (pruned at init if you don't use them).
- **Quality gates** — skill linting, cross-reference checks, version single-sourcing.
- **Exploration-first UI testing** — `playwright-cli` wired in for live-app exploration
  before any selector is written.

The template is bundled inside this package — no network fetch at init time, and the
initializer version always matches the template version.

Full documentation: <https://github.com/idavidov13/agentic-playwright>

## License

MIT
