## What

<!-- One or two sentences: what does this PR change? -->

## Why

<!-- The problem or motivation. Link the issue if one exists: Fixes #123 -->

## Checklist

- [ ] `npx tsc --noEmit`, `npx eslint .`, `npx prettier --check .` all pass
- [ ] `npm run check:skills` and `npm run check:version` pass
- [ ] Affected Playwright tests run green (`npx playwright test <file>`)
- [ ] Skill changes (if any) are made under `.claude/skills/`, then `npm run skills:sync`
- [ ] Commits are signed off (`git commit -s`, DCO)
