import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';

const fixture = mkdtempSync(path.resolve('tests/quarantine-report-'));
const output = mkdtempSync(path.join(tmpdir(), 'quarantine-summary-'));
const summary = path.join(output, 'summary.md');
try {
    writeFileSync(
        path.join(fixture, 'expired.spec.ts'),
        "test.fixme('expired', { annotation: { type: 'quarantine', description: 'owner=@alice; until=2000-01-01' } }, async () => {});\n"
    );
    execFileSync(process.execPath, ['lint/quarantine-report.mjs'], {
        env: {
            ...process.env,
            GITHUB_STEP_SUMMARY: summary,
            GITHUB_SERVER_URL: 'https://github.com',
            GITHUB_REPOSITORY: 'org/repo',
            GITHUB_SHA: 'abc123',
        },
    });
    const text = readFileSync(summary, 'utf8');
    assert.match(text, /^## Expired test quarantines\n\n/);
    assert.match(text, /owner=@alice; until=2000-01-01/);
    assert.match(
        text,
        /https:\/\/github\.com\/org\/repo\/blob\/abc123\/tests\/.*\/expired\.spec\.ts#L1/
    );
} finally {
    rmSync(fixture, { recursive: true, force: true });
    rmSync(output, { recursive: true, force: true });
}
