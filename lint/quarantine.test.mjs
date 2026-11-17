import tsParser from '@typescript-eslint/parser';
import { RuleTester } from 'eslint';
import rule from './quarantine.mjs';

const description = 'owner=@alice; until=2028-02-29';
const details = (value = description, extra = '') =>
    `{ ${extra}annotation: { type: 'quarantine', description: '${value}' } }`;
const annotation = details();
const fixme = '// FIXME: https://example.com/issue/1';

const valid = [
    `test.fixme('flaky', ${annotation}, () => {});`,
    `test.describe.fixme('group', ${annotation}, () => {});`,
    `test.describe.parallel.skip('group', ${annotation}, () => {});`,
    `test.describe.serial.fixme('group', ${annotation}, () => {});`,
    `test.skip('flaky', ${annotation}, () => {});`,
    `${fixme}\ntest.skip('contract', () => {});`,
    'other.fixme(true);',
    // The tag every test carries sits beside the annotation or the FIXME.
    `test.fixme('flaky', ${details(description, "tag: '@smoke', ")}, () => {});`,
    `${fixme} spec 422, API 500\ntest.skip('contract', { tag: '@api' }, async () => {});`,
    // Data-driven loops title their tests with a template literal.
    `for (const value of [1]) {\n${fixme}\ntest.skip(\`rejects \${value}\`, { tag: '@api' }, async () => {});\n}`,
    `for (const value of [1]) { test.fixme(\`flaky \${value}\`, ${annotation}, () => {}); }`,
    `${fixme}\ntest.skip(\`contract\`, () => {});`,
    // One quarantine entry in a list of annotations is enough.
    `test.fixme('flaky', { annotation: [{ type: 'issue', description: 'x' }, { type: 'quarantine', description: '${description}' }] }, () => {});`,
    // Field order and the spacing around ';' and '=' do not matter.
    `test.fixme('flaky', ${details('issue=#1; until=2028-02-29; owner=@alice')}, () => {});`,
    `test.fixme('flaky', ${details('owner=@alice ; until = 2028-02-29 ')}, () => {});`,
    `test.fixme('flaky', ${details('owner=@alice;until=2028-02-29;issue=https://example.com/?a=b')}, () => {});`,
    // `test` imported under another name is still the runner.
    `import { test as setup } from './test-options';\nsetup.fixme('flaky', ${annotation}, () => {});`,
    "import { other as setup } from './test-options';\nsetup.skip('not the runner', () => {});",
];

const invalid = [
    ...[
        "test.fixme('missing', () => {});",
        "test.fixme(true, 'reason');",
        "test.skip('missing', () => {});",
        "test['skip']('missing', () => {});",
        "test['describe']['parallel']['fixme']('missing', () => {});",
        `${fixme}\ntest.describe.skip('group', () => { test('one', () => {}); test('two', () => {}); });`,
        "test.describe.parallel.skip('missing', () => {});",
        "test.describe.serial.fixme('missing', () => {});",
        "// FIXME: later\ntest.skip('missing', () => {});",
        `${fixme}\ntest.skip(true, 'reason');`,
        `${fixme}\ntest.skip(() => true, 'reason');`,
        // A FIXME documents a contract skip, never a fixme or a bare template title.
        `${fixme}\ntest.fixme('flaky', () => {});`,
        "test.skip(`missing ${'x'}`, () => {});",
        // The in-body and step forms cannot carry an owner.
        "test('title', async ({}, testInfo) => { testInfo.skip(); });",
        "test('title', async () => { test.info().fixme(); });",
        `${fixme}\ntest('title', async () => { test.info().skip(true, 'reason'); });`,
        "test('title', async () => { await test.step.skip('step', async () => {}); });",
        "import { test as setup } from './test-options';\nsetup.skip('missing', () => {});",
        "import { test as setup } from './test-options';\nsetup('title', async () => { setup.info().fixme(); });",
        // A variable hides the annotation from the rule.
        `const quarantine = ${annotation};\ntest.fixme('flaky', quarantine, () => {});`,
        `test.fixme('flaky', { annotation: { type: 'issue', description: '${description}' } }, () => {});`,
    ].map((code) => [code, 'quarantine']),
    ...[
        details('until=2028-02-29'),
        details('owner=alice; until=2028-02-29'),
        details('owner=@org/team; until=2028-02-29'),
        details('owner=@-alice; until=2028-02-29'),
        details('owner=<@github-handle>; until=<YYYY-MM-DD>'),
    ].map((value) => [`test.fixme('bad owner', ${value}, () => {});`, 'owner']),
    ...[
        details('owner=@alice'),
        details('owner=@alice; until=2027-02-29'),
        details('owner=@alice; until=2028-2-29'),
        details('owner=@alice; until=tomorrow'),
        details('owner=@alice; until=<YYYY-MM-DD>'),
    ].map((value) => [`test.fixme('bad date', ${value}, () => {});`, 'until']),
].map(([code, messageId]) => ({ code, errors: [{ messageId }] }));

// Espree is the default parser; the project lints tests/** with the TypeScript one.
for (const languageOptions of [{ ecmaVersion: 2022 }, { parser: tsParser }])
    new RuleTester({ languageOptions }).run('quarantine', rule, {
        valid,
        invalid,
    });
