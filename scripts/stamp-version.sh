#!/usr/bin/env bash
# stamp-version.sh
#
# Single-source version stamper. The repo VERSION file is the one source of
# truth for the product version. This script writes that value into
# package.json's "version" field so the two never drift.
#
# Usage:
#   bash scripts/stamp-version.sh            # stamp VERSION -> package.json
#   bash scripts/stamp-version.sh <x.y.z>    # set VERSION to x.y.z, then stamp
#
# After stamping, add the matching `## v<x.y.z>` heading to CHANGELOG.md so
# `check-version-drift.sh` passes (it asserts VERSION == package.json == the
# latest CHANGELOG heading).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="${REPO_ROOT}/VERSION"
PKG_FILE="${REPO_ROOT}/package.json"

SEMVER='^[0-9]+\.[0-9]+\.[0-9]+$'

# Optional arg: set the VERSION file first.
if [[ $# -ge 1 ]]; then
    if [[ ! "$1" =~ ${SEMVER} ]]; then
        echo "ERROR: '$1' is not a valid x.y.z semver." >&2
        exit 2
    fi
    printf '%s\n' "$1" > "${VERSION_FILE}"
fi

if [[ ! -f "${VERSION_FILE}" ]]; then
    echo "ERROR: VERSION file not found at ${VERSION_FILE}" >&2
    exit 2
fi

VER="$(tr -d '[:space:]' < "${VERSION_FILE}")"
if [[ ! "${VER}" =~ ${SEMVER} ]]; then
    echo "ERROR: VERSION file content '${VER}' is not a valid x.y.z semver." >&2
    exit 2
fi

if [[ ! -f "${PKG_FILE}" ]]; then
    echo "ERROR: package.json not found at ${PKG_FILE}" >&2
    exit 2
fi

# Replace only the first top-level "version" field, preserving the 4-space
# indentation and surrounding formatting (avoids a JSON reflow diff).
tmp="$(mktemp)"
awk -v ver="${VER}" '
    !done && /^[[:space:]]*"version":[[:space:]]*"[^"]*",?[[:space:]]*$/ {
        sub(/"version":[[:space:]]*"[^"]*"/, "\"version\": \"" ver "\"")
        done = 1
    }
    { print }
' "${PKG_FILE}" > "${tmp}"

if ! grep -q "\"version\": \"${VER}\"" "${tmp}"; then
    rm -f "${tmp}"
    echo "ERROR: failed to stamp version into package.json (no version field matched)." >&2
    exit 2
fi

mv "${tmp}" "${PKG_FILE}"
echo "Stamped version ${VER} into package.json."
