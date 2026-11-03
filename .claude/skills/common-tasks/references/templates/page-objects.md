# Page object templates

Prompt templates for page objects. `page-objects` and `selectors` own the rules; `playwright-cli` is the only exploration tool. Resolve `{area}` with `ls pages/` first.

## Add a page object (with exploration)

```
Create a page object for [PAGE NAME].

Run `ls pages/` to find the real area folder, then explore [URL] with playwright-cli (goto, snapshot) to discover:
- element roles, labels and accessible names
- form fields and their validation messages
- buttons and the actions they trigger
- dynamic content and loading states

Generate pages/{area}/[name].page.ts from the snapshot and register it in fixtures/pom/page-object-fixture.ts, following the page-objects and selectors skills.
```

## Add a page object (exploration already done)

Use only when the element structure comes from a `playwright-cli` snapshot taken in this session or supplied by a human; "I know what the page looks like" does not qualify.

```
Create a page object for [PAGE NAME] from the attached playwright-cli snapshot:
- elements: [list]
- actions: [list]

Location pages/{area}/[name].page.ts (run `ls pages/` first); pattern file pages/app/app.page.ts. Register it in fixtures/pom/page-object-fixture.ts. Follow the page-objects and selectors skills.
```

## Add locators to an existing page object

```
Add these locators to [PAGE NAME]:
- [element 1]: [description]
- [element 2]: [description]

Follow the existing getter pattern and the selectors skill's priority order.
```

## Add an action method

```
Add an action method to [PAGE NAME]:
- name: [methodName]
- purpose: [what it does]
- parameters: [list]
- waits for: [API response or element state]

Explicit return type and JSDoc with @param and @returns, per the page-objects skill.
```
