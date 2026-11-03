# create-agentic-playwright

> **Stop teaching your AI how to write tests. Hand it the rulebook.**

Scaffold a production-grade Playwright + TypeScript test framework with a harness for
all major AI coding agents baked in — one command, first test run green in minutes.

```bash
npm create agentic-playwright@latest . -- --demo
```

The `.` scaffolds into the current (empty) directory and names the project after the
folder; pass a name like `my-tests` to create a subfolder instead.

## Commands

| Command                                                   | What it does                                                    |
| --------------------------------------------------------- | --------------------------------------------------------------- |
| `npm create agentic-playwright@latest . -- --demo`        | No questions: demo API, install, smoke test. Green in minutes.  |
| `npm create agentic-playwright@latest .`                  | Interactive: Claude Code? Other agents? Demo API or your app?   |
| `npm create agentic-playwright@latest . -- --bare`        | Your own app: asks for its URLs and credentials, no smoke test. |
| `npm create agentic-playwright@latest my-tests -- --demo` | Same as the first, into a new `./my-tests` folder.              |
| `npm create agentic-playwright@latest -- --help`          | Every flag.                                                     |

With npm, the `--` passes the flags through npm to the initializer; pnpm, yarn and bun
do not need it.

**Flags:** `--no-claude` leaves out Claude Code (`.claude/`, `CLAUDE.md`); `--no-agents`
leaves out the other agents, such as Codex, Cursor and GitHub Copilot (`.agents/`,
`.github/prompts/`). `AGENTS.md` always ships, so at least one skill tree stays.
`--bare --yes` asks nothing and writes placeholders to `env/.env.dev`. `--skip-install`,
`--skip-browsers`, `--skip-git` and `--skip-smoke` skip that step.

## What you get

- **Scaffold core** — dependency-injected page objects, API testing with runtime-validated
  Zod contracts, Faker + Zod data factories, enums as the single source of truth.
- **AI harness** — one `AGENTS.md` Constitution plus 17 skills for Claude Code and the
  other agents (Codex, Cursor, GitHub Copilot, ...), with a write-time hook for Claude Code and a commit-time
  scan for every tool.
- **Quality gates** — eight skill gates (`AGENTS.md` budget, generated-tree sync, shape,
  vendored-skill hashes, rule drift, references, heading pointers, cross-references),
  version single-sourcing.
- **Exploration-first UI testing** — `playwright-cli` wired in for live-app exploration
  before any selector is written.

The template is bundled inside this package — no network fetch at init time, and the
initializer version always matches the template version.

Full documentation: <https://github.com/idavidov13/agentic-playwright>

## License

MIT
