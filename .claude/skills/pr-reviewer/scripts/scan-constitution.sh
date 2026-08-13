#!/usr/bin/env bash
# scan-constitution.sh — deterministic half of the Constitution checklist.
#
# Greps the changed files for the mechanically-detectable violations so the
# reviewer doesn't have to eyeball them (and can't miss one). Judgment items
# (coverage gaps, sibling divergence, schema-vs-contract fidelity) are NOT here
# — those stay with the model. Every check maps to a row in
# references/constitution-checklist.md by its [#].
#
# Usage:
#   scan-constitution.sh [base]          # base defaults to master; diffs base...HEAD
#   scan-constitution.sh --files a.ts b.ts
#
# Exit code: 0 = no mechanical violations, 1 = at least one FAIL.

set -uo pipefail

BASE="master"
FILES=""

if [[ "${1:-}" == "--files" ]]; then
    shift
    FILES="$*"
else
    [[ -n "${1:-}" ]] && BASE="$1"
    FILES="$(git diff "${BASE}...HEAD" --name-only --diff-filter=d)"
fi

if [[ -z "${FILES// }" ]]; then
    echo "No changed files to scan."
    exit 0
fi

# Partition the changed paths.
TS_FILES=()
SPEC_FILES=()
STATIC_JSON=()
PAGE_FILES=()
while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    [[ ! -f "$f" ]] && continue
    case "$f" in
        *.spec.ts) SPEC_FILES+=("$f"); TS_FILES+=("$f") ;;
        *.ts)      TS_FILES+=("$f") ;;
    esac
    case "$f" in
        test-data/static/*.json) STATIC_JSON+=("$f") ;;
        pages/*.ts) PAGE_FILES+=("$f") ;;
    esac
done <<< "$FILES"

FAIL=0
# report TIER "[#] rule" hits -- hard rule: hits => ❌ and sets FAIL.
report() {
    local tier="$1" rule="$2"; shift 2
    local hits="$*"
    if [[ -n "${hits// }" ]]; then
        echo "❌ ${tier} ${rule}"
        echo "${hits}" | sed 's/^/      /'
        FAIL=1
    else
        echo "✅ ${tier} ${rule}"
    fi
}

# soft_report -- needs-human-judgment signals (🟡). Prints hits but does NOT
# set FAIL, so the exit code reflects only hard violations.
soft_report() {
    local tier="$1" rule="$2"; shift 2
    local hits="$*"
    if [[ -n "${hits// }" ]]; then
        echo "❓ ${tier} ${rule} — review:"
        echo "${hits}" | sed 's/^/      /'
    else
        echo "✅ ${tier} ${rule}"
    fi
}

# grep helper: fixed-list of files, quiet on no-match, prints file:line:match
g() {
    local pattern="$1"; shift
    local files=() f
    for f in "$@"; do [[ -n "$f" ]] && files+=("$f"); done
    [[ ${#files[@]} -eq 0 ]] && return 0
    grep -nE "$pattern" "${files[@]}" 2>/dev/null
}

echo "=== Constitution scan (mechanical) — base ${BASE} ==="
echo

# [3] no `any`
report "🔴" "[3] no 'any' type" \
    "$(g ':\s*any\b|<any>|as any|Array<any>|: any\[\]' "${TS_FILES[@]:-}")"

# [4] strict schemas — z.object( is forbidden in schema files
report "🔴" "[4] z.strictObject (no z.object)" \
    "$(g '\bz\.object\(' "${TS_FILES[@]:-}")"

# [20] no hard waits
report "🔴" "[20] no waitForTimeout / hard waits" \
    "$(g 'waitForTimeout' "${TS_FILES[@]:-}")"

# [16] no XPath
report "🔴" "[16] no XPath selectors" \
    "$(g "xpath=|locator\(['\"]//|locator\(['\"]\.\.//" "${TS_FILES[@]:-}")"

# [1] spec files must import the test/expect FIXTURES from test-options, not
# @playwright/test. Type-only imports (Locator, Page, APIResponse, ...) from
# @playwright/test are fine — only flag when `test` or `expect` is pulled from it.
report "🔴" "[1] specs import test/expect from test-options, not @playwright/test" \
    "$(g "import\s*\{[^}]*\b(test|expect)\b[^}]*\}\s*from\s*['\"]@playwright/test['\"]" "${SPEC_FILES[@]:-}")"
# Informational: any other @playwright/test import in a spec (usually a type) —
# allowed, but listed so the reviewer can sanity-check it's type-only.
OTHER_PW_IMPORT="$(g "from ['\"]@playwright/test['\"]" "${SPEC_FILES[@]:-}" | grep -vE '\b(test|expect)\b' || true)"
[[ -n "${OTHER_PW_IMPORT// }" ]] && { echo "ℹ️  [1] other @playwright/test imports in specs (ok if type-only):"; echo "${OTHER_PW_IMPORT}" | sed 's/^/      /'; }

# [2] no manual page-object instantiation in specs
report "🔴" "[2] no 'new XxxPage()/XxxComponent()' in specs" \
    "$(g 'new [A-Z][A-Za-z0-9_]*(Page|Component)\s*\(' "${SPEC_FILES[@]:-}")"

# [25] forbidden @functional tag, and tags on describe
report "🔴" "[25] no @functional tag" \
    "$(g '@functional' "${TS_FILES[@]:-}")"
# Only the six canonical Constitution tags — repo-specific area tags are not
# part of the contract and must not be hardcoded here.
report "🔴" "[25] no tag on test.describe()" \
    "$(g "describe\([^)]*@(smoke|sanity|regression|e2e|api|destructive)" "${TS_FILES[@]:-}")"

# [23] static data must be .ts, never .json
if [[ ${#STATIC_JSON[@]} -gt 0 ]]; then
    echo "❌ 🔴 [23] no JSON under test-data/static"
    printf '      %s\n' "${STATIC_JSON[@]}"
    FAIL=1
else
    echo "✅ 🔴 [23] no JSON under test-data/static"
fi

# [21] magic-number timeouts: numeric literal passed to timeout:
soft_report "🟡" "[21] possible magic-number timeout" \
    "$(g 'timeout:\s*[0-9]{3,}' "${TS_FILES[@]:-}")"

# [12] hardcoded http(s) URL literal (should come from env/config)
soft_report "🟡" "[12] possible hardcoded URL (should be env/config)" \
    "$(g "(baseUrl|url|apiUrl)\s*:\s*['\"]https?://" "${TS_FILES[@]:-}")"

# [8] response assertion shape — informational: list Schema.parse() calls so the
# reviewer can confirm each is the `expect(Schema.parse(body)).toBeTruthy()` form.
# Exclude JSON.parse — that's deserialization, not schema validation.
PARSE_HITS="$(g '\.parse\(' "${SPEC_FILES[@]:-}" | grep -vE '\bJSON\.parse\(' || true)"
echo "ℹ️  [8] Schema.parse() call sites (verify each is expect(...).toBeTruthy()):"
[[ -n "${PARSE_HITS// }" ]] && echo "${PARSE_HITS}" | sed 's/^/      /' || echo "      (none)"

echo
if [[ $FAIL -eq 0 ]]; then
    echo "Mechanical scan: no violations. Judgment items still require manual review."
else
    echo "Mechanical scan: violations above — carry each into the report at its tier."
fi
exit $FAIL
