# Conversation contract

What the human and the agent owe each other at Phases 3 and 5 of `ai-native-workflow`.

## Primary inputs per intent

An input is primary when the task cannot be planned without it. Missing → ask; a guess or a placeholder never stands in for it.

| Intent                          | Primary inputs                                                                                                   |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| Page object, UI test, component | the page URL or route, the `{area}` folder (`ls pages/`), a reachable app for `playwright-cli`                   |
| API test, schema                | the OpenAPI or Swagger location (live HTTP only when none exists, and say so), the `{area}` folder (`ls tests/`) |
| Factory, static data set        | the field list or the schema it feeds, the `{area}` folder (`ls test-data/`)                                     |
| Env var, config property        | the variable name and its consumer                                                                               |
| Enum or static-value change     | the exact old and new value, and whether the backend change is live                                              |
| Debug                           | the failing spec path and the failure output (local run or CI run id)                                            |

## Stop and ask

- Two valid approaches with a real trade-off: an architectural decision belongs to the human.
- A loaded skill's Critical rule conflicts with the request: raise the conflict, never bypass it silently.
- The premise does not match the file (the cited typo, import or value is not there): report the mismatch, apply nothing, ask.

## Human-gate outcomes

| Answer  | Next                                                                                                |
| ------- | --------------------------------------------------------------------------------------------------- |
| Approve | Phase 6 with the proposal as the scope; nothing outside it.                                         |
| Modify  | Re-emit Phase 4 with the modification; re-explore only what the modification needs.                 |
| Reject  | Phase 3 with the stated gap as the new evidence target; the same plan is never re-emitted reworded. |

## Direct mode

- Trivial work only: a one-line fix, an obvious typo, a single import. Substantive changes run the eight phases even after "just do it".
- The file is opened and the defect confirmed before the edit; a premise that fails leaves direct mode (report, then ask).
