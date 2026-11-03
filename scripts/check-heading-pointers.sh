#!/usr/bin/env bash
# check-heading-pointers.sh — dangling `→ "Heading"` and `\`skill\` step N`
# pointers are drift.
#
# Skills cross-reference each other's sections as `... SKILL.md` → "Heading"
# or `the \`x\` skill → "Heading"`, and each other's Procedure steps as
# `\`api-testing\` step 5`, `\`type-safety\` · steps 2–3` (AI-WORKFLOWS.md) or
# `step 7 of \`api-testing\``. Renaming a heading or renumbering a Procedure
# silently strands every pointer (this class of bug shipped once: three
# files pointed at a selectors heading that had been renamed).
# check-skill-references-drift.sh validates file links; this validates the
# heading and step halves.
#
# Resolution order per pointer line:
#   1. an explicit `skills/<name>/SKILL.md` on the same line
#   2. a `\`<skill>\` skill` mention on the same line
#   3. a `references/<file>` mention on the same line (same skill)
# Lines with a `→ "..."` but NO file/skill mention are not pointers (e.g.
# vendored rubric examples: `PDF form → "Field alignment"`) and are skipped.
#
# A step pointer resolves when 1 <= N <= the number of numbered steps in the
# named skill's `## Procedure` (a skill without one, e.g. a vendored skill,
# is skipped; a skill that does not exist is check-skill-crossrefs' finding).
#
# Exit 0 = all pointers resolve, 1 = dangling pointer(s).

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$REPO_ROOT" <<'PYEOF'
import os
import re
import sys

root = sys.argv[1]
skills_dir = os.path.join(root, ".claude", "skills")
# Claude tree pruned at init (--no-claude): lint the generated copy instead.
if not os.path.isdir(skills_dir):
    skills_dir = os.path.join(root, ".agents", "skills")
if not os.path.isdir(skills_dir):
    print("SKIP: no skill tree present (pruned at init) — nothing to check.")
    sys.exit(0)

POINTER = re.compile(r'→ "([^"]+)"')
EXPLICIT = re.compile(r"skills/([a-z0-9-]+)/SKILL\.md")
# Backtick and bold mention forms — `x` skill / **x** skill — plus a bare
# backtick mention (`x` →) directly before the pointer arrow.
SKILL_MENTION = re.compile(r"[`*]{1,2}([a-z0-9-]+)[`*]{1,2} skill|`([a-z0-9-]+)`\s*→")
REF_MENTION = re.compile(r"`(?:\.claude/skills/[a-z0-9-]+/)?(references/[A-Za-z0-9._-]+\.md)`")

def headings(path):
    try:
        text = open(path, encoding="utf-8").read()
    except OSError:
        return set()
    return {
        m.group(1).strip()
        for m in re.finditer(r"^#{1,6}\s+(.+?)\s*$", text, re.MULTILINE)
    }

STEP_POINTER = re.compile(
    r"`([a-z0-9-]+)`(?:\s*·)?\s+steps?\s+(\d+)(?:\s*[–-]\s*(\d+))?"
    r"|steps?\s+(\d+)(?:\s*[–-]\s*(\d+))?\s+of\s+`([a-z0-9-]+)`"
)

def procedure_steps(skill):
    path = os.path.join(skills_dir, skill, "SKILL.md")
    try:
        text = open(path, encoding="utf-8").read()
    except OSError:
        return None
    m = re.search(r"^## Procedure\s*$(.*?)(?=^## |\Z)", text, re.M | re.S)
    if not m:
        return None
    return len(re.findall(r"^\d+\.\s", m.group(1), re.M))

# Per-file heading cache.
file_headings = {}
md_files = [
    os.path.join(root, "AGENTS.md"),
    os.path.join(root, "CLAUDE.md"),
    os.path.join(root, "AI-WORKFLOWS.md"),
]
for dirpath, dirnames, filenames in os.walk(skills_dir):
    dirnames[:] = [d for d in dirnames if not d.endswith("-workspace")]
    for name in filenames:
        if name.endswith(".md"):
            md_files.append(os.path.join(dirpath, name))
for path in md_files:
    file_headings[path] = headings(path)

def skill_of(path):
    rel = os.path.relpath(path, skills_dir)
    parts = rel.split(os.sep)
    return parts[0] if len(parts) > 1 else None

errors = 0
checked = 0
for path in md_files:
    try:
        lines = open(path, encoding="utf-8").read().splitlines()
    except OSError:
        continue
    for lineno, line in enumerate(lines, 1):
        for m in POINTER.finditer(line):
            heading = m.group(1).strip()
            checked += 1
            # 1. explicit SKILL.md path on the line
            targets = []
            em = EXPLICIT.search(line)
            if em:
                targets.append(
                    os.path.join(skills_dir, em.group(1), "SKILL.md")
                )
            # 2. `x` / **x** skill mention (either alternation group)
            for sm in SKILL_MENTION.finditer(line):
                name = sm.group(1) or sm.group(2)
                candidate = os.path.join(skills_dir, name, "SKILL.md")
                if os.path.isfile(candidate):
                    targets.append(candidate)
            # 3. references/<file> in the same skill
            rm = REF_MENTION.search(line)
            owner = skill_of(path)
            if rm and owner:
                targets.append(os.path.join(skills_dir, owner, rm.group(1)))
            if not targets:
                # No file/skill mention on the line -> not a heading pointer
                # (rubric examples etc.). Skip rather than guess.
                checked -= 1
                continue
            resolved = False
            for t in targets:
                if heading in file_headings.get(t, headings(t)):
                    resolved = True
                    break
            if not resolved:
                rel = os.path.relpath(path, root)
                print(
                    f'DRIFT {rel}:{lineno} :: pointer → "{heading}" '
                    f"does not match any heading in "
                    f"{', '.join(os.path.relpath(t, root) for t in targets) or 'the canonical tree'}"
                )
                errors += 1

step_checked = 0
step_counts = {}
for path in md_files:
    try:
        lines = open(path, encoding="utf-8").read().splitlines()
    except OSError:
        continue
    for lineno, line in enumerate(lines, 1):
        for m in STEP_POINTER.finditer(line):
            skill = m.group(1) or m.group(6)
            first = m.group(2) or m.group(4)
            last = m.group(3) or m.group(5) or first
            if skill not in step_counts:
                step_counts[skill] = procedure_steps(skill)
            count = step_counts[skill]
            if count is None:
                continue  # no Procedure (vendored) or no such skill
            step_checked += 1
            bad = [n for n in (int(first), int(last)) if n < 1 or n > count]
            if bad:
                rel = os.path.relpath(path, root)
                print(
                    f"DRIFT {rel}:{lineno} :: pointer `{skill}` step {first}"
                    + (f"–{last}" if last != first else "")
                    + f" — that Procedure has {count} step(s)"
                )
                errors += 1

print()
print(f"Checked {checked} heading pointer(s) and {step_checked} step pointer(s); {errors} dangling.")
sys.exit(1 if errors else 0)
PYEOF
