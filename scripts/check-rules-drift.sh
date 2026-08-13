#!/usr/bin/env bash
# check-rules-drift.sh
#
# Verifies every Constitution rule (CLAUDE.md MUST/WON'T tables) has a
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
CONSTITUTION="${REPO_ROOT}/CLAUDE.md"

if [[ ! -f "${CONSTITUTION}" ]]; then
    if [[ ! -d "${REPO_ROOT}/.claude" ]]; then
        echo "SKIP: Claude rule tree not present (pruned at init) — nothing to check."
        exit 0
    fi
    echo "ERROR: Constitution not found at ${CONSTITUTION}" >&2
    exit 2
fi

# anchor-token|owning-skill|label
read -r -d '' RULES <<'EOF' || true
fixtures/pom/test-options.ts|fixtures|Single import point for test/expect
new AppPage(page)|fixtures|No manual page-object instantiation
getByRole|selectors|Selector priority order
XPath|selectors|No XPath
z.strictObject|type-safety|Strict Zod schemas
NEVER** use `any`|type-safety|No any
SchemaName.parse(body)).toBeTruthy|api-testing|Response validation pattern
test.skip|api-testing|Behaviour-mismatch protocol
fuzz path parameters|api-testing|Path-parameter fuzzing
waitForTimeout|test-standards|No hard waits
exactly one|test-standards|Single-tag rule
@destructive|test-standards|@destructive heaviest
.ts|data-strategy|Static data is TS
Faker factory|data-strategy|Happy-path data via Faker
process.env|config|Env-driven URLs/credentials
ApiEndpoints|enums|Endpoint paths in enums
JSDoc|page-objects|JSDoc rules on actions only
expect(locator)|test-standards|Web-first assertions
Phase 1|refactor-values|Impact-analysis first
EOF

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

echo
echo "Checked ${checked} rule(s); ${errors} drift(s)."
[[ "${errors}" -eq 0 ]] || exit 1
