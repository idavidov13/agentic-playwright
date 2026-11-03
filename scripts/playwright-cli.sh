#!/usr/bin/env bash
# Run @playwright/cli with its own browser cache so we do not clobber
# PLAYWRIGHT_BROWSERS_PATH=/ms-playwright (used by @playwright/test in the dev container).
# @playwright/cli depends on a different Playwright version than the scaffold.
set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]}"
while [ -L "$SCRIPT_PATH" ]; do
  SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
done
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

export PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_CLI_BROWSERS_PATH:-${HOME}/.cache/playwright-cli-browsers}"

# Record that live exploration happened. The Constitution enforcement hook
# (.claude/scripts/enforce_constitution.py) requires a fresh marker before a
# NEW page object may be created (Explore Before Generate).
# Only commands that actually interact with / observe a live page count as
# exploration evidence — `--version`, `--help`, `close`, state/cookie
# bookkeeping etc. must NOT arm the gate. The marker is touched AFTER the CLI
# exits successfully, so a failed exploration (bad URL, auth failure, missing
# browser) does not arm the gate.
EXPLORE_CMDS=" open goto snapshot click dblclick fill type drag hover select upload check uncheck press keydown keyup mousemove mousedown mouseup mousewheel eval run-code screenshot pdf go-back go-forward reload resize tab-list tab-new tab-close tab-select dialog-accept dialog-dismiss console requests request find highlight generate-locator drop "
CMD="${1:-}"

STATUS=0
"${ROOT}/node_modules/.bin/playwright-cli" "$@" || STATUS=$?

# The literal quoting of ${CMD} inside the pattern matters: unquoted, glob
# metacharacters in the first argument (`*`, `?`, `[`) would match the list
# and forge the marker for a non-explore invocation.
if [ "$STATUS" -eq 0 ] && [ -n "$CMD" ] \
    && [ "${EXPLORE_CMDS#* "${CMD}" }" != "$EXPLORE_CMDS" ]; then
    mkdir -p "${ROOT}/.playwright-cli" 2>/dev/null || true
    touch "${ROOT}/.playwright-cli/.last-explored" 2>/dev/null || true
fi

exit "$STATUS"
