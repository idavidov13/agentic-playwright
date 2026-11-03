# Reporting

Step 7 of `pr-reviewer`. Fill `assets/report-template.md`: tiered findings (🔴 must-fix, 🟠 should-fix, 🟡 minor), a ✅ Good section, the verification results, a verdict with the confidence score, and open questions for the author. Every ❌ from the checklist appears at its tier.

## Confidence score

- **9 to 10**: the whole diff read, every applicable skill routed, lint and tsc clean on the changed files, every finding tied to a rule or a bug; only trivia uncertain.
- **6 to 8**: something could not be confirmed (tests unrunnable for lack of env, a contract not seen, a data assumption not verified).
- **5 or less**: the diff could not be read in full, the right skills could not be routed, or the branch depends on context not at hand. Say what is missing instead of guessing.

## Posting to GitHub (only when asked)

```bash
gh pr view <branch> --json number,url -q '.number'          # the PR must exist
gh pr review <number> --comment --body-file <report.md>     # whole report as one review
```

Inline findings, one comment per 🔴 or 🟠 finding ("location · problem · fix"), posted as a single review; `commit_id` is the branch's current HEAD and `line` is the line in the new version of the file:

```bash
HEAD_SHA=$(git rev-parse HEAD)
gh api -X POST "repos/{owner}/{repo}/pulls/<number>/reviews" \
  -f commit_id="$HEAD_SHA" -f event="COMMENT" -f body="<short summary>" \
  -F 'comments[][path]=path/to/file.ts' -F 'comments[][line]=42' \
  -F 'comments[][body]=🔴 problem · fix'
```

Repeat the three `comments[]` fields per finding. No PR for the branch: say so and ask whether to open one; never open it unasked.
