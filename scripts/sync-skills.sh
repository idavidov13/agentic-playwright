#!/usr/bin/env bash
# sync-skills.sh — regenerate .agents/skills/ from the canonical .claude/skills/.
#
# .claude/skills/ is the single source of truth (plan D1). .agents/skills/ is
# a byte-for-byte copy read natively by Codex, Cursor and Copilot; it is
# committed and never hand-edited. Run this after any change under
# .claude/skills/ (including `npm run skills:reinstall`), then commit both
# trees. `npm run check:skills-sync` fails when the committed copy differs
# from a fresh regeneration.
#
# No skill is excluded here: the `pro-` exclusion belongs to the open-source
# export. Only build junk is skipped (JUNK below) and removed from the
# destination if it crept in.
#
# Usage:
#   scripts/sync-skills.sh              # regenerate <repo>/.agents/skills/
#   scripts/sync-skills.sh --output DIR # regenerate into DIR (used by the check)
#
# Copies with rsync when it is on PATH, otherwise with a tar pipe (same result:
# a mirror with modes preserved, extra files removed). Set SKILLS_SYNC_NO_RSYNC=1
# to force the tar path (the Dev Container image has no rsync and takes it).
# `--output DIR` empties DIR first: point it at a fresh directory only.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${REPO_ROOT}/.claude/skills"
DST="${REPO_ROOT}/.agents/skills"

JUNK=(
    "__pycache__"
    ".DS_Store"
    "*-workspace"
)

if [[ "${1:-}" == "--output" ]]; then
    [[ -n "${2:-}" ]] || { echo "ERROR: --output needs a directory" >&2; exit 2; }
    DST="$2"
    shift 2
fi
if [[ $# -gt 0 ]]; then
    echo "ERROR: unknown argument(s): $*" >&2
    exit 2
fi

if [[ ! -d "${SRC}" ]]; then
    echo "ERROR: canonical tree not found at ${SRC}" >&2
    exit 2
fi

mkdir -p "${DST}"

if command -v rsync >/dev/null 2>&1 && [[ -z "${SKILLS_SYNC_NO_RSYNC:-}" ]]; then
    # --checksum: the default size+mtime quick check skips a same-size edit
    # made within the second of the last copy (seen: `setup` -> `setup-ui`
    # in a padded table row); content comparison never does.
    args=(-a --checksum --delete --delete-excluded)
    for j in "${JUNK[@]}"; do args+=(--exclude "${j}"); done
    rsync "${args[@]}" "${SRC}/" "${DST}/"
    method="rsync"
else
    # tar pipe: wipe the destination, then stream the source through tar so
    # --exclude applies and modes survive. Identical result to rsync --delete.
    find "${DST}" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
    args=()
    for j in "${JUNK[@]}"; do args+=(--exclude "${j}"); done
    tar -C "${SRC}" "${args[@]}" -cf - . | tar -C "${DST}" -xf -
    method="tar"
fi

count="$(find "${DST}" -type f | wc -l | tr -d ' ')"
echo "Synced ${SRC#"${REPO_ROOT}"/} -> ${DST#"${REPO_ROOT}"/} (${method}, ${count} files)."
