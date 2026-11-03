#!/usr/bin/env node
// Cross-platform installer for @playwright/cli's bundled Chromium.
// Bash equivalent: scripts/install-playwright-cli-browsers.sh
//
// Installs into the cache the wrappers read (scripts/playwright-cli.sh and
// .cmd): PLAYWRIGHT_CLI_BROWSERS_PATH, else ~/.cache/playwright-cli-browsers,
// on every machine. The CLI's Playwright differs from the test runner's, and
// in the Dev Container PLAYWRIGHT_BROWSERS_PATH=/ms-playwright is read-only.
// (Before 3.0.1 a local run installed to Playwright's default location, which
// the wrappers never read: "Browser chromium not installed".)
const { execFileSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

const root = process.argv[2] || process.cwd();
const nested = path.join(
    root,
    'node_modules',
    '@playwright',
    'cli',
    'node_modules',
    'playwright'
);
const hoisted = path.join(root, 'node_modules', 'playwright');
const cliPkg = path.join(
    root,
    'node_modules',
    '@playwright',
    'cli',
    'package.json'
);

// Resolve the playwright package that @playwright/cli uses. Prefer the nested
// copy (always correct when present); fall back to the hoisted top-level
// node_modules/playwright IF its version matches the version @playwright/cli
// declares as its dependency. This handles npm hoisting introduced when the
// declared version stops conflicting with the workspace's other deps.
let cliPw;
if (fs.existsSync(nested)) {
    cliPw = nested;
} else if (fs.existsSync(hoisted) && fs.existsSync(cliPkg)) {
    try {
        const declared = (
            JSON.parse(fs.readFileSync(cliPkg, 'utf8')).dependencies || {}
        ).playwright;
        const hoistedVersion = JSON.parse(
            fs.readFileSync(path.join(hoisted, 'package.json'), 'utf8')
        ).version;
        if (declared && declared === hoistedVersion) {
            cliPw = hoisted;
        }
    } catch {
        // fall through to the not-found message below
    }
}

if (!cliPw) {
    console.log(
        `Skipping playwright-cli browsers: neither ${nested} nor a matching hoisted ${hoisted} was found (run npm ci first).`
    );
    process.exit(0);
}

const browsersPath =
    process.env.PLAYWRIGHT_CLI_BROWSERS_PATH ||
    path.join(os.homedir(), '.cache', 'playwright-cli-browsers');
fs.mkdirSync(browsersPath, { recursive: true });
const env = { ...process.env, PLAYWRIGHT_BROWSERS_PATH: browsersPath };

const pkg = JSON.parse(
    fs.readFileSync(path.join(cliPw, 'package.json'), 'utf8')
);
const marker = path.join(browsersPath, `.pw-cli-browsers.${pkg.version}`);
if (fs.existsSync(marker)) {
    console.log(
        `playwright-cli browsers already cached for Playwright ${pkg.version} at ${browsersPath} — skipping download.`
    );
    process.exit(0);
}

console.log(`Installing Chromium for playwright-cli into ${browsersPath} ...`);
execFileSync('node', [path.join(cliPw, 'cli.js'), 'install', 'chromium'], {
    stdio: 'inherit',
    env,
});
fs.writeFileSync(marker, '');
