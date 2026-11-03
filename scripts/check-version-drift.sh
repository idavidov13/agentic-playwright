#!/usr/bin/env bash
# check-version-drift.sh
#
# Asserts the product version is consistent across its four surfaces:
#   1. VERSION            -- the single source of truth
#   2. package.json       -- "version" field (stamped by stamp-version.sh)
#   3. package-lock.json  -- the two root "version" fields (top level and
#                            packages[""]; also stamped by stamp-version.sh).
#                            npm rewrites them on every install, so a stale
#                            lock means a dirty tree after `npm install`.
#   4. CHANGELOG.md       -- the latest "## v<x.y.z>" heading
#
# Exits non-zero on any mismatch so it can gate CI / the pre-commit hook.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="${REPO_ROOT}/VERSION"
PKG_FILE="${REPO_ROOT}/package.json"
LOCK_FILE="${REPO_ROOT}/package-lock.json"
CHANGELOG="${REPO_ROOT}/CHANGELOG.md"

fail() { echo "ERROR: $1" >&2; exit 1; }

[[ -f "${VERSION_FILE}" ]] || fail "VERSION file not found at ${VERSION_FILE}"
[[ -f "${PKG_FILE}" ]] || fail "package.json not found at ${PKG_FILE}"
[[ -f "${LOCK_FILE}" ]] || fail "package-lock.json not found at ${LOCK_FILE}"
[[ -f "${CHANGELOG}" ]] || fail "CHANGELOG.md not found at ${CHANGELOG}"

SEMVER='^[0-9]+\.[0-9]+\.[0-9]+$'

VERSION_VAL="$(tr -d '[:space:]' < "${VERSION_FILE}")"
[[ "${VERSION_VAL}" =~ ${SEMVER} ]] || fail "VERSION content '${VERSION_VAL}' is not valid x.y.z semver."

# package.json version field (first top-level occurrence).
PKG_VAL="$(grep -m1 -E '^[[:space:]]*"version":' "${PKG_FILE}" \
    | sed -E 's/.*"version":[[:space:]]*"([^"]*)".*/\1/')"

# package-lock.json root version: the first two "version" fields of a
# lockfileVersion 3 file are the top-level entry and packages[""]; dependency
# entries only start after them. Both must equal VERSION.
LOCK_VALS="$(grep -m2 -E '^[[:space:]]*"version":' "${LOCK_FILE}" \
    | sed -E 's/.*"version":[[:space:]]*"([^"]*)".*/\1/' | sort -u | paste -sd ' ' -)"

# Latest CHANGELOG heading: first line like "## v2.4.0 -- ...".
CHG_VAL="$(grep -m1 -E '^## v?[0-9]+\.[0-9]+\.[0-9]+' "${CHANGELOG}" \
    | sed -E 's/^## v?([0-9]+\.[0-9]+\.[0-9]+).*/\1/')"

echo "VERSION          : ${VERSION_VAL}"
echo "package.json     : ${PKG_VAL}"
echo "package-lock.json: ${LOCK_VALS}"
echo "CHANGELOG top    : ${CHG_VAL}"
echo

errors=0
if [[ "${PKG_VAL}" != "${VERSION_VAL}" ]]; then
    echo "DRIFT package.json version '${PKG_VAL}' != VERSION '${VERSION_VAL}'. Run: npm run version:stamp"
    errors=$((errors + 1))
fi
if [[ "${LOCK_VALS}" != "${VERSION_VAL}" ]]; then
    echo "DRIFT package-lock.json root version '${LOCK_VALS}' != VERSION '${VERSION_VAL}'. Run: npm run version:stamp"
    errors=$((errors + 1))
fi
if [[ "${CHG_VAL}" != "${VERSION_VAL}" ]]; then
    echo "DRIFT latest CHANGELOG heading '${CHG_VAL}' != VERSION '${VERSION_VAL}'. Add a '## v${VERSION_VAL}' entry (or fix VERSION)."
    errors=$((errors + 1))
fi

if [[ "${errors}" -eq 0 ]]; then
    echo "OK    version consistent across VERSION, package.json, package-lock.json, CHANGELOG."
fi
[[ "${errors}" -eq 0 ]] || exit 1
