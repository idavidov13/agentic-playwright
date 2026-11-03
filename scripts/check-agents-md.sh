#!/usr/bin/env bash
# check-agents-md.sh — AGENTS.md stays small, import-safe and in sync;
# CLAUDE.md and the Copilot prompt stay in step with it.
#
# AGENTS.md is the always-loaded orchestrator for every harness (Claude Code
# imports it from CLAUDE.md; Codex, Cursor and Copilot read it natively).
# This gate fails when:
#
#   1. Budget   -- the file exceeds MAX_LINES or MAX_WORDS (`wc -l` / `wc -w`;
#                  the PRO block counts, it is loaded too).
#   2. Bare `@` -- an `@` appears outside a code span or fenced block. Claude
#                  Code parses a bare `@path` in an imported file as another
#                  import, so `@smoke` or `@playwright/test` in prose must be
#                  written as code spans.
#   3. Index    -- the "## Skills Index" names do not match the skill
#                  directories under .claude/skills/ (both directions), after
#                  removing EXCLUDED_SKILLS. Every `pro-*` index line must sit
#                  inside a PRO block so the OSS export strips it.
#   4. Shape    -- a required heading is missing (the other drift gates key on
#                  them), or the <!-- PRO:START --> / <!-- PRO:END --> markers
#                  are unbalanced or nested.
#   5. CLAUDE.md -- the Claude Code importer stays within CLAUDE_MAX_LINES /
#                  CLAUDE_MAX_WORDS, its only bare `@` line is `@AGENTS.md`
#                  (anything else would be a second import), it carries the
#                  "## Claude Code only" heading, and its PRO markers balance.
#                  Skipped when CLAUDE.md is absent (pruned at init).
#   6. Prompt    -- .github/prompts/pr-reviewer.prompt.md is a hand-written
#                  condensation of the pr-reviewer skill; it must keep the
#                  hardened git-flow anchors (base auto-resolution, checkout
#                  restore, three-dot diff, Constitution scan, strict
#                  schemas). Skipped when the prompt is absent (pruned at init).
#
# Exits non-zero on any failure so pre-commit and CI can gate.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENTS="${REPO_ROOT}/AGENTS.md"
CLAUDE="${REPO_ROOT}/CLAUDE.md"
SKILLS_DIR="${REPO_ROOT}/.claude/skills"
# Claude tree pruned at init (--no-claude): lint the generated copy instead.
[[ -d "${SKILLS_DIR}" ]] || SKILLS_DIR="${REPO_ROOT}/.agents/skills"
PR_PROMPT="${REPO_ROOT}/.github/prompts/pr-reviewer.prompt.md"

MAX_LINES=100
MAX_WORDS=800
CLAUDE_MAX_LINES=30
CLAUDE_MAX_WORDS=250
CLAUDE_IMPORT="@AGENTS.md"
CLAUDE_HEADING="## Claude Code only"

# Skill directories deliberately absent from the index. Empty by default:
# vendored skills (playwright-cli, skill-creator) are indexed because the
# Constitution routes to them. Add a name here only as a decision.
EXCLUDED_SKILLS=()

REQUIRED_HEADINGS=(
    "## Constitution"
    "### MUST"
    "### SHOULD"
    "### WON'T"
    "## Workflow"
    "## Skills Index"
    "## Before you report done"
)

# Load-bearing git-flow anchors of the pr-reviewer prompt (section 6).
PR_PROMPT_ANCHORS=(
    "origin/HEAD"          # base auto-resolution from the remote default head
    "ORIGINAL_REF"         # capture + restore the user's starting checkout
    "switch -C"            # reset a stale local branch to the origin tip
    "...HEAD"              # three-dot merge-base diff
    "scan-constitution.sh" # mandatory Phase 6 Constitution scan
    "strictObject"         # schema-strictness review rule
)

PRO_START="<!-- PRO:START -->"
PRO_END="<!-- PRO:END -->"

if [[ ! -f "${AGENTS}" ]]; then
    echo "ERROR: ${AGENTS#"${REPO_ROOT}"/} not found" >&2
    exit 2
fi

errors=0
checked=0

# ---- 1. Budget -------------------------------------------------------------
lines="$(wc -l < "${AGENTS}" | tr -d ' ')"
words="$(wc -w < "${AGENTS}" | tr -d ' ')"
if [[ "${lines}" -gt "${MAX_LINES}" ]]; then
    echo "BUDGET AGENTS.md :: ${lines} lines, cap ${MAX_LINES}"
    errors=$((errors + 1))
else
    checked=$((checked + 1))
fi
if [[ "${words}" -gt "${MAX_WORDS}" ]]; then
    echo "BUDGET AGENTS.md :: ${words} words, cap ${MAX_WORDS}"
    errors=$((errors + 1))
else
    checked=$((checked + 1))
fi

# ---- 2. Bare `@` outside code spans ----------------------------------------
# Strip fenced blocks, then inline code spans, then flag any remaining `@`.
bare_at="$(awk '
    /^```/ { fence = !fence; next }
    fence  { next }
    {
        line = $0
        gsub(/`[^`]*`/, "", line)
        if (index(line, "@") > 0) printf "%d: %s\n", NR, $0
    }
' "${AGENTS}")"
if [[ -n "${bare_at}" ]]; then
    while IFS= read -r hit; do
        echo "BARE-AT AGENTS.md:${hit}"
    done <<< "${bare_at}"
    errors=$((errors + 1))
else
    checked=$((checked + 1))
fi

# ---- 3. Skills Index <-> .claude/skills ------------------------------------
index_section="$(awk '
    /^## Skills Index/ { in_sec = 1; next }
    in_sec && /^## /   { in_sec = 0 }
    in_sec             { print }
' "${AGENTS}")"
index_skills="$(printf '%s\n' "${index_section}" \
    | grep -oE '^- `[a-z0-9-]+`' | sed 's/^- `//; s/`$//' || true)"

is_excluded() {
    local name="$1" ex
    for ex in "${EXCLUDED_SKILLS[@]+"${EXCLUDED_SKILLS[@]}"}"; do
        [[ "${name}" == "${ex}" ]] && return 0
    done
    return 1
}

disk_skills=""
while IFS= read -r skill_md; do
    name="$(basename "$(dirname "${skill_md}")")"
    is_excluded "${name}" && continue
    disk_skills="${disk_skills}${name}"$'\n'
done < <(find "${SKILLS_DIR}" -mindepth 2 -maxdepth 2 -name SKILL.md -type f | sort)

while IFS= read -r name; do
    [[ -z "${name}" ]] && continue
    if printf '%s' "${disk_skills}" | grep -F -x -q -- "${name}"; then
        checked=$((checked + 1))
    else
        echo "INDEX AGENTS.md :: \`${name}\` is indexed but .claude/skills/${name}/SKILL.md is missing (or the name is excluded)"
        errors=$((errors + 1))
    fi
done <<< "${index_skills}"

while IFS= read -r name; do
    [[ -z "${name}" ]] && continue
    if ! printf '%s\n' "${index_skills}" | grep -F -x -q -- "${name}"; then
        echo "INDEX AGENTS.md :: .claude/skills/${name}/ exists but is not in the Skills Index"
        errors=$((errors + 1))
    fi
done <<< "${disk_skills}"

# Duplicate index lines are a copy-paste slip.
dupes="$(printf '%s\n' "${index_skills}" | grep -v '^$' | sort | uniq -d || true)"
if [[ -n "${dupes}" ]]; then
    echo "INDEX AGENTS.md :: duplicate index line(s): $(printf '%s' "${dupes}" | tr '\n' ' ')"
    errors=$((errors + 1))
fi

# ---- 4. Shape: headings and PRO markers ------------------------------------
for heading in "${REQUIRED_HEADINGS[@]}"; do
    if grep -F -x -q -- "${heading}" "${AGENTS}"; then
        checked=$((checked + 1))
    else
        echo "SHAPE AGENTS.md :: required heading '${heading}' missing"
        errors=$((errors + 1))
    fi
done

# Markers must alternate START, END, START, END ... and `pro-` index lines
# must fall inside a block.
marker_state() {
    awk -v s="${PRO_START}" -v e="${PRO_END}" '
        $0 == s { if (open) { print "nested START at line " NR; bad = 1 } open = 1; next }
        $0 == e { if (!open) { print "END without START at line " NR; bad = 1 } open = 0; next }
        !open && /^- `pro-[a-z0-9-]+`/ { print "pro- index line outside a PRO block at line " NR; bad = 1 }
        END {
            if (open) { print "START without END"; bad = 1 }
            if (!bad) print "ok"
        }
    ' "$1"
}
state="$(marker_state "${AGENTS}")"
if [[ "${state}" == "ok" ]]; then
    checked=$((checked + 1))
else
    while IFS= read -r msg; do
        echo "SHAPE AGENTS.md :: ${msg}"
    done <<< "${state}"
    errors=$((errors + 1))
fi

# ---- 5. CLAUDE.md: the importer -------------------------------------------
claude_summary=""
if [[ -f "${CLAUDE}" ]]; then
    c_lines="$(wc -l < "${CLAUDE}" | tr -d ' ')"
    c_words="$(wc -w < "${CLAUDE}" | tr -d ' ')"
    claude_summary=" CLAUDE.md: ${c_lines}/${CLAUDE_MAX_LINES} lines, ${c_words}/${CLAUDE_MAX_WORDS} words."
    if [[ "${c_lines}" -gt "${CLAUDE_MAX_LINES}" ]]; then
        echo "BUDGET CLAUDE.md :: ${c_lines} lines, cap ${CLAUDE_MAX_LINES}"
        errors=$((errors + 1))
    else
        checked=$((checked + 1))
    fi
    if [[ "${c_words}" -gt "${CLAUDE_MAX_WORDS}" ]]; then
        echo "BUDGET CLAUDE.md :: ${c_words} words, cap ${CLAUDE_MAX_WORDS}"
        errors=$((errors + 1))
    else
        checked=$((checked + 1))
    fi
    # Every line with an `@` outside a code span is an import; exactly one is
    # allowed and it is the orchestrator.
    c_imports="$(awk '
        /^```/ { fence = !fence; next }
        fence  { next }
        {
            line = $0
            gsub(/`[^`]*`/, "", line)
            if (index(line, "@") > 0) print NR ": " $0
        }
    ' "${CLAUDE}")"
    if [[ "${c_imports}" == "1: ${CLAUDE_IMPORT}" ]]; then
        checked=$((checked + 1))
    else
        echo "IMPORT CLAUDE.md :: expected line 1 to be the only bare-@ line (${CLAUDE_IMPORT}); found:"
        printf '%s\n' "${c_imports:-<none>}" | sed 's/^/  /'
        errors=$((errors + 1))
    fi
    if grep -F -x -q -- "${CLAUDE_HEADING}" "${CLAUDE}"; then
        checked=$((checked + 1))
    else
        echo "SHAPE CLAUDE.md :: required heading '${CLAUDE_HEADING}' missing"
        errors=$((errors + 1))
    fi
    state="$(marker_state "${CLAUDE}")"
    if [[ "${state}" == "ok" ]]; then
        checked=$((checked + 1))
    else
        while IFS= read -r msg; do
            echo "SHAPE CLAUDE.md :: ${msg}"
        done <<< "${state}"
        errors=$((errors + 1))
    fi
fi

# ---- 6. Copilot prompt: pr-reviewer.prompt.md keeps the git-flow anchors --
# A prompt edit must not silently regress to the pre-hardening review flow.
if [[ -f "${PR_PROMPT}" ]]; then
    for anchor in "${PR_PROMPT_ANCHORS[@]}"; do
        if grep -F -q -- "${anchor}" "${PR_PROMPT}"; then
            checked=$((checked + 1))
        else
            echo "PROMPT ${PR_PROMPT#"${REPO_ROOT}"/} :: anchor '${anchor}' missing"
            errors=$((errors + 1))
        fi
    done
fi

echo
echo "AGENTS.md: ${lines}/${MAX_LINES} lines, ${words}/${MAX_WORDS} words.${claude_summary} Checked ${checked} point(s); ${errors} failure(s)."
[[ "${errors}" -eq 0 ]] || exit 1
