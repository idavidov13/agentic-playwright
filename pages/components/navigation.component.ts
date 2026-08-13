import { Locator, Page } from '@playwright/test';

/**
 * Component Object for navigation elements.
 * Demonstrates the component pattern for reusable UI fragments.
 *
 * Components are smaller, reusable pieces that can be composed into Page Objects.
 * Use this pattern for headers, footers, sidebars, modals, and other repeated UI elements.
 *
 * @example
 * ```ts
 * // Usage in a Page Object
 * export class DashboardPage {
 *     readonly nav: NavigationComponent;
 *
 *     constructor(private readonly page: Page) {
 *         this.nav = new NavigationComponent(page);
 *     }
 * }
 *
 * // In tests
 * await dashboardPage.nav.clickHome();
 * ```
 */
export class NavigationComponent {
    constructor(private readonly page: Page) {}

    // ==================== Locators ====================

    get container(): Locator {
        return this.page.getByRole('navigation');
    }

    get homeLink(): Locator {
        return this.page.getByRole('link', { name: 'Home' });
    }

    get dashboardLink(): Locator {
        return this.page.getByRole('link', { name: 'Dashboard' });
    }

    get settingsLink(): Locator {
        return this.page.getByRole('link', { name: 'Settings' });
    }

    get userMenuButton(): Locator {
        return this.page.getByTestId('user-menu-button');
    }

    get logoutButton(): Locator {
        return this.page.getByRole('button', { name: 'Logout' });
    }

    // ==================== Actions ====================

    /**
     * Navigates to the home page via the navigation link.
     *
     * @returns {Promise<void>}
     */
    async clickHome(): Promise<void> {
        await this.homeLink.click();
    }

    /**
     * Navigates to the dashboard via the navigation link.
     *
     * @returns {Promise<void>}
     */
    async clickDashboard(): Promise<void> {
        await this.dashboardLink.click();
    }

    /**
     * Navigates to settings via the navigation link.
     *
     * @returns {Promise<void>}
     */
    async clickSettings(): Promise<void> {
        await this.settingsLink.click();
    }

    /**
     * Opens the user dropdown menu.
     *
     * @returns {Promise<void>}
     */
    async openUserMenu(): Promise<void> {
        await this.userMenuButton.click();
    }

    /**
     * Performs logout by opening user menu and clicking logout.
     *
     * @returns {Promise<void>}
     */
    async logout(): Promise<void> {
        await this.openUserMenu();
        await this.logoutButton.click();
    }
}
