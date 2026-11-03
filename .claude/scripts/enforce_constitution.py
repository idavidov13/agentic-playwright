#!/usr/bin/env python3
"""Deterministic enforcement of the AGENTS.md Constitution.

Two modes:

1. PreToolUse hook (default, stdin JSON) -- blocks Write / Edit / MultiEdit
   tool calls that would introduce content forbidden by the MUST / WON'T
   lists. The agent-facing rules stay in AGENTS.md and the skills; this
   hook is the hard backstop for the subset of rules that can be checked
   mechanically. Comments are blanked before matching (a `//` note about
   `waitForTimeout` is not a hard wait); string literals are kept because
   several rules match string content. Write is judged on the whole file;
   Edit and MultiEdit are applied to the file in memory and judged on what
   they add relative to the current content, so a pre-existing violation
   elsewhere in the file does not block an unrelated edit.

2. Scan mode (`--scan file1 file2 ...`) -- applies the same rules to whole
   files on disk and prints one line per violation:
       <rule-id>\t<path>:<line>:<matched text>
   Exit 0 = clean, 1 = violations found. This is the single source of truth
   the pr-reviewer's scan-constitution.sh delegates to, so the hook and the
   review-time scan can never drift apart.

Rule ids are marked with `# hook-rule-id` comments — scripts/check-rules-drift.sh
and scripts/check-hook-eslint-parity.sh extract them from those markers, so a
new rule without a marker fails the tuple-count cross-check.

Contract (Claude Code hooks):
  stdin  -- JSON payload: {"tool_name": ..., "tool_input": {...}}
  exit 0 -- allow the tool call
  exit 2 -- block the tool call; stderr is fed back to the agent
"""

import json
import os
import re
import sys
import time
from collections import Counter


def _project_root() -> str:
    """Repo root, independent of the CWD the hook was launched from.

    Claude Code sets CLAUDE_PROJECT_DIR for hook commands; when absent
    (scan mode, manual runs) fall back to this script's location —
    .claude/scripts/ is always two levels below the repo root.
    """
    env_root = os.environ.get("CLAUDE_PROJECT_DIR", "")
    if env_root and os.path.isdir(env_root):
        return env_root
    return os.path.dirname(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    )


PROJECT_ROOT = _project_root()


def repo_rel(path: str) -> str:
    """Normalize a path to repo-root-relative with forward slashes.

    A relative path is taken as relative to the project root (not the CWD:
    a session launched from `tests/` would otherwise mis-relativize every
    path and silently disable the path-scoped rules). `./x`, `a/../x` and a
    symlinked root all resolve to the same relative path, so a spelling
    cannot slip past the protected-path gate.
    """
    root = os.path.realpath(PROJECT_ROOT)
    full = path if os.path.isabs(path) else os.path.join(root, path)
    rel = os.path.relpath(os.path.realpath(full), root)
    return rel.replace(os.sep, "/")


# Path scopes are case-insensitive: macOS and Windows disks are, so
# `Tests/x.Spec.ts` is the same file as `tests/x.spec.ts` there.
SPEC_FILE = re.compile(r"(^|/)tests/.+\.(spec|setup)\.ts$", re.I)
SPEC_ONLY_FILE = re.compile(r"(^|/)tests/.+\.spec\.ts$", re.I)
TS_FILE = re.compile(r"\.ts$", re.I)
SCHEMA_FILE = re.compile(r"(^|/)fixtures/api/schemas/.+\.ts$", re.I)
UI_OR_TEST_FILE = re.compile(r"(^|/)(pages|tests)/.+\.ts$", re.I)
STATIC_JSON = re.compile(r"(^|/)test-data/static/.+\.json$", re.I)
STATIC_TS = re.compile(r"(^|/)test-data/static/.+\.ts$", re.I)
# playwright.config.ts included: the single most likely home of a hardcoded
# `baseURL:` (mirrored in eslint.config.mts's URL-rule files array).
TEST_OR_FIXTURE_TS = re.compile(
    r"(^|/)(tests|fixtures|pages|helpers|enums|config)/.+\.ts$"
    r"|(^|/)playwright\.config\.ts$",
    re.I,
)
PAGE_OBJECT_FILE = re.compile(r"(^|/)pages/.+\.(page|component)\.ts$", re.I)
PAGES_TS = re.compile(r"(^|/)pages/.+\.ts$", re.I)

_TAG = r"@(?:smoke|sanity|regression|e2e|api|destructive|functional)(?![\w-])"
TAG_IN_DESCRIBE = re.compile(
    r"(?:test\s*\.\s*)?\bdescribe(?:\s*\.\s*\w+)?\s*\(\s*[`'\"][^`'\"]*" + _TAG
)
# Playwright's official options API: test.describe('t', { tag: '@x' }, fn).
# `[\s\S]{0,200}?` (not `[^}]*`): a nested object before `tag:` — e.g.
# `{ annotation: { type: 'a' }, tag: '@smoke' }` — contains a closing brace
# that `[^}]*` cannot cross; the bounded window keeps false positives out.
DESCRIBE_TAG_OPTION = re.compile(
    r"(?:test\s*\.\s*)?\bdescribe(?:\s*\.\s*\w+)?\s*\(\s*[`'\"][^`'\"\n]*[`'\"]\s*,\s*\{[\s\S]{0,200}?\btag\s*:",
    re.S,
)
# Two sanctioned tags inside ONE string literal — the "exactly one tag" rule.
_ONE_TAG = r"@(?:smoke|sanity|regression|e2e|api|destructive)(?![\w-])"
MULTI_TAG_TITLE = re.compile(
    r"['\"`][^'\"`\n]*" + _ONE_TAG + r"[^'\"`\n]*" + _ONE_TAG
)
MULTI_TAG_ARRAY = re.compile(
    r"\btag\s*:\s*\[\s*['\"`]@[^\]\n]*['\"`]\s*,\s*['\"`]@"
)
# One tag in the title AND a { tag: ... } option = two tags total, split so
# each looked single. `test('... @smoke', { tag: '@regression' }, fn)`.
# Bounded any-char window instead of `[^}]*` — see DESCRIBE_TAG_OPTION.
MULTI_TAG_TITLE_OPTION = re.compile(
    r"\btest(?:\s*\.\s*\w+)?\s*\(\s*[`'\"][^`'\"\n]*"
    + _ONE_TAG
    + r"[^`'\"\n]*[`'\"]\s*,\s*\{[\s\S]{0,200}?\btag\s*:"
)
# A runtime import in static data. Both fully-type-only forms are exempt:
# `import type { A }` AND `import { type A, type B }` — the inline-type
# specifier list erases at compile time exactly like the `import type` form.
NON_TYPE_IMPORT = re.compile(
    r"^\s*import\s+(?!type\b)"
    r"(?!\{(?:\s*type\s+[\w$]+(?:\s+as\s+[\w$]+)?\s*,?)+\s*\}\s*from)",
    re.MULTILINE,
)
# `import type { ... } from '@playwright/test'` is legitimate (types only);
# the ESLint layer exempts it too — only value imports are blocked.
# Newlines may be crossed only INSIDE the specifier braces (Prettier wraps
# long lists); an unbounded `[^;]*?` crossed statement boundaries in
# semicolon-less code and false-positived on a legal `import type` on the
# NEXT line.
PLAYWRIGHT_VALUE_IMPORT = re.compile(
    r"^\s*import\s+(?!type\b)(?:\{[^;}]*\}|[^;{\n])*?"
    r"from\s+['\"]@playwright/test['\"]",
    re.MULTILINE,
)
HARDCODED_URL = re.compile(r"""\b(url|baseUrl|baseURL|apiUrl)\s*:\s*['"`]https?://""", re.I)
HARDCODED_GOTO_URL = re.compile(r"""\.goto\(\s*['"`]https?://""", re.I)
# `\s*` between tokens: Prettier line-wraps long chains (`z\n  .object(`),
# and a formatter must not be able to smuggle a violation past the hook.
# Any receiver (`z`, `zod`, aliased import), `looseObject` (Zod 4's loose
# builder), and `.catchall()` (reopens a strictObject) all count.
LOOSE_SCHEMA = re.compile(
    r"\b[\w$]+\s*\.\s*(?:object|looseObject)\s*\(|\.\s*catchall\s*\("
)
# Direct call, computed-member access, the setTimeout-Promise equivalent, and
# the `timers/promises` import (its `setTimeout(ms)` IS a sleep).
# The setTimeout arm allows newlines between `new Promise` and `setTimeout`
# (bounded window) so the idiomatic multi-line sleep is caught, not just the
# one-liner; `[^;\n]*` used to let the multi-line form slip.
HARD_WAIT = re.compile(
    r"\bwaitForTimeout\s*\(|\[\s*['\"]waitForTimeout['\"]\s*\]|\bnew\s+Promise\b[\s\S]{0,80}?\bsetTimeout\b"
    r"|from\s*['\"](?:node:)?timers/promises['\"]|\brequire\(\s*['\"](?:node:)?timers/promises['\"]"
)
# XPath: `xpath=` inside a string, a selector-taking call whose string starts
# with `//` (incl. parenthesized `('(//div)[1]')`) or `..`, or an axis
# (descendant:: …) at string start. Quote context is required so a prose
# comment mentioning `xpath=` is not a violation.
# Selector-taking calls: locator/frameLocator on ANY receiver, plus the
# deprecated page.* selector-string APIs (click/fill/waitForSelector/...).
# The deprecated set requires a literal `page.` receiver: on a locator these
# methods take a VALUE, not a selector, and `locator.fill('//x')` would
# false-positive.
_SELECTOR_CALL = (
    r"(?:locator|frameLocator)\(|"
    r"page\s*\.\s*(?:click|dblclick|fill|check|uncheck|hover|tap|type|"
    r"selectOption|dispatchEvent|waitForSelector|setChecked|setInputFiles|"
    r"press)\s*\("
)
XPATH_SELECTOR = re.compile(
    r"""['"`][^'"`\n]*xpath=|(?:"""
    + _SELECTOR_CALL
    + r""")\s*['"`](\s|\()*//|(?:"""
    + _SELECTOR_CALL
    + r""")\s*['"`]\.\.(?:['"`]|/)|['"`]\s*\(*(?:descendant|descendant-or-self|ancestor|ancestor-or-self|following|following-sibling|preceding|preceding-sibling|child|parent|self)::"""
)
# `new LoginPage(page)` and member forms like `new pages.LoginPage(page)`.
MANUAL_INSTANTIATION = re.compile(
    r"new\s+(?:[\w$]+\s*\.\s*)*[A-Z][A-Za-z0-9_]*(?:Page|Component)\s*\("
)
INLINE_UNIVERSAL_INVALIDS = re.compile(
    r"\[\s*123\s*,\s*true\s*,\s*null\s*,\s*undefined"
)
# A tag outside the sanctioned six, on a test-level call: in the title
# (`test('x @nightly'`) or in the `{ tag }` option (string or array).
# `@functional` has its own rule. The lookbehind keeps `user@example.com`
# out: a tag is preceded by a quote, whitespace or a paren, never a word
# character or a dot. describe/step titles are not test-level calls.
_KNOWN_TAG = r"(?:smoke|sanity|regression|e2e|api|destructive|functional)(?![\w-])"
_UNKNOWN_TAG_TOKEN = r"(?<![\w.\-])@(?!" + _KNOWN_TAG + r")[A-Za-z][\w-]*"
UNKNOWN_TAG = re.compile(
    r"\btest(?:\s*\.\s*(?!describe\b|step\b)\w+)?\s*\(\s*[`'\"][^`'\"\n]*"
    + _UNKNOWN_TAG_TOKEN
    + r"|\btag\s*:\s*(?:\[\s*)?[`'\"]" + _UNKNOWN_TAG_TOKEN
    + r"|\btag\s*:\s*\[[^\]\n]*,\s*[`'\"]" + _UNKNOWN_TAG_TOKEN
)
# A JSDoc block (`/** ... */`) directly before a locator getter. Line
# comments (`// ...`) are fine; JSDoc belongs on action methods. The block
# body cannot contain `*/`, so a JSDoc on an action method can never pair
# with a later getter.
JSDOC_ON_LOCATOR = re.compile(
    r"/\*\*(?:(?!\*/)[\s\S])*\*/\s+(?:(?:public|protected|private|readonly)\s+)*"
    r"get\s+[\w$]+\s*\(\s*\)\s*:\s*Locator\b"
)
# Inline text in a text matcher or getByText(): a quoted string that
# starts with content, or a template that does not open with `${`.
# An empty string (`toHaveValue('')`) is not content.
_INLINE_TEXT_ARG = r"\(\s*(?:['\"][^'\"]|`(?!\$\{))"
HARDCODED_TEST_CONTENT = re.compile(
    r"\.(?:toHaveText|toContainText|toHaveValue|toHaveTitle)" + _INLINE_TEXT_ARG
    + r"|\bgetByText" + _INLINE_TEXT_ARG
)
# A test-level call whose title literal is followed by something other than
# a `{ tag }` option: the title must carry a tag. "Exactly one tag" has a
# lower bound too; `npm run test:smoke` and friends filter by tag, so an
# untagged test never runs in a tagged run. describe/step/beforeEach never
# match (the callee list is test + its modifiers, and the first argument must
# be a string literal). Setup projects (`*.setup.ts`) run as dependencies
# and carry no tag by design: the rule's path scope is `*.spec.ts` only.
UNTAGGED_TEST = re.compile(
    r"\btest(?:\s*\.\s*(?:only|skip|fixme|fail|slow))?\s*\(\s*(['\"`])"
    r"((?:(?!\1)[^\n])*)\1\s*,\s*(?![\s{])"
)
_ANY_TAG_TOKEN = re.compile(r"(?<![\w.\-])@[A-Za-z]")


def missing_tag(content: str):
    """First test-level call with a literal title that carries no `@tag`."""
    for m in UNTAGGED_TEST.finditer(content):
        if not _ANY_TAG_TOKEN.search(m.group(2)):
            return m
    return None


# An inline directive that switches a scaffold/* rule off for a line, or all
# rules off for the file. Checked on the raw content (it IS a comment).
ESLINT_DISABLE_SCAFFOLD = re.compile(
    r"eslint-disable(?:-next-line|-line)?\b[^\n]*\bscaffold/|/\*\s*eslint-disable\s*\*/"
)
# Rules that read the file as written; every other rule sees the content
# with comments blanked (see strip_comments).
RAW_CONTENT_RULES = {"no-eslint-disable-scaffold"}

# Enforcement infrastructure: agent Write/Edit here would rewrite the rules,
# the hook wiring, or forge exploration evidence — the [protected-path] gate
# blocks it (the Bash write-guard blocks the shell side of the same hole).
# Humans edit these files normally; hooks only run on agent tool calls.
PROTECTED_PATH = re.compile(
    # Unanchored on the left: a nested copy (a git worktree under
    # .claude/worktrees/, a scaffolded project inside this one) is the same
    # hole one level down.
    r"(?:^|/)(?:\.claude/scripts/|\.claude/settings(?:\.local)?\.json$|\.playwright-cli/)",
    re.I,
)

# Explore-before-generate marker: scripts/playwright-cli.sh touches this file
# when an exploration command (open/goto/snapshot/click/...) runs. Creating a
# NEW page object without a fresh marker means selectors are being invented
# instead of explored.
EXPLORE_MARKER = ".playwright-cli/.last-explored"
EXPLORE_MARKER_MAX_AGE_MIN = int(os.environ.get("EXPLORE_MARKER_MAX_AGE_MIN", "240"))

# (rule id, path predicate, content predicate or None, message)
# content predicate None => the write itself is forbidden for matching paths.
# Every id line carries a `# hook-rule-id` marker — the drift/parity gates
# extract ids from the markers and cross-check the count of rule tuples.
RULES = [
    (
        "no-playwright-test-import",  # hook-rule-id
        lambda p: SPEC_FILE.search(p),
        lambda c: PLAYWRIGHT_VALUE_IMPORT.search(c),
        "Spec/setup files must import `test`/`expect` from `fixtures/pom/test-options.ts`, "
        "never from `@playwright/test` (`import type` is fine) "
        "(Constitution MUST: Imports).",
    ),
    (
        "no-hard-wait",  # hook-rule-id
        lambda p: TS_FILE.search(p),
        lambda c: HARD_WAIT.search(c),
        "`waitForTimeout()`, `new Promise(... setTimeout ...)` and `timers/promises` "
        "sleeps are forbidden everywhere. Use web-first assertions, e.g. "
        "`expect(locator).toBeVisible()` (Constitution WON'T: No Hard Waits).",
    ),
    (
        "no-loose-schema",  # hook-rule-id
        lambda p: SCHEMA_FILE.search(p),
        lambda c: LOOSE_SCHEMA.search(c),
        "API schemas must use `z.strictObject()` — never `z.object()`, "
        "`z.looseObject()`, or `.catchall()` "
        "(Constitution WON'T: No Loose Schemas).",
    ),
    (
        "no-xpath",  # hook-rule-id
        lambda p: UI_OR_TEST_FILE.search(p),
        lambda c: XPATH_SELECTOR.search(c),
        "XPath selectors are forbidden. Use getByRole > getByLabel > getByPlaceholder > "
        "getByText > getByTestId (Constitution WON'T: No XPath).",
    ),
    (
        "no-json-static-data",  # hook-rule-id
        lambda p: STATIC_JSON.search(p),
        None,
        "Files under `test-data/static/` must be TypeScript (`.ts` with `as const` exports). "
        "JSON is forbidden (Constitution WON'T: No JSON Static Data).",
    ),
    (
        "no-functional-tag",  # hook-rule-id
        lambda p: SPEC_FILE.search(p),
        lambda c: re.search(r"@functional(?![\w-])", c),
        "The `@functional` tag is forbidden. Use exactly one of @smoke, @sanity, "
        "@regression, @e2e, @api, @destructive (Constitution WON'T: No Multiple Tags).",
    ),
    (
        "no-multiple-tags",  # hook-rule-id
        lambda p: SPEC_FILE.search(p),
        lambda c: MULTI_TAG_TITLE.search(c) or MULTI_TAG_ARRAY.search(c) or MULTI_TAG_TITLE_OPTION.search(c),
        "Multiple tags on one test — each test has exactly ONE tag: @smoke, @sanity, "
        "@regression, @e2e, @api, or @destructive "
        "(Constitution WON'T: No Multiple Tags).",
    ),
    (
        "no-tags-on-describe",  # hook-rule-id
        lambda p: SPEC_FILE.search(p),
        lambda c: TAG_IN_DESCRIBE.search(c) or DESCRIBE_TAG_OPTION.search(c),
        "Tags belong on individual tests, never in `test.describe()` titles or "
        "its `{ tag: ... }` option (Constitution WON'T: No Tags on Describe).",
    ),
    (
        "no-manual-instantiation",  # hook-rule-id
        lambda p: SPEC_FILE.search(p),
        lambda c: MANUAL_INSTANTIATION.search(c),
        "Never `new PageObject(page)` inside test files — use the fixtures from "
        "`fixtures/pom/test-options.ts` (Constitution MUST: Dependency Injection / "
        "WON'T: No Manual Instantiation).",
    ),
    (
        "no-runtime-code-in-static-data",  # hook-rule-id
        lambda p: STATIC_TS.search(p),
        lambda c: re.search(r"\bfaker\.", c) or NON_TYPE_IMPORT.search(c),
        "Files under `test-data/static/` may only export literal values (`as const`). "
        "No Faker calls, no runtime imports (`import type` is fine) — dynamic data "
        "belongs in `test-data/factories/` (data-strategy skill, three-tier rule).",
    ),
    (
        "no-hardcoded-url",  # hook-rule-id
        lambda p: TEST_OR_FIXTURE_TS.search(p),
        lambda c: HARDCODED_URL.search(c),
        "URL literals are forbidden in tests/fixtures/pages/helpers/enums/config — "
        "base URLs come from "
        "`process.env.APP_URL` / `process.env.API_URL` (declared in `env/.env.example`), "
        "paths from `enums/{area}/*` (Constitution MUST: Sources of Truth).",
    ),
    (
        "no-hardcoded-goto-url",  # hook-rule-id
        lambda p: TEST_OR_FIXTURE_TS.search(p),
        lambda c: HARDCODED_GOTO_URL.search(c),
        "`page.goto()` with a URL literal is forbidden — navigate with "
        "`process.env.APP_URL` + a route from `enums/{area}/*` "
        "(Constitution MUST: Sources of Truth).",
    ),
    (
        "no-inline-universal-invalids",  # hook-rule-id
        lambda p: SPEC_FILE.search(p),
        lambda c: INLINE_UNIVERSAL_INVALIDS.search(c),
        "Do not redefine the universal invalid-value arrays inline. Import "
        "`INVALID_*` from `test-data/static/util/invalid-values.ts` "
        "(data-strategy skill: universal arrays are imported, never redefined).",
    ),
    (
        "no-unknown-tag",  # hook-rule-id
        lambda p: SPEC_FILE.search(p),
        lambda c: UNKNOWN_TAG.search(c),
        "Unknown tag — each test carries exactly ONE of @smoke, @sanity, @regression, "
        "@e2e, @api, @destructive (Constitution WON'T: No Multiple Tags).",
    ),
    (
        "no-jsdoc-on-locators",  # hook-rule-id
        lambda p: PAGES_TS.search(p),
        lambda c: JSDOC_ON_LOCATOR.search(c),
        "JSDoc on a locator getter — JSDoc (`@param`, `@returns`) belongs on action "
        "methods only; a `//` line comment is fine "
        "(Constitution WON'T: No JSDoc on Locators).",
    ),
    (
        "no-hardcoded-test-content",  # hook-rule-id
        lambda p: SPEC_FILE.search(p),
        lambda c: HARDCODED_TEST_CONTENT.search(c),
        "Inline text in an assertion or `getByText()` — expected messages come from "
        "`enums/{area}/*`, names and labels from factories or `test-data/static/` "
        "(Constitution WON'T: No Hardcoded Test Content).",
    ),
    (
        "no-missing-tag",  # hook-rule-id
        lambda p: SPEC_ONLY_FILE.search(p),
        lambda c: missing_tag(c),
        "A test without a tag — each test carries exactly ONE of @smoke, @sanity, "
        "@regression, @e2e, @api, @destructive, in the title or the `{ tag }` option "
        "(Constitution WON'T: No Multiple Tags).",
    ),
    (
        "no-eslint-disable-scaffold",  # hook-rule-id
        lambda p: TS_FILE.search(p),
        lambda c: ESLINT_DISABLE_SCAFFOLD.search(c),
        "An inline `eslint-disable` for a `scaffold/*` rule (or for every rule) "
        "switches the Constitution off for that code — fix the content instead "
        "(Constitution MUST: Linting).",
    ),
]


def strip_comments(content: str) -> str:
    """Blank `//` line comments and plain `/* */` blocks, keep everything else.

    Newlines survive (line numbers stay right), string literals survive
    (xpath, tags, URLs and test content are matched inside strings), JSDoc
    blocks (`/**`) survive (no-jsdoc-on-locators needs them) and a regex
    literal in expression position (`= /…/`, `(/…/`, `, /…/`) is copied as
    is, so a `//` inside it is not a comment start. Known blind spot: a
    regex literal after a keyword (`return /a\/\/b/`) reads as division.
    """
    out = []
    i, n = 0, len(content)
    quote = None
    last = ""  # last non-space character emitted outside comments
    while i < n:
        ch = content[i]
        if quote:
            out.append(ch)
            if ch == "\\" and i + 1 < n:
                out.append(content[i + 1])
                i += 2
                continue
            if ch == quote or (ch == "\n" and quote != "`"):
                quote = None
            if not ch.isspace():
                last = ch
            i += 1
            continue
        if ch in ("'", '"', "`"):
            quote = ch
            out.append(ch)
            last = ch
            i += 1
            continue
        if content.startswith("//", i):
            j = content.find("\n", i)
            j = n if j == -1 else j
            out.append(" " * (j - i))
            i = j
            continue
        if content.startswith("/*", i) and not content.startswith("/**", i):
            j = content.find("*/", i + 2)
            j = n if j == -1 else j + 2
            out.append("".join("\n" if c == "\n" else " " for c in content[i:j]))
            i = j
            continue
        if ch == "/" and (last == "" or last in "(,=:[!&|?{};+-*%<>~^"):
            j, in_class = i + 1, False
            while j < n and content[j] != "\n":
                c = content[j]
                if c == "\\":
                    j += 2
                    continue
                if in_class:
                    in_class = c != "]"
                elif c == "[":
                    in_class = True
                elif c == "/":
                    break
                j += 1
            if j < n and content[j] == "/":
                out.append(content[i : j + 1])
                last = "/"
                i = j + 1
                continue
        out.append(ch)
        if not ch.isspace():
            last = ch
        i += 1
    return "".join(out)


def read_existing(rel_path: str) -> "str | None":
    full = os.path.join(os.path.realpath(PROJECT_ROOT), rel_path)
    try:
        with open(full, encoding="utf-8", errors="replace") as fh:
            return fh.read()
    except OSError:
        return None


def apply_edits(text: str, edits: "list[dict]") -> "str | None":
    """Apply Edit/MultiEdit replacements in memory (Claude Code semantics:
    first occurrence, or every occurrence with replace_all). None when one
    cannot apply: the tool call itself would fail, or the shape is unknown."""
    for edit in edits:
        old = edit.get("old_string", "")
        new = edit.get("new_string", "")
        if not isinstance(old, str) or not isinstance(new, str):
            return None
        if old == "" or old not in text:
            return None
        text = text.replace(old, new) if edit.get("replace_all") else text.replace(old, new, 1)
    return text


def content_views(tool_name: str, tool_input: dict, rel_path: str):
    """(old, new, delta): the file before and after this call.

    Write: new is the whole file, judged as a whole (delta False). Edit and
    MultiEdit: the replacements are applied to the file on disk and only
    what they add is judged (delta True). When the file cannot be read or
    an old_string is absent, fall back to the inserted text alone.
    """
    if tool_name == "Write":
        return "", tool_input.get("content", "") or "", False
    edits = [tool_input] if tool_name == "Edit" else list(tool_input.get("edits", []) or [])
    existing = read_existing(rel_path)
    applied = apply_edits(existing, edits) if existing is not None else None
    if applied is None:
        return "", "\n".join(str(e.get("new_string", "") or "") for e in edits), False
    return existing, applied, True


def matched_lines(content_match, content: str):
    """Multiset of matching (stripped) lines, plus the whole-content match."""
    lines = [line.strip() for line in content.splitlines() if content_match(line)]
    return Counter(lines), bool(content_match(content))


def rule_fires(rule_id: str, content_match, old: str, new: str, delta: bool) -> bool:
    """Whole-content judgement, or (delta) only what the call adds: a matching
    line that was not already in the file, or a multi-line match that was not
    already there."""
    raw = rule_id in RAW_CONTENT_RULES
    new_view = new if raw else strip_comments(new)
    if not delta:
        return bool(content_match(new_view))
    old_view = old if raw else strip_comments(old)
    new_lines, new_whole = matched_lines(content_match, new_view)
    old_lines, old_whole = matched_lines(content_match, old_view)
    return bool(new_lines - old_lines) or (new_whole and not old_whole)


def explore_marker_violation(tool_name: str, rel_path: str) -> "str | None":
    """Block creating a NEW page-object/component file without fresh exploration.

    scripts/playwright-cli.sh touches EXPLORE_MARKER when an exploration
    command runs (not on --version/--help/close/state bookkeeping).
    Only file creation is gated — edits to existing page objects are governed
    by the prose rules, so small refactors aren't blocked. An EMPTY existing
    file still counts as creation: `touch pages/x.page.ts` must not skip the
    gate.
    """
    if tool_name != "Write" or not PAGE_OBJECT_FILE.search(rel_path):
        return None
    full_path = os.path.join(PROJECT_ROOT, rel_path)
    try:
        if os.path.exists(full_path) and os.path.getsize(full_path) > 0:
            return None  # editing an existing page object — not gated
    except OSError:
        pass  # unreadable => treat as creation, gate it
    marker = os.path.join(PROJECT_ROOT, EXPLORE_MARKER)
    if not os.path.exists(marker):
        return (
            "Creating a new page object requires live exploration first "
            "(Constitution MUST: Explore Before Generate). Run `playwright-cli` "
            "(open/goto + snapshot) against the real app — the wrapper records "
            f"`{EXPLORE_MARKER}` — then retry. If playwright-cli cannot run, "
            "STOP and notify the human; do not substitute another tool."
        )
    age_min = (time.time() - os.path.getmtime(marker)) / 60
    if age_min > EXPLORE_MARKER_MAX_AGE_MIN:
        return (
            f"Last `playwright-cli` exploration was {age_min:.0f} min ago "
            f"(max {EXPLORE_MARKER_MAX_AGE_MIN}). Re-explore the live page before "
            "creating a new page object (Constitution MUST: Explore Before Generate)."
        )
    return None


def scan(paths: "list[str]") -> int:
    """Apply RULES to whole files on disk. Prints rule-id\tpath:line:text."""
    found = False
    for path in paths:
        # --scan paths come from a shell, so a relative one is relative to the
        # CWD (unlike hook payloads): resolve it here, or a scan run from
        # `tests/` drops the `tests/` prefix and no path-scoped rule applies.
        path = os.path.abspath(path)
        rel_path = repo_rel(path)
        if not os.path.isfile(path):
            continue
        try:
            content = open(path, encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        original_lines = content.splitlines()
        stripped = strip_comments(content)
        for rule_id, path_match, content_match, _message in RULES:
            if not path_match(rel_path):
                continue
            if content_match is None:
                print(f"{rule_id}\t{rel_path}:1:(forbidden file type)")
                found = True
                continue
            view = content if rule_id in RAW_CONTENT_RULES else stripped
            if not content_match(view):
                continue
            hit_lines = [
                (i, original_lines[i - 1].strip())
                for i, line in enumerate(view.splitlines(), 1)
                if content_match(line)
            ]
            if not hit_lines:
                # Multiline-only match (e.g. describe( split across lines).
                m = content_match(view)
                lineno = view[: m.start()].count("\n") + 1 if hasattr(m, "start") else 1
                hit_lines = [(lineno, "(multiline match)")]
            for lineno, text in hit_lines:
                print(f"{rule_id}\t{rel_path}:{lineno}:{text}")
                found = True
    return 1 if found else 0


def hook() -> int:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0  # malformed payload: never block on hook infrastructure errors

    tool_name = payload.get("tool_name", "")
    tool_input = payload.get("tool_input", {}) or {}
    file_path = tool_input.get("file_path", "")
    if not file_path or tool_name not in ("Write", "Edit", "MultiEdit"):
        return 0

    rel_path = repo_rel(file_path)

    if PROTECTED_PATH.search(rel_path):
        print(
            f"BLOCKED by Constitution enforcement hook ({rel_path}):\n"
            "  - [protected-path] Enforcement infrastructure (.claude/scripts/, "
            ".claude/settings.json, .claude/settings.local.json, .playwright-cli/) "
            "is not agent-writable — an agent must not rewrite its own gates, "
            "switch hooks off or forge exploration evidence. Changes here belong "
            "to the human: describe the change and ask them to apply it.",
            file=sys.stderr,
        )
        return 2

    old, new, delta = content_views(tool_name, tool_input, rel_path)
    violations = []
    for rule_id, path_match, content_match, message in RULES:
        if not path_match(rel_path):
            continue
        if content_match is None or rule_fires(rule_id, content_match, old, new, delta):
            violations.append(f"[{rule_id}] {message}")

    marker_msg = explore_marker_violation(tool_name, rel_path)
    if marker_msg:
        violations.append(f"[explore-before-generate] {marker_msg}")

    if violations:
        print(
            f"BLOCKED by Constitution enforcement hook ({rel_path}):\n"
            + "\n".join(f"  - {v}" for v in violations),
            file=sys.stderr,
        )
        return 2
    return 0


def main() -> int:
    # Canary hook: prove the fail-closed guard below actually blocks. The
    # hooks canary sets this to force a crash and asserts exit 2 — see
    # scripts/check-hooks-canary.sh. Never set in normal operation.
    if os.environ.get("_ENFORCE_SELFTEST_CRASH"):
        raise RuntimeError("selftest: forced crash to verify the fail-closed guard")
    if len(sys.argv) > 1 and sys.argv[1] == "--scan":
        return scan(sys.argv[2:])
    return hook()


if __name__ == "__main__":
    # Fail CLOSED on any unexpected crash. A bug in a single rule regex or an
    # os error must BLOCK the write (exit 2), never let it through silently
    # (a bare traceback exits 1, which PreToolUse treats as non-blocking —
    # the exact fail-open hole this layer exists to remove). A malformed
    # payload is handled separately inside hook() and stays fail-open, because
    # that is Claude Code hook-infra noise, not the agent's change.
    #
    # This guard only reaches crashes AFTER module import; a module-level
    # syntax error or a missing python3 exits 1/127 before it runs. Those are
    # covered one layer up: settings.json wraps the hook command with
    # `|| exit 2`, mapping ANY non-zero exit to a block. The CI hooks canary
    # proves both layers on every run.
    try:
        code = main()
    except Exception as exc:  # noqa: BLE001 -- deliberate catch-all, fail closed
        import traceback

        print(
            "BLOCKED — Constitution enforcement hook crashed (failing closed):\n"
            f"  {type(exc).__name__}: {exc}\n"
            "  The write was blocked because enforcement could not run. This is "
            "a bug in the hook, not your change — fix the hook, then retry.",
            file=sys.stderr,
        )
        traceback.print_exc()
        code = 2
    sys.exit(code)
