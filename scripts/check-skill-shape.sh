#!/usr/bin/env bash
# check-skill-shape.sh — every scaffold skill keeps the authoring standard's
# shape and size caps.
#
# The caps keep the always-loaded and on-demand context small and the skills
# harness-neutral. Per scaffold skill (vendored skills from skills-lock.json
# are exempt: their text is upstream's):
#
#   SKILL.md        <= 100 lines, <= 600 words; frontmatter holds exactly
#                   `name` (= directory) and `description` (one line,
#                   <= 50 words); one `# Title`; the H2 headings are exactly
#                   `## Critical`, `## Procedure`, `## References` in that
#                   order (the drift gates key on them).
#   ## Critical     <= 25 non-blank lines, <= 250 words.
#   ## Procedure    1 to 8 numbered steps.
#   code fences     <= 6 lines each (longer examples go to references/).
#   references/*.md <= 150 lines, <= 1,000 words each.
#   wording         harness-neutral: no PreToolUse/PostToolUse, settings.json,
#                   .claude/ path, CLAUDE.md or "the enforcement hook blocks"
#                   talk (that belongs to the Claude Code block of CLAUDE.md).
#   all skills      <= 1,500 lines, <= 9,000 words together.
#
# Exit 0 = every cap holds, 1 = a cap is exceeded, 2 = cannot run.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="${REPO_ROOT}/.claude/skills"

if [[ ! -d "${SKILLS_DIR}" ]]; then
    echo "SKIP: ${SKILLS_DIR#"${REPO_ROOT}"/} not present (pruned at init) — nothing to check."
    exit 0
fi

python3 - "${REPO_ROOT}" <<'PYEOF'
import json
import os
import re
import sys

root = sys.argv[1]
skills_dir = os.path.join(root, ".claude", "skills")

CAPS = {
    "skill_lines": 100,
    "skill_words": 600,
    "description_words": 50,
    "critical_lines": 25,
    "critical_words": 250,
    "procedure_steps": 8,
    "fence_lines": 6,
    "reference_lines": 150,
    "reference_words": 1000,
    "total_lines": 1500,
    "total_words": 9000,
}
HEADINGS = ["## Critical", "## Procedure", "## References"]
# Playwright's afterEach/afterAll are hooks too, so "hook" alone is not a hit.
HARNESS = re.compile(
    r"PreToolUse|PostToolUse|settings\.json|\.claude/|CLAUDE\.md|enforcement hook|hook (?:will )?(?:block|refuse|reject)",
)

try:
    lock = json.load(open(os.path.join(root, "skills-lock.json"), encoding="utf-8"))
    vendored = set((lock.get("skills") or {}).keys())
except (OSError, ValueError):
    vendored = set()


def words(text):
    return len(text.split())


def lines(text):
    return text.count("\n") + (1 if text and not text.endswith("\n") else 0)


errors = 0
skills = 0
refs = 0
total_lines = 0
total_words = 0


def fail(skill, msg):
    global errors
    print(f"SHAPE {skill} :: {msg}")
    errors += 1


for name in sorted(os.listdir(skills_dir)):
    skill_md = os.path.join(skills_dir, name, "SKILL.md")
    if not os.path.isfile(skill_md) or name in vendored:
        continue
    skills += 1
    text = open(skill_md, encoding="utf-8").read()
    n_lines, n_words = lines(text), words(text)
    total_lines += n_lines
    total_words += n_words
    if n_lines > CAPS["skill_lines"]:
        fail(name, f"SKILL.md is {n_lines} lines, cap {CAPS['skill_lines']}")
    if n_words > CAPS["skill_words"]:
        fail(name, f"SKILL.md is {n_words} words, cap {CAPS['skill_words']}")

    # frontmatter
    fm = re.match(r"\A---\n(.*?)\n---\n", text, re.S)
    if not fm:
        fail(name, "SKILL.md has no frontmatter block")
        body = text
    else:
        body = text[fm.end():]
        fields = {}
        for line in fm.group(1).splitlines():
            m = re.match(r"^([A-Za-z-]+):\s*(.*)$", line)
            if m:
                fields[m.group(1)] = m.group(2)
            elif line.strip():
                fail(name, f"frontmatter line is not a single-line field: {line[:60]}")
        if set(fields) != {"name", "description"}:
            fail(name, f"frontmatter fields are {sorted(fields)}; expected exactly name and description")
        if fields.get("name") != name:
            fail(name, f"frontmatter name is {fields.get('name')!r}, expected {name!r}")
        desc_words = words(fields.get("description", ""))
        if desc_words > CAPS["description_words"]:
            fail(name, f"description is {desc_words} words, cap {CAPS['description_words']}")

    # headings
    h1 = re.findall(r"^# .+$", body, re.M)
    if len(h1) != 1:
        fail(name, f"expected one `# Title`, found {len(h1)}")
    h2 = re.findall(r"^## .*$", body, re.M)
    if h2 != HEADINGS:
        fail(name, f"H2 headings are {h2}; expected exactly {HEADINGS} in that order")

    # sections
    def section(heading):
        m = re.search(r"^" + re.escape(heading) + r"\s*$(.*?)(?=^## |\Z)", body, re.M | re.S)
        return m.group(1) if m else ""

    critical = section("## Critical")
    crit_lines = len([l for l in critical.splitlines() if l.strip()])
    crit_words = words(critical)
    if crit_lines > CAPS["critical_lines"]:
        fail(name, f"## Critical is {crit_lines} non-blank lines, cap {CAPS['critical_lines']}")
    if crit_words > CAPS["critical_words"]:
        fail(name, f"## Critical is {crit_words} words, cap {CAPS['critical_words']}")
    steps = len(re.findall(r"^\d+\.\s", section("## Procedure"), re.M))
    if steps < 1 or steps > CAPS["procedure_steps"]:
        fail(name, f"## Procedure has {steps} numbered steps, expected 1 to {CAPS['procedure_steps']}")

    # fences
    for m in re.finditer(r"^```[^\n]*\n(.*?)^```", body, re.M | re.S):
        fence_lines = len(m.group(1).splitlines())
        if fence_lines > CAPS["fence_lines"]:
            fail(name, f"a code fence is {fence_lines} lines, cap {CAPS['fence_lines']} (move it to references/)")

    # wording
    for lineno, line in enumerate(text.splitlines(), 1):
        if HARNESS.search(line):
            fail(name, f"SKILL.md:{lineno} names the harness (keep skills harness-neutral): {line.strip()[:80]}")

    # references
    ref_dir = os.path.join(skills_dir, name, "references")
    for dirpath, _dirs, files in os.walk(ref_dir):
        for fname in sorted(files):
            if not fname.endswith(".md"):
                continue
            refs += 1
            rpath = os.path.join(dirpath, fname)
            rtext = open(rpath, encoding="utf-8").read()
            rel = os.path.relpath(rpath, os.path.join(skills_dir, name))
            rl, rw = lines(rtext), words(rtext)
            if rl > CAPS["reference_lines"]:
                fail(name, f"{rel} is {rl} lines, cap {CAPS['reference_lines']}")
            if rw > CAPS["reference_words"]:
                fail(name, f"{rel} is {rw} words, cap {CAPS['reference_words']}")
            for lineno, line in enumerate(rtext.splitlines(), 1):
                if HARNESS.search(line):
                    fail(name, f"{rel}:{lineno} names the harness: {line.strip()[:80]}")

if total_lines > CAPS["total_lines"]:
    print(f"SHAPE all :: the scaffold skills total {total_lines} lines, cap {CAPS['total_lines']}")
    errors += 1
if total_words > CAPS["total_words"]:
    print(f"SHAPE all :: the scaffold skills total {total_words} words, cap {CAPS['total_words']}")
    errors += 1

print()
print(
    f"Checked {skills} scaffold skill(s) and {refs} reference file(s): "
    f"{total_lines}/{CAPS['total_lines']} lines, {total_words}/{CAPS['total_words']} words; {errors} failure(s)."
)
sys.exit(1 if errors else 0)
PYEOF
