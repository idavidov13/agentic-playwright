# Multi-call steps

A test with more than one API call: each call in its own `test.step()`, named `<verb> <resource> via <METHOD> <path>`, with the status and schema assertions inside the step. Cleanup of what the test created sits in `afterEach`, so it runs after a failed step too. `ApiEndpoints.PRODUCTS`, `generateProduct()` and `ProductResponseSchema` are illustrative.

```typescript
test.describe('POST /products - create and read back', () => {
    let productId: string;

    test.afterEach(async ({ apiRequest }) => {
        await apiRequest({
            method: 'DELETE',
            url: `${ApiEndpoints.PRODUCTS}/${productId}`,
            baseUrl: process.env.API_URL,
            headers: process.env.ACCESS_TOKEN,
        });
    });

    test(
        'should create a product and read it back',
        { tag: '@api' },
        async ({ apiRequest }) => {
            const payload = generateProduct();

            await test.step('Create product via POST /products', async () => {
                const { status, body } = await apiRequest<ProductResponse>({
                    method: 'POST',
                    url: ApiEndpoints.PRODUCTS,
                    baseUrl: process.env.API_URL,
                    headers: process.env.ACCESS_TOKEN,
                    body: payload,
                });

                expect(status).toBe(201);
                expect(ProductResponseSchema.parse(body)).toBeTruthy();
                productId = body.id;
            });

            await test.step('Read product via GET /products/:id', async () => {
                const { status, body } = await apiRequest<ProductResponse>({
                    method: 'GET',
                    url: `${ApiEndpoints.PRODUCTS}/${productId}`,
                    baseUrl: process.env.API_URL,
                    headers: process.env.ACCESS_TOKEN,
                });

                expect(status).toBe(200);
                expect(ProductResponseSchema.parse(body)).toBeTruthy();
                expect(body.name).toBe(payload.name);
            });
        }
    );
});
```

A DELETE endpoint's own 204 row is a separate test in its own describe block (`references/coverage-matrix.md`), with the resource created in `beforeAll`.

Wrong: the same two calls in one body without `test.step()`. The report shows one block, and the failing call has to be found by reading the assertions.
