# Scaffold Usage — READ FIRST (repo-owned, not upstream)

`SKILL.md` and the other files in `references/` are **vendored upstream
documentation** for the `@playwright/cli` tool (hash-locked via
`skills-lock.json`). They document the tool correctly, but they know nothing
about this scaffold's Constitution — several of their examples violate it.
This file is the scaffold's overlay: it says how the tool is used **here**.

## Role in this scaffold: exploration only

`playwright-cli` is the **mandatory and only sanctioned tool** for live-app
exploration before authoring page objects, selectors, or UI tests
(Constitution MUST: **Explore Before Generate**; WON'T: **No Substitute UI
Exploration**). It is NOT a code generator for this repo.

- Run it via the wrapper on PATH (`playwright-cli`, which resolves to
  `scripts/playwright-cli.sh`). The wrapper records
  `.playwright-cli/.last-explored` — the Constitution enforcement hook
  requires a fresh marker before a **new** page object file can be created.
- If the CLI cannot run, **stop and notify the human**. Never substitute an
  IDE browser, MCP browser tool, or `playwright codegen`.

## Generated code must be rewritten — never committed as-is

The upstream `references/test-generation.md` builds test files with
`import { test, expect } from '@playwright/test'`, hardcoded URLs and
credentials (`"password123"`), inline locators, and hardcoded assertion
strings. **All of that is forbidden in committed scaffold code** (Constitution
MUST: Imports, Sources of Truth; WON'T: No Secrets, No Hardcoded Test
Content). Treat CLI-generated code as raw exploration notes:

1. Selectors → into a page object under `pages/{area}/` (`page-objects` +
   `selectors` skills, priority order enforced).
2. Test flow → into a spec importing from `fixtures/pom/test-options.ts`
   (`test-standards` skill).
3. URLs/credentials → `process.env.*`; UI strings → `enums/{area}/*`;
   content values → factories (`data-strategy` skill).

Likewise, patterns in `references/running-code.md` (`page.waitForSelector`,
CSS `input[name=email]` selectors) are exploration-session conveniences —
never copy them into `pages/**` or `tests/**`.

## Storage state — where files may be written

Upstream examples save auth state to the working directory
(`state-save auth.json`). **In this repo the working directory is the repo
root and `auth.json` is NOT gitignored** — a saved state file contains live
session tokens. Rules:

- Save exploration auth state **only** into `.playwright-cli/` (gitignored):
  `playwright-cli state-save .playwright-cli/exploration-auth.json`
- To explore behind the scaffold's own login, reuse the test suite's storage
  state instead of logging in by hand: run `npx playwright test --project
  setup` once, then `playwright-cli state-load .auth/app/appStorageState.json`
  (the `StorageStatePaths.APP` value; `.auth/` is gitignored).
- Never commit a state file; never save one outside `.playwright-cli/` or
  `.auth/`.

## Session hygiene

- `playwright-cli close` when exploration is done.
- Never commit explore-only artifacts — snapshot dumps, scratch specs, HTML
  dumps (Constitution WON'T: No Explore-Only Files).
