# Helper fixtures

The shape of a promoted setup/teardown in `fixtures/helper/helper-fixture.ts`. Fixture code calls `apiRequest` from `fixtures/api/plain-function.ts` with the raw `request` context; tests call the `apiRequest` fixture. The type goes into `HelperFixtures`; the file is already merged into `fixtures/pom/test-options.ts` (`fixtures`). `ApiEndpoints.PRODUCTS`, `generateProduct()` and `ProductResponseSchema` are illustrative; the file's `createdResource` is the live placeholder.

## Pattern

```typescript
export type HelperFixtures = {
    /** Creates a product before the test and deletes it after */
    createdProduct: ProductResponse;
};

export const test = base.extend<HelperFixtures>({
    createdProduct: async ({ request }, use) => {
        const { body } = await apiRequest({
            request,
            method: 'POST',
            url: ApiEndpoints.PRODUCTS,
            baseUrl: process.env.API_URL,
            headers: process.env.ACCESS_TOKEN,
            body: generateProduct(),
        });
        const product = ProductResponseSchema.parse(body);

        await use(product);

        await apiRequest({
            request,
            method: 'DELETE',
            url: `${ApiEndpoints.PRODUCTS}/${product.id}`,
            baseUrl: process.env.API_URL,
            headers: process.env.ACCESS_TOKEN,
        });
    },
});
```

Setup runs before the test, `use(product)` hands the parsed value to the test, teardown runs after it, also after a failure.

## Usage

```typescript
test(
    'should show the product name',
    { tag: '@regression' },
    async ({ createdProduct, appPage }) => {
        await appPage.openProduct(createdProduct.id);
        await expect(appPage.productName).toHaveText(createdProduct.name);
    }
);
```

Below the threshold, the same two calls sit in `beforeAll`/`afterAll` of the one spec that needs them, through the `apiRequest` fixture.
