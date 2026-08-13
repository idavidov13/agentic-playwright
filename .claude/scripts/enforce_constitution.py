#!/usr/bin/env python3
"""PreToolUse hook: deterministic enforcement of the CLAUDE.md Constitution.

Blocks Write / Edit / MultiEdit tool calls that would introduce content
forbidden by the MUST / WON'T tables. The agent-facing rules stay in
CLAUDE.md and the skills; this hook is the hard backstop for the subset
of rules that can be checked mechanically with zero false-positive risk.

Contract (Claude Code hooks):
  stdin  -- JSON payload: {"tool_name": ..., "tool_input": {...}}
  exit 0 -- allow the tool call
  exit 2 -- block the tool call; stderr is fed back to the agent
"""

import json
import os
import re
import sys

SPEC_FILE = re.compile(r"(^|/)tests/.+\.(spec|setup)\.ts$")
TS_FILE = re.compile(r"\.ts$")
SCHEMA_FILE = re.compile(r"(^|/)fixtures/api/schemas/.+\.ts$")
UI_OR_TEST_FILE = re.compile(r"(^|/)(pages|tests)/.+\.ts$")
STATIC_JSON = re.compile(r"(^|/)test-data/static/.+\.json$")

TAG_IN_DESCRIBE = re.compile(
    r"test\.describe(?:\.\w+)?\(\s*[`'\"][^`'\"]*@(smoke|sanity|regression|e2e|api|destructive|functional)"
)

# (rule id, path predicate, content predicate or None, message)
# content predicate None => the write itself is forbidden for matching paths.
RULES = [
    (
        "no-playwright-test-import",
        lambda p: SPEC_FILE.search(p),
        lambda c: re.search(r"""from\s+['"]@playwright/test['"]""", c),
        "Spec/setup files must import `test`/`expect` from `fixtures/pom/test-options.ts`, "
        "never from `@playwright/test` (Constitution MUST: Imports).",
    ),
    (
        "no-hard-wait",
        lambda p: TS_FILE.search(p),
        lambda c: "waitForTimeout(" in c,
        "`waitForTimeout()` is forbidden everywhere. Use web-first assertions, e.g. "
        "`expect(locator).toBeVisible()` (Constitution WON'T: No Hard Waits).",
    ),
    (
        "no-loose-schema",
        lambda p: SCHEMA_FILE.search(p),
        lambda c: re.search(r"\bz\.object\(", c),
        "API schemas must use `z.strictObject()`, never `z.object()` "
        "(Constitution WON'T: No Loose Schemas).",
    ),
    (
        "no-xpath",
        lambda p: UI_OR_TEST_FILE.search(p),
        lambda c: re.search(r"""xpath=|locator\(\s*[`'\"]//""", c),
        "XPath selectors are forbidden. Use getByRole > getByLabel > getByPlaceholder > "
        "getByText > getByTestId (Constitution WON'T: No XPath).",
    ),
    (
        "no-json-static-data",
        lambda p: STATIC_JSON.search(p),
        None,
        "Files under `test-data/static/` must be TypeScript (`.ts` with `as const` exports). "
        "JSON is forbidden (Constitution WON'T: No JSON Static Data).",
    ),
    (
        "no-functional-tag",
        lambda p: SPEC_FILE.search(p),
        lambda c: "@functional" in c,
        "The `@functional` tag is forbidden. Use exactly one of @smoke, @sanity, "
        "@regression, @e2e, @api, @destructive (Constitution WON'T: No Multiple Tags).",
    ),
    (
        "no-tags-on-describe",
        lambda p: SPEC_FILE.search(p),
        lambda c: TAG_IN_DESCRIBE.search(c),
        "Tags belong on individual tests, never in `test.describe()` titles "
        "(Constitution WON'T: No Tags on Describe).",
    ),
]


def added_content(tool_name: str, tool_input: dict) -> str:
    """Return only the text this tool call would add to the file."""
    if tool_name == "Write":
        return tool_input.get("content", "")
    if tool_name == "Edit":
        return tool_input.get("new_string", "")
    if tool_name == "MultiEdit":
        return "\n".join(
            edit.get("new_string", "") for edit in tool_input.get("edits", [])
        )
    return ""


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0  # malformed payload: never block on hook infrastructure errors

    tool_name = payload.get("tool_name", "")
    tool_input = payload.get("tool_input", {}) or {}
    file_path = tool_input.get("file_path", "")
    if not file_path or tool_name not in ("Write", "Edit", "MultiEdit"):
        return 0

    rel_path = os.path.relpath(file_path).replace(os.sep, "/")
    content = added_content(tool_name, tool_input)

    violations = []
    for rule_id, path_match, content_match, message in RULES:
        if not path_match(rel_path):
            continue
        if content_match is None or content_match(content):
            violations.append(f"[{rule_id}] {message}")

    if violations:
        print(
            f"BLOCKED by Constitution enforcement hook ({rel_path}):\n"
            + "\n".join(f"  - {v}" for v in violations),
            file=sys.stderr,
        )
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
