# Tools

One tool per investigation. Artifacts land in `test-results/<test-id>/` (trace.zip, test-failed-1.png, video.webm) and `playwright-report/`; the capture policy and the timeouts live in `playwright.config.ts`.

| Situation                                                                                      | Tool                                    | Command                                                            |
| ---------------------------------------------------------------------------------------------- | --------------------------------------- | ------------------------------------------------------------------ |
| Reproducible locally, iterating on a locator or a step                                         | UI Mode                                 | `npm run test:ui`                                                  |
| A trace file exists (CI artifact, or a run with `--trace on`) and a desktop browser is at hand | Trace Viewer (GUI)                      | `npx playwright show-trace <path/to/trace.zip>`                    |
| A trace file exists, no display (CI agent, SSH, container)                                     | Trace inspector (CLI, Playwright 1.59+) | `npx playwright trace open <path/to/trace.zip>`                    |
| Stepping through test or page-object logic line by line                                        | Inspector                               | `npm run test:debug` (`F10` steps; a `debugger;` statement breaks) |
| Stepping without a GUI (agent-driven)                                                          | CLI debugger (Playwright 1.59+)         | `npx playwright test <file> --debug=cli`                           |
| Watching an animation, a tooltip or an async race                                              | Headed run                              | `npm run test:headed`                                              |
| Screenshots, videos, error stacks of the last run                                              | HTML report                             | `npm run report`                                                   |

## UI Mode

- Click the failing test to replay it; the timeline shows the DOM snapshot at every action.
- **Pick locator** tests a candidate selector against the live DOM.
- Watch mode re-runs on save.
- The **Network** tab shows every request with status and body; it answers most `ZodError` questions.
- It keeps a hot browser context; close it between sessions. For a pure post-mortem, open the trace instead.

## Trace Viewer (GUI)

Action panel with arguments and outcome, DOM snapshots before, during and after each action, console and network at that moment, the source with the failed line. When the HTML report opened on failure, the trace is linked from the failed test card.

## Trace inspector (CLI)

```bash
npx playwright trace open path/to/trace.zip
npx playwright trace actions              # --grep "expect" narrows
npx playwright trace action 9
npx playwright trace snapshot 9 --name before   # or --name after
npx playwright trace requests
npx playwright trace console
npx playwright trace errors
npx playwright trace screenshot 9
npx playwright trace close
```

Same data as the GUI viewer, addressable from a terminal.

## CLI debugger

`npx playwright test <file> --debug=cli` pauses and prints a `playwright-cli attach <session-id>` instruction; drive it with `playwright-cli --session=<id> step-over` and `playwright-cli --session=<id> snapshot` (the `playwright-cli` skill covers the executable). `npm run test:debug` keeps the GUI Inspector.

## Deterministic local run

```bash
npx playwright test <file> --trace on --workers=1 --retries=0 --headed
```

Everything captured, one worker, no retry, visible browser.

## Pitfalls

- **No trace after a failure.** Local `retries: 0` means `on-first-retry` never fires; add `--trace on` or use UI Mode.
- **Stale report.** `npm run report` shows the last run; re-run the failing test first.
- **Other browsers.** Only `chromium` is active; the `firefox` and `webkit` project blocks in `playwright.config.ts` are commented out. Enable one for the investigation (`--project=firefox`), then comment it out again; enabling it in CI is a team decision.
