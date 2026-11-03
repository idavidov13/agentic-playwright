# Contract sourcing

The documented contract (OpenAPI / Swagger or an equivalent document) is the source of truth for schemas and tests. Observed behaviour is evidence about the implementation, not about the contract.

## Where to look

1. A spec file in the repo: `find . -path ./node_modules -prune -o \( -name 'openapi*' -o -name 'swagger*' \) -print`.
2. The API host. The demo API serves its OpenAPI JSON at `${API_URL}/docs` and a Swagger UI at `${API_URL}/api/documentation`; another API will use its own route, so check `/docs`, `/openapi.json`, `/swagger.json` and `/api/documentation`.
3. A document the human provides.

Nothing found: stop and ask. A short search that finds nothing is not "no documentation exists".

## Recording the source

Put the source (URL or file path, and the version or date the document states) in a comment at the top of the schema file, so later drift can be attributed to a spec change or a backend change.

## Partially documented endpoint

The spec exists but omits a body shape or a status code:

- The documented parts stay contract-bound.
- For the undocumented parts only, capture the live shape with one real request and mark the schema with `FIXME:` naming what the spec omits. `fixtures/api/schemas/util/errorResponseSchema.ts` is the live instance: the spec documents the error codes without bodies, so the 401 `{ error }`, 404 `{ message }` and 422 field-map shapes are captured.
- One missing error shape does not make the whole endpoint undocumented.

## No documentation at all

Make one real request per status code and capture field names, types, required versus optional, nullability, nested shapes and the error bodies. Treat the capture as the working contract, write the schema from it, and flag the missing documentation in the report: tests against "whatever the API does today" are a stopgap.
