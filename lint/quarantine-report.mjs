import { ESLint } from 'eslint';
import { appendFile } from 'node:fs/promises';
import { relative } from 'node:path';
import { expiry } from './quarantine.mjs';

const eslint = new ESLint({
    overrideConfig: {
        files: ['tests/**/*.ts', 'tests/**/*.tsx'],
        plugins: { 'quarantine-expiry': { rules: { expired: expiry } } },
        rules: { 'quarantine-expiry/expired': 'warn' },
    },
});
const results = await eslint.lintFiles(['tests']);
const fatal = results.flatMap((result) =>
    result.messages
        .filter((message) => message.fatal)
        .map(
            (message) =>
                `${result.filePath}:${message.line}: ${message.message}`
        )
);
if (fatal.length)
    throw new Error(`Cannot inspect quarantines:\n${fatal.join('\n')}`);
const findings = results.flatMap((result) =>
    result.messages
        .filter((message) => message.ruleId === 'quarantine-expiry/expired')
        .map((message) => ({
            file: relative(process.cwd(), result.filePath),
            ...message,
        }))
);
const rows = findings.map(({ file, line, message }) =>
    process.env.GITHUB_REPOSITORY
        ? `- [${file}:${line}](${process.env.GITHUB_SERVER_URL}/${process.env.GITHUB_REPOSITORY}/blob/${process.env.GITHUB_SHA}/${file}#L${line}): ${message}`
        : `- ${file}:${line}: ${message}`
);
const summary = `## Expired test quarantines\n\n${rows.length ? rows.join('\n') : 'No expired quarantines.'}\n`;
if (process.env.GITHUB_STEP_SUMMARY)
    await appendFile(process.env.GITHUB_STEP_SUMMARY, summary);
else process.stdout.write(summary);
