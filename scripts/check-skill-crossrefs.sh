#!/usr/bin/env bash
# check-skill-crossrefs.sh
#
# Lints the orchestration layer's cross-skill wiring -- the gaps not covered
# by the sibling linters (check-rules-drift.sh validates Constitution rules
# against Critical blocks; check-skill-references-drift.sh validates
# references/*.md pointers; check-agents-md.sh keeps the AGENTS.md Skills
# Index in sync with .claude/skills/). This script catches two failure modes:
#
#   1. Frontmatter drift -- SKILL.md frontmatter `name:` does not match its
#                          directory name, or `description:` is missing/empty.
#   2. Dangling skill ref -- a backticked kebab-case token in AGENTS.md,
#                          CLAUDE.md, the Copilot prompt, a SKILL.md or a
#                          scaffold skill's references/*.md names a skill
#                          that does not exist (typically left behind by a
#                          rename/delete).
#   3. Dangling skill-context ref -- any backticked token, single words
#                          included, written as a skill ("see `x`",
#                          "per `x`", "`x` skill") must name a skill.
#
# For mode 2, a token is considered resolved if it (a) names an existing
# skill, (b) appears in the static allowlist below, or (c) equals the
# basename (with or without extension) or a whole segment of a git-tracked
# path (`test-options` -> fixtures/pom/test-options.ts; a substring match
# used to accept `page-object` via page-object-fixture.ts).
#
# Exits non-zero on any drift so CI can gate.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="${REPO_ROOT}/.claude/skills"
# Claude tree pruned at init (--no-claude): lint the generated copy instead.
[[ -d "${SKILLS_DIR}" ]] || SKILLS_DIR="${REPO_ROOT}/.agents/skills"
CONSTITUTION="${REPO_ROOT}/AGENTS.md"

if [[ ! -f "${CONSTITUTION}" && ! -d "${REPO_ROOT}/.claude" ]]; then
    echo "SKIP: Claude rule tree not present (pruned at init) — nothing to check."
    exit 0
fi

# Kebab tokens that are legitimate prose, doc examples, or placeholders --
# not skill names and not repo paths. Extend deliberately when a new
# false positive appears.
ALLOWLIST=(
    "front-office"      # {area} placeholder example
    "back-office"       # {area} placeholder example
    "on-failure"        # Playwright config literal (debugging skill)
    "on-first-retry"    # Playwright config literal (debugging skill)
    "only-on-failure"   # Playwright config literal (debugging skill)
    "retain-on-failure" # Playwright config literal (debugging skill)
    "show-trace"        # playwright CLI subcommand (debugging skill)
    "test-results"      # Playwright output dir, gitignored (debugging skill)
    "research-helper"   # worked example name in skill-creator
    "research-helper-v2" # worked example name in skill-creator
    "front-chromium"    # Playwright project-name example (pr-reviewer skill)
    "setup-api"         # Playwright project name (playwright.config.ts)
    "setup-ui"          # Playwright project name (playwright.config.ts)
    "webmcp-list"       # playwright-cli subcommand (vendored playwright-cli skill, 0.1.22+)
    "aria-label"        # HTML attribute (selectors reference)
    "data-test"         # test-id attribute name (selectors reference)
    "pr-review-tsc-detour" # anchor id inside the Copilot prompt
)

errors=0

# --- Collect skills on disk (dirs under .claude/skills/ that have a SKILL.md) ---
disk_skills=""
while IFS= read -r skill_md; do
    disk_skills="${disk_skills}$(basename "$(dirname "${skill_md}")")"$'\n'
done < <(find "${SKILLS_DIR}" -mindepth 2 -maxdepth 2 -name SKILL.md -type f | sort)

# --- Check 1: frontmatter name/description per SKILL.md ---
frontmatter_field() {
    # Print the value of a frontmatter field ($2) from file $1.
    awk -v field="$2" '
        NR == 1 && /^---$/ { in_fm = 1; next }
        in_fm && /^---$/   { exit }
        in_fm && index($0, field ":") == 1 {
            sub(field ":[ ]*", ""); print; exit
        }
    ' "$1"
}

while IFS= read -r name; do
    [[ -z "${name}" ]] && continue
    skill_md="${SKILLS_DIR}/${name}/SKILL.md"
    fm_name="$(frontmatter_field "${skill_md}" "name")"
    fm_desc="$(frontmatter_field "${skill_md}" "description")"
    if [[ "${fm_name}" != "${name}" ]]; then
        echo "DRIFT frontmatter :: ${name}/SKILL.md name is '${fm_name:-<missing>}', expected '${name}'"
        errors=$((errors + 1))
    fi
    if [[ -z "${fm_desc}" ]]; then
        echo "DRIFT frontmatter :: ${name}/SKILL.md has a missing or empty description"
        errors=$((errors + 1))
    fi
done <<< "${disk_skills}"

# --- Check 2: dangling backticked skill-shaped tokens ---
in_allowlist() {
    local token="$1" allowed
    for allowed in "${ALLOWLIST[@]}"; do
        [[ "${token}" == "${allowed}" ]] && return 0
    done
    return 1
}

# Tracked basenames (with and without extension) and path segments, once.
# Outside a git checkout (`--skip-git`), every file except node_modules.
tracked_names="$( { git -C "${REPO_ROOT}" ls-files 2>/dev/null \
    || (cd "${REPO_ROOT}" && find . -type f -not -path './node_modules/*' -not -path './.git/*' | sed 's|^\./||'); } | awk -F/ '
    { for (i = 1; i <= NF; i++) { print $i; seg = $i; sub(/\.[A-Za-z0-9]+$/, "", seg); print seg } }' | sort -u)"

is_tracked_name() {
    printf '%s\n' "${tracked_names}" | grep -F -x -q -- "$1"
}

checked_tokens=0
check_tokens_in() {
    local file="$1" display="$2" token
    # 2. kebab-case tokens anywhere in the file
    while IFS= read -r token; do
        [[ -z "${token}" ]] && continue
        checked_tokens=$((checked_tokens + 1))
        if printf '%s' "${disk_skills}" | grep -F -x -q -- "${token}"; then
            continue
        fi
        if in_allowlist "${token}"; then
            continue
        fi
        if is_tracked_name "${token}"; then
            continue
        fi
        echo "DRIFT crossref :: ${display} mentions \`${token}\` -- not a skill, not allowlisted, no tracked file or directory of that name"
        errors=$((errors + 1))
    done < <(grep -oE '`[a-z0-9]+(-[a-z0-9]+)+`' "${file}" | tr -d '\`' | sort -u)
    # 3. any token written as a skill ("see `x`", "per `x`", "`x` skill")
    while IFS= read -r token; do
        [[ -z "${token}" ]] && continue
        checked_tokens=$((checked_tokens + 1))
        if printf '%s' "${disk_skills}" | grep -F -x -q -- "${token}"; then
            continue
        fi
        echo "DRIFT crossref :: ${display} refers to \`${token}\` as a skill -- no such skill"
        errors=$((errors + 1))
    done < <(grep -oE '(see|per) `[a-z0-9-]+`|`[a-z0-9-]+` skill' "${file}" | grep -oE '`[a-z0-9-]+`' | tr -d '\`' | sort -u)
}

# Vendored skills (skills-lock.json) are upstream text: their references are
# not scanned (their SKILL.md still is, for the index and frontmatter).
vendored_skills="$(node -e "
    const lock = JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8'));
    console.log(Object.keys(lock.skills || {}).join('\n'));
" "${REPO_ROOT}/skills-lock.json" 2>/dev/null || true)"
is_vendored() { printf '%s\n' "${vendored_skills}" | grep -F -x -q -- "$1"; }

check_tokens_in "${CONSTITUTION}" "AGENTS.md"
[[ -f "${REPO_ROOT}/CLAUDE.md" ]] && check_tokens_in "${REPO_ROOT}/CLAUDE.md" "CLAUDE.md"
[[ -f "${REPO_ROOT}/.github/prompts/pr-reviewer.prompt.md" ]] \
    && check_tokens_in "${REPO_ROOT}/.github/prompts/pr-reviewer.prompt.md" ".github/prompts/pr-reviewer.prompt.md"
while IFS= read -r name; do
    [[ -z "${name}" ]] && continue
    check_tokens_in "${SKILLS_DIR}/${name}/SKILL.md" "${name}/SKILL.md"
    is_vendored "${name}" && continue
    while IFS= read -r ref; do
        [[ -z "${ref}" ]] && continue
        check_tokens_in "${ref}" "${name}/${ref#"${SKILLS_DIR}/${name}/"}"
    done < <(find "${SKILLS_DIR}/${name}/references" -name '*.md' -type f 2>/dev/null | sort)
done <<< "${disk_skills}"

skill_count="$(printf '%s' "${disk_skills}" | grep -c . || true)"
echo
echo "Checked ${skill_count} skill(s) and ${checked_tokens} crossref token(s); ${errors} drift(s)."
[[ "${errors}" -eq 0 ]] || exit 1
