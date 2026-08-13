#!/usr/bin/env node
/**
 * create-agentic-playwright — scaffold a new Agentic Playwright project.
 *
 * Usage:
 *   npm create agentic-playwright my-tests            # interactive (3 questions)
 *   npm create agentic-playwright my-tests -- --demo  # zero questions, demo API, smoke run
 *   npm create agentic-playwright my-tests -- --bare  # your own app URLs, no smoke run
 *
 * Flags:
 *   --demo            Zero questions. Demo API (practicesoftwaretesting.com),
 *                     all AI rule trees, install deps + browser, run @smoke.
 *   --bare            Prompt for your app's URLs instead of the demo API.
 *   --yes             Accept all defaults for any question not answered by flags.
 *   --no-cursor       Prune the Cursor rule tree (.cursor/).
 *   --no-copilot      Prune the GitHub Copilot rule tree (.github instructions/prompts/skills).
 *   --skip-install    Do not run npm install (implies --skip-browsers, --skip-smoke).
 *   --skip-browsers   Do not download the Playwright browser.
 *   --skip-git        Do not run git init / initial commit.
 *   --skip-smoke      Do not run the @smoke verification test.
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

function parseArgs(argv) {
    const flags = new Set();
    let dir;
    for (const a of argv) {
        if (a.startsWith('--')) flags.add(a.slice(2));
        else if (!dir) dir = a;
    }
    return { dir, flags };
}

function printHelp() {
    const header = fs
        .readFileSync(__filename, 'utf8')
        .split('\n')
        .slice(1, 23)
        .filter((l) => l !== '/**' && l !== ' */')
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

const CURSOR_PATHS = ['.cursor'];
const COPILOT_PATHS = [
    '.github/instructions',
    '.github/prompts',
    '.github/skills',
    '.github/copilot-instructions.md',
];

// ------------------------------------------------------------------- main

async function main() {
    const { dir, flags } = parseArgs(process.argv.slice(2));

    printBrand();

    if (flags.has('help') || !dir) {
        printHelp();
        process.exit(dir ? 0 : 1);
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
    if (fs.existsSync(projectDir) && fs.readdirSync(projectDir).length > 0) {
        fail(`Target directory "${dir}" already exists and is not empty.`);
    }

    const demo = flags.has('demo');
    const bare = flags.has('bare');
    const yes = flags.has('yes') || demo;
    if (demo && bare) fail('--demo and --bare are mutually exclusive.');

    // ---- gather answers -------------------------------------------------
    let keepCursor = !flags.has('no-cursor');
    let keepCopilot = !flags.has('no-copilot');
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
        log('\ncreate-agentic-playwright — a few questions (Enter = default):');

        keepCursor =
            keepCursor &&
            (await askYesNo(rl, '1/3 Include Cursor rules?', true));
        keepCopilot =
            keepCopilot &&
            (await askYesNo(rl, '2/3 Include GitHub Copilot rules?', true));
        log(
            '    (Claude Code rules always ship — they are the canonical tree.)'
        );

        if (bare) {
            log('3/3 Your application under test:');
            env = {
                APP_URL: await ask(
                    rl,
                    '    APP_URL',
                    'https://your-app.example.com'
                ),
                API_URL: await ask(
                    rl,
                    '    API_URL',
                    'https://api.your-app.example.com'
                ),
                APP_EMAIL: await ask(rl, '    APP_EMAIL', 'user@example.com'),
                APP_PASSWORD: await ask(rl, '    APP_PASSWORD', 'change-me'),
            };
        } else {
            const useDemo = await askYesNo(
                rl,
                '3/3 Use the public demo API (practicesoftwaretesting.com) so tests run green immediately?',
                true
            );
            if (!useDemo) {
                env = {
                    APP_URL: await ask(
                        rl,
                        '    APP_URL',
                        'https://your-app.example.com'
                    ),
                    API_URL: await ask(
                        rl,
                        '    API_URL',
                        'https://api.your-app.example.com'
                    ),
                    APP_EMAIL: await ask(
                        rl,
                        '    APP_EMAIL',
                        'user@example.com'
                    ),
                    APP_PASSWORD: await ask(
                        rl,
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

    const pruned = [];
    if (!keepCursor) {
        pruneTree(projectDir, CURSOR_PATHS);
        pruned.push('Cursor');
    }
    if (!keepCopilot) {
        pruneTree(projectDir, COPILOT_PATHS);
        pruned.push('Copilot');
    }
    if (pruned.length) {
        log(`  Pruned rule trees: ${pruned.join(', ')} (gates tolerate this).`);
    }

    // ---- git ------------------------------------------------------------
    if (doGit) {
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
    log(`  cd ${dir}`);
    if (!doInstall) log('  npm install && npx playwright install chromium');
    log('  npx playwright test          # run the example suite');
    log('  npm run check:skills         # verify the AI rule trees');
    log('\nAI assistants pick up their rules automatically:');
    log('  Claude Code — CLAUDE.md + .claude/skills/');
    if (keepCursor) log('  Cursor — .cursor/rules/ + .cursor/skills/');
    if (keepCopilot)
        log('  Copilot — .github/copilot-instructions.md + instructions/');
    log('\nExploring UI before writing selectors (mandatory workflow):');
    log('  npm run setup:check          # links the playwright-cli wrapper');
    log('\nDocs: https://github.com/idavidov13/agentic-playwright');
    log('----------------------------------------------------------------');
}

main().catch((err) => fail(err.stack || String(err)));
