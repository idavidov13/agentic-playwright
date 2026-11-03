# Verification checklist

Walk it after every generated or modified artifact, once `npm run lint` and `npx tsc --noEmit` are clean (the lint layer already catches imports, tags, `any`, hard waits, XPath, loose schemas, manual instantiation, JSON static data and hardcoded URLs). These boxes need judgment, not a linter.

- [ ] Nothing changed outside the approved proposal's scope.
- [ ] Endpoint paths come from `enums/{area}/*`, URLs and credentials from `process.env.*`; no literal path or secret in the artifact.
- [ ] Happy-path content (names, emails, text) comes from a factory; curated invalid values come from `test-data/static/`.
- [ ] A test that mutates shared state is tagged only `@destructive`; every state-mutating test, shared or own-data, reverts in `afterEach` or `afterAll`.
- [ ] Locator getters carry no JSDoc; action methods carry `@param` and `@returns`.
- [ ] A page object for a form or CRUD page has success, error and validation-message locators.
- [ ] API: every documented status code has a test, passing or `test.skip` + `// FIXME`; no schema was loosened to make a test pass.
- [ ] API: every body field has a per-field omission test and an invalid-type `for...of` loop over the universal arrays.
- [ ] API: path parameters have the invalid-format loop; secured endpoints have 401 and 403 tests; every endpoint has one 405 test.
- [ ] No explore-only or throwaway file is left in the tree.
- [ ] The affected tests ran green (`npx playwright test <file>`).
