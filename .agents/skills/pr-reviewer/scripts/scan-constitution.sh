#!/usr/bin/env bash
# scan-constitution.sh — deterministic half of the Constitution checklist.
#
# The shared mechanical rules are NOT duplicated here: they live in
# .claude/scripts/enforce_constitution.py (the PreToolUse hook), which this
# script invokes in --scan mode over the changed files. One rule list, two
# consumers — the hook and this review-time scan can never drift apart.
# Judgment items (coverage gaps, sibling divergence, schema-vs-contract
# fidelity) are NOT here — those stay with the model. Every check maps to a
# row in references/constitution-checklist.md by its [#].
#
# Usage:
#   scan-constitution.sh [base]          # base defaults to the remote default
#                                        # branch (origin/HEAD); diffs base...HEAD
#   scan-constitution.sh --files a.ts b.ts
#
# Exit code: 0 = no mechanical violations, 1 = at least one FAIL,
#            2 = usage error (unresolvable base ref / missing enforcement script).

set -uo pipefail

# Everything below (git diffs, file-existence checks, the enforcement engine)
# assumes repo-root-relative paths. Running from a subdirectory would make the
# diff paths unresolvable and the scan would false-pass as "no changed files".
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$REPO_ROOT" ]]; then
    echo "ERROR: not inside a git repository — cannot scan." >&2
    exit 2
fi
ORIG_PWD="$PWD"
cd "$REPO_ROOT"

BASE=""
FILES=""

if [[ "${1:-}" == "--files" ]]; then
    shift
    # One path per line — the loops below read line-by-line. Relative paths
    # were relative to the caller's CWD, which we just left — anchor them.
    FILES=""
    for a in "$@"; do
        [[ "$a" == /* ]] || a="${ORIG_PWD}/${a}"
        FILES+="${a}"$'\n'
    done
else
    if [[ -n "${1:-}" ]]; then
        BASE="$1"
    else
        # Resolve the repo's actual default branch instead of assuming a name.
        BASE="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
        if [[ -z "$BASE" ]]; then
            for candidate in origin/main origin/master main master; do
                if git rev-parse --verify --quiet "$candidate" >/dev/null; then
                    BASE="$candidate"
                    break
                fi
            done
        fi
    fi
    # A bad base must fail loudly — an unverified ref would make the diff
    # empty and the scan would false-pass as "no changed files".
    if [[ -z "$BASE" ]] || ! git rev-parse --verify --quiet "$BASE" >/dev/null; then
        echo "ERROR: cannot resolve base ref '${BASE:-<none>}'. Pass an explicit base: scan-constitution.sh <base>" >&2
        exit 2
    fi
    # lint-fixtures/ holds deliberate violations (proven by check:enforcement);
    # scanning them would report every forbidden fixture as a branch finding.
    FILES="$(git diff "${BASE}...HEAD" --name-only --diff-filter=d -- . ':!lint-fixtures')"
fi

if [[ -z "${FILES// }" ]]; then
    echo "No changed files to scan (diff ${BASE:-<file list>}...HEAD is empty)."
    exit 0
fi

ENFORCER="${REPO_ROOT}/.claude/scripts/enforce_constitution.py"
if [[ ! -f "$ENFORCER" ]]; then
    # Fallback: resolve relative to this script (.claude/skills/pr-reviewer/scripts/).
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    ENFORCER="${SCRIPT_DIR}/../../../scripts/enforce_constitution.py"
fi
if [[ ! -f "$ENFORCER" ]]; then
    echo "ERROR: shared rule engine not found (.claude/scripts/enforce_constitution.py)" >&2
    exit 2
fi

# Collect changed files (existing only) for the shared engine + local checks.
ALL_FILES=()
TS_FILES=()
SPEC_FILES=()
while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    [[ ! -f "$f" ]] && continue
    ALL_FILES+=("$f")
    case "$f" in
        *.spec.ts|*.setup.ts) SPEC_FILES+=("$f"); TS_FILES+=("$f") ;;
        *.ts)                 TS_FILES+=("$f") ;;
    esac
done <<< "$FILES"

if [[ ${#ALL_FILES[@]} -eq 0 ]]; then
    echo "No existing changed files to scan."
    exit 0
fi

# ---- Shared rules: one invocation of the hook's rule engine ----------------
SCAN_OUT="$(python3 "$ENFORCER" --scan "${ALL_FILES[@]}")"
PY_EXIT=$?
# Engine exit 0 = clean, 1 = violations (output non-empty). Anything else, or
# exit 1 with no output, means the engine itself failed — never report green.
if [[ $PY_EXIT -gt 1 || ( $PY_EXIT -eq 1 && -z "${SCAN_OUT// }" ) ]]; then
    echo "ERROR: enforce_constitution.py --scan failed (exit ${PY_EXIT})" >&2
    exit 2
fi

FAIL=0
# hits_for <rule-id> — pull that rule's violations out of the engine output.
hits_for() {
    [[ -z "$SCAN_OUT" ]] && return 0
    awk -F'\t' -v r="$1" '$1 == r { sub(/^[^\t]*\t/, ""); print }' <<< "$SCAN_OUT"
}

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

# grep helper for the scan-only checks: prints file:line:match.
g() {
    local pattern="$1"; shift
    local files=() f
    for f in "$@"; do [[ -n "$f" ]] && files+=("$f"); done
    [[ ${#files[@]} -eq 0 ]] && return 0
    grep -HnE "$pattern" "${files[@]}" 2>/dev/null
}

echo "=== Constitution scan (mechanical) — base ${BASE:-<file list>} ==="
echo "    shared rules via .claude/scripts/enforce_constitution.py --scan"
echo

# ---- Rows backed by the shared engine (rule-id → checklist row) ------------
report "🔴" "[1] specs import test/expect from test-options, not @playwright/test" \
    "$(hits_for no-playwright-test-import)"
report "🔴" "[2] no 'new XxxPage()/XxxComponent()' in specs" \
    "$(hits_for no-manual-instantiation)"
report "🔴" "[4] z.strictObject (no z.object) in fixtures/api/schemas" \
    "$(hits_for no-loose-schema)"
report "🔴" "[12] no hardcoded url:/baseUrl: literal (env/config + enums instead)" \
    "$(hits_for no-hardcoded-url)"
report "🔴" "[12] no page.goto() with a URL literal (env APP_URL + route enums)" \
    "$(hits_for no-hardcoded-goto-url)"
report "🔴" "[16] no XPath selectors" \
    "$(hits_for no-xpath)"
report "🔴" "[20] no waitForTimeout / hard waits" \
    "$(hits_for no-hard-wait)"
report "🔴" "[23] no JSON under test-data/static" \
    "$(hits_for no-json-static-data)"
report "🔴" "[23] static data is literals-only (no faker/runtime imports)" \
    "$(hits_for no-runtime-code-in-static-data)"
report "🔴" "[25] no @functional tag" \
    "$(hits_for no-functional-tag)"
report "🔴" "[25] exactly one tag per test" \
    "$(hits_for no-multiple-tags)"
report "🔴" "[25] no tag on test.describe()" \
    "$(hits_for no-tags-on-describe)"
report "🔴" "[24] no inline universal invalid-value arrays (import INVALID_*)" \
    "$(hits_for no-inline-universal-invalids)"

# Safety net: any engine rule not mapped to a row above still fails the scan.
KNOWN_IDS="no-playwright-test-import|no-manual-instantiation|no-loose-schema|no-hardcoded-url|no-hardcoded-goto-url|no-xpath|no-hard-wait|no-json-static-data|no-runtime-code-in-static-data|no-functional-tag|no-multiple-tags|no-tags-on-describe|no-inline-universal-invalids"
UNMAPPED="$(awk -F'\t' -v known="$KNOWN_IDS" 'NF >= 2 && $1 !~ "^(" known ")$" { print $1": "$2 }' <<< "$SCAN_OUT")"
report "🔴" "[--] other Constitution-engine violations" "$UNMAPPED"

# ---- Scan-only checks (review-time signals, not PreToolUse-blockable) ------

# [3] no `any` (ESLint no-explicit-any is the authoritative gate; this is the
# quick review-time signal). `as any` needs a left non-letter boundary —
# without it, prose like "has anything" in a comment contains the substring
# and a hard ❌ here becomes a false-finding generator.
report "🔴" "[3] no 'any' type" \
    "$(g ':\s*any\b|<any>|(^|[^A-Za-z])as any\b|Array<any>|: any\[\]' "${TS_FILES[@]:-}")"

# [4-soft] z.object( outside schema files — fine unless it validates an API response
soft_report "🟡" "[4] z.object( outside fixtures/api/schemas (ok unless it validates an API response)" \
    "$(g '\bz\.object\(' "${TS_FILES[@]:-}" | grep -v 'fixtures/api/schemas/' || true)"

# [21] magic-number timeouts: numeric literal passed to timeout:
soft_report "🟡" "[21] possible magic-number timeout" \
    "$(g 'timeout:\s*[0-9]{3,}' "${TS_FILES[@]:-}")"

# [12-soft] any other http(s) literal the narrow hard rule didn't catch
soft_report "🟡" "[12] other https?:// literal (should come from env/config)" \
    "$(g "['\"\`]https?://" "${TS_FILES[@]:-}" | grep -vE '^\S+:[0-9]+:\s*(//|\*|/\*)' || true)"

# [1-info] any other @playwright/test import in a spec (usually a type) —
# allowed, but listed so the reviewer can sanity-check it's type-only.
OTHER_PW_IMPORT="$(g "from ['\"]@playwright/test['\"]" "${SPEC_FILES[@]:-}" | grep -vE '\b(test|expect)\b' || true)"
[[ -n "${OTHER_PW_IMPORT// }" ]] && { echo "ℹ️  [1] other @playwright/test imports in specs (ok if type-only):"; echo "${OTHER_PW_IMPORT}" | sed 's/^/      /'; }

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
