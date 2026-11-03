@AGENTS.md

## Claude Code only

- `.claude/skills/` is the canonical skill tree; every other skill tree is generated from it. Edit a skill here only.
- `.claude/settings.json` wires the hooks. **PreToolUse `enforce_constitution.py`** (Write, Edit, MultiEdit) blocks a mechanical Constitution violation before the file is written and names the rule; fix the content, never the hook.
- Status line: `.claude/settings.local.json` runs `python3 .claude/scripts/status_line.py` (per user; README "Claude Code Custom Status Line").
- `.claude/scripts/`, `.claude/settings.json`, `.claude/settings.local.json` and `.playwright-cli/` are protected paths: the hook refuses an agent write there, so describe the change to the human, who applies it.
- A new `*.page.ts` or `*.component.ts` file under `pages/` needs a fresh `playwright-cli` exploration marker (`.playwright-cli/.last-explored`, touched by `scripts/playwright-cli.sh`, 240 minutes max); explore first, then write.
