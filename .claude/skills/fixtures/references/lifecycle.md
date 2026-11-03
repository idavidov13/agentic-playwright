# Fixture lifecycle

The live instances are `fixtures/pom/page-object-fixture.ts` (page objects, `resetStorageState`), `fixtures/api/api-request-fixture.ts` (`apiRequest`, the worker-scoped auto fixture `accessTokenLoaded`) and `fixtures/helper/helper-fixture.ts` (`createdResource`, an example to replace).

## Helper fixture skeleton

Fixture code uses `apiRequest` from `fixtures/api/plain-function.ts`, which takes the raw `request` context; the `apiRequest` fixture is for specs.

```typescript
import { test as base } from '@playwright/test';
import { ApiEndpoints } from '../../enums/app/app';
import { apiRequest } from '../api/plain-function';
import { ResourceResponseSchema } from '../api/schemas/app/resourceSchema';
import type { ResourceResponse } from '../api/schemas/app/resourceSchema';
import { generateResource } from '../../test-data/factories/app/resource.factory';

export type HelperFixtures = {
    createdResource: ResourceResponse;
};

export const test = base.extend<HelperFixtures>({
    createdResource: async ({ request }, use) => {
        const { body } = await apiRequest({
            request,
            method: 'POST',
            url: ApiEndpoints.RESOURCES,
            baseUrl: process.env.API_URL,
            headers: process.env.ACCESS_TOKEN,
            body: generateResource(),
        });
        const resource = ResourceResponseSchema.parse(body);

        await use(resource);

        await apiRequest({
            request,
            method: 'DELETE',
            url: `${ApiEndpoints.RESOURCES}/${resource.id}`,
            baseUrl: process.env.API_URL,
            headers: process.env.ACCESS_TOKEN,
        });
    },
});
```

`ApiEndpoints.RESOURCES`, `ResourceResponseSchema` and `generateResource` are illustrative; each lives in its own home (`enums`, `type-safety`, `data-strategy`) before the fixture uses it. Teardown runs after a failed test too.

## New category

```typescript
// fixtures/mailbox/mailbox-fixture.ts
import { test as base } from '@playwright/test';

export type MailboxFixtures = { mailbox: Mailbox };

export const test = base.extend<MailboxFixtures>({
    mailbox: async ({ request }, use) => {
        const mailbox = await openMailbox(request);
        await use(mailbox);
        await mailbox.purge();
    },
});
```

Then in `fixtures/pom/test-options.ts`: `mergeTests(pageObjectFixture, apiRequestFixture, helperFixture, mailboxFixture)`. Specs need no new import.

## Symptoms

| Symptom                                                      | Cause                                                        | Fix                                        |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------ |
| `appPage` (or any fixture) missing on the test context       | spec imports `test` from `@playwright/test`                  | import from `fixtures/pom/test-options.ts` |
| Fixture implemented but TypeScript rejects it on the context | property not added to `FrameworkFixtures` / `HelperFixtures` | add it to the type literal                 |
| Teardown never runs                                          | code sits before `await use(...)`, or `use` is missing       | setup → `await use(data)` → teardown       |
| New category not injected                                    | not merged into `test-options.ts`                            | append it to `mergeTests(...)`             |
