# create-agentic-playwright

> **Stop teaching your AI how to write tests. Hand it the rulebook.**

Scaffold a production-grade Playwright + TypeScript test framework with a harness for
all major AI coding agents baked in — one command, first test run green in minutes.

```bash
npm create agentic-playwright .
```

The `.` scaffolds into the current (empty) directory and names the project after the
folder; pass a name like `my-tests` to create a subfolder instead.

## Presets

```bash
npm create agentic-playwright . -- --demo          # zero questions: demo API, every AI tool's rules, smoke run
npm create agentic-playwright . -- --bare          # your own app URLs, no demo smoke run
npm create agentic-playwright .                    # interactive — 4 questions
npm create agentic-playwright my-tests -- --demo   # same, but into a new ./my-tests subfolder
```

Other flags: `--no-claude` / `--no-agents` / `--no-copilot`, `--yes`, `--skip-install`, `--skip-browsers`, `--skip-git`, `--skip-smoke`.

## What you get

- **Scaffold core** — dependency-injected page objects, API testing with runtime-validated
  Zod contracts, Faker + Zod data factories, enums as the single source of truth.
- **AI harness** — one `AGENTS.md` Constitution plus 17 skills for Claude Code, Codex,
  Cursor and GitHub Copilot, with a write-time hook for Claude Code and a commit-time
  scan for every tool.
- **Quality gates** — eight skill gates (budget, generated-tree sync, shape, drift,
  references, cross-references), version single-sourcing.
- **Exploration-first UI testing** — `playwright-cli` wired in for live-app exploration
  before any selector is written.

The template is bundled inside this package — no network fetch at init time, and the
initializer version always matches the template version.

Full documentation: <https://github.com/idavidov13/agentic-playwright>

## License

MIT
