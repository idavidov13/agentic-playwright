# CI replay

For a test that is red in CI and green locally. In CI the config runs one worker with two retries and writes a blob report plus an HTML report (`reporter` in `playwright.config.ts`); the CI workflow must upload `playwright-report/` (and the blob report when sharded) as artifacts for this recipe to work.

1. Download the artifacts of the failed run: `gh run download <run-id> -n playwright-report` (sharded runs: download the blob report and run `npx playwright merge-reports --reporter html <blob-dir>`).
2. Open the failed trace, GUI or CLI (the tool table in the Procedure, step 4); trace zips live under `data/` inside the report. With two CI retries the trace is from the first retry, so the first attempt's failure may differ from the retried one; read both results in the report.
3. Compare the environments:
    - env file: CI sets `ENVIRONMENT` or injects shell variables; `ls env/` shows which files exist (the scaffold ships `.env.dev` and `.env.example` only; a missing file loads nothing and every `process.env.*` is `undefined`).
    - storage state and token: did `setup-ui` write `.auth/app/appStorageState.json` and `setup-api` write `.auth/app/apiAccessToken.json`?
    - viewport and browser: the `chromium` project is `1920x1080` Desktop Chrome; CI installs the browser `@playwright/test` pins.
    - timing: a cold app container (first `page.goto` refused for seconds) is a CI-only cause; the fix is a readiness check in `auth.setup.ts`, never a longer `navigationTimeout`.
4. Replay with CI conditions:

    ```bash
    CI=1 npx playwright test <file> --workers=1 --retries=0
    # only when env/.env.<name> exists:
    ENVIRONMENT=<name> CI=1 npx playwright test <file> --workers=1 --retries=0
    ```

5. Still green: the cause is environment-driven (network, timing, state). Add temporary instrumentation (`console.log`, a screenshot, `--trace on`), push, read the new artifacts, then remove the instrumentation before merging.
