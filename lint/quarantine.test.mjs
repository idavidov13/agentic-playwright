import { RuleTester } from 'eslint';
import rule from './quarantine.mjs';

const tester = new RuleTester({ languageOptions: { ecmaVersion: 2022 } });
const annotation =
    "{ annotation: { type: 'quarantine', description: 'owner=@alice; until=2028-02-29' } }";
tester.run('quarantine', rule, {
    valid: [
        `test.fixme('flaky', ${annotation}, () => {});`,
        `test.describe.fixme('group', ${annotation}, () => {});`,
        `test.skip('flaky', ${annotation}, () => {});`,
        "// FIXME: https://example.com/issue/1\ntest.skip('contract', () => {});",
        'other.fixme(true);',
    ],
    invalid: [
        "test.fixme('missing', () => {});",
        "test.fixme(true, 'reason');",
        "test.skip('missing', () => {});",
        "// FIXME: later\ntest.skip('missing', () => {});",
        `test.fixme('bad date', ${annotation.replace('2028-02-29', '2027-02-29')}, () => {});`,
        `test.fixme('missing owner', ${annotation.replace('owner=@alice; ', '')}, () => {});`,
    ].map((code) => ({ code, errors: [{ messageId: 'quarantine' }] })),
});
