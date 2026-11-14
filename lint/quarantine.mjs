const value = (object, key) =>
    object?.type === 'ObjectExpression'
        ? object.properties.find(
              (p) =>
                  p.type === 'Property' &&
                  !p.computed &&
                  (p.key.name ?? p.key.value) === key
          )?.value
        : undefined;
const string = (node) =>
    node?.type === 'Literal' && typeof node.value === 'string'
        ? node.value
        : undefined;
const valid = (node) => {
    if (string(value(node, 'type')) !== 'quarantine') return false;
    const description = string(value(node, 'description')) ?? '';
    const date = /(?:^|;\s*)until=(\d{4}-\d{2}-\d{2})(?:;|$)/.exec(
        description
    )?.[1];
    const parsed = date && new Date(`${date}T00:00:00Z`);
    return (
        /(?:^|;\s*)owner=@[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?(?:;|$)/.test(
            description
        ) &&
        !!parsed &&
        !Number.isNaN(parsed.valueOf()) &&
        parsed.toISOString().slice(0, 10) === date
    );
};
const annotated = (details) => {
    const annotation = value(details, 'annotation');
    return annotation?.type === 'ArrayExpression'
        ? annotation.elements.some(valid)
        : valid(annotation);
};
const method = (callee) => {
    if (
        callee?.type !== 'MemberExpression' ||
        callee.computed ||
        !['fixme', 'skip'].includes(callee.property.name)
    )
        return;
    let object = callee.object;
    if (
        object.type === 'MemberExpression' &&
        !object.computed &&
        ['parallel', 'serial'].includes(object.property.name)
    )
        object = object.object;
    if (object.type === 'Identifier' && object.name === 'test')
        return callee.property.name;
    if (
        object.type === 'MemberExpression' &&
        !object.computed &&
        object.object.name === 'test' &&
        object.property.name === 'describe'
    )
        return callee.property.name;
};
export default {
    meta: {
        type: 'problem',
        schema: [],
        messages: {
            quarantine:
                'Use a declaration with a quarantine annotation containing owner=@handle and a valid until=YYYY-MM-DD, or document a contract skip with // FIXME: <ticket-url>.',
        },
    },
    create(context) {
        return {
            CallExpression(node) {
                const kind = method(node.callee);
                if (!kind) return;
                const [title, details] = node.arguments;
                if (string(title) !== undefined && annotated(details)) return;
                if (kind === 'skip') {
                    const comments = context.sourceCode.getCommentsBefore(
                        node.parent
                    );
                    if (
                        comments.some((comment) =>
                            /\bFIXME:\s*https?:\/\/\S+/.test(comment.value)
                        )
                    )
                        return;
                }
                context.report({ node, messageId: 'quarantine' });
            },
        };
    },
};
