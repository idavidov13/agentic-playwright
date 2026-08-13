#!/usr/bin/env node
/**
 * prepack.js — build the bundled template/ payload from the repository root.
 *
 * Runs automatically on `npm pack` / `npm publish` (prepack hook).
 *
 * The manifest is `git ls-files` at the repo root: only git-tracked files can
 * ever enter the tarball, so untracked local files (env/.env.dev, reports,
 * browser caches) are structurally excluded. On top of that, repo-infra files
 * that make sense for the GitHub repository but not for a generated project
 * are excluded explicitly below.
 *
 * npm strips `.gitignore` files from published packages, so the template's
 * .gitignore is stored as `_gitignore` and the CLI renames it back on scaffold.
 */

const { execFileSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');

const PKG_ROOT = path.resolve(__dirname, '..');
const REPO_ROOT = path.resolve(PKG_ROOT, '..', '..');
const TEMPLATE_DIR = path.join(PKG_ROOT, 'template');

/** Repo-infra paths (relative, POSIX) excluded from the template payload. */
const EXCLUDE_PREFIXES = [
    'packages/', // the initializer itself
    '.github/ISSUE_TEMPLATE/', // repo community files
];
const EXCLUDE_FILES = new Set([
    'CHANGELOG.md', // repo history; the CLI writes a fresh one
    'CODE_OF_CONDUCT.md',
    'CONTRIBUTING.md',
    'SECURITY.md',
    '.github/PULL_REQUEST_TEMPLATE.md',
    '.github/dependabot.yml',
]);

function isExcluded(rel) {
    if (EXCLUDE_FILES.has(rel)) return true;
    return EXCLUDE_PREFIXES.some((p) => rel.startsWith(p));
}

function main() {
    const out = execFileSync('git', ['ls-files', '-z'], {
        cwd: REPO_ROOT,
        encoding: 'utf8',
        maxBuffer: 64 * 1024 * 1024,
    });
    const files = out.split('\0').filter(Boolean);
    if (files.length < 100) {
        throw new Error(
            `git ls-files returned only ${files.length} files — refusing to pack a partial template.`
        );
    }

    fs.rmSync(TEMPLATE_DIR, { recursive: true, force: true });

    let copied = 0;
    for (const rel of files) {
        if (isExcluded(rel)) continue;
        const src = path.join(REPO_ROOT, rel);
        // npm strips .gitignore from tarballs — store under a safe name.
        const destRel = rel === '.gitignore' ? '_gitignore' : rel;
        const dest = path.join(TEMPLATE_DIR, destRel);
        fs.mkdirSync(path.dirname(dest), { recursive: true });
        fs.copyFileSync(src, dest);
        copied += 1;
    }

    if (!fs.existsSync(path.join(TEMPLATE_DIR, 'package.json'))) {
        throw new Error('Template payload is missing package.json — aborting.');
    }
    if (!fs.existsSync(path.join(TEMPLATE_DIR, '_gitignore'))) {
        throw new Error('Template payload is missing _gitignore — aborting.');
    }

    console.log(`prepack: bundled ${copied} template files into template/`);
}

main();
