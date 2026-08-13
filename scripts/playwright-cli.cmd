@echo off
REM Windows equivalent of scripts/playwright-cli.sh
REM Sets PLAYWRIGHT_BROWSERS_PATH to an isolated cache so @playwright/cli
REM does not clobber the browsers used by @playwright/test.
if defined PLAYWRIGHT_CLI_BROWSERS_PATH (
    set "PLAYWRIGHT_BROWSERS_PATH=%PLAYWRIGHT_CLI_BROWSERS_PATH%"
) else (
    set "PLAYWRIGHT_BROWSERS_PATH=%USERPROFILE%\.cache\playwright-cli-browsers"
)
"%~dp0..\node_modules\.bin\playwright-cli.cmd" %*
