#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${1:-$(pwd -P)}"
USER_BIN_DIR="${HOME}/.local/bin"
PLAYWRIGHT_SOURCE="${WORKSPACE_DIR}/node_modules/.bin/playwright"
PLAYWRIGHT_CLI_SOURCE="${WORKSPACE_DIR}/node_modules/.bin/playwright-cli"
PLAYWRIGHT_CLI_WRAPPER="${WORKSPACE_DIR}/scripts/playwright-cli.sh"

mkdir -p "${USER_BIN_DIR}"

link_binary() {
    local source_path="$1"
    local target_path="$2"

    if [ ! -x "${source_path}" ]; then
        echo "Missing executable: ${source_path}" >&2
        return 1
    fi

    ln -sfn "${source_path}" "${target_path}"
}

if [ -x "${PLAYWRIGHT_SOURCE}" ]; then
    link_binary "${PLAYWRIGHT_SOURCE}" "${USER_BIN_DIR}/playwright"
    echo "Linked playwright -> ${PLAYWRIGHT_SOURCE}"
else
    echo "Skipping playwright link; install npm dependencies first." >&2
fi

if [ -f "${PLAYWRIGHT_CLI_WRAPPER}" ] && [ -x "${PLAYWRIGHT_CLI_SOURCE}" ]; then
    # Wrapper may be root-owned on bind-mounted workspaces; skip chmod if already executable
    if [ ! -x "${PLAYWRIGHT_CLI_WRAPPER}" ]; then
        chmod +x "${PLAYWRIGHT_CLI_WRAPPER}" 2>/dev/null || true
    fi
    link_binary "${PLAYWRIGHT_CLI_WRAPPER}" "${USER_BIN_DIR}/playwright-cli"
    echo "Linked playwright-cli -> ${PLAYWRIGHT_CLI_WRAPPER} (isolated PLAYWRIGHT_BROWSERS_PATH for CLI)"
elif [ -x "${PLAYWRIGHT_CLI_SOURCE}" ]; then
    link_binary "${PLAYWRIGHT_CLI_SOURCE}" "${USER_BIN_DIR}/playwright-cli"
    echo "Linked playwright-cli -> ${PLAYWRIGHT_CLI_SOURCE}"
else
    echo "Skipping playwright-cli link; install @playwright/cli (npm ci) first." >&2
fi

