#!/usr/bin/env bash
# verify-changed.sh — pr-reviewer step 4: lint, format-check and type-check the
# TypeScript files the branch changed (three-dot diff against the base).
#
# Usage: scripts/verify-changed.sh <base-ref>        # e.g. origin/main
# Exit: 0 every check clean on the changed files · 1 a check failed · 2 usage.
# tsc errors outside the changed files are printed separately, never discarded:
# a changed type can break an unchanged consumer.

set -uo pipefail

BASE="${1:-}"
[[ -n "$BASE" ]] || { echo "usage: $0 <base-ref>" >&2; exit 2; }
cd "$(git rev-parse --show-toplevel)"
git rev-parse --verify --quiet "$BASE" >/dev/null || { echo "ERROR: cannot resolve '$BASE'." >&2; exit 2; }

# lint-fixtures/ holds deliberate violations (proven by check:enforcement);
# linting them here would report the violations as the branch's own.
CHANGED="$(git diff "$BASE"...HEAD --name-only --diff-filter=d -- '*.ts' ':!lint-fixtures')"
if [[ -z "$CHANGED" ]]; then
    echo "no changed TypeScript files"
    exit 0
fi
printf 'changed TypeScript files:\n%s\n\n' "$CHANGED"
status=0

echo "== eslint"
echo "$CHANGED" | xargs npx eslint --max-warnings 0 --no-warn-ignored || status=1
echo "== prettier"
echo "$CHANGED" | xargs npx prettier --check || status=1

# Whole-project tsc (single-file tsc ignores tsconfig.json), output split by path.
echo "== tsc (changed files)"
TSC_OUT="$(npx tsc --noEmit 2>&1 || true)"
IN_CHANGED="$(printf '%s\n' "$TSC_OUT" | grep -F -f <(printf '%s\n' "$CHANGED") || true)"
OUTSIDE="$(printf '%s\n' "$TSC_OUT" | grep -E 'error TS[0-9]+' | grep -v -F -f <(printf '%s\n' "$CHANGED") || true)"
if [[ -n "$IN_CHANGED" ]]; then
    printf '%s\n' "$IN_CHANGED"
    status=1
else
    echo "clean"
fi
if [[ -n "$OUTSIDE" ]]; then
    echo "== tsc errors outside the changed files (pre-existing on the base, or broken by a changed type; check the base)"
    printf '%s\n' "$OUTSIDE"
fi
exit "$status"
