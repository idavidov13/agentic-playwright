---
name: page-objects
description: Page Object Model pattern for the Playwright scaffold — class structure, get-accessor locator pattern, action-method conventions, component composition, registration via the page-object fixture, and the mandatory exploration-first workflow. Use when creating a new page object, adding or updating locators on an existing page object, adding a new reusable component, or registering a page in the fixture layer. For the locator priority order and feedback/validation-message rules see the selectors skill; for the terminal-only live-app exploration tool see the playwright-cli skill; for the DI wiring see the fixtures skill; for UI message strings and endpoint enums see the enums skill.
author: Ivan Davidov
---

# Page Object Model

## Critical

- **Locators are `get` accessors** returning `Locator`. This is a style/readability convention — Playwright's `Locator` is lazy either way (it only queries the DOM when an action runs), so `get` vs `readonly` field behave identically at runtime. Use `get` for consistency with the rest of the scaffold.
- **Constructor uses `private readonly page: Page`.** No other visibility modifiers, no alternative DI patterns.
- **Page objects import `expect, Locator, Page` from `@playwright/test`** — never from `fixtures/pom/test-options.ts` (that's for spec files and fixtures).
- **JSDoc rules:**
    - **Forbidden** on locator getters and on any method that returns a `Locator`. Names are self-documenting.
    - **Required** (with `@param` and `@returns`) on every action method and every verification method.
    - **Allowed** on component fields (e.g. `readonly nav: NavigationComponent`) — these are not locators.
- **Three locator sections** when the page has forms or CRUD: interactive-element locators, feedback/validation-message locators, action methods. Feedback locators are not optional — see the `selectors` skill.
- **Feedback/message strings come from `enums/{area}/*`** (e.g. `Messages.LOGIN_ERROR`). Never hardcoded strings inside `getByText(...)`.
- **NEVER** `page.waitForTimeout(...)` inside a page object. Use web-first assertions (`await expect(locator).toBeVisible()`) or `page.waitForResponse(...)`.
- **Exploration with `playwright-cli` is mandatory** before writing any locators (see the `selectors` skill's Exploration-First Workflow). No guessing from wireframes, docs, or screenshots. If the app is unavailable, stop and say so — never ship placeholder locators.
- **Register every new page object** as a fixture in `fixtures/pom/page-object-fixture.ts`. Tests consume page objects through the fixture, never via `new PageObject(page)`.

## File Locations

> **`{area}` is a placeholder.** Before creating or referencing any path below, run `ls pages/` to discover the real subdirectory names in this repo (e.g., `front-office`, `back-office`) and use those instead.

| Type         | Directory           | Naming                | Scaffold example                                                   |
| ------------ | ------------------- | --------------------- | ------------------------------------------------------------------ |
| Page objects | `pages/{area}/`     | `[name].page.ts`      | `pages/app/app.page.ts` (`AppPage`)                                |
| Components   | `pages/components/` | `[name].component.ts` | `pages/components/navigation.component.ts` (`NavigationComponent`) |

## Page Object Pattern

```typescript
import { expect, Locator, Page } from '@playwright/test';
import { Messages } from '../../enums/app/app';

export class ExamplePage {
    constructor(private readonly page: Page) {}

    // ==================== Locators ====================

    get emailInput(): Locator {
        return this.page.getByLabel('Email');
    }

    get submitButton(): Locator {
        return this.page.getByRole('button', { name: 'Submit' });
    }

    // ==================== Feedback Locators ====================

    get successMessage(): Locator {
        return this.page.getByText(Messages.LOGIN_SUCCESS);
    }

    get errorMessage(): Locator {
        return this.page.getByText(Messages.LOGIN_ERROR);
    }

    get requiredFieldError(): Locator {
        return this.page.getByText(Messages.REQUIRED_FIELD);
    }

    // ==================== Actions ====================

    /**
     * Submits the form and waits for the API response.
     * @param {string} email - The user's email address.
     * @returns {Promise<void>}
     */
    async submitForm(email: string): Promise<void> {
        await this.emailInput.fill(email);
        await this.submitButton.click();
        await this.page.waitForResponse((r) => r.url().includes('/api/submit'));
    }
}
```

Every page object that handles forms or CRUD operations must have three locator sections: interactive element locators, feedback/validation message locators, and action methods. Feedback locators are not optional — see the `selectors` skill for the full list of feedback types to capture.

## Rules

### Locators as getters

Use `get accessor` returning `Locator`. Both `get` and `readonly field` work identically at runtime (Playwright's `Locator` is lazy), but `get` is the scaffold convention — terser, locators stay grouped in the class body, constructor stays focused on dependencies.

```typescript
// PREFERRED -- the scaffold's convention
get submitButton(): Locator {
    return this.page.getByRole('button', { name: 'Submit' });
}
```

### Constructor pattern

```typescript
constructor(private readonly page: Page) {}
```

### No JSDoc on locators

JSDoc is **forbidden** on locator getters and on any method that returns a `Locator`. The name documents what it is:

```typescript
// CORRECT -- no comment needed
get submitButton(): Locator {
    return this.page.getByRole('button', { name: 'Submit' });
}

// WRONG -- locators don't need JSDoc
/** The submit button. */
get submitButton(): Locator {
    return this.page.getByRole('button', { name: 'Submit' });
}
```

JSDoc is **required** on action methods and verification methods (see below).

### Action methods and verification methods

- **Action methods** represent complete user actions (`login()`, `submitForm()`, `addToCart()`).
- **Verification methods** combine an action with a success assertion (`loginAndVerify()`). They may use `expect(...)` internally.
- Plain action methods should not assert — the test asserts. Use a verification method when the success check is re-used across tests.
- Always wait for API responses or state changes inside the method (`page.waitForResponse`, web-first assertions). Never `page.waitForTimeout(...)`.
- Always specify an explicit return type (`Promise<void>` is the common case).
- JSDoc with `@param` and `@returns` is required; an `@example` block is encouraged for non-trivial methods.

### Imports in page objects

Page objects import from `@playwright/test` (not from `test-options.ts`):

```typescript
import { expect, Locator, Page } from '@playwright/test';
```

## Component composition

Reusable UI fragments (headers, modals, sidebars) are defined as **components** and composed into page objects:

```typescript
// pages/components/navigation.component.ts
import { Locator, Page } from '@playwright/test';

export class NavigationComponent {
    constructor(private readonly page: Page) {}

    get homeLink(): Locator {
        return this.page.getByRole('link', { name: 'Home' });
    }

    async clickHome(): Promise<void> {
        await this.homeLink.click();
    }

    async logout(): Promise<void> {
        await this.page.getByTestId('user-menu-button').click();
        await this.page.getByRole('button', { name: 'Logout' }).click();
    }
}
```

Compose components into page objects:

```typescript
// pages/app/dashboard.page.ts
import { Page } from '@playwright/test';
import { NavigationComponent } from '../components/navigation.component';

export class DashboardPage {
    /** Navigation component for header/nav interactions */
    readonly nav: NavigationComponent;

    constructor(private readonly page: Page) {
        this.nav = new NavigationComponent(page);
    }
}

// Usage in tests
await dashboardPage.nav.clickHome();
await dashboardPage.nav.logout();
```

The `nav: NavigationComponent` field is a component, not a locator, so the JSDoc-forbidden rule does not apply — a short descriptive JSDoc is allowed.

## Instructions

### Phase 1: Verify prerequisites

Before writing any code:

- Run `ls pages/` to resolve `{area}` (e.g. `app`, `front-office`, `back-office`). Do not guess.
- Identify which enums the page needs (`Messages`, `ApiEndpoints`, `Roles`, etc.). If a required enum member does not yet exist, extend it via the `enums` skill **first** — verify UI text with `playwright-cli` before encoding it.
- Confirm the scaffold has a matching schema (for pages that trigger API calls you need to wait for / assert on) via `ls fixtures/api/schemas/`; if missing, create it via the `api-testing` skill.

### Phase 2: Explore the live application (mandatory)

Never create a page object from assumptions, wireframes, or documentation alone.

1. **Open and authenticate** — use **only** `playwright-cli` in the terminal (not IDE browser MCP, not Cursor browser tools, not any substitute). Orchestrator rule: **No Substitute UI Exploration**. If the page doesn't load or auth fails, stop and notify the human.
2. **Explore like a user** — navigate through the feature, trigger CRUD operations, observe forms, buttons, feedback messages, validation errors, and dynamic content.
3. Record every observed element's role, accessible name, label, and (if applicable) test ID.

Read the full workflow in the `selectors` skill (`.claude/skills/selectors/SKILL.md` → "Exploration-First Workflow") and `playwright-cli` skill for the specific commands.

**Forbidden:** Skipping exploration. If the application is unavailable, say so and wait — do not create placeholder locators with guessed names.

### Phase 3: Plan the page object's test coverage

Draft, in writing, which paths the page object needs to support:

- **Happy paths** — the main user flow succeeds.
- **Validation paths** — field-level rejections (empty, bad format, boundary).
- **Error paths** — server rejections, surfaced via error feedback messages.
- **Edge cases** — timeouts, intermittent network, concurrent edits, long strings.

The plan drives **which feedback locators** end up on the page object. A page with 5 happy-path buttons and 0 feedback locators is incomplete.

### Phase 4: Build the class

Follow the Page Object Pattern above. Specifically:

- Import `expect, Locator, Page` from `@playwright/test`.
- Constructor: `private readonly page: Page` — plus component instantiation if composing.
- Three locator sections (Interactive / Feedback / Actions), each separated by a visual header comment. Feedback locators reference `enums/{area}/*` values, never hardcoded strings.
- Every action method: explicit return type, `@param` / `@returns` JSDoc, waits for API responses or state changes (web-first assertions or `waitForResponse`), no `waitForTimeout`.
- Verification method naming: `xxxAndVerify()` — may use `expect(...)` internally.
- Reusable fragments → component under `pages/components/` and composed via a `readonly field: ComponentClass` in the page object (see Component composition above).

### Phase 5: Register the page object

After creating the class, register it as a fixture in `fixtures/pom/page-object-fixture.ts`:

1. Import the class.
2. Add the property to `FrameworkFixtures`.
3. Add the fixture body.

```typescript
import { test as base } from '@playwright/test';
import { AppPage } from '../../pages/app/app.page';
import { DashboardPage } from '../../pages/app/dashboard.page';

export type FrameworkFixtures = {
    appPage: AppPage;
    dashboardPage: DashboardPage; // Add type
    resetStorageState: () => Promise<void>;
};

export const test = base.extend<FrameworkFixtures>({
    appPage: async ({ page }, use) => {
        await use(new AppPage(page));
    },
    dashboardPage: async ({ page }, use) => {
        await use(new DashboardPage(page)); // Add fixture
    },
    resetStorageState: async ({ context }, use) => {
        await use(async () => {
            await context.clearCookies();
            await context.clearPermissions();
        });
    },
});
```

No `mergeTests()` change needed — `pageObjectFixture` is already merged into `fixtures/pom/test-options.ts`. For the deeper DI rules (new fixture categories, lifecycle, Built-in Fixtures table) see the `fixtures` skill.

### Phase 6: Consume from tests via the fixture

```typescript
import { expect, test } from '../../../fixtures/pom/test-options';

test('should show error on bad login', async ({ appPage }) => {
    await appPage.openHomePage();
    await appPage.login('bad@example.com', 'wrong');
    await expect(appPage.errorMessage).toBeVisible();
});
```

**Never** `new AppPage(page)` inside a test. If the fixture feels too heavy, fix the fixture, don't bypass it.

## See Also

- **`selectors`** skill — exploration-first workflow (4 steps), selector priority order, feedback/validation message rules, forbidden patterns.
- **`playwright-cli`** skill — the terminal-only live-app exploration tool (no IDE browser MCP substitutes).
- **`fixtures`** skill — full DI rules, `FrameworkFixtures` / `HelperFixtures`, `mergeTests`, Built-in Fixtures table.
- **`enums`** skill — where `Messages.*`, `ApiEndpoints.*`, `Roles`, `StorageStatePaths` live; how to add new values with live-text verification.
- **`common-tasks`** skill — prompt templates for "Add a New Page Object (With / Without Exploration)" and "Add Locators to Existing Page".
- **`api-testing`** skill — helper fixtures and factories used from page-object tests.
- **`debugging`** skill — when a test using this page object fails, classify the failure (TimeoutError on action, locator returned multiple, etc.) and use the right tool to investigate before changing the page object.
- **`references/examples.md`** — three end-to-end walkthroughs (new page, locator addition, component extraction).
- **`references/troubleshooting.md`** — common page-object pitfalls and their fixes.
