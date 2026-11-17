# Verification checklist

Walk it after every generated or modified artifact, once `npm run lint` and `npx tsc --noEmit` are clean (the lint layer already catches imports, tags, `any`, hard waits, XPath, loose schemas, manual instantiation, JSON static data and hardcoded URLs). These boxes need judgment, not a linter.

- [ ] Nothing changed outside the approved proposal's scope.
- [ ] Endpoint paths come from `enums/{area}/*`, URLs and credentials from `process.env.*`; no literal path or secret in the artifact.
- [ ] Happy-path content (names, emails, text) comes from a factory; curated invalid values come from `test-data/static/`.
- [ ] A test that mutates shared state is tagged only `@destructive`; every state-mutating test, shared or own-data, reverts in `afterEach` or `afterAll`.
- [ ] Locator getters carry no JSDoc; action methods carry `@param` and `@returns`.
- [ ] A page object for a form or CRUD page has success, error and validation-message locators.
- [ ] API: every documented status code has a test, passing or `test.skip` + `// FIXME`, or a `// SCOPE` line naming who cut it; no schema was loosened to make a test pass; a test for an undocumented code or body carries `// OBSERVED`.
- [ ] API: every body field has a per-field omission test and an invalid-type `for...of` loop over the universal arrays, or the request-body rows carry `// SCOPE` lines.
- [ ] API: path parameters have the invalid-format loop; secured endpoints have missing-auth and wrong-role tests; every endpoint has one unsupported-method test; a row left out has its `// SCOPE` line.
- [ ] No explore-only or throwaway file is left in the tree.
- [ ] The affected tests ran green (`npx playwright test <file>`).
- [ ] Quarantines have human approval, an owner, expiry and investigation evidence.
