#!/usr/bin/env bash
# Install Chromium for @playwright/cli's bundled Playwright into a dedicated cache
# (see scripts/playwright-cli.sh). Safe to run multiple times.
# Skips download when cache already matches the CLI's Playwright version (e.g. after devcontainer rebuild).
set -euo pipefail

WORKSPACE_DIR="${1:-$(pwd -P)}"
NESTED="${WORKSPACE_DIR}/node_modules/@playwright/cli/node_modules/playwright"
HOISTED="${WORKSPACE_DIR}/node_modules/playwright"
CLI_PKG="${WORKSPACE_DIR}/node_modules/@playwright/cli/package.json"
export PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_CLI_BROWSERS_PATH:-${HOME}/.cache/playwright-cli-browsers}"

# Resolve the playwright package that @playwright/cli uses. Prefer the nested
# copy (always correct when present); fall back to the hoisted top-level
# node_modules/playwright IF its version matches what @playwright/cli declares
# as its dependency. This handles npm hoisting introduced when the declared
# version stops conflicting with the workspace's other deps.
CLI_PW=""
if [ -d "${NESTED}" ]; then
  CLI_PW="${NESTED}"
elif [ -d "${HOISTED}" ] && [ -f "${CLI_PKG}" ]; then
  DECLARED=$(node -p "require('${CLI_PKG}').dependencies && require('${CLI_PKG}').dependencies.playwright || ''" 2>/dev/null || echo "")
  HOISTED_V=$(node -p "require('${HOISTED}/package.json').version" 2>/dev/null || echo "")
  if [ -n "${DECLARED}" ] && [ "${DECLARED}" = "${HOISTED_V}" ]; then
    CLI_PW="${HOISTED}"
  fi
fi

if [ -z "${CLI_PW}" ]; then
  echo "Skipping playwright-cli browsers: neither ${NESTED} nor a matching hoisted ${HOISTED} was found (run npm ci first)." >&2
  exit 0
fi

mkdir -p "${PLAYWRIGHT_BROWSERS_PATH}"

CLI_PW_VERSION="$(node -p "require('${CLI_PW}/package.json').version" 2>/dev/null || echo unknown)"
MARKER="${PLAYWRIGHT_BROWSERS_PATH}/.pw-cli-browsers.${CLI_PW_VERSION}"
if [ -f "${MARKER}" ]; then
  echo "playwright-cli browsers already cached for Playwright ${CLI_PW_VERSION} at ${PLAYWRIGHT_BROWSERS_PATH} — skipping download."
  exit 0
fi

echo "Installing Chromium for playwright-cli into ${PLAYWRIGHT_BROWSERS_PATH} ..."
node "${CLI_PW}/cli.js" install chromium
touch "${MARKER}"
