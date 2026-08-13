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

exec "${ROOT}/node_modules/.bin/playwright-cli" "$@"
