# Principles That Make the Scaffold AI-Native

The scaffold is engineered so an LLM can reason from a small surface and produce consistent output. Five principles drive this.

## 1. Single Source of Truth for Every Value Class

- URLs / credentials → `process.env.*` (declared in `env/.env.example`).
- Endpoint paths / route constants / UI message strings / storage-state paths → `enums/{area}/*` and `enums/util/*`.
- Universal type-mismatch arrays → `test-data/static/util/invalid-values.ts`.
- Domain-specific curated invalid sets → `test-data/static/{area}/*.ts`.
- Dynamic happy-path data → Faker factories in `test-data/factories/{area}/`.

There is exactly one right answer per value kind; the agent never has to guess.

## 2. Hard-Stop Forbidden Patterns

Every Critical block lists `NEVER` rules with concrete anti-examples. Forbidden patterns are not soft preferences; they are refusal triggers. When the agent encounters a forbidden pattern in a user's request or in an example, it raises the conflict instead of complying.

## 3. Mandatory Exploration Discipline

`playwright-cli` for UI, OpenAPI / docs first for API. The agent does not speculate about UI text or response shapes. When exploration is impossible (CLI broken, app unreachable, docs missing), the agent stops and notifies the human — it does not substitute another tool.

## 4. Strict Folder Discipline

Every artifact has exactly one home (and the path uses an `{area}` placeholder that the agent resolves with `ls`). Skill triggering by description keyword works because the folder maps cleanly to the skill name.

## 5. Phased Instructions Inside Skills

Each specialized skill walks the agent through numbered phases with checklists. The agent doesn't have to invent a workflow per task; it follows the skill's phases.

## The Combined Effect

These five principles together produce **consistent results across sessions, agents, and contributors** — the operational definition of "AI-native" in this codebase.
