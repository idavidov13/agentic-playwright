# Class pattern

The live instance is `pages/app/app.page.ts` (`AppPage`). Section comments mark the groups; locators use the priority order from `selectors`.

```typescript
import { expect, Locator, Page } from '@playwright/test';
import { AppRoutes, Messages } from '../../enums/app/app';

export class ProfilePage {
    constructor(private readonly page: Page) {}

    // ==================== Locators ====================

    get nameInput(): Locator {
        return this.page.getByLabel('Name *');
    }

    get saveButton(): Locator {
        return this.page.getByRole('button', { name: 'Save' });
    }

    // ==================== Feedback Locators ====================

    get savedMessage(): Locator {
        return this.page.getByText(Messages.PROFILE_SAVED);
    }

    get nameRequiredError(): Locator {
        return this.page.getByText(Messages.NAME_REQUIRED);
    }

    // ==================== Actions ====================

    /**
     * Opens the profile page using the configured APP_URL.
     *
     * @returns {Promise<void>} Resolves when navigation is complete.
     */
    async openProfilePage(): Promise<void> {
        await this.page.goto(`${process.env.APP_URL!}${AppRoutes.PROFILE}`, {
            waitUntil: 'domcontentloaded',
        });
    }

    /**
     * Fills the name field and submits the form.
     *
     * @param {string} name - The display name to save.
     * @returns {Promise<void>} Resolves when the form has been submitted.
     */
    async saveName(name: string): Promise<void> {
        await this.nameInput.fill(name);
        await this.saveButton.click();
    }

    /**
     * Saves the name and verifies the success message.
     *
     * @param {string} name - The display name to save.
     * @returns {Promise<void>} Resolves when the save is confirmed.
     */
    async saveNameAndVerify(name: string): Promise<void> {
        await this.saveName(name);
        await expect(this.savedMessage).toBeVisible();
    }
}
```

`Messages.PROFILE_SAVED`, `Messages.NAME_REQUIRED` and `AppRoutes.PROFILE` are illustrative; each is added to `enums/{area}/*` with text captured from the live app before the class uses it.

An action method that must wait for a request does so with `this.page.waitForResponse((r) => r.url().includes(ApiEndpoints.PROFILE))`. An action whose input can be rejected client-side sends no request, so it does not wait; the caller asserts the outcome with a web-first assertion.
