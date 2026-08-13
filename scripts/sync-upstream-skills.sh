#!/usr/bin/env bash
# sync-upstream-skills.sh
#
# Manages the upstream-tracked Anthropic-style skills listed in `skills-lock.json`:
# `skill-creator` (source: github anthropics/skills) and `playwright-cli` (source:
# npm @playwright/cli, bundles SKILL.md). Three modes:
#
#   verify    -- (default) Re-hash the locally vendored SKILL.md files and
#                exit non-zero if any hash diverges from `skills-lock.json`.
#                Detects local tampering between deliberate updates.
#
#   reinstall -- Fetch each upstream SKILL.md, overwrite the vendored copies
#                in .claude/skills/<name>/SKILL.md and .cursor/skills/<name>/SKILL.md,
#                and refresh the corresponding hash in `skills-lock.json`. The
#                Copilot mirror at .github/instructions/<name>.instructions.md is
#                NOT touched -- it carries Copilot-specific frontmatter and
#                is hand-maintained per the v2.1 self-contained-trees policy.
#
#   update    -- Re-hash the local files (without fetching upstream) and write
#                the new hashes into `skills-lock.json`. Use when intentional
#                local edits to a vendored skill need to be re-locked.
#
# Sources are read from the lock; `sourceType` decides how to fetch:
#   github  -> https://raw.githubusercontent.com/<source>/<ref|main>/<skillPath>
#   npm     -> node_modules/<source>/<skillPath>  (npm install must have run)
#
# Exit codes: 0 OK, 1 drift / fetch failure, 2 misuse.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK="${REPO_ROOT}/skills-lock.json"
MODE="${1:-verify}"

case "$MODE" in
    verify | reinstall | update) ;;
    *)
        echo "Usage: $0 [verify|reinstall|update]" >&2
        echo "  verify    Re-hash local SKILL.md files; exit 1 on divergence (default)." >&2
        echo "  reinstall Fetch upstream SKILL.md, overwrite vendored copies, refresh lock." >&2
        echo "  update    Re-hash local SKILL.md files and write new hashes into lock." >&2
        exit 2
        ;;
esac

if [[ ! -f "$LOCK" ]]; then
    echo "ERROR: $LOCK not found" >&2
    exit 2
fi

if ! command -v node >/dev/null 2>&1; then
    echo "ERROR: node is required to parse skills-lock.json" >&2
    exit 2
fi

# Emit one tab-separated line per skill: <name>\t<sourceType>\t<source>\t<ref>\t<skillPath>\t<computedHash>
# Using node so we don't depend on jq being installed.
list_skills() {
    node -e "
        const fs = require('fs');
        const lock = JSON.parse(fs.readFileSync(process.argv[1], 'utf8'));
        for (const [name, v] of Object.entries(lock.skills || {})) {
            const ref = v.ref || 'main';
            const out = [name, v.sourceType, v.source, ref, v.skillPath, v.computedHash || ''].join('\t');
            console.log(out);
        }
    " "$LOCK"
}

write_hash() {
    local name="$1"
    local hash="$2"
    node -e "
        const fs = require('fs');
        const path = process.argv[1];
        const name = process.argv[2];
        const hash = process.argv[3];
        const lock = JSON.parse(fs.readFileSync(path, 'utf8'));
        if (!lock.skills || !lock.skills[name]) {
            console.error('ERROR: skill ' + name + ' not in lock');
            process.exit(1);
        }
        lock.skills[name].computedHash = hash;
        fs.writeFileSync(path, JSON.stringify(lock, null, 2) + '\n');
    " "$LOCK" "$name" "$hash"
}

sha256() {
    shasum -a 256 "$1" | awk '{print $1}'
}

fetch_upstream() {
    local source_type="$1"
    local source="$2"
    local ref="$3"
    local skill_path="$4"
    local out_file="$5"

    case "$source_type" in
        github)
            local url="https://raw.githubusercontent.com/${source}/${ref}/${skill_path}"
            if ! curl -fsSL "$url" -o "$out_file"; then
                echo "ERROR: fetch failed: $url" >&2
                return 1
            fi
            ;;
        npm)
            local src_file="${REPO_ROOT}/node_modules/${source}/${skill_path}"
            if [[ ! -f "$src_file" ]]; then
                echo "ERROR: ${src_file} missing -- run 'npm install' first" >&2
                return 1
            fi
            cp "$src_file" "$out_file"
            ;;
        *)
            echo "ERROR: unknown sourceType '${source_type}'" >&2
            return 1
            ;;
    esac
}

errors=0
processed=0

# .claude is the canonical tree; .cursor mirrors it byte-for-byte. Copilot is hand-maintained.
LOCAL_TREES=(
    "${REPO_ROOT}/.claude/skills"
    "${REPO_ROOT}/.cursor/skills"
)

while IFS=$'\t' read -r name source_type source ref skill_path expected_hash; do
    [[ -z "$name" ]] && continue
    processed=$((processed + 1))

    canonical="${REPO_ROOT}/.claude/skills/${name}/SKILL.md"

    case "$MODE" in
        verify)
            if [[ ! -f "$canonical" ]]; then
                echo "MISS  ${name} :: ${canonical} not found"
                errors=$((errors + 1))
                continue
            fi
            actual="$(sha256 "$canonical")"
            if [[ "$actual" != "$expected_hash" ]]; then
                echo "DRIFT ${name} :: lock says ${expected_hash}, local is ${actual}"
                errors=$((errors + 1))
            else
                echo "OK    ${name} :: hash matches lock"
            fi
            ;;

        reinstall)
            tmp="$(mktemp)"
            if ! fetch_upstream "$source_type" "$source" "$ref" "$skill_path" "$tmp"; then
                errors=$((errors + 1))
                rm -f "$tmp"
                continue
            fi
            new_hash="$(sha256 "$tmp")"
            for tree in "${LOCAL_TREES[@]}"; do
                dest="${tree}/${name}/SKILL.md"
                mkdir -p "$(dirname "$dest")"
                cp "$tmp" "$dest"
                echo "WROTE ${dest}"
            done
            write_hash "$name" "$new_hash"
            echo "LOCK  ${name} :: hash refreshed -> ${new_hash}"
            rm -f "$tmp"
            ;;

        update)
            if [[ ! -f "$canonical" ]]; then
                echo "MISS  ${name} :: ${canonical} not found"
                errors=$((errors + 1))
                continue
            fi
            new_hash="$(sha256 "$canonical")"
            if [[ "$new_hash" == "$expected_hash" ]]; then
                echo "NOOP  ${name} :: hash already up to date"
                continue
            fi
            write_hash "$name" "$new_hash"
            echo "LOCK  ${name} :: ${expected_hash} -> ${new_hash}"
            ;;
    esac
done < <(list_skills)

echo
echo "Mode: ${MODE}; Processed ${processed} skill(s); ${errors} issue(s)."
[[ "$errors" -eq 0 ]] || exit 1
