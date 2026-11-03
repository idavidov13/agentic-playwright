# Components

A component is a class for a UI fragment that appears on more than one page: header, navigation, modal, toast, sidebar. Same shape as a page object (`get` locators, JSDoc on actions only), stored in `pages/components/<name>.component.ts`. The live instance is `pages/components/navigation.component.ts`.

```typescript
import { Locator, Page } from '@playwright/test';

export class NotificationComponent {
    constructor(private readonly page: Page) {}

    get toast(): Locator {
        return this.page.getByRole('status');
    }

    get closeButton(): Locator {
        return this.toast.getByRole('button', { name: 'Close' });
    }

    /**
     * Dismisses the visible toast.
     *
     * @returns {Promise<void>} Resolves when the toast is closed.
     */
    async dismiss(): Promise<void> {
        await this.closeButton.click();
    }
}
```

## Composition

The page object holds the component as a `readonly` field and creates it in the constructor. The field is not a locator, so a one-line JSDoc on it is allowed.

```typescript
import { Page } from '@playwright/test';
import { NotificationComponent } from '../components/notification.component';

export class DashboardPage {
    /** Toast notifications shown on this page */
    readonly notification: NotificationComponent;

    constructor(private readonly page: Page) {
        this.notification = new NotificationComponent(page);
    }
}
```

In a test: `await dashboardPage.notification.dismiss();`. Components are not registered as fixtures; they are reached through the page object that owns them.

## Splitting a large page object

A page object that covers several flows (a settings screen with profile, billing and security tabs) is split by flow (`SettingsProfilePage`, `SettingsBillingPage`), each registered as its own fixture. Fragments repeated across the split pages become components. One class per screen's worth of interactions.
