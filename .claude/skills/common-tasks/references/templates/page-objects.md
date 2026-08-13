# Page Object Templates

Prompt templates for page objects and their locators/actions. The `page-objects`, `selectors`, and `playwright-cli` skills own the deep rules; these are 10-15 line starters. Resolve `{area}` with `ls pages/` first.

> **Important:** Before generating page objects, read the `playwright-cli` skill (`.claude/skills/playwright-cli/SKILL.md`) and run **`playwright-cli` in the terminal** (`goto`, `snapshot`, etc.). **Do not** use IDE browser MCP, Cursor browser tools, or any substitute — orchestrator rule **No Substitute UI Exploration**. If the CLI cannot run, stop and notify the human.

## Add a New Page Object (With Exploration)

```
Create a new page object for [PAGE NAME].

First, run `ls pages/` to find the correct area subdirectory (e.g., front-office, back-office).

Then use playwright-cli to navigate to [URL] and explore the page to discover:
- Element roles, labels, and accessible names
- Form field structure and validation
- Button names and available actions
- Any dynamic content or loading states

Then generate the page object with:
- File location: pages/{area}/[name].page.ts  (use real area name from ls)
- Accurate semantic locators based on exploration
- NO JSDoc on locator getters/methods — names are self-documenting
- JSDoc with @param and @returns on action methods only
- Registration in fixtures/pom/page-object-fixture.ts
```

## Add a New Page Object (Without Exploration)

Use this when you already know the exact element structure:

```
Create a new page object for [PAGE NAME] with the following elements:
- [List of elements/locators needed]
- [Actions the page should perform]

Requirements:
- File location: pages/{area}/[name].page.ts  (run `ls pages/` first to find real area name)
- Use semantic locators (getByRole > getByLabel > getByTestId)
- NO JSDoc on locator getters/methods
- JSDoc with @param and @returns on action methods only
- Register in fixtures/pom/page-object-fixture.ts
- Follow the pattern from pages/app/app.page.ts
```

## Add Locators to Existing Page

```
Add the following locators to [PAGE_NAME] page object:
- [Element 1]: [description]
- [Element 2]: [description]

Use getByRole() as the primary selector strategy.
Add getter methods following the existing pattern.
```

## Add Action Method to Page Object

```
Add an action method to [PAGE_NAME] page object:
- Method name: [methodName]
- Purpose: [what it does]
- Parameters: [list parameters]
- Wait for: [API response or element state]

Include proper return type and JSDoc comment.
```
