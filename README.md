<p align="center">
  <img src="assets/hero-terminal.svg" width="720" alt="npm create agentic-playwright@latest . -- --demo: ArchQA banner, the five setup steps, smoke test green, AI rules loaded">
</p>

<h1 align="center">Agentic Playwright</h1>

<p align="center">
  <strong>Stop teaching your AI how to write tests. Hand it the rulebook.</strong>
</p>

<p align="center">
  <a href="https://www.npmjs.com/package/create-agentic-playwright"><img src="https://img.shields.io/npm/v/create-agentic-playwright?style=flat-square&label=npm" alt="npm"></a>
  <a href="https://github.com/idavidov13/agentic-playwright/actions/workflows/template-smoke.yml"><img src="https://img.shields.io/github/actions/workflow/status/idavidov13/agentic-playwright/template-smoke.yml?style=flat-square&label=template%20smoke" alt="Template Smoke Test"></a>
  <img src="https://img.shields.io/badge/works%20with-Claude%20Code%20·%20Codex%20·%20Cursor%20·%20Copilot-blue?style=flat-square" alt="Works with Claude Code, Codex, Cursor, Copilot">
  <a href="https://nodejs.org/"><img src="https://img.shields.io/badge/node-%3E%3D22-green?style=flat-square" alt="Node >= 22"></a>
  <a href="https://playwright.dev/"><img src="https://img.shields.io/badge/playwright-%5E1.64-orange?style=flat-square" alt="Playwright ^1.64"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="MIT license"></a>
</p>

<p align="center">
  Production-grade Playwright + TypeScript Scaffold for Agentic Testing.<br>
  A complete, running test framework — page objects, API contracts, data factories, CI —<br>
  plus the AI rules your assistant picks up automatically, from the very first prompt.
</p>

## See it

From the (empty) directory your project should live in — the `.` means "scaffold right
here, and name the project after this folder" (a fresh `git clone` of an empty repo
works too). Prefer a new subfolder? Pass a name instead of `.`:

```bash
npm create agentic-playwright@latest . -- --demo
```

Zero questions. Scaffolds the framework, installs dependencies and a browser, and ends
by running the smoke test against a live demo application — **you see green before
writing a line.** Under 5 minutes on normal broadband.

## Without the rulebook vs with it

The same prompt — _"write a test for the product search"_ — to the same AI assistant:

```ts
// ❌ Unsupervised: XPath, hard waits, `any`, magic timeouts, no structure
test('search', async ({ page }) => {
    await page.goto('https://practicesoftwaretesting.com');
    await page.locator('//input[@id="search-query"]').fill('pliers');
    await page.locator('//button[@type="submit"]').click();
    await page.waitForTimeout(5000);
    const cards: any = await page.$$('.card');
    expect(cards.length > 0).toBe(true);
});
```

```ts
// ✅ With Agentic Playwright: fixtures, steps, web-first assertions
import { expect, test } from '../../../fixtures/pom/test-options';

test(
    'should show only matching products when searching',
    { tag: '@regression' },
    async ({ homePage }) => {
        await test.step('GIVEN the user is on the home page', async () => {
            await homePage.open();
        });

        await test.step('WHEN the user searches for "pliers"', async () => {
            await homePage.searchFor('pliers');
        });

        await test.step('THEN every result matches the search term', async () => {
            await expect(homePage.searchCaption).toContainText('pliers');
            await expect(homePage.productNames.first()).toContainText('Pliers');
        });
    }
);
```

Dependency-injected page objects, Given/When/Then steps, web-first assertions, no hard
waits, no `any`, one tag per test — enforced by one `AGENTS.md` Constitution and 17 skills the
assistant loads automatically, a write-time hook that blocks the forbidden patterns
outright in Claude Code, and the same rules scanned at commit time for every tool.

_Not affiliated with Microsoft. [Playwright](https://playwright.dev/) is an open-source project by Microsoft; this scaffold builds on it._

> **This is a scaffold, not a finished framework.** The example files (`AppPage`, `login.spec.ts`, `NavigationComponent`, etc.) demonstrate the patterns and conventions you should follow. Replace them with your real application's pages, tests, and data as you build out your test suite.

---

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start: npm create](#quick-start-npm-create)
- [Quick Start: Dev Container](#quick-start-dev-container)
    - [Claude Code Custom Status Line](#claude-code-custom-status-line)
- [Quick Start: Local Setup Script](#quick-start-local-setup-script)
- [Manual Installation](#manual-installation)
- [Getting Started: Adapting the Scaffold](#getting-started-adapting-the-scaffold)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Environment Variables](#environment-variables)
- [Running Tests](#running-tests)
- [Tag Reference](#tag-reference)
- [Writing Tests](#writing-tests)
- [Page Object Model](#page-object-model)
- [API Testing](#api-testing)
- [Data Strategy](#data-strategy)
- [Authentication Setup](#authentication-setup)
- [Code Quality](#code-quality)
- [Coding Standards](#coding-standards)
- [Core Principles (The Constitution)](#core-principles-the-constitution)
- [AI-Assisted Development Workflow](#ai-assisted-development-workflow)
- [AI Rules Architecture](#ai-rules-architecture)
- [Architecture Overview](#architecture-overview)
- [Troubleshooting](#troubleshooting)
- [Agentic Playwright Pro](#agentic-playwright-pro)
- [License](#license)

---

## Features

- **TypeScript** -- Full type safety with strict mode enabled
- **Page Object Model** -- Maintainable and scalable test architecture
- **Fixture-based Architecture** -- Reusable test components with dependency injection
- **API Testing** -- Built-in `apiRequest` fixture with Zod schema validation and helper fixtures for setup/teardown
- **Multi-browser Support** -- Chrome, Firefox, and WebKit configurations
- **Environment Management** -- Flexible `.env` configuration with multi-environment support
- **Authentication Handling** -- Pre-configured storage state for authenticated tests
- **Code Quality** -- ESLint + Prettier + Husky pre-commit hooks
- **Parallel Execution** -- Fast test runs with configurable workers
- **Comprehensive Reporting** -- HTML reports with traces, screenshots, and videos
- **AI-Assisted Development** -- One orchestrator, [`AGENTS.md`](AGENTS.md), holds the Constitution, the workflow and the Skills Index. Codex, Cursor and GitHub Copilot read it natively; Claude Code imports it through `CLAUDE.md`. The 17 skills live once, in `.claude/skills/`, and are generated byte-for-byte into `.agents/skills/` (`npm run skills:sync`) for the harnesses that load skills from there; `npm run check:skills-sync` fails when the two differ.
- **Confidence-Gated Workflow** -- The `ai-native-workflow` skill is the sole entry-point router for non-trivial work. Every plan must include `Confidence: <1-10>`, `Rationale`, and `Unknowns`; below confidence 5 the agent is required to stop and ask the user for the missing primary input rather than emit a plan built on guesses.
- **Constitution Enforcement Hook** -- `.claude/scripts/enforce_constitution.py` is wired as a Claude Code `PreToolUse` hook in `.claude/settings.json`. It blocks any `Write`/`Edit`/`MultiEdit` that would introduce one of 18 mechanically detectable Constitution violations (`waitForTimeout`, `z.object` in schemas, XPath, `@playwright/test` imports in specs, `.json` static data, unknown, multiple or missing tags, tags on `test.describe()`, `new PageObject()` in specs, hardcoded URLs, JSDoc on locator getters, inline text in assertions, and more) before the file is written; an `Edit` is judged on the file it produces, and comments are ignored. Its `--scan` mode runs the same rules over the staged TypeScript in pre-commit and over the changed TypeScript in CI, so Codex, Cursor and Copilot meet them at commit time.
- **Version Single-Source** -- the root `VERSION` file is the one source of truth for the product version. `npm run version:stamp` writes it into `package.json` and into the two root entries of `package-lock.json`; `npm run check:version` asserts `VERSION` == `package.json` == `package-lock.json` root == the latest `CHANGELOG.md` heading and fails on drift. Gated in `.husky/pre-commit` (when a version surface is staged) and in CI (`skill-lint.yml`).
- **Pre-Commit Drift Lints** -- `npm run check:skills` runs eight gates: the `AGENTS.md` budget and index, generated-tree parity (content and modes), the skill authoring caps, the vendored-skill lock, Constitution anchors in each skill's Critical block (and hook rule ids mapped to Constitution rows), `references/` pointers, heading and step pointers, and cross-skill names. `.husky/pre-commit` runs them when their inputs are staged (a commit touching none of them pays for lint-staged and the scan alone); `skill-lint.yml` runs all of them in CI.
- **Upstream Skill Sync** -- `skills-lock.json` records the SHA-256 of the locally vendored copies of `skill-creator` (from `anthropics/skills`) and `playwright-cli` (from `@playwright/cli`). `npm run skills:verify` re-hashes the local files and exits non-zero on drift; `npm run skills:reinstall` fetches upstream, overwrites `.claude/skills/<name>/SKILL.md` and refreshes the lock (then `npm run skills:sync` regenerates `.agents/skills/`); `npm run skills:update` re-locks after intentional local edits.
- **Playwright CLI Exploration** -- `playwright-cli` is the default browser exploration path for UI discovery, tracing, storage inspection, and flow capture
- **Out-of-the-Box Vendored Skills** -- `playwright-cli` (Microsoft's `@playwright/cli`) and `skill-creator` (Anthropic's `anthropics/skills`) are reinstalled fresh from upstream and tracked via `skills-lock.json` for reproducible installs
- **AI Task Workflows Playbook** -- [`AI-WORKFLOWS.md`](AI-WORKFLOWS.md) maps the exact step sequence for every common flow (API suite for a controller, functional tests from a ticket, E2E suite, debugging, refactors, and more) to its owning skill and phase, with an anti-drift guardrails table -- so AI-assisted execution stays consistent across sessions

## Prerequisites

- **Node.js** v22.x or later
- **npm** v10.x or later
- **Python 3**, reachable as `python3`: the Constitution hook, its pre-commit scan and three of the skill gates run on it. On Windows, the python.org installer adds only `python` and `py`, and a bare `python3` may open the Microsoft Store stub. Claude Code then blocks every Write and Edit, because the hook fails closed. Use the Dev Container or WSL, or make `python3` resolve to a real Python 3.

## Quick Start: npm create

The fastest path — scaffold a fresh project with everything wired, straight into the
directory you are standing in:

```bash
npm create agentic-playwright@latest . -- --demo
```

**Why the `.`?** It scaffolds into the **current directory** and names the project
after the folder — the natural fit when you have already created (or cloned) an empty
repo for your tests. The directory must be empty apart from repo bookkeeping like
`.git`; if a git repo already exists there, the initializer detects it and skips
`git init`. Prefer a new subfolder instead? Pass a name:

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

## Quick Start: Dev Container

The fastest way to get a fully working environment. Requires [Docker Desktop](https://www.docker.com/products/docker-desktop/) and a Dev Containers extension for your editor:

- **Cursor**: Install the [Dev Containers extension](https://marketplace.cursorapi.com/items?itemName=devcontainers.devcontainers) by _Dev Containers_.
- **VS Code**: Install the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) by _Microsoft_.

> **Important:** Make sure Docker Desktop is **up and running** before proceeding with the steps below. The Dev Container will fail to build if Docker is not started.

1. **Clone the repository:**

    ```bash
    git clone <your-repository-url>   # replace with your fork/clone URL
    cd agentic-playwright
    ```

2. **Open in Cursor/VS Code** and accept the prompt to **"Reopen in Container"** (or run `Dev Containers: Reopen in Container` from the Command Palette).

3. **Done.** The Docker image ships with pre-warmed npm and `playwright-cli` browser caches, so `postCreateCommand` completes in seconds even on first start. The container provides Node.js, npm dependencies (on a fast named volume), Playwright test browsers, Python 3, Claude Code CLI, and `playwright`/`playwright-cli` linked into `~/.local/bin`. Edit `env/.env.dev` with your app configuration and run `npm test`.

    Inside the container, the test browsers live in `/ms-playwright` (`PLAYWRIGHT_BROWSERS_PATH`) and `playwright-cli` gets its own Chromium in the `/ms-playwright-cli` volume (`scripts/playwright-cli.sh` points `PLAYWRIGHT_CLI_BROWSERS_PATH` there), so the two never share a cache. The image has no `rsync`; `npm run skills:sync` takes its tar fallback there with the same result.

> **Version alignment:** The Playwright Docker image tag in `.devcontainer/Dockerfile` (`PLAYWRIGHT_VERSION`, also in `devcontainer.json`) must match the `@playwright/test` version in `package.json`. When upgrading Playwright, update all three.

### Claude Code Custom Status Line

The scaffold includes a custom Claude Code status line that displays git branch, PR status, model, duration, cost, lines changed, and context window usage directly in the terminal.

To enable it, add the following to your `.claude/settings.local.json` (create the file if it doesn't exist):

```json
{
    "statusLine": {
        "type": "command",
        "command": "python3 .claude/scripts/status_line.py"
    }
}
```

This renders a rich status bar at the bottom of the Claude Code terminal:

```
✦ main ● | 📁 project | 🤖 Sonnet 4.6 | ⏳ 12m05s | 💰 $1.42 | + 85 | — 12 | [████████░░░░] 42.5% (85,012/200k)
```

The status line script lives at `.claude/scripts/status_line.py` and uses a Gruvbox Dark color palette. It shows:

| Segment           | Description                                                     |
| ----------------- | --------------------------------------------------------------- |
| **Git branch**    | Current branch with dirty indicator (●)                         |
| **PR status**     | Review state emoji with clickable PR link (requires `gh` CLI)   |
| **Directory**     | Current workspace folder                                        |
| **Model**         | Active Claude model                                             |
| **Duration**      | Session duration                                                |
| **Cost**          | Cumulative API cost                                             |
| **Lines changed** | Lines added/removed in the session                              |
| **Context bar**   | Visual context window usage scaled to the autocompact threshold |

> **Note:** Cost, lines changed, and context bar segments appear dynamically as you interact with Claude Code. A fresh session will only show git, directory, model, and duration.

## Quick Start: Local Setup Script

For terminal-based workflows or if you prefer not to use Docker. Works on macOS and Linux (Windows users: use WSL2).

1. **Clone the repository:**

    ```bash
    git clone <your-repository-url>   # replace with your fork/clone URL
    cd agentic-playwright
    ```

2. **Run the setup script:**

    ```bash
    bash scripts/setup.sh
    ```

    This automatically installs Node.js v22 (via nvm if needed), npm dependencies, Playwright browsers with system deps, Python 3.11+, links `playwright` and `playwright-cli` into `~/.local/bin`, and installs a dedicated `playwright-cli` Chromium cache. If you already have Node.js v22+ installed, you can also run `npm run setup` — it is equivalent.

3. **Ensure `~/.local/bin` is on your PATH** (if your shell does not already include it):

    ```bash
    export PATH="$HOME/.local/bin:$PATH"
    ```

    This is where the scaffold links `playwright` and `playwright-cli`. Add this line to your `~/.zshrc` or `~/.bashrc` to make it permanent.

4. Edit `env/.env.dev` with your app configuration and run `npm test`.

## Manual Installation

If you prefer to install dependencies manually. Steps 1-3 and 5-6 are identical on all platforms; step 4 differs.

1. **Clone the repository:**

    ```bash
    git clone <your-repository-url>   # replace with your fork/clone URL
    cd agentic-playwright
    ```

2. **Install npm dependencies:**

    ```bash
    npm install
    ```

3. **Install Playwright test browsers:**

    ```bash
    npx playwright install --with-deps
    ```

4. **Link CLI commands and install `playwright-cli` browsers:**

    **macOS / Linux:**

    ```bash
    bash scripts/link-cli.sh "$(pwd -P)"
    npm run playwright-cli:install-browsers
    ```

    Then ensure `~/.local/bin` is on your PATH (add to `~/.zshrc` or `~/.bashrc` to make permanent):

    ```bash
    export PATH="$HOME/.local/bin:$PATH"
    ```

    **Windows (PowerShell):**

    ```powershell
    npm run playwright-cli:install-browsers
    ```

5. **Set up environment variables:**

    **macOS / Linux:**

    ```bash
    cp env/.env.example env/.env.dev
    ```

    **Windows (PowerShell):**

    ```powershell
    Copy-Item env\.env.example env\.env.dev
    ```

    Edit `env/.env.dev` with your application's configuration.

6. **Run tests:**

    ```bash
    npm test
    ```

## Verify Your Installation

After any setup method, confirm all tools are available:

**macOS / Linux:**

```bash
playwright --version
playwright-cli --version
```

**Windows (PowerShell):**

```powershell
npx playwright --version
playwright-cli --version
```

Expected output (exact versions vary with your installed packages):

```
playwright --version      → Version 1.64.1
playwright-cli --version  → 0.1.23
```

---

## Getting Started: Adapting the Scaffold

This scaffold ships with example files that demonstrate every pattern. Here's how to replace them with your real application code, step by step.

### Step 1: Configure Your Environment

Edit `env/.env.dev` with your application's actual URLs and credentials:

```bash
APP_URL=https://your-real-app.com
API_URL=https://your-real-api.com
APP_EMAIL=your-test-user@example.com
APP_PASSWORD=your-test-password
```

### Step 2: Update Enums

Open `enums/app/app.ts` and replace the placeholder values with your app's actual messages, API endpoints, and storage state paths:

```typescript
export enum Messages {
    LOGIN_SUCCESS = 'Your actual success message',
    LOGIN_ERROR = 'Your actual error message',
    // Add more messages as needed
}

export enum ApiEndpoints {
    LOGIN = '/your/actual/login/endpoint',
    // Add more endpoints as needed
}
```

### Step 3: Create Your First Page Object

Replace `pages/app/app.page.ts` with a page object for your application's actual login page (or whichever page you're testing first). Use the existing file as a template:

1. Update the locators to match your app's actual elements
2. Update the action methods to match your app's actual behavior
3. Keep the same patterns: getter locators, JSDoc comments, `Promise<void>` return types

> **Tip:** If using Cursor with AI, ask it to "navigate to [your-url] and create a page object" -- the AI rules will guide it to use `playwright-cli` by default to explore the page and generate accurate locators.

### Step 4: Update Authentication Setup

Edit `helpers/app/createStorageState.ts` to match your app's actual login flow. The two functions to update:

- `createAppStorageState()` -- Browser-based login for storage state
- `setUserAccessToken()` -- API-based login for access tokens

### Step 5: Write Your First Real Test

Replace the example tests in `tests/app/functional/` with tests for your application. Follow the pattern in the example files:

```typescript
import { expect, test } from '../../../fixtures/pom/test-options';

test.describe('Your Feature', () => {
    test(
        'should do something specific',
        { tag: '@smoke' },
        async ({ appPage }) => {
            await test.step('GIVEN precondition', async () => {
                /* ... */
            });
            await test.step('WHEN action is taken', async () => {
                /* ... */
            });
            await test.step('THEN expected result', async () => {
                /* ... */
            });
        }
    );
});
```

### Step 6: Run and Verify

```bash
npm test
```

### What to Keep vs. What to Replace

| Keep As-Is                                                                | Replace With Your App                                   |
| ------------------------------------------------------------------------- | ------------------------------------------------------- |
| `fixtures/pom/test-options.ts`                                            | `pages/app/*.page.ts` (your page objects)               |
| `fixtures/pom/page-object-fixture.ts` (extend it)                         | `tests/app/**/*.spec.ts` (your tests)                   |
| `fixtures/api/plain-function.ts`                                          | `enums/app/app.ts` (your messages/endpoints)            |
| `fixtures/api/api-types.ts`                                               | `test-data/static/app/*.ts` (your test data)            |
| `fixtures/helper/helper-fixture.ts` (extend it)                           | `test-data/factories/app/*.factory.ts` (your factories) |
| `config/`, `helpers/util/`                                                | `helpers/app/createStorageState.ts` (your auth flow)    |
| `.claude/skills/` (the AI skills; `.agents/skills/` is generated from it) | `fixtures/api/schemas/app/` (your API schemas)          |
| `playwright.config.ts` (mostly)                                           | `pages/components/` (your UI components)                |

---

## Project Structure

```
root/
├── .devcontainer/             # Dev Container configuration (Docker-based setup)
│   ├── Dockerfile             # Playwright + Python + pre-warmed npm/CLI caches + Claude Code
│   ├── devcontainer.json      # VS Code/Cursor container settings
│   └── post-create.sh         # Auto-setup script (npm ci, CLI links, env file, etc.)
│
├── .playwright/
│   └── cli.config.json        # playwright-cli browser defaults (Chromium channel)
│
├── scripts/
│   ├── check-agents-md.sh               # AGENTS.md budget, bare @, Skills Index <-> .claude/skills; CLAUDE.md import; Copilot prompt anchors
│   ├── check-skills-sync.sh             # .agents/skills equals a fresh generation from .claude/skills
│   ├── sync-skills.sh                   # Regenerate .agents/skills (npm run skills:sync)
│   ├── check-rules-drift.sh             # Constitution rows <-> skill Critical-block anchors <-> hook rule ids
│   ├── check-skill-references-drift.sh  # SKILL.md <-> references/ pointers, orphans, anchors
│   ├── check-heading-pointers.sh        # Cross-skill "-> Heading" and "step N" pointers resolve
│   ├── check-skill-crossrefs.sh         # Frontmatter names, dangling skill references
│   ├── check-skill-shape.sh             # Skill authoring caps, headings, harness-neutral wording
│   ├── check-version-drift.sh           # VERSION <-> package.json <-> package-lock.json <-> CHANGELOG
│   ├── stamp-version.sh                 # Stamp VERSION into package.json + package-lock.json
│   ├── sync-upstream-skills.sh          # Verify / reinstall the vendored skill directories against skills-lock.json
│   ├── rules-manifest.txt               # Constitution anchor tokens per owning skill
│   ├── install-playwright-cli-browsers.js   # Installs playwright-cli's own Chromium cache (npm run playwright-cli:install-browsers)
│   ├── install-playwright-cli-browsers.sh   # Shell entry point for the same (setup.sh, the Dev Container)
│   ├── link-cli.sh                      # Links playwright/playwright-cli into ~/.local/bin
│   ├── playwright-cli.sh / .cmd         # Wrapper: isolated browsers path; records the exploration marker
│   └── setup.sh                         # Local development setup (non-Docker alternative)
│
├── VERSION                    # Single source of truth for the product version
├── CHANGELOG.md               # Release history (newest first)
├── AGENTS.md                  # The orchestrator: Constitution, workflow, Skills Index (every harness)
├── CLAUDE.md                  # Claude Code: imports AGENTS.md, adds the hook and status-line notes
├── AI-WORKFLOWS.md            # Step-by-step task workflow playbook (anti-drift reference)
│
├── .claude/                   # Claude Code configuration and the canonical skills
│   ├── settings.json          # Hook wiring (PreToolUse: the Constitution hook)
│   ├── scripts/
│   │   ├── enforce_constitution.py      # PreToolUse hook: 18 mechanical rules; --scan mode for reviews, pre-commit and CI
│   │   └── status_line.py               # Custom status line renderer (Gruvbox Dark theme)
│   └── skills/                # Canonical skills (edit here only): SKILL.md + references/
│       ├── ai-native-workflow/  # Router: classify, route, explore, propose with confidence, apply, verify
│       ├── api-testing/       # apiRequest fixture, coverage matrix, schemas from the contract
│       ├── common-tasks/      # Prompt templates and the verification checklist
│       ├── config/            # Environment variables, config properties, utility URLs
│       ├── data-strategy/     # Factories (Faker) vs static TS data (`as const`, three-tier rule)
│       ├── debugging/         # Failure taxonomy, capture defaults, CI replay
│       ├── enums/             # Endpoint paths, routes, messages, roles, storage-state paths
│       ├── fixtures/          # DI pattern, fixture creation, merging
│       ├── helpers/           # Plain helpers, the auth bootstrap, helper vs fixture
│       ├── page-objects/      # POM pattern, getter locators, components
│       ├── playwright-cli/    # The mandatory live-app exploration tool (vendored, hash-locked)
│       ├── pr-reviewer/       # Review a branch as a PR against the base, judged by AGENTS.md
│       ├── refactor-values/   # Impact analysis before changing an enum or static value
│       ├── selectors/         # Exploration-first workflow, selector priority, feedback selectors
│       ├── skill-creator/     # Meta-skill for creating and improving skills (vendored, hash-locked)
│       ├── test-standards/    # Test structure, tagging, steps, assertions, cleanup
│       └── type-safety/       # Zod schemas, no-any, `!` versus `??`
│
├── .agents/
│   ├── README.md              # "generated from .claude/skills, do not edit here"
│   └── skills/                # Generated copy of .claude/skills -- Codex, Cursor and Copilot read it
│
├── .github/
│   ├── prompts/
│   │   └── pr-reviewer.prompt.md  # Copilot prompt: review a branch against AGENTS.md
│   ├── workflows/
│   │   ├── lint.yml           # ESLint on changed TypeScript, tsc, the test-runner check, Prettier (pushes to main, every PR)
│   │   ├── skill-lint.yml     # The eight rule-layer gates and the version gate
│   │   ├── playwright.yml     # API tests against the demo app (non-blocking)
│   │   ├── template-smoke.yml # Pack the initializer, scaffold projects, run their gates
│   │   └── release.yml        # Publish create-agentic-playwright on a version tag
│   ├── ISSUE_TEMPLATE/        # Bug, feature and rule-quality reports
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── FUNDING.yml
│   └── dependabot.yml
│
├── packages/
│   └── create-agentic-playwright/  # The `npm create agentic-playwright` initializer (bundles this repo)
│
├── .husky/
│   └── pre-commit             # lint-staged, the Constitution scan, the path-triggered gate blocks
│
├── config/                    # Application configuration
│   ├── app.ts                 # App-specific config (URLs, paths)
│   └── util/                  # Utility configurations
│       └── util.ts
│
├── enums/                     # Constants and enumerations
│   ├── app/                   # App-specific enums
│   │   └── app.ts
│   └── util/                  # Shared enums (roles, etc.)
│       └── roles.ts
│
├── env/                       # Environment configuration
│   ├── .env.example           # Template for environment variables
│   └── .env.dev               # Development environment (git-ignored)
│
├── fixtures/                  # Playwright test fixtures
│   ├── api/                   # API testing utilities
│   │   ├── api-request-fixture.ts  # API request fixture (apiRequest)
│   │   ├── api-types.ts            # TypeScript types for API
│   │   ├── plain-function.ts       # Core API request function (internal)
│   │   └── schemas/                # Zod validation schemas
│   │       ├── app/                # App-specific schemas
│   │       │   └── userSchema.ts
│   │       └── util/               # Common error schemas
│   │           └── errorResponseSchema.ts
│   ├── helper/                # Setup/teardown helper fixtures
│   │   └── helper-fixture.ts      # API-driven precondition fixtures
│   └── pom/                   # Page Object fixtures
│       ├── page-object-fixture.ts  # Page object instantiation
│       └── test-options.ts         # Merged test fixtures (use this)
│
├── helpers/                   # Helper functions
│   ├── app/                   # App-specific helpers
│   │   └── createStorageState.ts   # Authentication helpers
│   └── util/                  # Utility functions
│       └── util.ts
│
├── pages/                     # Page Object Model classes
│   ├── app/                   # App page objects
│   │   └── app.page.ts        # Main application page
│   └── components/            # Reusable UI components
│       └── navigation.component.ts
│
├── test-data/                 # Test data files
│   ├── static/                # Immutable data (boundary/invalid cases), .ts only
│   │   ├── app/
│   │   │   └── invalidCredentials.ts
│   │   └── util/
│   │       └── invalid-values.ts   # The universal INVALID_* arrays
│   └── factories/             # Dynamic data generators (Faker + Zod)
│       └── app/
│           └── user.factory.ts
│
├── tests/                     # Test specifications
│   └── app/                   # App tests
│       ├── auth-api.setup.ts  # API token setup (setup-api project, no browser)
│       ├── auth.setup.ts      # Browser storage-state setup (setup-ui project)
│       ├── api/               # API tests
│       │   └── login.spec.ts
│       ├── e2e/               # End-to-end tests
│       │   └── e2e.spec.ts
│       └── functional/        # Functional tests
│           └── login.spec.ts
│
├── .dockerignore
├── .gitattributes
├── .gitignore
├── .nvmrc                     # Node 22
├── LICENSE                    # MIT
├── NOTICE.md                  # Third-party notices (vendored skills)
├── CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md
├── .prettierrc                # Prettier configuration
├── .prettierignore            # Vendored skills and the generated tree are not reformatted
├── eslint.config.mts          # ESLint configuration (flat config)
├── package.json
├── playwright.config.ts       # Playwright configuration
├── README.md
├── skills-lock.json           # SHA-256 of the two vendored skill directories
└── tsconfig.json              # TypeScript configuration
```

## Configuration

### Playwright Configuration

The `playwright.config.ts` file contains all test runner settings:

| Setting            | Local                   | CI                |
| ------------------ | ----------------------- | ----------------- |
| Parallel execution | Enabled                 | Enabled           |
| Workers            | Auto                    | 1                 |
| Retries            | 0                       | 2                 |
| Reporter           | HTML (opens on failure) | Blob + HTML       |
| Traces             | On first retry          | On first retry    |
| Screenshots        | On failure              | On failure        |
| Videos             | Retain on failure       | Retain on failure |

### Browser Projects

| Project     | Description                                  | Dependencies            |
| ----------- | -------------------------------------------- | ----------------------- |
| `setup-api` | API token over HTTP (`auth-api.setup.ts`)    | None                    |
| `setup-ui`  | Browser storage state (`auth.setup.ts`)      | None                    |
| `api`       | API tests, request context only (no browser) | `setup-api`             |
| `chromium`  | Main tests on Chrome                         | `setup-api`, `setup-ui` |
| `firefox`   | Firefox (commented out)                      | `setup-api`, `setup-ui` |
| `webkit`    | Safari (commented out)                       | `setup-api`, `setup-ui` |

### Timeouts

| Timeout            | Value      |
| ------------------ | ---------- |
| Test timeout       | 60 seconds |
| Action timeout     | 10 seconds |
| Navigation timeout | 30 seconds |
| Expect timeout     | 10 seconds |

## Environment Variables

### Setup

1. Copy the example file:

    ```bash
    cp env/.env.example env/.env.dev
    ```

2. Configure your variables in `env/.env.dev`:

    ```bash
    # Application URL (frontend)
    APP_URL=https://your-app-url.com

    # API URL (backend)
    API_URL=https://your-api-url.com

    # Test User Credentials
    APP_EMAIL=your-email@example.com
    APP_PASSWORD=your-secure-password

    # Additional service URLs
    UTILITY_URL=https://your-utility-service.com
    ```

### Switching Environments

```bash
# Default (dev)
npm test

# Staging environment
ENVIRONMENT=staging npm test

# Production environment (read-only tests)
ENVIRONMENT=prod npm test
```

### Creating New Environments

Create `env/.env.<environment>` files:

- `env/.env.dev` -- Development
- `env/.env.staging` -- Staging
- `env/.env.prod` -- Production

## Running Tests

### Basic Commands

```bash
# Run all tests (excludes @destructive)
npm test

# Run tests on specific browser (excludes @destructive)
npm run test:chromium
npm run test:firefox
npm run test:webkit

# Run in headed mode (see browser)
npm run test:headed

# Run in debug mode (Playwright Inspector)
npm run test:debug

# Run with UI mode (interactive)
npm run test:ui
```

### Running by Tag

Run tests filtered by tag. See the [Tag Reference](#tag-reference) section for the full list of available tags and their meanings.

```bash
# Run by importance level
npm run test:smoke          # Critical path tests
npm run test:sanity         # Key functionality verification
npm run test:regression     # Full regression coverage

# Run by test type
npm run test:api            # API-only tests
npm run test:e2e            # End-to-end user flows

# Run destructive tests only (single worker, isolated)
npm run test:destructive
```

### CI Mode

Optimized for CI environments with single worker, blob reports:

```bash
npm run test:ci
```

### View Reports

```bash
npm run report
```

---

## Tag Reference

Tags control selective test execution. Each test has **exactly one** tag. Apply tags to individual tests via `{ tag: '@smoke' }` -- **never** on `test.describe()` blocks. **`@functional` is forbidden.**

### The Single-Tag Rule

A test gets exactly one tag from this set. **`@destructive` is the heaviest tag and always wins -- but only for shared/global state.** A test that mutates state other tests or users depend on (locale, permissions, roles, guest access, feature flags, global settings) is tagged **only** `@destructive`, regardless of what importance or type tag it would otherwise carry. A test that creates and cleans up **only its own isolated data** is NOT destructive -- tag it by importance (`@smoke`/`@regression`/`@api`/…).

| Tag            | Purpose                                                                                                                               | npm Command                |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------- | -------------------------- |
| `@smoke`       | Critical path -- run first and frequently                                                                                             | `npm run test:smoke`       |
| `@sanity`      | Key functionality verification                                                                                                        | `npm run test:sanity`      |
| `@regression`  | Full regression coverage of a single behaviour                                                                                        | `npm run test:regression`  |
| `@e2e`         | End-to-end multi-feature user journey                                                                                                 | `npm run test:e2e`         |
| `@api`         | API contract and schema validation                                                                                                    | `npm run test:api`         |
| `@destructive` | Mutates **shared/global** state -- locale, permissions, roles, guest access, feature flags, global settings (overrides any other tag) | `npm run test:destructive` |

### How Tag Filtering Works

- **`npm test`** runs the full suite **excluding** `@destructive` tests (via `--grep-invert`), because the full suite runs in parallel and destructive tests modify shared state.
- **Tag-specific commands** (e.g., `test:smoke`) use `--grep @smoke` to run only matching tests. Because each test has exactly one tag, a `@destructive` test only runs under `npm run test:destructive` -- not under `test:smoke`, `test:regression`, etc.
- **`npm run test:destructive`** runs only `@destructive` tests with `--workers=1` for sequential execution.

### The `@destructive` Tag

`@destructive` is reserved for **shared/global** state -- state that lives outside the test and that other tests, users, or sessions depend on: changing the locale, granting/removing permissions, roles, or guest access, toggling feature flags or global settings, or mutating shared seed data every test reads (e.g. "delete all users"). They follow strict rules:

1. **Excluded from `npm test`** -- The base command uses `--grep-invert @destructive` to prevent them from running in the parallel full-suite execution.
2. **Run via dedicated command** -- `npm run test:destructive` with a single worker.

**Not destructive:** a test that creates its **own** record, asserts, then deletes **only that record** in cleanup is _isolated_, not destructive. Tag it by importance and let it run in the parallel suite.

**Cleanup applies to any state-mutating test.** Every test that writes persistent state -- `@destructive` shared-state tests **and** isolated own-data tests -- MUST use `test.afterEach()` or `test.afterAll()` to revert what it wrote, so subsequent tests always run against a clean environment.

```typescript
test.describe('admin data management', () => {
    test.afterEach(async ({ apiRequest }) => {
        // REQUIRED: Revert state changes made by the test
        await apiRequest({
            method: 'POST',
            url: '/api/admin/reset',
            baseUrl: process.env.API_URL,
        });
    });

    test(
        'should delete all inactive users',
        { tag: '@destructive' },
        async ({ apiRequest }) => {
            // Test modifies shared state, afterEach reverts it
        }
    );
});
```

### Forbidden Tag Patterns

```typescript
// FORBIDDEN -- @functional is not a valid tag
test('should login', { tag: '@functional' }, async ({ appPage }) => { ... });

// FORBIDDEN -- combining tags is not allowed
test('should authenticate', { tag: ['@smoke', '@api'] }, async ({ apiRequest }) => { ... });

// FORBIDDEN -- @destructive must be the ONLY tag (it always wins)
test('should purge cache', { tag: ['@regression', '@destructive'] }, async ({ apiRequest }) => { ... });

// FORBIDDEN -- tags belong on the test, not on the describe
test.describe('Feature @smoke', () => { ... });
```

---

## Writing Tests

### Test File Structure

Always import from the merged fixtures in `test-options.ts`:

```typescript
import { expect, test } from '../../../fixtures/pom/test-options';

test.describe('Feature Tests', () => {
    test.beforeEach(async ({ appPage }) => {
        await appPage.openHomePage();
    });

    test('should perform action', { tag: '@smoke' }, async ({ appPage }) => {
        await test.step('GIVEN user is on the home page', async () => {
            await expect(appPage.appTitle).toBeVisible();
        });

        await test.step('WHEN user performs an action', async () => {
            // Perform action
        });

        await test.step('THEN expected result should occur', async () => {
            // Assert result
        });
    });
});
```

### Using Test Steps

Use `test.step()` for better readability and reporting with Given/When/Then structure:

```typescript
test('descriptive test name', async ({ appPage }) => {
    await test.step('GIVEN user is on the login page', async () => {
        await appPage.openHomePage();
    });

    await test.step('WHEN user enters valid credentials', async () => {
        await appPage.login(email, password);
    });

    await test.step('THEN user should see dashboard', async () => {
        await expect(appPage.username).toBeVisible();
    });
});
```

### Data-Driven Tests

Use loops outside of test blocks to generate individual tests:

```typescript
import { INVALID_LOGIN_ATTEMPTS } from '../../../test-data/static/app/invalidCredentials';

for (const { description, email, password } of INVALID_LOGIN_ATTEMPTS) {
    test(
        `should show error for ${description}`,
        { tag: '@regression' },
        async ({ appPage }) => {
            await appPage.openHomePage();
            await appPage.login(email, password);
            await expect(appPage.errorMessage).toBeVisible();
        }
    );
}
```

## Page Object Model

### Creating Page Objects

Page objects encapsulate locators and actions for a page or component:

```typescript
import { expect, Locator, Page } from '@playwright/test';
import { Messages } from '../../enums/app/app';

export class MyPage {
    constructor(private readonly page: Page) {}

    // ==================== Locators ====================

    get inputField(): Locator {
        return this.page.getByLabel('Email address');
    }

    get submitButton(): Locator {
        return this.page.getByRole('button', { name: 'Submit' });
    }

    // ==================== Feedback Locators ====================

    get successMessage(): Locator {
        return this.page.getByText(Messages.SUBMIT_SUCCESS);
    }

    get errorMessage(): Locator {
        return this.page.getByText(Messages.SUBMIT_FAILED);
    }

    // ==================== Actions ====================

    /**
     * Submits the form and waits for the response.
     * @param {string} value - The value to enter in the form.
     * @returns {Promise<void>}
     */
    async submitForm(value: string): Promise<void> {
        await this.inputField.fill(value);
        await this.submitButton.click();
        await this.page.waitForResponse((response) =>
            response.url().includes('/api/submit')
        );
    }
}
```

### Locator Priority

Use semantic locators in this order of preference:

1. `page.getByRole()` -- Accessibility-based (recommended)
2. `page.getByLabel()` -- Form labels
3. `page.getByPlaceholder()` -- Placeholder text
4. `page.getByText()` -- Text content
5. `page.getByTestId()` -- Test IDs (fallback)

XPath and CSS class or id selectors are not allowed. When no semantic option fits, ask for a test id.

### Registering Page Objects

Add new page objects to `fixtures/pom/page-object-fixture.ts`:

```typescript
import { test as base } from '@playwright/test';
import { AppPage } from '../../pages/app/app.page';
import { MyNewPage } from '../../pages/app/my-new.page';

export type FrameworkFixtures = {
    appPage: AppPage;
    myNewPage: MyNewPage;
};

export const test = base.extend<FrameworkFixtures>({
    appPage: async ({ page }, use) => {
        await use(new AppPage(page));
    },
    myNewPage: async ({ page }, use) => {
        await use(new MyNewPage(page));
    },
});
```

### Using the `resetStorageState` Fixture

The framework provides a `resetStorageState` fixture that clears cookies, permissions and the app origin's `localStorage` and `sessionStorage` (it navigates to `APP_URL` first, because web storage is per origin). Call it in `beforeEach` when a test must start signed out inside an authenticated project: login flows, or forms that pre-fill a signed-in user's data:

```typescript
test.beforeEach(async ({ resetStorageState, appPage }) => {
    await resetStorageState();
    await appPage.openHomePage();
});

test('should login successfully', async ({ appPage }) => {
    await appPage.login(email, password);
    await expect(appPage.username).toBeVisible();
});
```

### Component Pattern

Reusable UI components can be composed into Page Objects:

```typescript
import { NavigationComponent } from '../components/navigation.component';

export class DashboardPage {
    readonly nav: NavigationComponent;

    constructor(private readonly page: Page) {
        this.nav = new NavigationComponent(page);
    }
}

// Usage in tests
await dashboardPage.nav.clickHome();
await dashboardPage.nav.logout();
```

## API Testing

### Making API Requests

Use the `apiRequest` fixture for all API calls in tests:

```typescript
import { ApiEndpoints } from '../../../enums/app/app';
import {
    UserResponse,
    UserResponseSchema,
} from '../../../fixtures/api/schemas/app/userSchema';
import { expect, test } from '../../../fixtures/pom/test-options';

test(
    'should return 200 and user data for valid credentials',
    { tag: '@api' },
    async ({ apiRequest }) => {
        const { status, body } = await apiRequest<UserResponse>({
            method: 'POST',
            url: ApiEndpoints.LOGIN,
            baseUrl: process.env.API_URL,
            body: {
                email: process.env.APP_EMAIL,
                password: process.env.APP_PASSWORD,
            },
        });

        expect(status).toBe(200);
        expect(UserResponseSchema.parse(body)).toBeTruthy();
    }
);
```

Use the `apiRequest` fixture directly for all API work -- assertions, `beforeEach`/`afterEach`, one-off calls. Do not create separate helpers for every endpoint.

### API Request Options

| Option     | Type                                              | Description                                   |
| ---------- | ------------------------------------------------- | --------------------------------------------- |
| `method`   | `'GET' \| 'POST' \| 'PUT' \| 'DELETE' \| 'PATCH'` | HTTP method                                   |
| `url`      | `string`                                          | Endpoint path                                 |
| `baseUrl`  | `string` (optional)                               | Base URL to prepend                           |
| `body`     | `Record<string, unknown>` (optional)              | Request payload                               |
| `headers`  | `string` (optional)                               | Authentication token for Authorization header |
| `authType` | `'Bearer' \| 'Token' \| 'Basic'` (optional)       | Auth scheme (default: `'Bearer'`)             |

### Schema Validation with Zod

Define schemas in `fixtures/api/schemas/`. Zod 4 promotes string format validators to top-level APIs for better tree-shaking and clarity:

```typescript
import { z } from 'zod';

export const UserResponseSchema = z.strictObject({
    id: z.uuid(),
    email: z.email(),
    token: z.string(),
});

export type UserResponse = z.infer<typeof UserResponseSchema>;
```

Use schemas to validate responses:

```typescript
const { body } = await apiRequest<UserResponse>({ ... });

// This will throw if the response doesn't match the schema
const validatedUser = UserResponseSchema.parse(body);
```

### Helper Fixtures for Important Setup/Teardown

For critical, recurring setup/teardown reused across many test files, use helper fixtures in `fixtures/helper/helper-fixture.ts`:

```typescript
// In tests -- the fixture handles lifecycle automatically
test('should edit resource', async ({ createdResource, appPage }) => {
    // createdResource was created via API before this test
    await appPage.navigateToResource(createdResource.id);
    // createdResource is deleted via API after this test (even on failure)
});
```

See `fixtures/helper/helper-fixture.ts` for the full setup/teardown pattern. Use helpers only when the same multi-step setup/teardown is duplicated across 3+ test files.

## Data Strategy

This framework uses a **bifurcated data strategy** to ensure both determinism and test isolation:

### Static Data (`test-data/static/`)

Immutable TypeScript files (`.ts` with `as const` exports) for **curated boundary and invalid data**. This data never changes, ensuring reproducible tests for edge cases. JSON is forbidden -- it cannot represent `undefined`, has no comments, no type safety, and no narrow literal autocomplete.

The scaffold follows a **three-tier rule** (see the `data-strategy` skill):

1. **Universal type-mismatch arrays** (wrong type for any field of a given primitive type) live in `test-data/static/util/invalid-values.ts` as exported `as const` tuples (`INVALID_STRING_VALUES`, `INVALID_NUMBER_VALUES`, `INVALID_BOOLEAN_VALUES`, `INVALID_UUID_VALUES`, `INVALID_ENUM_VALUES`, `INVALID_ARRAY_VALUES`, `INVALID_OBJECT_VALUES`). Import; never redefine inline.
2. **Domain-specific curated invalid sets** (invalid email formats, weak passwords, forbidden enum values, locale strings, etc.) live under `test-data/static/{area}/*.ts` -- this is where new static files usually go.
3. **Field-specific boundary / range values** (e.g., out-of-range for a `1..5` number) may stay inline in the spec file when used in exactly one place.

```
test-data/static/
├── util/
│   └── invalid-values.ts       # Universal type-mismatch tuples (as const)
└── app/
    └── invalidCredentials.ts   # Domain-specific: INVALID_EMAILS, INVALID_PASSWORDS, INVALID_LOGIN_ATTEMPTS
```

**Usage:**

```typescript
import { INVALID_LOGIN_ATTEMPTS } from '../../../test-data/static/app/invalidCredentials';

for (const { description, email, password } of INVALID_LOGIN_ATTEMPTS) {
    test(
        `should reject ${description}`,
        { tag: '@regression' },
        async ({ appPage }) => {
            await appPage.login(email, password);
            await expect(appPage.errorMessage).toBeVisible();
        }
    );
}
```

### Dynamic Data (`test-data/factories/`)

TypeScript factory functions using **Faker + Zod** for generating unique, valid data per test run. This prevents data collision in parallel execution.

```
test-data/factories/
└── app/
    └── user.factory.ts  # generateUser(), generateLoginCredentials()
```

**Usage:**

```typescript
import {
    generateUser,
    generateLoginCredentials,
} from '../../../test-data/factories/app/user.factory';

test('should create user with unique data', async ({ apiRequest }) => {
    // Generate unique user data for this test run
    const user = generateUser();
    const credentials = generateLoginCredentials();

    // Use in API calls or UI interactions
    const { status } = await apiRequest({
        method: 'POST',
        url: '/api/users',
        baseUrl: process.env.API_URL,
        body: { email: credentials.email, password: credentials.password },
    });

    expect(status).toBe(201);
});
```

**Factory with Overrides:**

```typescript
// Generate user with specific properties
const adminUser = generateUser({ email: 'admin@company.com' });

// Generate credentials with specific password
const creds = generateLoginCredentials({ password: 'SpecificPassword123!' });
```

## Authentication Setup

### How It Works

1. Two setup projects run before the main tests: `setup-api` (`tests/app/auth-api.setup.ts`) logs in over HTTP and saves the access token to `.auth/app/apiAccessToken.json`; `setup-ui` (`tests/app/auth.setup.ts`) logs in through the browser and saves the storage state
2. The `api` project depends on `setup-api` only, so API tests never launch a browser and pass where the UI is unreachable (fresh environments, CI behind bot protection); the `chromium` project depends on both
3. UI tests use the saved storage state (already authenticated)
4. Every worker of the `api` project loads the token file into `process.env.ACCESS_TOKEN` before its first test

### Storage State

The storage state is saved to `.auth/app/appStorageState.json` and includes:

- Cookies
- localStorage data
- Session information

The access token lives in a separate file because Playwright runs each project in its own worker processes: a `process.env` write made in the setup worker is not visible to other workers, so the setup writes the validated login response to `.auth/app/apiAccessToken.json` and the `apiRequest` fixture file reads it once per worker.

### Using Authentication in Tests

Tests using the `chromium` project automatically load the storage state:

```typescript
// No login needed - user is already authenticated
test('should show dashboard', async ({ appPage }) => {
    await appPage.openHomePage();
    await expect(appPage.username).toBeVisible();
});
```

### Using API Token

For API tests requiring authentication:

```typescript
const { status, body } = await apiRequest<UserData>({
    method: 'GET',
    url: '/api/protected-resource',
    baseUrl: process.env.API_URL,
    headers: process.env.ACCESS_TOKEN, // minted by auth-api.setup.ts, loaded per worker
});
```

## Code Quality

### Linting

```bash
# Check for issues
npm run lint

# Auto-fix issues
npm run lint:fix
```

### Formatting

```bash
npm run format
```

### Pre-commit Hooks

Husky runs on every commit:

- ESLint with auto-fix (`--max-warnings 0`) and Prettier on the staged TypeScript (lint-staged), then the Constitution scan (`enforce_constitution.py --scan`) over the same files
- The rule-layer gates (`check:agents-md`, `check:skills-sync`, `check:skills-shape`, `skills:verify`, `check:skills-drift`, `check:skills-references`, `check:skills-headings`, `check:skills-crossrefs`) -- only when `AGENTS.md`, `CLAUDE.md`, `AI-WORKFLOWS.md`, a skill tree, the Copilot prompt, the rule manifest, `skills-lock.json`, the Constitution hook or one of their gate scripts is staged
- Version drift lint (`check:version`) -- only when `VERSION`, `package.json`, `package-lock.json`, or `CHANGELOG.md` is staged

A commit that touches none of those paths pays for lint-staged and the scan alone. Pre-commit can be skipped with `git commit --no-verify`, so it is not the last line of defense. CI is: `lint.yml` runs ESLint and the Constitution scan over every PR's changed TypeScript (the whole project when a lint rule changed), then `tsc`, a test-runner check (`node_modules/playwright` must match `@playwright/test`, and `npx playwright test --list` must collect tests) and Prettier over the whole project; `skill-lint.yml` runs the eight gates and the version gate. A violation committed with `--no-verify` is caught there. The gates read the working tree, so stage the whole change; a deleted or renamed gated file triggers its block as well.

### Constitution Enforcement Hook

`.claude/scripts/enforce_constitution.py` is registered as a Claude Code `PreToolUse` hook in `.claude/settings.json` (matcher `Write|Edit|MultiEdit`). It is the deterministic backstop beneath the prompt-level Constitution: it reads the pending tool call on stdin and **blocks** (exit 2, message fed back to the agent) any write that would introduce a mechanically detectable violation. A `Write` is judged on the whole file; an `Edit` or `MultiEdit` is applied to the file in memory and judged on what it adds, so a fragment that completes a violation is caught and a pre-existing violation elsewhere does not block an unrelated edit. Comments are ignored (a `//` note about `waitForTimeout` is not a hard wait); string literals are not. Each hook rule names the Constitution row it enforces, and `npm run check:skills-drift` keeps that map honest. The same rules reach Codex, Cursor and Copilot through the scan in pre-commit and CI:

| Hook rule                                                 | Scope                                                                  | Constitution row          |
| --------------------------------------------------------- | ---------------------------------------------------------------------- | ------------------------- |
| `no-playwright-test-import`                               | spec and setup files                                                   | Imports                   |
| `no-hard-wait`                                            | every `.ts`                                                            | No Hard Waits             |
| `no-loose-schema`                                         | `fixtures/api/schemas/**`                                              | No Loose Schemas          |
| `no-xpath`                                                | `pages/**`, `tests/**`                                                 | No XPath                  |
| `no-json-static-data`                                     | `test-data/static/**`                                                  | No JSON Static Data       |
| `no-functional-tag`, `no-multiple-tags`, `no-unknown-tag` | spec and setup files                                                   | No Multiple Tags          |
| `no-missing-tag`                                          | spec files                                                             | No Multiple Tags          |
| `no-tags-on-describe`                                     | spec and setup files                                                   | No Tags on Describe       |
| `no-manual-instantiation`                                 | spec and setup files                                                   | No Manual Instantiation   |
| `no-runtime-code-in-static-data`                          | `test-data/static/**`                                                  | Data Strategy             |
| `no-hardcoded-url`, `no-hardcoded-goto-url`               | tests, pages, fixtures, helpers, enums, config, `playwright.config.ts` | Sources of Truth          |
| `no-inline-universal-invalids`                            | spec and setup files                                                   | Data Strategy             |
| `no-jsdoc-on-locators`                                    | `pages/**`                                                             | No JSDoc on Locators      |
| `no-hardcoded-test-content`                               | spec and setup files                                                   | No Hardcoded Test Content |
| `no-eslint-disable-scaffold`                              | every `.ts`                                                            | Linting                   |

Two more write-time gates: `[explore-before-generate]` refuses a new `*.page.ts` or `*.component.ts` file under `pages/` unless `scripts/playwright-cli.sh` recorded a live exploration in the last 240 minutes (the broader rule, explore before any UI spec or selector, stays with the agent), and `[protected-path]` refuses agent writes under `.claude/scripts/`, `.claude/settings.json`, `.claude/settings.local.json` and `.playwright-cli/`, however the path is spelled.

Malformed payloads and non-target files always pass -- the hook never blocks on Claude Code hook-infra noise. An unexpected **crash**, however, **fails closed** (exit 2, the write is blocked): a bug in a single rule must never silently reopen the gate, which is the exact fail-open hole this layer removes. A bug in a rule therefore shows up as a blocked write with a traceback, never as a silently open gate.

### Versioning

The root `VERSION` file is the single source of truth. To cut a release:

```bash
# 1. Bump the version (writes VERSION, then stamps package.json and package-lock.json)
npm run version:stamp 3.0.0

# 2. Add the matching `## v3.0.0` entry at the top of CHANGELOG.md

# 3. Verify all four surfaces agree
npm run check:version
```

`check:version` fails if `VERSION`, `package.json`, the root entries of `package-lock.json`, and the latest `CHANGELOG.md` heading disagree -- enforced in `.husky/pre-commit` and the `skill-lint.yml` CI workflow. The lock is covered because npm rewrites its root `version` on every install, so a lock left at an old version turns every `npm install` into a dirty tree.

## Coding Standards

### TypeScript

| Rule             | Description                                           |
| ---------------- | ----------------------------------------------------- |
| Type annotations | Always specify types for parameters and return values |
| No `any`         | Use proper types or `unknown`                         |
| Strict mode      | Enabled in tsconfig.json                              |
| ESNext features  | Optional chaining, nullish coalescing                 |

### Naming Conventions

| Type             | Convention                 | Example                         |
| ---------------- | -------------------------- | ------------------------------- |
| Variables        | camelCase                  | `userName`                      |
| Functions        | camelCase                  | `getUserData()`                 |
| Classes          | PascalCase                 | `AppPage`                       |
| Interfaces/Types | PascalCase                 | `UserResponse`                  |
| Enums            | PascalCase                 | `Roles`                         |
| Enum values      | SCREAMING_SNAKE            | `ADMIN`                         |
| Files            | kebab-case or dot notation | `user-schema.ts`, `app.page.ts` |

### File Naming Conventions

| Type             | Directory                   | Pattern               | Example                   |
| ---------------- | --------------------------- | --------------------- | ------------------------- |
| Page objects     | `pages/app/`                | `[name].page.ts`      | `login.page.ts`           |
| Components       | `pages/components/`         | `[name].component.ts` | `navigation.component.ts` |
| Functional tests | `tests/app/functional/`     | `[name].spec.ts`      | `login.spec.ts`           |
| API tests        | `tests/app/api/`            | `[name].spec.ts`      | `login.spec.ts`           |
| E2E tests        | `tests/app/e2e/`            | `[name].spec.ts`      | `checkout.spec.ts`        |
| Setup files      | `tests/app/`                | `[name].setup.ts`     | `auth.setup.ts`           |
| Data factories   | `test-data/factories/app/`  | `[name].factory.ts`   | `user.factory.ts`         |
| Static data      | `test-data/static/app/`     | `[name].ts`           | `invalidCredentials.ts`   |
| Zod schemas      | `fixtures/api/schemas/app/` | `[name]Schema.ts`     | `userSchema.ts`           |

### Page Object Guidelines

1. **Locators as Getters** -- Use `get` accessors for all locators
2. **Semantic Locators** -- Use `getByRole`, `getByLabel` and the other semantic locators; never XPath or a CSS class or id selector
3. **Three Locator Sections** -- Every page object should have: interactive element locators, feedback/validation message locators, and action methods
4. **Action Methods** -- Methods should represent complete user flows
5. **JSDoc on Actions Only** -- Add JSDoc with `@param` and `@returns` to action methods only. Never add JSDoc to locator getters.

### Test Guidelines

1. **Descriptive Names** -- Test names should describe expected behavior
2. **Test Tags** -- Use importance tags (`@smoke`, `@sanity`, `@regression`), type tags (`@e2e`, `@api`), and `@destructive` for tests that modify shared/global state (see [Tag Reference](#tag-reference))
3. **Tags on Tests Only** -- Apply tags to individual tests via `{ tag: '@...' }`, never on `test.describe()` blocks
4. **Test Steps** -- Use `test.step()` with Given/When/Then for readability
5. **Independence** -- Tests should be independent and not rely on other tests
6. **Web-first Assertions** -- Use `toBeVisible`, `toHaveText`, etc.
7. **No Hardcoded Timeouts** -- Rely on Playwright's auto-waiting

---

## Core Principles (The Constitution)

The Constitution has one home, [`AGENTS.md`](AGENTS.md): 15 MUST, 4 SHOULD and 17 WON'T rules, one line each, with the skill that owns the detail named in the Skills Index. Every harness loads that file (Claude Code through `CLAUDE.md`), every hook message cites a rule by its name there, and `npm run check:skills-drift` proves each rule is anchored in its owning skill. This README does not repeat the rules, so they cannot drift here.

What they amount to:

- **One import point, injected page objects.** `test` and `expect` come from `fixtures/pom/test-options.ts`; page objects are fixtures, never `new SomePage(page)` in a spec.
- **Sources of truth, not literals.** URLs and credentials from `process.env.*`, paths and messages from `enums/`, test content from factories and `test-data/static/`.
- **Strict contracts.** `z.strictObject()` schemas built from the API document; a runtime mismatch is `test.skip` plus `// FIXME`, never a loosened schema.
- **Explore before you generate.** The live app through `playwright-cli` before any page object or selector; the OpenAPI document before any API test.
- **One tag per test, web-first assertions, no hard waits, lint clean, affected tests green before "done".**

The mechanical subset is enforced at write time (the Claude Code hook), at commit and CI time (the hook's `--scan` mode, every harness) and at review time (the `pr-reviewer` scan); see [Constitution Enforcement Hook](#constitution-enforcement-hook).

---

## AI-Assisted Development Workflow

This framework is optimized for AI-assisted test development. Follow this workflow for the best results:

### The Golden Rule: Verify -> Commit -> Proceed

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         AI-ASSISTED DEVELOPMENT CYCLE                       │
│                                                                             │
│    ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐          │
│    │  PROMPT  │────▶│  REVIEW  │────▶│  VERIFY  │────▶│  COMMIT  │──┐       │
│    │          │     │   CODE   │     │  TESTS   │     │          │  │       │
│    └──────────┘     └──────────┘     └──────────┘     └──────────┘  │       │
│         ▲                                                           │       │
│         └───────────────────────────────────────────────────────────┘       │
│                              Next prompt                                    │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Step-by-Step Best Practices

| Step                         | Action                                                                                                                                  | Why It Matters                                                                  |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| **1. One Task Per Prompt**   | Focus each prompt on a single, well-defined task (one page object, one test file, one schema)                                           | Smaller changes are easier to review, test, and revert if needed                |
| **2. Review Generated Code** | Read through the AI-generated code before running it. Check for selector accuracy, proper patterns, and adherence to Constitution rules | Catch issues early before they propagate to dependent code                      |
| **3. Verify Tests Pass**     | Run the generated tests: `npm test` or specific test commands. Ensure they pass consistently                                            | A failing test committed now becomes technical debt later                       |
| **4. Commit Working Code**   | Once verified, commit immediately with a descriptive message                                                                            | Creates a safe checkpoint. Future prompts cannot break what's already committed |
| **5. Proceed to Next Task**  | Only after committing, move to the next prompt                                                                                          | Builds incrementally on verified, working code                                  |

### Why This Workflow?

- **Isolation of Changes**: Each commit represents a verified, working state
- **Easy Rollback**: If a prompt produces broken code, simply `git checkout` to the last working commit
- **Incremental Progress**: Complex features are built step-by-step with verification at each stage
- **AI Context Preservation**: Committed code becomes part of the codebase context for future prompts
- **Reduced Debugging**: Issues are caught immediately, not after multiple layers of changes

### Example Workflow Session

```bash
# Prompt 1: "Create a LoginPage page object for https://app.example.com/login"
# → Review the generated code
# → Run: npm run test:smoke (verify any smoke tests still pass)
# → Commit: git add . && git commit -m "Add LoginPage page object"

# Prompt 2: "Create login tests for valid and invalid credentials"
# → Review the generated tests
# → Run: npx playwright test tests/<area>/functional/<file>.spec.ts (verify tests pass)
# → Commit: git add . && git commit -m "Add login functional tests"

# Prompt 3: "Add password reset flow to LoginPage"
# → Review the additions
# → Run tests
# → Commit: git add . && git commit -m "Add password reset flow"
```

### Recovery from Bad Prompts

If a prompt produces unsatisfactory results, simply discard the changes and try again:

```bash
# Discard all uncommitted changes and continue
git checkout .
```

If you need to go back to a specific commit (e.g., after multiple bad prompts):

```bash
# View commit history to find the commit you want
git log --oneline

# Go back to a specific commit (replace <commit-hash> with actual hash)
git reset --hard <commit-hash>

# Example: go back to the commit before the last 3 commits
git reset --hard HEAD~3
```

This is why **committing after each verified change** is critical. Each commit is a safe checkpoint you can return to at any time.

---

## AI Rules Architecture

One orchestrator, one canonical skill tree, one generated copy, one enforcement layer. It works with **Claude Code**, **Codex**, **Cursor** and **GitHub Copilot**.

### How It Works

- **[`AGENTS.md`](AGENTS.md)** -- always loaded. The Constitution (36 one-line rules), the workflow (proceed, verify, commit) and the Skills Index (17 skills, one read-when line each). Codex, Cursor and Copilot read it natively; Claude Code imports it from `CLAUDE.md`, which adds the Claude-only notes (hooks, protected paths, status line). `npm run check:agents-md` caps it at 100 lines / 800 words and keeps the index equal to the skill directories.
- **`.claude/skills/<name>/SKILL.md`** -- the canonical skills, at most 100 lines each: a Critical block (the rules), a Procedure (the steps) and References (the long material in `references/`, read on demand). Edit skills here only.
- **`.agents/skills/`** -- a byte-for-byte copy generated by `npm run skills:sync`. Codex loads skills from this directory; Cursor and VS Code Copilot read both trees (the same skills, listed twice). `npm run check:skills-sync` fails when it differs from the canonical tree, in content or in file modes.
- **Enforcement** -- the mechanical rules live in the Claude Code hook (write time), in the hook's `--scan` mode (pre-commit and CI, every harness) and in the `pr-reviewer` scan (review time).
- **[`AI-WORKFLOWS.md`](AI-WORKFLOWS.md)** -- the step map for the common tasks, each step citing its owning skill and step.

### Tool Comparison

| Feature              | Claude Code                          | Codex                                 | Cursor                    | GitHub Copilot                                               |
| -------------------- | ------------------------------------ | ------------------------------------- | ------------------------- | ------------------------------------------------------------ |
| Orchestrator         | `CLAUDE.md` imports `AGENTS.md`      | `AGENTS.md`                           | `AGENTS.md`               | `AGENTS.md`                                                  |
| Skills               | `.claude/skills/`                    | `.agents/skills/`                     | both trees                | both trees                                                   |
| Skill activation     | on demand, from the index            | on demand, from the index or `$skill` | on demand, from the index | on demand, from the index                                    |
| Write-time hook      | yes (`PreToolUse`, blocks the write) | no                                    | no                        | no                                                           |
| Scan, pre-commit, CI | yes                                  | yes                                   | yes                       | yes                                                          |
| Review-time scan     | `pr-reviewer` skill                  | `pr-reviewer` skill                   | `pr-reviewer` skill       | `pr-reviewer` skill, `.github/prompts/pr-reviewer.prompt.md` |
| Browser exploration  | `playwright-cli`                     | `playwright-cli` (see the note)       | `playwright-cli`          | `playwright-cli`                                             |

Codex notes: it has no write-time hook, so the scan in pre-commit and CI is its enforcement. On macOS its workspace-write sandbox cannot launch Chromium; run the exploration step with `codex --sandbox danger-full-access` or explore outside Codex first. Without an OpenAI account, `codex exec --oss --local-provider ollama -m gpt-oss:20b` runs the same harness on a local model; start Ollama with `OLLAMA_CONTEXT_LENGTH=131072`.

### Skills Index

The index is the `## Skills Index` section of [`AGENTS.md`](AGENTS.md): one line per skill, name and read-when. It is not repeated here; `npm run check:agents-md` keeps it equal to the directories under `.claude/skills/`.

---

## Architecture Overview

The framework uses a layered fixture composition pattern that provides clean separation of concerns:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         test-options.ts                                 │
│                    (Single Import Point for Tests)                      │
│                                                                         │
│     import { test, expect } from 'fixtures/pom/test-options';           │
└──────────┬──────────────────────┬───────────────────────┬───────────────┘
           │                      │                       │
    mergeTests()           mergeTests()            mergeTests()
           │                      │                       │
┌──────────▼────────────┐  ┌──────▼──────────────┐  ┌────▼──────────────────┐
│ page-object-fixture   │  │ api-request-fixture │  │ helper-fixture.ts     │
│                       │  │                     │  │                       │
│ • appPage: AppPage    │  │ • apiRequest<T>()   │  │ • createdResource     │
│ • resetStorageState() │  │   - Type-safe       │  │ • (your setup/        │
│                       │  │   - Zod validation  │  │    teardown fixtures) │
└──────────┬────────────┘  └──────┬──────────────┘  └──────┬────────────────┘
           │                      │                        │
┌──────────▼───────────┐  ┌────────▼──────────────┐  ┌─────▼─────────────────┐
│    pages/            │  │ fixtures/api/schemas/ │  │ fixtures/api/         │
│                      │  │                       │  │ plain-function.ts     │
│ • AppPage            │  │ • UserResponseSchema  │  │ (internal impl used   │
│ • NavigationComponent│  │ • ErrorResponseSchema │  │  by fixture & helpers)│
│ • (Your Pages)       │  │ • (Your Schemas)      │  └───────────────────────┘
└──────────────────────┘  └───────────────────────┘
```

### Key Architectural Decisions

| Decision                 | Rationale                                                                           |
| ------------------------ | ----------------------------------------------------------------------------------- |
| **Single import point**  | Tests always import from `test-options.ts`, ensuring consistent fixture access      |
| **`apiRequest` fixture** | Primary tool for all API calls in tests -- injected via DI, type-safe with generics |
| **Helper fixtures**      | Important recurring setup/teardown with guaranteed lifecycle (setup/yield/teardown) |
| **Fixture composition**  | `mergeTests()` combines POM, API, and helper fixtures without coupling              |
| **Schema validation**    | Zod schemas provide runtime type safety for API responses                           |
| **Component pattern**    | Reusable UI components (like `NavigationComponent`) can be composed into pages      |

---

## Troubleshooting

### `APP_URL is undefined` or tests navigate to `undefined`

The environment file is missing or not loaded. Ensure `env/.env.dev` exists:

```bash
cp env/.env.example env/.env.dev
```

Then edit it with your application's actual URLs and credentials.

### `browserType.launch: Executable doesn't exist`

Playwright test browsers are not installed. Run:

```bash
npx playwright install
```

If the error is coming from `playwright-cli`, refresh its separate browser cache instead:

```bash
npm run playwright-cli:install-browsers
```

### `playwright-cli: command not found`

The scaffold links CLI tools into `~/.local/bin`. Add it to your shell PATH and re-run the linker:

```bash
export PATH="$HOME/.local/bin:$PATH"
bash scripts/link-cli.sh "$(pwd -P)"
```

### `bash\r: No such file or directory` when running scripts in the container

Shell scripts have Windows-style CRLF line endings. The `\r` is appended to `bash` in the shebang, making the kernel look for an interpreter called `bash\r`. This happens when Git's `core.autocrlf=true` (the Windows default) converts LF to CRLF on checkout, and the files are then bind-mounted into the Linux container.

The `.gitattributes` file prevents this for new clones, but existing working trees need a one-time re-normalization. On the **host** (Windows), run:

```bash
# Delete affected files and let Git re-checkout them with LF endings
rm scripts/*.sh .devcontainer/Dockerfile .devcontainer/post-create.sh
git checkout -- scripts/ .devcontainer/
```

Verify with `git ls-files --eol -- scripts/*.sh` -- all files should show `w/lf`.

### Auth setup fails and all tests are skipped

The setup projects run before the test projects: `setup-api` before `api` and `chromium`, `setup-ui` before `chromium`. If one fails (wrong credentials, app not reachable), every project that depends on it is skipped entirely. Check:

1. Your `APP_URL` and `API_URL` are reachable from your machine
2. Your `APP_EMAIL` and `APP_PASSWORD` are valid credentials
3. The login flow in `helpers/app/createStorageState.ts` matches your app's actual login form

### `Cannot find module '../fixtures/pom/test-options'`

Import paths are relative to the test file location. From `tests/app/functional/`:

```typescript
import { expect, test } from '../../../fixtures/pom/test-options';
```

Count the directory levels carefully. Spec files in `tests/app/api/` and `tests/app/e2e/` use the same relative path.

### ESLint errors after generating code

Run the auto-fixer:

```bash
npm run lint:fix
```

If errors persist, check that the generated code follows the [Core Principles](#core-principles-the-constitution) -- common violations are missing return types, use of `any`, or raw locators.

### Tests pass locally but fail in CI

Common causes:

- **Missing environment variables** -- Ensure CI has all variables from `env/.env.example`
- **Timeouts** -- CI machines may be slower; adjust timeouts in `playwright.config.ts` if needed
- **Browser differences** -- CI typically runs headless; test locally with `npm run test:ci` first to reproduce

## Agentic Playwright Pro

> **Rules are advice. Enforcement is a guarantee.**

The free scaffold tells your AI what good tests look like. **Agentic Playwright Pro** makes it physically unable to ship anything else — a three-layer enforcement engine that checks every line as it's written, plus an automated evaluation suite that continuously proves the rules still work.

|                                                                                          | Free (this repo) | Pro |
| ---------------------------------------------------------------------------------------- | :--------------: | :-: |
| Full Playwright + TypeScript scaffold (page objects, API contracts, factories, fixtures) |        ✅        | ✅  |
| `AGENTS.md` Constitution + 17 AI skills (Claude Code, Codex, Cursor, GitHub Copilot)     |        ✅        | ✅  |
| PR-review skill + exploration-first UI workflow                                          |        ✅        | ✅  |
| Constitution write-time hook (Claude Code) + its commit-time scan (every tool)           |        ✅        | ✅  |
| Skill lint, cross-reference, generated-tree sync and version gates                       |        ✅        | ✅  |
| **Full enforcement hook suite** (Bash write guard, refactor + verification reminders)    |        —         | ✅  |
| **Custom AST lint rules** (`scaffold/*`) for every mechanical Constitution rule          |        —         | ✅  |
| **Enforcement proof** — forbidden fixtures, hook ↔ ESLint parity and canary gates in CI  |        —         | ✅  |
| **Automated skill-evaluation CI** — the rules re-tested continuously                     |        —         | ✅  |
| **Every new release first** + direct access to the author                                |        —         | ✅  |

**[Get Agentic Playwright Pro →](https://buy.polar.sh/polar_cl_FEq10TonCCmFZlivhYDlMetfUowrXjcop8FBi3yGsDC)**

## License

This project is licensed under the MIT License -- see the [LICENSE](LICENSE) file for details.
