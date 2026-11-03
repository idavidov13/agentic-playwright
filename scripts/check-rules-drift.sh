#!/usr/bin/env bash
# check-rules-drift.sh
#
# Verifies every Constitution rule (AGENTS.md MUST/SHOULD/WON'T lists) has a
# matching anchor token inside the Critical block of its owning leaf skill.
# Exits non-zero on drift so it can gate CI.
#
# Manifest format (one rule per line):
#   <anchor-token>|<owning-skill-dir>|<short-label>
#
# The anchor token must be a distinctive substring of the rule that the leaf
# skill's Critical block is expected to contain verbatim. Keep tokens short
# and unique enough that a stylistic rewrite of the Critical block still
# triggers a deliberate manifest update.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="${REPO_ROOT}/.claude/skills"
# Claude tree pruned at init (--no-claude): lint the generated copy instead.
[[ -d "${SKILLS_DIR}" ]] || SKILLS_DIR="${REPO_ROOT}/.agents/skills"
CONSTITUTION="${REPO_ROOT}/AGENTS.md"

if [[ ! -f "${CONSTITUTION}" ]]; then
    if [[ ! -d "${REPO_ROOT}/.claude" ]]; then
        echo "SKIP: Claude rule tree not present (pruned at init) — nothing to check."
        exit 0
    fi
    echo "ERROR: Constitution not found at ${CONSTITUTION}" >&2
    exit 2
fi

# anchor-token|owning-skill|label
MANIFEST="${REPO_ROOT}/scripts/rules-manifest.txt"
if [[ ! -f "${MANIFEST}" ]]; then
    echo "ERROR: shared manifest not found at ${MANIFEST}" >&2
    exit 2
fi
RULES="$(grep -v '^\s*#' "${MANIFEST}" | grep -v '^\s*$')"

extract_critical_block() {
    # Print the Critical block of a SKILL.md: lines from "## Critical" (or
    # "## Mandatory" — playwright-cli uses that name) up to the next
    # top-level "## " heading.
    local file="$1"
    awk '
        /^## (Critical|Mandatory)/ { in_block = 1; next }
        in_block && /^## / { in_block = 0 }
        in_block { print }
    ' "${file}"
}

errors=0
checked=0

while IFS='|' read -r token skill label; do
    [[ -z "${token}" ]] && continue
    skill_file="${SKILLS_DIR}/${skill}/SKILL.md"
    if [[ ! -f "${skill_file}" ]]; then
        echo "MISS  ${skill}/SKILL.md not found (rule: ${label})"
        errors=$((errors + 1))
        continue
    fi
    block="$(extract_critical_block "${skill_file}")"
    if printf '%s' "${block}" | grep -F -q -- "${token}"; then
        echo "OK    ${skill} :: ${label}"
    else
        echo "DRIFT ${skill} :: ${label} -- token '${token}' not found in Critical block"
        errors=$((errors + 1))
    fi
    checked=$((checked + 1))
done <<< "${RULES}"

# ---------------------------------------------------------------------------
# Bidirectional check: the manifest above only proves the SKILLS carry the
# rules — it never reads the Constitution itself, so a deleted or renamed
# AGENTS.md row would stay green. Assert the Constitution's MUST/SHOULD/WON'T
# row keys match this expected list exactly, both directions:
#   - a key listed here but missing from AGENTS.md  -> a rule was deleted/renamed
#   - a key in AGENTS.md but not listed here        -> a rule was added without
#     updating this manifest (and probably without a skill anchor or hook rule)
# ---------------------------------------------------------------------------
read -r -d '' EXPECTED_ROWS <<'EOF' || true
Dependency Injection
Imports
Selectors
Type Safety
Strict Schemas
Response Validation
Sources of Truth
Assertions
Linting
Data Strategy
State Cleanup
API Test Steps
Test Verification
Explore Before Generate
Data Generation
Test Isolation
Test Steps
JSDoc on Actions
Enums for Strings
No XPath
No Hard Waits
No Secrets
No `any`
No Tags on Describe
No Multiple Tags
No Magic Numbers
No Manual Instantiation
No Loose Schemas
No JSDoc on Locators
No Hardcoded Test Content
No Explore-Only Files
No Empty-Body-Only 400
No Feedback-Less POM
No Substitute UI Exploration
No Silent Coverage Drops
No JSON Static Data
EOF

ACTUAL_ROWS="$(awk '/^## Constitution/ { in_sec = 1; next }
                   in_sec && /^## /    { in_sec = 0 }
                   in_sec              { print }' "${CONSTITUTION}" \
    | grep -oE '^- \*\*[^*]+\*\*' | sed 's/^- \*\*//; s/\*\*$//')"

while IFS= read -r row; do
    [[ -z "${row}" ]] && continue
    if grep -F -x -q -- "${row}" <<< "${ACTUAL_ROWS}"; then
        checked=$((checked + 1))
    else
        echo "DRIFT AGENTS.md :: Constitution row '${row}' missing (deleted or renamed?)"
        errors=$((errors + 1))
    fi
done <<< "${EXPECTED_ROWS}"

while IFS= read -r row; do
    [[ -z "${row}" ]] && continue
    if ! grep -F -x -q -- "${row}" <<< "${EXPECTED_ROWS}"; then
        echo "DRIFT AGENTS.md :: new Constitution row '${row}' not in this manifest -- add it here (+ skill anchor / hook rule if mechanical)"
        errors=$((errors + 1))
    fi
done <<< "${ACTUAL_ROWS}"

# ---------------------------------------------------------------------------
# Hook mapping: every mechanical rule id in enforce_constitution.py must map
# to a Constitution row that still exists. A new hook rule without a mapping
# here, or a mapped row that vanished from AGENTS.md, is drift.
# ---------------------------------------------------------------------------
ENFORCER="${REPO_ROOT}/.claude/scripts/enforce_constitution.py"
# `_infra` sentinel: the rule protects the enforcement layer itself and has
# no Constitution row by design — the row check is skipped for it.
read -r -d '' HOOK_MAP <<'EOF' || true
no-playwright-test-import|Imports
no-hard-wait|No Hard Waits
no-loose-schema|No Loose Schemas
no-xpath|No XPath
no-json-static-data|No JSON Static Data
no-functional-tag|No Multiple Tags
no-multiple-tags|No Multiple Tags
no-tags-on-describe|No Tags on Describe
no-manual-instantiation|No Manual Instantiation
no-runtime-code-in-static-data|Data Strategy
no-hardcoded-url|Sources of Truth
no-hardcoded-goto-url|Sources of Truth
no-unknown-tag|No Multiple Tags
no-jsdoc-on-locators|No JSDoc on Locators
no-hardcoded-test-content|No Hardcoded Test Content
no-inline-universal-invalids|Data Strategy
no-missing-tag|No Multiple Tags
no-eslint-disable-scaffold|Linting
explore-before-generate|Explore Before Generate
protected-path|_infra
EOF

if [[ ! -f "${ENFORCER}" && ! -d "${REPO_ROOT}/.claude" ]]; then
    echo "SKIP hook :: .claude/ pruned at init — no hook to map."
elif [[ ! -f "${ENFORCER}" ]]; then
    echo "DRIFT hook :: enforce_constitution.py not found"
    errors=$((errors + 1))
else
    # Rule ids carry a `# hook-rule-id` marker on their tuple line (any id
    # shape, not just `no-*`); gate ids appear as bracket tags in violation
    # messages.
    # `|| true`: under set -e + pipefail an empty grep would abort the script
    # mute; an empty id set already produces explicit DRIFT messages below.
    HOOK_IDS="$(
        {
            grep -E '",\s*#\s*hook-rule-id' "${ENFORCER}" | grep -oE '"[a-z0-9-]+"' | tr -d '"'
            grep -oE '\[explore-before-generate\]|\[protected-path\]' "${ENFORCER}" | tr -d '[]'
        } | sort -u || true
    )"
    # A rule tuple WITHOUT a marker would be invisible to the map — cross-check
    # the tuple count (one `lambda p:` path predicate per tuple) against the
    # marker count.
    TUPLE_COUNT="$(awk '/^RULES = \[/{f=1} f{print} /^\]/{if(f) exit}' "${ENFORCER}" \
        | { grep -c 'lambda p:' || true; })"
    MARKER_COUNT="$(grep -cE '",\s*#\s*hook-rule-id' "${ENFORCER}" || true)"
    if [[ "${TUPLE_COUNT}" -ne "${MARKER_COUNT}" ]]; then
        echo "DRIFT hook :: ${TUPLE_COUNT} rule tuple(s) but ${MARKER_COUNT} '# hook-rule-id' marker(s) — a rule was added without a marker (invisible to this gate)"
        errors=$((errors + 1))
    else
        checked=$((checked + 1))
    fi
    while IFS= read -r hid; do
        [[ -z "${hid}" ]] && continue
        mapped_row="$(awk -F'|' -v h="${hid}" '$1 == h { print $2 }' <<< "${HOOK_MAP}")"
        if [[ -z "${mapped_row}" ]]; then
            echo "DRIFT hook :: rule id '${hid}' has no Constitution mapping in this manifest"
            errors=$((errors + 1))
        elif [[ "${mapped_row}" == "_infra" ]]; then
            checked=$((checked + 1))
        elif ! grep -F -x -q -- "${mapped_row}" <<< "${ACTUAL_ROWS}"; then
            echo "DRIFT hook :: '${hid}' maps to Constitution row '${mapped_row}' which no longer exists"
            errors=$((errors + 1))
        else
            checked=$((checked + 1))
        fi
    done <<< "${HOOK_IDS}"
    # Inverse: every manifest entry must still exist as a hook rule id.
    while IFS='|' read -r hid _row; do
        [[ -z "${hid}" ]] && continue
        if ! grep -F -x -q -- "${hid}" <<< "${HOOK_IDS}"; then
            echo "DRIFT hook :: mapped rule id '${hid}' no longer present in enforce_constitution.py"
            errors=$((errors + 1))
        fi
    done <<< "${HOOK_MAP}"
fi

echo
echo "Checked ${checked} rule(s); ${errors} drift(s)."
[[ "${errors}" -eq 0 ]] || exit 1
