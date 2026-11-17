/**
 * ESLint rule `quarantine/annotation`: a skipped test says who owns it.
 *
 * Two forms pass, both declarations (`test.skip('title', ...)`), so fixtures
 * and hooks never run:
 *   - a quarantine: `test.fixme` or `test.skip` with an annotation of type
 *     `quarantine` whose description holds `owner=@handle` and
 *     `until=YYYY-MM-DD`, also on `test.describe.*`;
 *   - a contract mismatch: `test.skip` with `// FIXME: <ticket-url>` on the
 *     line above.
 * The title is a string or a template literal (data-driven loops).
 *
 * Everything else is reported: a bare skip, the in-body forms
 * (`test.skip(true, ...)`, `testInfo.skip()`, `test.info().fixme()`) and
 * `test.step.skip()`, none of which can carry an owner. The date is checked
 * for form only; an expired quarantine is not a lint error.
 */
const OWNER = /^@[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?$/;
const DATE = /^\d{4}-\d{2}-\d{2}$/;
const FIXME = /\bFIXME:\s*https?:\/\/\S+/;
const FUNCTIONS = ['ArrowFunctionExpression', 'FunctionExpression'];

const property = (object, key) =>
    object?.type === 'ObjectExpression'
        ? object.properties.find(
              (p) =>
                  p.type === 'Property' &&
                  !p.computed &&
                  (p.key.name ?? p.key.value) === key
          )?.value
        : undefined;
const text = (node) =>
    node?.type === 'Literal' && typeof node.value === 'string'
        ? node.value
        : undefined;
const isTitle = (node) =>
    text(node) !== undefined || node?.type === 'TemplateLiteral';
const isCalendarDate = (value) => {
    if (!DATE.test(value)) return false;
    const parsed = new Date(`${value}T00:00:00Z`);
    return (
        !Number.isNaN(parsed.valueOf()) &&
        parsed.toISOString().slice(0, 10) === value
    );
};
/** `owner=@a; until=2028-12-01` as a map; spaces around `;` and `=` are ignored. */
const fields = (description) =>
    new Map(
        description.split(';').map((part) => {
            const [key, ...rest] = part.split('=');
            return [key.trim(), rest.join('=').trim()];
        })
    );
/** The messageId of what one annotation lacks; undefined when it is valid. */
const lacks = (annotation) => {
    if (text(property(annotation, 'type')) !== 'quarantine')
        return 'quarantine';
    const entries = fields(text(property(annotation, 'description')) ?? '');
    if (!OWNER.test(entries.get('owner') ?? '')) return 'owner';
    if (!isCalendarDate(entries.get('until') ?? '')) return 'until';
};
/** The same for a test's details object, whose annotation is one or a list. */
const problem = (details) => {
    const annotation = property(details, 'annotation');
    const results = (
        annotation?.type === 'ArrayExpression'
            ? annotation.elements
            : [annotation]
    ).map(lacks);
    if (results.includes(undefined)) return;
    return results.find((result) => result !== 'quarantine') ?? 'quarantine';
};
const memberName = (node) =>
    node?.type === 'MemberExpression'
        ? node.computed
            ? text(node.property)
            : node.property.name
        : undefined;
/**
 * What a call skips. `runners` holds `test` and every local alias it was
 * imported under (`import { test as setup }`).
 */
const target = (callee, runners) => {
    const kind = memberName(callee);
    if (kind !== 'fixme' && kind !== 'skip') return;
    const isRunner = (node) =>
        node?.type === 'Identifier' && runners.has(node.name);
    let object = callee.object;
    if (
        (object.type === 'Identifier' && object.name === 'testInfo') ||
        (object.type === 'CallExpression' &&
            memberName(object.callee) === 'info' &&
            isRunner(object.callee.object)) ||
        (memberName(object) === 'step' && isRunner(object.object))
    )
        return { kind, runtime: true };
    if (['parallel', 'serial'].includes(memberName(object)))
        object = object.object;
    if (isRunner(object)) return { kind, group: false };
    if (memberName(object) === 'describe' && isRunner(object.object))
        return { kind, group: true };
};

export default {
    meta: {
        type: 'problem',
        schema: [],
        messages: {
            quarantine:
                'Use a declaration with a quarantine annotation containing owner=@handle and a valid until=YYYY-MM-DD, or document a contract skip with // FIXME: <ticket-url>.',
            owner: 'The quarantine annotation needs owner=@handle, a GitHub handle a human approved.',
            until: 'The quarantine annotation needs until=YYYY-MM-DD, a real calendar date a human approved.',
        },
    },
    create(context) {
        const runners = new Set(['test']);
        return {
            ImportSpecifier(node) {
                if ((node.imported.name ?? node.imported.value) === 'test')
                    runners.add(node.local.name);
            },
            CallExpression(node) {
                const found = target(node.callee, runners);
                if (!found) return;
                const [title, details] = node.arguments;
                const declared = !found.runtime && isTitle(title);
                const messageId = declared ? problem(details) : 'quarantine';
                if (!messageId) return;
                if (
                    declared &&
                    found.kind === 'skip' &&
                    !found.group &&
                    FUNCTIONS.includes(node.arguments.at(-1)?.type) &&
                    context.sourceCode
                        .getCommentsBefore(node.parent)
                        .some((comment) => FIXME.test(comment.value))
                )
                    return;
                context.report({ node, messageId });
            },
        };
    },
};
