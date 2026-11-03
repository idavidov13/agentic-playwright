# Auth bootstrap

How the scaffold signs in once per run and hands the result to every worker. The live files are `tests/app/auth-api.setup.ts` (the `setup-api` project: the token, no browser), `tests/app/auth.setup.ts` (the `setup-ui` project: the browser storage state) and `helpers/app/createStorageState.ts`. In `playwright.config.ts` the `api` project depends on `setup-api` only, so API runs never launch a browser; `chromium` depends on both.

## The chain

1. `createAppStorageState()` opens a browser, signs in through the page object with `process.env.APP_EMAIL` / `APP_PASSWORD`, and writes cookies and web storage to `StorageStatePaths.APP`; the `chromium` project loads that file, so UI tests start signed in.
2. `setUserAccessToken(apiRequest)` posts the same credentials to `ApiEndpoints.LOGIN`, asserts `UserResponseSchema`, writes the validated body to `StorageStatePaths.API_ACCESS_TOKEN`, and sets `process.env.ACCESS_TOKEN` for the setup worker.
3. `loadUserAccessToken()` reads that file into `process.env.ACCESS_TOKEN`; a worker-scoped auto fixture in `fixtures/api/api-request-fixture.ts` calls it once per worker before any test, so `headers: process.env.ACCESS_TOKEN` works in every project.

A `process.env` write is visible only inside the process that made it, which is why the token crosses the worker boundary as a file and not as an env var.

## Adapting it to another app

Replace the sign-in steps inside the two mint functions; keep the file paths in `StorageStatePaths`, the credentials in `process.env.*` and the schema assertion. A second role (the 403 row of the API coverage matrix) is a second credential pair declared in `env/.env.example` and a second token file, minted the same way; never read an env var no helper populates.

## `process.env.ACCESS_TOKEN` is `undefined` in a test

- The `setup-api` project did not run: the spec's project lost `setup-api` in its `dependencies`, or the run filtered it out.
- The token file is missing or stale: delete `.auth/app/apiAccessToken.json` and re-run; the setup writes it fresh every run.
- The login response changed shape: `UserResponseSchema.parse` fails inside the setup, so the setup test is red before any API test runs.
