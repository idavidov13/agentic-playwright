@echo off
setlocal
REM Windows equivalent of scripts/playwright-cli.sh
REM Sets PLAYWRIGHT_BROWSERS_PATH to an isolated cache so @playwright/cli
REM does not clobber the browsers used by @playwright/test.
if defined PLAYWRIGHT_CLI_BROWSERS_PATH (
    set "PLAYWRIGHT_BROWSERS_PATH=%PLAYWRIGHT_CLI_BROWSERS_PATH%"
) else (
    set "PLAYWRIGHT_BROWSERS_PATH=%USERPROFILE%\.cache\playwright-cli-browsers"
)
REM Record that live exploration happened — the Constitution enforcement hook
REM requires a fresh marker before a NEW page object may be created.
REM Only page-interaction/observation commands count as exploration evidence;
REM --version/--help/close/state bookkeeping must NOT arm the gate. The marker
REM is touched AFTER the CLI exits successfully, so a failed exploration does
REM not arm the gate.
set "CMD=%~1"
set "EXPLORE_CMDS= open goto snapshot click dblclick fill type drag hover select upload check uncheck press keydown keyup mousemove mousedown mouseup mousewheel eval run-code screenshot pdf go-back go-forward reload resize tab-list tab-new tab-close tab-select dialog-accept dialog-dismiss console requests request find highlight generate-locator drop "

"%~dp0..\node_modules\.bin\playwright-cli.cmd" %*
set "STATUS=%ERRORLEVEL%"
if not "%STATUS%"=="0" exit /b %STATUS%
if "%CMD%"=="" exit /b 0

REM Delayed expansion is enabled only NOW, after the CLI call: enabled at the
REM top, the parser would eat `!` characters in the arguments passed via %*
REM (fill text, URLs, passwords). !VAR! is still required for the line below —
REM the nested %CMD% inside the substitution needs a second expansion pass
REM (%EXPLORE_CMDS: %CMD% =% mis-parses with plain expansion). setlocal also
REM stops CMD/STRIPPED leaking into the caller's shell between invocations.
setlocal EnableDelayedExpansion
set "STRIPPED=!EXPLORE_CMDS: %CMD% =!"
if not "!STRIPPED!"=="!EXPLORE_CMDS!" (
    if not exist "%~dp0..\.playwright-cli" mkdir "%~dp0..\.playwright-cli" >nul 2>&1
    REM `type nul >>` creates the file; the `copy /b +,,` idiom refreshes the
    REM mtime when it already exists (append-nothing does not touch mtime).
    type nul >> "%~dp0..\.playwright-cli\.last-explored" & copy /b "%~dp0..\.playwright-cli\.last-explored"+,, "%~dp0..\.playwright-cli\.last-explored" >nul 2>&1
)
exit /b 0
