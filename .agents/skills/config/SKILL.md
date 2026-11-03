---
name: config
description: Use when adding an environment variable, a config property, an environment file or a utility-service URL, or when a test, fixture or helper needs APP_URL, API_URL, APP_EMAIL, APP_PASSWORD or UTILITY_URL. Not for endpoint paths and routes (see `enums`) or the `!` versus `??` typing of a read (see `type-safety`).
---

# Configuration

## Critical

- URLs, credentials and other environment-driven values come from `process.env.*`, backed by `env/.env.${ENVIRONMENT}` (default `env/.env.dev`), never from a literal in code.

    ```typescript
    // CORRECT
    baseUrl: process.env.API_URL,
    // WRONG
    baseUrl: 'https://api.example.com',
    ```

- Endpoint paths, routes and storage-state paths are enums (`enums`), never config properties or env vars.
- Every env var the scaffold reads is declared in `env/.env.example` with a safe placeholder (no real domain, token or password); the one exception is `ACCESS_TOKEN`, minted at runtime by the auth setup (`helpers`).
- A config property exists only for a URL or infrastructure setting worth a documented surface: app values in `config/app.ts`, utility services in `config/util/util.ts`, each with a JSDoc line naming its env var; credentials stay env-only.
- Only `env/.env.example` is tracked; a real env file is never committed.
- `ENVIRONMENT` and `CI` are shell variables, never written to an env file.

## Procedure

1. Classify the value: URL or infrastructure setting → env var (plus a config property); credential → env var only; path or message → `enums`; timeout, retries, workers → `playwright.config.ts`.
2. Add the key to `env/.env.example` under its comment group, then to the local `env/.env.<name>` file.
3. For a URL or infrastructure setting, add the property to `config/app.ts` or `config/util/util.ts` with its JSDoc line.
4. Read it where it is used, `!` or `?? fallback` per `type-safety`.
5. Run with `ENVIRONMENT=<name> npx playwright test <file>`; a missing env file loads nothing and leaves every value `undefined`, so confirm the value before blaming the test.

## References

- None. The live instances are `env/.env.example`, `config/app.ts` (`appConfig`), `config/util/util.ts` (`utilityConfig`) and the `dotenv` block at the top of `playwright.config.ts`.
