#!/bin/sh
# Orca worktree setup hook: seeds a freshly created git worktree with the
# gitignored files that live only in the main checkout.
#
# Wire up: Orca → Settings → Repository Hooks → Setup Script
#   sh "$ORCA_ROOT_PATH/.claude/orca/orca-worktree-setup.sh"
#
# Env provided by Orca: ORCA_ROOT_PATH (main checkout), ORCA_WORKTREE_PATH.
# Both are derived from git when the script is run by hand, from any directory
# inside a worktree.
#
# Flags: --force    overwrite items already present in the worktree
#        --dry-run  print what would be copied, change nothing

set -u

FORCE=0
DRY=0
for arg in "$@"; do
    case "$arg" in
        --force) FORCE=1 ;;
        --dry-run) DRY=1 ;;
        *) printf 'unknown flag: %s\n' "$arg" >&2; exit 2 ;;
    esac
done

# ---------------------------------------------------------------- resolve paths
WT="${ORCA_WORKTREE_PATH:-}"
ROOT="${ORCA_ROOT_PATH:-}"

if [ -z "$WT" ]; then
    # Run by hand: the worktree is the top level of the checkout around $PWD,
    # never $PWD itself, so a run from a subdirectory cannot seed that subdirectory.
    WT=$(git rev-parse --show-toplevel 2>/dev/null) || WT=""
    if [ -z "$WT" ]; then
        printf 'orca-setup: not inside a git checkout (set ORCA_WORKTREE_PATH)\n' >&2
        exit 1
    fi
fi

if [ ! -d "$WT" ]; then
    printf 'orca-setup: worktree path does not exist: %s\n' "$WT" >&2
    exit 1
fi

if [ -z "$ROOT" ]; then
    # A worktree's git common dir is <main>/.git; its parent is the main checkout.
    common=$(git -C "$WT" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || common=""
    [ -n "$common" ] && ROOT=$(dirname "$common")
fi

if [ -z "$ROOT" ] || [ ! -d "$ROOT" ]; then
    printf 'orca-setup: cannot resolve main checkout (set ORCA_ROOT_PATH)\n' >&2
    exit 1
fi

# Never let the hook copy the main checkout onto itself.
if [ "$(cd "$ROOT" && pwd -P)" = "$(cd "$WT" && pwd -P)" ]; then
    printf 'orca-setup: worktree == main checkout (%s), nothing to do\n' "$WT"
    exit 0
fi

printf 'orca-setup: %s\n         -> %s\n\n' "$ROOT" "$WT"

# ------------------------------------------------------------------- copy engine
# Prefer APFS clonefile (-c): instant, copy-on-write, almost no extra disk.
CP_CLONE="cp -Rc"
CP_PLAIN="cp -R"
# The probe writes into the worktree, so a dry run skips it.
if [ "$DRY" = "0" ]; then
    if ! cp -Rc "$ROOT/.gitignore" "$WT/.orca-cp-probe" 2>/dev/null; then
        CP_CLONE="$CP_PLAIN"
        printf 'note: clonefile unavailable, falling back to plain copy\n\n'
    fi
    rm -f "$WT/.orca-cp-probe"
fi

copied=0
skipped=0
missing=0
failed=0

# copy_item <relative path> <mode>
#   req  required: a missing source fails the whole hook
#   opt  optional: a missing source is only noted
copy_item() {
    rel="$1"
    mode="$2"
    src="$ROOT/$rel"
    dst="$WT/$rel"

    if [ ! -e "$src" ]; then
        if [ "$mode" = "req" ]; then
            printf '  MISSING  %s  (required, not in main checkout)\n' "$rel"
            missing=$((missing + 1))
        else
            printf '  absent   %s\n' "$rel"
        fi
        return 0
    fi

    if [ -e "$dst" ] && [ "$FORCE" = "0" ]; then
        printf '  exists   %s  (use --force to overwrite)\n' "$rel"
        skipped=$((skipped + 1))
        return 0
    fi

    if [ "$DRY" = "1" ]; then
        printf '  would    %s\n' "$rel"
        return 0
    fi

    mkdir -p "$(dirname "$dst")"
    [ -e "$dst" ] && rm -rf "$dst"

    # A clone that fails partway leaves a partial $dst; remove it first, or the
    # plain copy would nest inside it (node_modules/node_modules).
    if $CP_CLONE "$src" "$dst" 2>/dev/null || { rm -rf "$dst"; $CP_PLAIN "$src" "$dst"; }; then
        printf '  copied   %s\n' "$rel"
        copied=$((copied + 1))
    else
        rm -rf "$dst"    # a partial copy would read as "exists" on the next run
        printf '  FAILED   %s\n' "$rel"
        failed=$((failed + 1))
    fi
}

# ------------------------------------------------------------------- what to copy
# Required: the worktree cannot lint or run a test without these.
copy_item 'env/.env.dev'  req    # URLs + credentials; playwright.config.ts loads it by default
copy_item 'node_modules'  req    # ~110M; a CoW clone costs seconds and almost no real disk

# Optional: any other environment file (ENVIRONMENT=<name> selects env/.env.<name>).
for envfile in "$ROOT"/env/.env.*; do
    [ -e "$envfile" ] || continue
    name=$(basename "$envfile")
    case "$name" in
        .env.example | .env.dev) continue ;;    # tracked / handled above
    esac
    copy_item "env/$name" opt
done

# Optional: per-user and cached state.
copy_item '.husky/_'                    opt    # core.hooksPath=.husky/_ is relative and the dir is
                                               # gitignored, so without it the worktree commits with
                                               # NO pre-commit gates. `npm ci` recreates it too.
copy_item '.auth'                       opt    # saved storage states; the setup project regenerates them
copy_item '.claude/settings.local.json' opt    # per-user status line wiring

# Tracked, so git already checked them out (nothing to copy):
#   CLAUDE.md AGENTS.md .claude/ .agents/ .playwright/cli.config.json
#
# Deliberately NOT copied:
#   .playwright-cli/   exploration session state AND the `.last-explored` marker.
#                      Copying it would arm the Explore Before Generate gate in a
#                      worktree where no exploration happened. Explore again here.
#   test-results/ playwright-report/ blob-report/    generated output
#   packages/create-agentic-playwright/template/     prepack build output
#   .DS_Store

# ------------------------------------------------------------- dependency check
# node_modules is a copy of the MAIN checkout's install, so it is only as fresh
# as main's last `npm ci`: a merged dependency bump that was never installed
# there, or a branch whose package.json differs, leaves it out of sync. Two
# checks, because neither covers the other:
#   npm ls        node_modules against package.json: a missing, invalid or
#                 extraneous package. It never reads the lockfile.
#   lock_matches  package-lock.json against node_modules/.package-lock.json,
#                 npm's record of what it installed: a bump that stays inside
#                 the package.json range.
# When either fails, reinstall from this worktree's own lockfile. Runs even when
# node_modules was skipped as "exists", which is exactly the stale case.

# Runs in the current directory. Nothing to compare (no lockfile, or an install
# that left no record) counts as a match: `npm ls` is then the only check.
lock_matches() {
    [ -f package-lock.json ] && [ -f node_modules/.package-lock.json ] || return 0
    node -e '
        const fs = require("fs");
        const read = (file) => JSON.parse(fs.readFileSync(file, "utf8")).packages || {};
        const lock = read("package-lock.json");
        const installed = read("node_modules/.package-lock.json");
        for (const [name, want] of Object.entries(lock)) {
            if (!name.startsWith("node_modules/") || want.link) continue; // root project, workspace
            const have = installed[name];
            if (!have && want.optional) continue; // optional package for another platform
            if (!have || have.version !== want.version) process.exit(1);
        }
    ' 2>/dev/null
}

deps_ok() {
    (cd "$1" && npm ls --depth=0 >/dev/null 2>&1 && lock_matches)
}

if ! command -v npm >/dev/null 2>&1 || ! command -v node >/dev/null 2>&1; then
    # Without npm every check below fails, which would read as a broken install.
    printf '\n  skipped  dependency check: npm is not on PATH\n'
    printf '           verify by hand: (cd "%s" && npm ls --depth=0)\n' "$WT"
else
    if [ -d "$ROOT/node_modules" ] && ! deps_ok "$ROOT"; then
        printf '\n  WARN     main checkout node_modules is out of sync with package.json or its lockfile\n'
        printf '           fix at the source: (cd "%s" && npm ci --prefer-offline)\n' "$ROOT"
    fi

    if [ "$DRY" = "1" ]; then
        if deps_ok "$WT"; then
            printf '  in sync  node_modules\n'
        else
            printf '  would    npm ci --prefer-offline  (node_modules absent or out of sync)\n'
        fi
    elif ! deps_ok "$WT"; then
        printf '\n  syncing  node_modules (npm ci --prefer-offline)\n'
        if ci_log=$(cd "$WT" && npm ci --prefer-offline 2>&1) && deps_ok "$WT"; then
            printf '  synced   node_modules\n'
        else
            printf '  FAILED   npm ci in worktree, run it by hand; its last lines:\n'
            printf '%s\n' "$ci_log" | tail -n 15 | sed 's/^/           /'
            failed=$((failed + 1))
        fi
    else
        printf '  in sync  node_modules\n'
    fi
fi

# ------------------------------------------------------------------------ fix-ups
if [ "$DRY" = "0" ]; then
    # No chmod on purpose: cp carries the source's permission bits across.
    find "$WT/.auth" "$WT/.husky/_" -name '.DS_Store' -delete 2>/dev/null
fi

# ------------------------------------------------------------------------ summary
printf '\norca-setup: %d copied, %d skipped, %d missing, %d failed\n' \
    "$copied" "$skipped" "$missing" "$failed"

if [ "$missing" -gt 0 ] || [ "$failed" -gt 0 ]; then
    printf 'orca-setup: worktree is INCOMPLETE\n' >&2
    exit 1
fi

exit 0
