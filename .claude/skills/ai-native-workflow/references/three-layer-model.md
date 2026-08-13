# The Scaffold's Three-Layer Model

Read this once, then it's invisible.

| Layer                      | What it is                                                                   | When it loads                                                                                    | Who owns it                                |
| -------------------------- | ---------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ | ------------------------------------------ |
| **L1: Orchestrator**       | `CLAUDE.md` — Constitution (MUST/SHOULD/WON'T), Skills Index                 | **Always loaded** at the start of every conversation                                             | Project root                               |
| **L2: Specialized skills** | `.claude/skills/{name}/SKILL.md` — deep rules, phased instructions, examples | **Triggered by description keywords** (skill descriptions are matched against the user's intent) | Each `SKILL.md`'s frontmatter description  |
| **L3: Code conventions**   | The actual TypeScript code: fixtures, page objects, enums, factories, etc.   | **Lives in the repo**; the agent reads it on demand                                              | The codebase + the skills that document it |

The skill suite (L2) is the brain. The orchestrator (L1) is the table of contents. The code (L3) is the truth.

## Why This Layering Matters

**L1 stays small** because it loads on every turn. If a rule is relevant to every task, it lives here. If it's relevant to a subset, it lives in L2.

**L2 loads on demand** via skill descriptions. The frontmatter `description` field is matched against the user's intent. If the description doesn't trigger, the skill never loads — wasted work.

**L3 is read, not summarized.** Skills point at the code (`fixtures/pom/test-options.ts`, `enums/{area}/*`) rather than restating its contents. The code is authoritative; the skills tell the agent where to look.

## Implications for Skill Authors

- Don't restate L1 rules inside L2 skills. Link to `CLAUDE.md` instead.
- Don't restate L3 code shape inside L2 skills. Point at the file.
- L2 cross-references should use the canonical form `→ see \`{skill}\` Phase N` so the linters can validate them. Three linters gate this in CI (`.github/workflows/skill-lint.yml`, or run `npm run check:skills`locally):`scripts/check-rules-drift.sh`(Constitution rules ↔ skill Critical blocks),`scripts/check-skill-references-drift.sh` (`references/`pointers, orphans, anchors),`scripts/check-skill-crossrefs.sh` (Skills Index ↔ disk sync, frontmatter, dangling skill-name refs).
- When L2 grows past ~5000 words, split into `references/` per the Claude Code skills guide.
