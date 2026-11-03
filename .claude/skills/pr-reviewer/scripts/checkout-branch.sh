#!/usr/bin/env bash
# checkout-branch.sh — pr-reviewer step 1: resolve the base branch, refuse a
# dirty tree, fetch the branch and the base, switch to the branch at its
# origin tip.
#
# Usage: scripts/checkout-branch.sh <branch> [base-name]
# Prints BASE=origin/<name> and ORIGINAL_REF=<ref> on success; restore the
# user's checkout after the report with `git switch "$ORIGINAL_REF"`.
# Exit: 0 ok · 2 usage error or unresolvable base · 3 STOP and ask the user
#       (dirty tree, branch missing on origin, local branch has unpushed commits).

set -euo pipefail

BRANCH="${1:-}"
[[ -n "$BRANCH" ]] || { echo "usage: $0 <branch> [base-name]" >&2; exit 2; }
BASE_NAME="${2:-}"

cd "$(git rev-parse --show-toplevel)"

if [[ -n "$(git status --porcelain)" ]]; then
    echo "STOP: the working tree is dirty; commit or stash before the review." >&2
    exit 3
fi

if [[ -z "$BASE_NAME" ]]; then
    BASE_NAME="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || true)"
fi
if [[ -z "$BASE_NAME" ]]; then
    for candidate in main master; do
        if git rev-parse --verify --quiet "origin/$candidate" >/dev/null; then
            BASE_NAME="$candidate"
            break
        fi
    done
fi
[[ -n "$BASE_NAME" ]] || { echo "ERROR: cannot resolve the base branch; pass it as the second argument." >&2; exit 2; }

ORIGINAL_REF="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse HEAD)"

git fetch --quiet origin "$BRANCH" "$BASE_NAME" 2>/dev/null || true
git rev-parse --verify --quiet "origin/$BASE_NAME" >/dev/null || { echo "ERROR: origin/$BASE_NAME does not exist." >&2; exit 2; }
git rev-parse --verify --quiet "origin/$BRANCH" >/dev/null || { echo "STOP: origin/$BRANCH does not exist." >&2; exit 3; }

# A leftover local branch is reset to the origin tip (otherwise old code is
# reviewed), but a local branch carrying unpushed commits is never discarded.
if git rev-parse --verify --quiet "refs/heads/$BRANCH" >/dev/null \
    && ! git merge-base --is-ancestor "$BRANCH" "origin/$BRANCH"; then
    echo "STOP: local '$BRANCH' has commits not on origin; ask before resetting it." >&2
    exit 3
fi

git switch -C "$BRANCH" "origin/$BRANCH" >/dev/null
echo "BASE=origin/$BASE_NAME"
echo "ORIGINAL_REF=$ORIGINAL_REF"
