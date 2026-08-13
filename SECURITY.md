# Security Policy

## Supported Versions

Only the latest published release receives security fixes.

## Reporting a Vulnerability

Please **do not** open a public issue for security problems.

Report vulnerabilities privately via [GitHub Security Advisories](https://github.com/idavidov13/agentic-playwright/security/advisories/new) ("Report a vulnerability"). You will receive an acknowledgment within 5 business days.

Please include a description of the issue, steps to reproduce, and the affected version or commit.

## Scope notes

- This scaffold intentionally reads credentials from `process.env.*` and never commits them; `env/.env.*` files (except `env/.env.example`) are git-ignored. If you find a path where a secret could end up tracked, that is in scope.
- The AI rule trees (`.claude/`, `.cursor/`, `.github/`) instruct coding agents. Prompt-injection vectors that could cause an agent following these rules to exfiltrate secrets or run destructive commands are in scope.
