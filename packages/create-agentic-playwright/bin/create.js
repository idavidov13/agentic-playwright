#!/usr/bin/env node
/**
 * create-agentic-playwright — scaffold a new Agentic Playwright project.
 *
 * Usage:
 *   npm create agentic-playwright@latest . -- --demo         # try it: no questions, green in minutes
 *   npm create agentic-playwright@latest .                   # interactive (3 questions)
 *   npm create agentic-playwright@latest . -- --bare         # your own app, no demo
 *   npm create agentic-playwright@latest my-tests -- --demo  # into ./my-tests
 *
 *   `.` scaffolds into the current (empty) folder; a name creates that subfolder.
 *   With npm, `--` passes the flags through npm to the initializer
 *   (pnpm, yarn and bun do not need it).
 *
 * Mode (at most one):
 *   --demo            No questions. Demo API (practicesoftwaretesting.com), both
 *                     skill trees, install deps + browser, run the @smoke test.
 *   --bare            Your own app: asks for its URLs and credentials, no smoke run.
 *                     Add --yes for no questions (placeholders in env/.env.dev).
 *
 * AI rules (AGENTS.md always ships):
 *   --no-claude       Leave out Claude Code: .claude/ and CLAUDE.md, which also
 *                     removes the write-time hook and the commit-time scan.
 *   --no-agents       Leave out the other agents (Codex, Cursor, GitHub Copilot, ...):
 *                     .agents/ and .github/prompts/. With --no-claude, .agents/
 *                     stays: AGENTS.md needs one skill tree.
 *
 * Skip steps:
 *   --skip-install    Do not run npm install (implies --skip-browsers, --skip-smoke).
 *   --skip-browsers   Do not download the Playwright browser.
 *   --skip-git        Do not run git init / initial commit.
 *   --skip-smoke      Do not run the @smoke verification test.
 *
 *   --help            Show this help.
 */

const { spawnSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');
const readline = require('node:readline/promises');

const TEMPLATE_DIR = path.resolve(__dirname, '..', 'template');

const DEMO_ENV = {
    APP_URL: 'https://practicesoftwaretesting.com',
    API_URL: 'https://api.practicesoftwaretesting.com',
    APP_EMAIL: 'customer@practicesoftwaretesting.com',
    APP_PASSWORD: 'welcome01',
};

// ---------------------------------------------------------------- branding

const BRAND_ART = String.raw`
     _             _      ___      _
    / \   _ __ ___| |__  / _ \    / \
   / _ \ | '__/ __| '_ \| | | |  / _ \
  / ___ \| | | (__| | | | |_| | / ___ \
 /_/   \_\_|  \___|_| |_|\__\_\/_/   \_\
`
    .split('\n')
    .slice(1, -1);
const BRAND_SUBTITLE = 'Agentic Playwright Test Automation';

/** Prints the ArchQA wordmark; cyan-to-blue fade on TTYs, plain elsewhere. */
function printBrand() {
    const useColor = process.stdout.isTTY && !process.env.NO_COLOR;
    const shades = [51, 45, 39, 33, 27];
    console.log('');
    BRAND_ART.forEach((line, i) => {
        console.log(useColor ? `\x1b[38;5;${shades[i]}m${line}\x1b[0m` : line);
    });
    console.log(
        useColor
            ? `\n  \x1b[1m${BRAND_SUBTITLE}\x1b[0m\n`
            : `\n  ${BRAND_SUBTITLE}\n`
    );
}

// ---------------------------------------------------------------- utilities

const isWindows = process.platform === 'win32';

function log(msg) {
    console.log(msg);
}

function step(msg) {
    console.log(`\n▶ ${msg}`);
}

function fail(msg) {
    console.error(`\nERROR: ${msg}`);
    process.exit(1);
}

/** Run a command with inherited stdio; returns true on exit code 0. */
function run(cmd, args, cwd) {
    const res = spawnSync(cmd, args, {
        cwd,
        stdio: 'inherit',
        shell: isWindows, // npm/npx are .cmd shims on Windows
    });
    return res.status === 0;
}

function copyDir(src, dest) {
    fs.cpSync(src, dest, { recursive: true });
}

// ------------------------------------------------------------------- args

// Flags npm keeps for itself when the `--` is forgotten
// (`npm create agentic-playwright . --demo`): npm warns "Unknown cli config"
// and hands each one to the initializer only as an npm_config_* variable
// (`--demo` -> "true", `--no-claude` -> npm_config_claude=""). `yes` is not
// recovered: npm's own `npm create --yes` sets npm_config_yes too.
const NPM_SWALLOWED = [
    'demo',
    'bare',
    'skip-install',
    'skip-browsers',
    'skip-git',
    'skip-smoke',
];
const NPM_SWALLOWED_NEGATED = ['claude', 'agents'];

function parseArgs(argv, env = process.env) {
    const flags = new Set();
    let dir;
    for (const a of argv) {
        if (a.startsWith('--')) flags.add(a.slice(2));
        else if (!dir) dir = a;
    }
    const recovered = [];
    for (const name of NPM_SWALLOWED) {
        const value = env[`npm_config_${name.replace(/-/g, '_')}`];
        if (value === 'true' && !flags.has(name)) {
            flags.add(name);
            recovered.push(`--${name}`);
        }
    }
    for (const name of NPM_SWALLOWED_NEGATED) {
        const value = env[`npm_config_${name}`];
        if ((value === '' || value === 'false') && !flags.has(`no-${name}`)) {
            flags.add(`no-${name}`);
            recovered.push(`--no-${name}`);
        }
    }
    return { dir, flags, recovered };
}

function printHelp() {
    // The help text is the header comment, up to its closing ` */`.
    const lines = fs.readFileSync(__filename, 'utf8').split('\n');
    const header = lines
        .slice(1, lines.indexOf(' */'))
        .filter((l) => l !== '/**')
        .map((l) => l.replace(/^ \* ?/, ''))
        .join('\n');
    console.log(header);
}

// -------------------------------------------------------------- questions

async function ask(rl, question, def) {
    const suffix = def ? ` (${def})` : '';
    const answer = (await rl.question(`${question}${suffix}: `)).trim();
    return answer || def || '';
}

async function askYesNo(rl, question, defYes) {
    const def = defYes ? 'Y/n' : 'y/N';
    const answer = (await rl.question(`${question} [${def}]: `))
        .trim()
        .toLowerCase();
    if (!answer) return defYes;
    return answer === 'y' || answer === 'yes';
}

// ------------------------------------------------------------ scaffolding

function stampPackageJson(projectDir, projectName) {
    const pkgPath = path.join(projectDir, 'package.json');
    const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
    pkg.name = projectName;
    pkg.version = '0.1.0';
    pkg.private = true;
    pkg.description = `${projectName} — Playwright test automation, scaffolded by create-agentic-playwright.`;
    delete pkg.repository;
    delete pkg.bugs;
    delete pkg.homepage;
    delete pkg.keywords;
    fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 4) + '\n');
}

function stampVersionFiles(projectDir, projectName) {
    fs.writeFileSync(path.join(projectDir, 'VERSION'), '0.1.0\n');
    const today = new Date().toISOString().slice(0, 10);
    fs.writeFileSync(
        path.join(projectDir, 'CHANGELOG.md'),
        `# Changelog\n\nAll notable changes to ${projectName} are documented here.\n\n---\n\n## v0.1.0 -- Project scaffolded -- ${today}\n\nScaffolded with [create-agentic-playwright](https://github.com/idavidov13/agentic-playwright).\n`
    );
}

function stampReadmeTitle(projectDir, projectName) {
    const readmePath = path.join(projectDir, 'README.md');
    if (!fs.existsSync(readmePath)) return;
    const lines = fs.readFileSync(readmePath, 'utf8').split('\n');
    if (lines[0].startsWith('# ')) {
        lines[0] = `# ${projectName}`;
        lines.splice(
            1,
            0,
            '',
            '> Built on [Agentic Playwright](https://github.com/idavidov13/agentic-playwright).'
        );
    }
    fs.writeFileSync(readmePath, lines.join('\n'));
}

function writeEnvFile(projectDir, values) {
    const envDir = path.join(projectDir, 'env');
    fs.mkdirSync(envDir, { recursive: true });
    const content = [
        '# Generated by create-agentic-playwright',
        '# Application under test (UI)',
        `APP_URL=${values.APP_URL}`,
        '',
        '# API under test',
        `API_URL=${values.API_URL}`,
        '',
        '# Authentication Credentials',
        `APP_EMAIL=${values.APP_EMAIL}`,
        `APP_PASSWORD=${values.APP_PASSWORD}`,
        '',
    ].join('\n');
    fs.writeFileSync(path.join(envDir, '.env.dev'), content);
}

function pruneTree(projectDir, relPaths) {
    for (const rel of relPaths) {
        fs.rmSync(path.join(projectDir, rel), { recursive: true, force: true });
    }
}

// AGENTS.md is every tool's Constitution (Claude Code imports it), so no
// flag prunes it.
const CLAUDE_PATHS = ['.claude', 'CLAUDE.md'];
// The other agents' side: the generated skills and the Copilot PR-review prompt.
const AGENTS_PATHS = ['.agents', '.github/prompts'];
// v1 per-tool flags: still accepted so old scripts keep working, prune nothing.
const DEPRECATED_FLAGS = ['no-copilot', 'no-cursor'];

// ------------------------------------------------------------------- main

async function main() {
    const { dir, flags, recovered } = parseArgs(process.argv.slice(2));

    printBrand();

    if (flags.has('help')) {
        printHelp();
        process.exit(0);
    }
    if (!dir) {
        printHelp();
        process.exit(1);
    }
    if (recovered.length) {
        log(
            `  Note: npm kept ${recovered.join(' ')} for itself; applied anyway. Put \`--\` before the flags: npm create agentic-playwright@latest ${dir} -- ${recovered.join(' ')}`
        );
    }
    for (const name of DEPRECATED_FLAGS) {
        if (flags.has(name)) {
            log(
                `  Note: --${name} is deprecated and prunes nothing; use --no-agents to leave out .agents/ (Codex, Cursor, Copilot, ...).`
            );
        }
    }
    if (!fs.existsSync(TEMPLATE_DIR)) {
        fail(
            'Bundled template not found. This is a broken or placeholder package build — please update: npm create agentic-playwright@latest'
        );
    }

    const projectDir = path.resolve(process.cwd(), dir);
    const projectName = path
        .basename(projectDir)
        .toLowerCase()
        .replace(/[^a-z0-9-_.]/g, '-');
    // `.` (or any existing dir) is allowed as long as it holds nothing but
    // repo bookkeeping — a fresh `git clone` of an empty repo qualifies.
    const IGNORED_ENTRIES = new Set(['.git', '.DS_Store', 'Thumbs.db']);
    const existingEntries = fs.existsSync(projectDir)
        ? fs.readdirSync(projectDir).filter((e) => !IGNORED_ENTRIES.has(e))
        : [];
    if (existingEntries.length > 0) {
        fail(`Target directory "${dir}" is not empty.`);
    }
    const hadGitRepo = fs.existsSync(path.join(projectDir, '.git'));

    const demo = flags.has('demo');
    const bare = flags.has('bare');
    const yes = flags.has('yes') || demo;
    if (demo && bare) fail('--demo and --bare are mutually exclusive.');

    // ---- gather answers -------------------------------------------------
    let keepClaude = !flags.has('no-claude');
    let keepAgents = !flags.has('no-agents');
    let env = { ...DEMO_ENV };
    let doInstall = !flags.has('skip-install');
    let doBrowsers = doInstall && !flags.has('skip-browsers');
    let doGit = !flags.has('skip-git');
    let doSmoke = doInstall && !flags.has('skip-smoke') && !bare;

    if (!yes) {
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout,
        });
        // If stdin ends (piped input exhausted), fall back to defaults for the
        // remaining questions instead of exiting mid-scaffold: an unresolved
        // rl.question() promise would otherwise silently end the process.
        let rlClosed = false;
        rl.once('close', () => {
            rlClosed = true;
        });
        const io = {
            question: (q) =>
                rlClosed
                    ? Promise.resolve('')
                    : Promise.race([
                          rl.question(q),
                          new Promise((resolve) =>
                              rl.once('close', () => resolve(''))
                          ),
                      ]),
        };
        log('\ncreate-agentic-playwright — a few questions (Enter = default):');

        keepClaude =
            keepClaude &&
            (await askYesNo(io, '1/3 Include Claude Code (.claude/)?', true));
        keepAgents =
            keepAgents &&
            (await askYesNo(
                io,
                '2/3 Include the other agents: Codex, Cursor, GitHub Copilot, ... (.agents/)?',
                true
            ));

        if (bare) {
            log('3/3 Your application under test:');
            env = {
                APP_URL: await ask(
                    io,
                    '    APP_URL',
                    'https://your-app.example.com'
                ),
                API_URL: await ask(
                    io,
                    '    API_URL',
                    'https://api.your-app.example.com'
                ),
                APP_EMAIL: await ask(io, '    APP_EMAIL', 'user@example.com'),
                APP_PASSWORD: await ask(io, '    APP_PASSWORD', 'change-me'),
            };
        } else {
            const useDemo = await askYesNo(
                io,
                '3/3 Use the public demo API (practicesoftwaretesting.com) so tests run green immediately?',
                true
            );
            if (!useDemo) {
                env = {
                    APP_URL: await ask(
                        io,
                        '    APP_URL',
                        'https://your-app.example.com'
                    ),
                    API_URL: await ask(
                        io,
                        '    API_URL',
                        'https://api.your-app.example.com'
                    ),
                    APP_EMAIL: await ask(
                        io,
                        '    APP_EMAIL',
                        'user@example.com'
                    ),
                    APP_PASSWORD: await ask(
                        io,
                        '    APP_PASSWORD',
                        'change-me'
                    ),
                };
                doSmoke = false; // user's app — example tests target the demo API
            }
        }
        rl.close();
    } else if (bare) {
        env = {
            APP_URL: 'https://your-app.example.com',
            API_URL: 'https://api.your-app.example.com',
            APP_EMAIL: 'user@example.com',
            APP_PASSWORD: 'change-me',
        };
    }

    // ---- scaffold -------------------------------------------------------
    step(`Creating ${projectName} in ${projectDir}`);
    copyDir(TEMPLATE_DIR, projectDir);
    const gitignore = path.join(projectDir, '_gitignore');
    if (fs.existsSync(gitignore)) {
        fs.renameSync(gitignore, path.join(projectDir, '.gitignore'));
    }

    stampPackageJson(projectDir, projectName);
    stampVersionFiles(projectDir, projectName);
    stampReadmeTitle(projectDir, projectName);
    writeEnvFile(projectDir, env);

    // AGENTS.md always ships and its Skills Index points at a skill tree, so
    // at least one tree must stay: pruning both would leave every pointer
    // dangling and the gates red. Keep .agents/ in that case.
    if (!keepClaude && !keepAgents) {
        keepAgents = true;
        log(
            '  Note: AGENTS.md needs one skill tree; keeping .agents/ because .claude/ is pruned.'
        );
    }

    const pruned = [];
    if (!keepClaude) {
        pruneTree(projectDir, CLAUDE_PATHS);
        pruned.push('Claude Code');
        log(
            '  Note: pruning Claude Code also removes the Constitution hook and its commit-time scan (both live in .claude/).'
        );
    }
    if (!keepAgents) {
        pruneTree(projectDir, AGENTS_PATHS);
        pruned.push('the other agents (.agents/, .github/prompts/)');
    }
    if (pruned.length) {
        log(`  Pruned: ${pruned.join(', ')} (the gates tolerate this).`);
    }

    // ---- git ------------------------------------------------------------
    if (doGit && hadGitRepo) {
        log('\n  Existing git repository detected — skipping git init/commit.');
    } else if (doGit) {
        step('Initializing git repository');
        const ok =
            run('git', ['init', '-b', 'main'], projectDir) &&
            run('git', ['add', '-A'], projectDir) &&
            run(
                'git',
                [
                    'commit',
                    '-m',
                    'chore: scaffold with create-agentic-playwright',
                ],
                projectDir
            );
        if (!ok) log('  git unavailable or failed — skipping (not fatal).');
    }

    // ---- install --------------------------------------------------------
    if (doInstall) {
        step('Installing dependencies (npm install)');
        if (!run('npm', ['install'], projectDir)) {
            fail(
                'npm install failed — fix the error above and re-run npm install manually.'
            );
        }
    }
    if (doBrowsers) {
        step('Installing Playwright browser (chromium)');
        if (!run('npx', ['playwright', 'install', 'chromium'], projectDir)) {
            log(
                '  Browser install failed — run `npx playwright install chromium` later.'
            );
            doSmoke = false;
        }
    }

    // ---- verify ---------------------------------------------------------
    let smokeGreen = null;
    if (doSmoke) {
        step('Running the @smoke verification test');
        smokeGreen = run(
            'npx',
            ['playwright', 'test', '--grep', '@smoke'],
            projectDir
        );
    }

    // ---- banner ---------------------------------------------------------
    log('\n----------------------------------------------------------------');
    log(`ArchQA — ${BRAND_SUBTITLE}`);
    log('----------------------------------------------------------------');
    if (smokeGreen === true) {
        log(`✅ ${projectName} is ready — the smoke test just passed.`);
    } else if (smokeGreen === false) {
        log(
            `⚠ ${projectName} scaffolded, but the smoke test failed (demo API may be down).`
        );
    } else {
        log(`✅ ${projectName} scaffolded.`);
    }
    log('\nNext steps:');
    if (dir !== '.') log(`  cd ${dir}`);
    if (!doInstall) log('  npm install && npx playwright install chromium');
    log('  npx playwright test          # run the example suite');
    log('  npm run check:skills         # verify the AI rules layer');
    log('\nAI assistants pick up their rules automatically:');
    if (keepClaude)
        log('  Claude Code — CLAUDE.md (imports AGENTS.md) + .claude/skills/');
    if (keepAgents) {
        log(
            '  Codex, Cursor, GitHub Copilot, ... — AGENTS.md + .agents/skills/'
        );
        log('  Copilot PR review — .github/prompts/pr-reviewer.prompt.md');
    }
    log('\nExploring UI before writing selectors (mandatory workflow):');
    log('  npm run setup:check          # links the playwright-cli wrapper');
    log(
        "  npm run playwright-cli:install-browsers  # Chromium for playwright-cli's own cache"
    );
    log('\nDocs: https://github.com/idavidov13/agentic-playwright');
    log('----------------------------------------------------------------');
}

main().catch((err) => fail(err.stack || String(err)));
