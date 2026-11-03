#!/usr/bin/env bash
# stamp-version.sh
#
# Single-source version stamper. The repo VERSION file is the one source of
# truth for the product version. This script writes that value into
# package.json's "version" field and into package-lock.json's two root
# "version" fields so none of them drift.
#
# Usage:
#   bash scripts/stamp-version.sh            # stamp VERSION -> package.json + lock
#   bash scripts/stamp-version.sh <x.y.z>    # set VERSION to x.y.z, then stamp
#
# After stamping, add the matching `## v<x.y.z>` heading to CHANGELOG.md so
# `check-version-drift.sh` passes (it asserts VERSION == package.json ==
# package-lock.json root == the latest CHANGELOG heading).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="${REPO_ROOT}/VERSION"
PKG_FILE="${REPO_ROOT}/package.json"
LOCK_FILE="${REPO_ROOT}/package-lock.json"

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

# package-lock.json carries the root version twice: at the top level and in
# packages[""]. npm rewrites both on every install, so a lock left at an old
# version turns every `npm install` into a dirty tree (this shipped once: the
# 2.5.0 lock still said 1.0.0). In a lockfileVersion 3 file the first two
# "version" fields are exactly those root entries — dependency versions come
# later under packages["node_modules/..."] — so stamp the first two and leave
# the rest untouched, preserving the file's formatting.
if [[ -f "${LOCK_FILE}" ]]; then
    tmp="$(mktemp)"
    awk -v ver="${VER}" '
        stamped < 2 && /^[[:space:]]*"version":[[:space:]]*"[^"]*",?[[:space:]]*$/ {
            sub(/"version":[[:space:]]*"[^"]*"/, "\"version\": \"" ver "\"")
            stamped++
        }
        { print }
    ' "${LOCK_FILE}" > "${tmp}"

    stamped_count="$(grep -m2 -E '^[[:space:]]*"version":' "${tmp}" \
        | grep -c "\"version\": \"${VER}\"" || true)"
    if [[ "${stamped_count}" -ne 2 ]]; then
        rm -f "${tmp}"
        echo "ERROR: failed to stamp version into package-lock.json (expected two root version fields)." >&2
        exit 2
    fi

    mv "${tmp}" "${LOCK_FILE}"
    echo "Stamped version ${VER} into package-lock.json (root + packages[\"\"])."
fi
