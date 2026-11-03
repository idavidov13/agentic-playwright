#!/usr/bin/env bash
# check-skills-sync.sh — the committed .agents/skills/ equals a fresh
# regeneration from .claude/skills/.
#
# Regenerates with scripts/sync-skills.sh into a temp directory and diffs it
# against .agents/skills/ (both directions: a changed, missing or extra file
# is drift), then compares file types and executable bits (`diff -r` sees
# content only; a script that lost its exec bit in the generated tree fails
# at use while content matches) and refuses symlinks in the generated tree.
# Exit 0 = equal, 1 = drift, 2 = cannot run.
#
# Fix: `npm run skills:sync`, then commit .agents/skills/ with the change.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${REPO_ROOT}/.claude/skills"
DST="${REPO_ROOT}/.agents/skills"
SYNC="${REPO_ROOT}/scripts/sync-skills.sh"

if [[ ! -d "${SRC}" ]]; then
    echo "SKIP: ${SRC#"${REPO_ROOT}"/} not present (pruned at init) — nothing to check."
    exit 0
fi
if [[ ! -d "${REPO_ROOT}/.agents" ]]; then
    echo "SKIP: .agents/ not present (pruned at init) — nothing to compare."
    exit 0
fi
if [[ ! -d "${DST}" ]]; then
    echo "DRIFT: ${DST#"${REPO_ROOT}"/} is missing — run: npm run skills:sync"
    exit 1
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/skills-sync.XXXXXX")"
trap 'rm -rf "${TMP}"' EXIT

bash "${SYNC}" --output "${TMP}/skills" >/dev/null

# Local junk the generator never copies (sync-skills.sh JUNK) and git ignores
# (.DS_Store, __pycache__) is not drift: skip it on both sides.
if diff -r -q -x '__pycache__' -x '.DS_Store' -x '*-workspace' \
    "${TMP}/skills" "${DST}" >"${TMP}/diff.txt" 2>&1; then
    if python3 - "${TMP}/skills" "${DST}" <<'PYEOF'
import fnmatch
import os
import stat
import sys

JUNK = ("__pycache__", ".DS_Store", "*-workspace")

def junk(name):
    return any(fnmatch.fnmatch(name, j) for j in JUNK)

def walk(root):
    out = {}
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if not junk(d)]
        for name in dirnames + [f for f in filenames if not junk(f)]:
            full = os.path.join(dirpath, name)
            rel = os.path.relpath(full, root)
            st = os.lstat(full)
            if stat.S_ISLNK(st.st_mode):
                out[rel] = ("symlink", None)
            elif stat.S_ISDIR(st.st_mode):
                out[rel] = ("dir", None)
            else:
                out[rel] = ("file", "exec" if st.st_mode & 0o111 else "plain")
    return out

fresh, committed = walk(sys.argv[1]), walk(sys.argv[2])
bad = 0
for rel in sorted(set(fresh) | set(committed)):
    if fresh.get(rel) != committed.get(rel):
        print(f"MODE .agents/skills/{rel}: regenerated {fresh.get(rel)} vs committed {committed.get(rel)}")
        bad += 1
    if (committed.get(rel) or ("",))[0] == "symlink":
        print(f"SYMLINK .agents/skills/{rel}: the generated tree holds real files only")
        bad += 1
sys.exit(1 if bad else 0)
PYEOF
    then
        count="$(find "${DST}" -type f ! -name '.DS_Store' ! -path '*/__pycache__/*' | wc -l | tr -d ' ')"
        echo "Skills sync OK: .agents/skills matches .claude/skills (${count} files, content and modes)."
        exit 0
    fi
    echo
    echo "DRIFT: .agents/skills content matches but a file type or mode differs."
    echo "Fix: npm run skills:sync, then commit .agents/skills/ together with the change."
    exit 1
fi

sed -e "s#${TMP}/skills#<regenerated>#g" -e "s#${DST}#.agents/skills#g" "${TMP}/diff.txt"
echo
echo "DRIFT: .agents/skills differs from a fresh regeneration of .claude/skills."
echo "Fix: npm run skills:sync, then commit .agents/skills/ together with the change."
exit 1
