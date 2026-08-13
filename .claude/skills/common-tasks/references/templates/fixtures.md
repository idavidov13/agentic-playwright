# Fixture Templates

Prompt templates for page-object fixtures, helper (setup/teardown) fixtures, and new fixture categories. The `fixtures` and `helpers` skills own the deep rules.

## Add a New Page Object Fixture

```
Create a new fixture for [PAGE OBJECT]:
- Location: fixtures/pom/page-object-fixture.ts (add to existing)
- Fixture name: [fixtureName]
- Purpose: [what page object it provides]

Requirements:
- Add type to FrameworkFixtures
- Add fixture with `async ({ page }, use) => { await use(new PageObject(page)); }`
- No separate fixture file needed for page objects
```

## Add a Helper Fixture (Setup/Teardown)

```
Create a helper fixture for [PURPOSE]:
- Location: fixtures/helper/helper-fixture.ts (add to existing)
- Fixture name: [fixtureName]
- Purpose: [what precondition it sets up and tears down]

Requirements:
- Add return type to HelperFixtures
- Use apiRequest from plain-function.ts for API calls
- Implement setup → use() → teardown pattern
- Setup: Create precondition via API before the test
- Yield: Pass created data to the test via use()
- Teardown: Clean up after the test (runs even on failure)
- Already merged into test-options.ts (no extra registration needed)
- Promote to a helper fixture only when the same setup/teardown is reused across 3+ spec files (see the api-testing skill, Phase 8)
```

## Add a New Fixture Category

```
Create a new fixture category for [PURPOSE]:
- Location: fixtures/[category]/[name]-fixture.ts
- Fixture name: [fixtureName]
- Purpose: [what it provides]

Requirements:
- Export test using base.extend<FixtureType>()
- Export the fixture types
- Add cleanup logic if needed
- Merge into fixtures/pom/test-options.ts via mergeTests()
```
