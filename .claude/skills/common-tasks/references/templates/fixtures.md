# Fixture templates

Prompt templates for page-object fixtures, helper (setup and teardown) fixtures and new fixture categories. `fixtures` owns registration and lifecycle, `helpers` the plain-function side, `api-testing` the helper-fixture promotion threshold.

## Add a page-object fixture

```
Register [PAGE OBJECT] as the fixture [fixtureName] in fixtures/pom/page-object-fixture.ts, following the existing entries and the fixtures skill.
```

## Add a helper fixture (setup and teardown)

```
Create the helper fixture [fixtureName] in fixtures/helper/helper-fixture.ts for [PURPOSE]:
- setup: [precondition created through the API]
- yields: [data the test receives]
- teardown: [what is reverted, also on failure]

Follow the fixtures skill for the lifecycle and the api-testing skill for the API calls; promote only if the reuse clears the threshold the api-testing skill states.
```

## Add a fixture category

```
Create the fixture category [category] at fixtures/[category]/[name]-fixture.ts for [PURPOSE], export its types and merge it into fixtures/pom/test-options.ts per the fixtures skill.
```
