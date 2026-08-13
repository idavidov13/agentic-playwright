# Feedback Selectors — Worked Example

A page object that handles a CRUD operation must include feedback selectors. This is the canonical pattern.

> `ProductsPage`, `Messages.PRODUCT_CREATED`, `Messages.PRODUCT_SAVE_FAILED`, and `Messages.NAME_REQUIRED` are **illustrative** — there is no `ProductsPage` in the scaffold today. Substitute your own page/class name and real enum members when following this pattern. The `Messages.*` values must be defined in `enums/{area}/*.ts` first (capture the exact rendered text with `playwright-cli`).

## Pattern

```typescript
export class ProductsPage {
    constructor(private readonly page: Page) {}

    // ==================== Form Locators ====================

    get nameInput(): Locator {
        return this.page.getByLabel('Product Name');
    }

    get saveButton(): Locator {
        return this.page.getByRole('button', { name: 'Save' });
    }

    // ==================== Feedback Locators ====================

    get successMessage(): Locator {
        return this.page.getByText(Messages.PRODUCT_CREATED);
    }

    get errorMessage(): Locator {
        return this.page.getByText(Messages.PRODUCT_SAVE_FAILED);
    }

    get nameValidationError(): Locator {
        return this.page.getByText(Messages.NAME_REQUIRED);
    }

    // ==================== Actions ====================

    /**
     * Creates a product and waits for the API response.
     * @param {string} name - Product name.
     * @returns {Promise<void>}
     */
    async createProduct(name: string): Promise<void> {
        await this.nameInput.fill(name);
        await this.saveButton.click();
        await this.page.waitForResponse((r) =>
            r.url().includes('/api/products')
        );
    }
}
```

## How tests assert on feedback

```typescript
await productsPage.createProduct(productData.name);
await expect(productsPage.successMessage).toBeVisible();
```

## Forbidden — page objects without feedback selectors

If a page object covers a form or CRUD operation but has no selectors for success / error / validation messages, the page object is incomplete. Every form submission or data mutation should have at least a success and error message selector so tests can verify the outcome.
