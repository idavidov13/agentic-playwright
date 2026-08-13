# Kick-off prompt

Paste this, replacing `<branch>`:

> Review PR for branch `<branch>` against the base branch (auto-resolve it; main or master): fetch it, switch to it, then check all diffs against this repo's CLAUDE.md and the skills that apply to the changed files (route by path — api-testing / type-safety / test-standards / data-strategy / page-objects / selectors / fixtures / enums / config / helpers as relevant). Verify with eslint + prettier + tsc on the changed files and attempt the affected tests. Report tiered findings (must-fix / should-fix / minor), what's good, a verdict, and a confidence score. Don't modify anything — just report. After the report, ask me if I want any findings implemented.

Shorter form (the skill fills in the rest):

> PR review on branch `<branch>` against the base branch.
