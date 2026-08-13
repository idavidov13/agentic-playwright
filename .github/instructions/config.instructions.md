---
applyTo: 'config/**/*.ts'
---

# Configuration

## Critical

- **NEVER** hardcode URLs, tokens, emails, or passwords anywhere in the scaffold. The only source of truth for env-driven values is `process.env.*`, backed by `env/.env.${environment}`.
- **NEVER** hardcode endpoint paths or route strings in `config/`. Paths belong in `enums/{area}/*` (see the `enums` skill).
- **ALWAYS** add every new env variable to `env/.env.example` with a safe placeholder — no real secrets, no production URLs.
- **ALWAYS** add a JSDoc comment on every config property describing the value and the backing env var.
- **ALWAYS** keep app-facing URLs/settings in `config/app.ts` and utility/third-party services in `config/util/util.ts`. Do not create ad-hoc config files elsewhere.
- **NEVER** commit `env/.env.dev`, `env/.env.staging`, or any other real env file containing credentials. Only `env/.env.example` is tracked.

## File Locations

| Type           | Directory                 | Purpose                                                        |
| -------------- | ------------------------- | -------------------------------------------------------------- |
| App config     | `config/app.ts`           | URLs and settings for the main application                     |
| Utility config | `config/util/util.ts`     | Utility / third-party service configuration                    |
| Env template   | `env/.env.example`        | Tracked template — safe placeholders only                      |
| Env (active)   | `env/.env.${ENVIRONMENT}` | Real values, selected at runtime (`.env.dev` etc.) — untracked |

## Instructions

### Phase 1: Understand how env files are loaded

`playwright.config.ts` loads env values via `dotenv` at startup:

```typescript
const environment = process.env.ENVIRONMENT ?? 'dev';
const environmentPath = `./env/.env.${environment}`;
dotenv.config({ path: environmentPath });
```

Consequences:

- Default environment is `dev` (file `env/.env.dev`).
- Override with a shell variable: `ENVIRONMENT=staging npx playwright test`.
- The selected file must exist — missing files silently load nothing and every `process.env.*` becomes `undefined`.
- `ENVIRONMENT` itself is set at the **shell** level; it is not declared in any `.env` file.

### Phase 2: Decide where the new value belongs

Use this decision table before adding anything:

| Value kind                                                 | Home                                                                        |
| ---------------------------------------------------------- | --------------------------------------------------------------------------- |
| URL of the main app under test                             | env var + `config/app.ts` (`appConfig.appUrl`, `apiUrl`)                    |
| URL of a utility / third-party service                     | env var + `config/util/util.ts` (`utilityConfig.*`)                         |
| Credential (email, password, API key, token seed)          | env var only — **do not** expose through a config object                    |
| Endpoint path (e.g. `/api/users`) or route (e.g. `/login`) | `enums/{area}/*` — **not** `config/` and **not** an env var                 |
| Storage-state file path                                    | `enums/{area}/*` (e.g. `StorageStatePaths`) — **not** `config/`             |
| Timeout / retry / workers tuning                           | `playwright.config.ts` — **not** `config/` unless reused outside Playwright |
| Runtime selector (`ENVIRONMENT`, `CI`)                     | Shell-level env var only — **not** `.env.example`                           |

If the value fits none of the rows above, stop and ask — do not invent a new config file.

### Phase 3: Add the env var to `env/.env.example`

Every env var the scaffold relies on must appear in the tracked template with a **safe placeholder**:

```
APP_URL=https://your-app-url.com
API_URL=https://your-api-url.com
APP_EMAIL=your-email@example.com
APP_PASSWORD=your-secure-password
UTILITY_URL=https://your-utility-service.com
```

Rules for the placeholder:

- No real domains, no real tokens, no real passwords.
- Same key name as the eventual `process.env.*` lookup (exact case).
- Group related variables under a short comment header (see existing groupings).

Then add the real value to your active env file (`env/.env.dev` or similar) — this file is untracked.

### Phase 4: Add the config property (only if warranted) with JSDoc

Not every env var gets a config-object slot. Credentials (`APP_EMAIL`, `APP_PASSWORD`, tokens) stay env-only. URLs and infra settings that the scaffold wants to document **do** go into a config object.

**`config/app.ts`** — app-facing URLs and settings:

```typescript
/**
 * Application configuration object.
 * Contains URL configuration for the main application.
 *
 * For route paths and API endpoints, use enums from `enums/app/app.ts`.
 */
export const appConfig = {
    /** Frontend application URL loaded from APP_URL env variable */
    appUrl: process.env.APP_URL,
    /** Backend API URL loaded from API_URL env variable */
    apiUrl: process.env.API_URL,
};
```

**`config/util/util.ts`** — utility / third-party services:

```typescript
/**
 * Utility service configuration object.
 * Contains URL configuration for utility/helper services.
 *
 * For API endpoints, use enums from `enums/` folder.
 */
export const utilityConfig = {
    /** Utility service base URL */
    baseUrl: process.env.UTILITY_URL,
};
```

Every property requires a JSDoc comment naming the backing env var.

### Phase 5: Consume the value from tests, fixtures, and helpers

Two equally valid access patterns exist in the scaffold today:

1. **Direct `process.env.*` access** — the dominant pattern in tests, fixtures, and helpers:

    ```typescript
    baseUrl: process.env.API_URL,
    headers: process.env.ACCESS_TOKEN,
    body: { email: process.env.APP_EMAIL, password: process.env.APP_PASSWORD },
    ```

2. **Config-object access** — used when you want to import a documented, organized surface:

    ```typescript
    import { appConfig } from '../../config/app';

    await page.goto(appConfig.appUrl!);
    ```

Pick whichever fits the call site; do not mix them inside a single file without reason. For how to satisfy the TypeScript `string | undefined` that `process.env.*` returns — non-null assertion (`!`) vs fallback default — see the `type-safety` skill.

## Examples

### Example 1: Add a new staging environment

User says: _"Add a staging environment pointing at the staging cluster."_

Actions:

1. **Phase 1** — Confirm `playwright.config.ts` already honors `ENVIRONMENT`; no code change needed.
2. Create `env/.env.staging` **locally** (untracked) with the real staging URLs/credentials, using the same keys as `env/.env.example`.
3. Run `ENVIRONMENT=staging npx playwright test` to verify the file loads.
4. **Do not** modify `env/.env.example` (the key names haven't changed) and **do not** commit `.env.staging`.

### Example 2: Add a new utility-service URL

User says: _"Wire up the reporting service URL so helpers can post run results."_

Actions:

1. **Phase 2** — It's a utility-service URL → belongs in `config/util/util.ts` as a property of `utilityConfig`; env var `REPORTING_URL`.
2. **Phase 3** — Add to `env/.env.example`:

    ```
    # Optional: Additional service URLs
    UTILITY_URL=https://your-utility-service.com
    REPORTING_URL=https://your-reporting-service.com
    ```

3. **Phase 4** — Extend `config/util/util.ts`:

    ```typescript
    export const utilityConfig = {
        /** Utility service base URL */
        baseUrl: process.env.UTILITY_URL,
        /** Reporting service base URL loaded from REPORTING_URL env variable */
        reportingUrl: process.env.REPORTING_URL,
    };
    ```

4. **Phase 5** — Import `utilityConfig.reportingUrl` in the helper that posts results; follow the `type-safety` skill for `!` vs fallback handling.

## Troubleshooting

**`process.env.X` is `undefined` at runtime.**
Cause: The key is missing from the active env file, or the active env file doesn't exist.
Fix: Confirm the key exists in `env/.env.${ENVIRONMENT}` (default `env/.env.dev`). If you renamed or added a key, also update `env/.env.example`.

**Wrong environment is being loaded.**
Cause: `ENVIRONMENT` is unset, misspelled, or points at a missing file.
Fix: `playwright.config.ts` defaults to `dev`. Set `ENVIRONMENT=staging` in the shell (not in an `.env` file) before running tests; confirm `env/.env.staging` exists.

**I can't find `ACCESS_TOKEN` / `ACCESS_TOKEN_ZERO` in `env/.env.example`.**
Cause: These tokens are populated dynamically by an auth-bootstrap helper, not committed.
Fix: In the scaffold's demo setup, an auth-bootstrap helper under `helpers/{area}/` logs in and writes the token into `process.env.ACCESS_TOKEN` before the main suite runs. Do not add the token to `env/.env.example`. See the `helpers` skill (Phase 6) for the pattern.

**TypeScript complains that `process.env.X` is `string | undefined`.**
Cause: `process.env` values are always optional types in Node.
Fix: See the `type-safety` skill for the two sanctioned patterns (non-null assertion with `!` for values guaranteed to exist at runtime; fallback default with `??` otherwise).

**I want to put an endpoint path in a config file.**
Cause: Wrong skill. Paths are source-controlled constants, not environment-driven settings.
Fix: Add the path to `enums/{area}/*` (see the `enums` skill). `config/` is only for URLs, credentials, and infra settings.

**My new config property has no JSDoc and the PR review is blocking.**
Fix: Every config property requires a JSDoc comment naming the backing env var, e.g. `/** Reporting service base URL loaded from REPORTING_URL env variable */`.

**I accidentally committed `env/.env.dev`.**
Fix: Remove the file from the commit (`git rm --cached env/.env.dev`), verify it's covered by `.gitignore`, rotate any credentials that were exposed, and push the fix.

## See Also

- **`enums` skill** — endpoint paths, route constants, and storage-state paths live there, not in `config/`.
- **`type-safety` skill** — handling `string | undefined` returned by `process.env.*` (`!` vs fallback defaults).
- **`api-testing` skill** — which env vars tests consume (`API_URL`, `ACCESS_TOKEN`, `ACCESS_TOKEN_ZERO`, `APP_EMAIL`, `APP_PASSWORD`) and how.
- **`debugging` skill** — when `process.env.X` is `undefined` at runtime, when a CI run reads different env values than local, or when a navigation times out because `APP_URL` is wrong.
