# Noema Native Stack Skeleton

## Scope

This artifact opens the first native Go API seam under `services/api` without touching production, real Secrets, databases, Redis, S3, Elasticsearch, Kubernetes, or irreversible data.

The skeleton is intentionally small:

- `go.mod` at repo root with module `github.com/agentwego/noema`.
- `services/api/cmd/api` starts a local HTTP server.
- `services/api/internal/config` reads explicit native runtime knobs. Database DSNs are empty by default and only come from environment/Secret handoff via `NOEMA_DATABASE_URL`; local tests use disposable placeholder DSNs only.
- `services/api/internal/http` exposes `/healthz` for local smoke checks and a minimal `/search` contract endpoint backed by the search provider seam. Health reports the actual injected provider identity via `Provider.Name()`, including local/test unknown-provider fallback to noop; non-local envs fail fast on unavailable providers. Unsupported `/healthz` methods return stable JSON `405 {"error":"method not allowed"}` and unknown API routes return stable JSON `404 {"error":"not found"}`.
- `services/api/internal/search` defines the native search provider/index seam and a no-op provider for bootstrap tests; `services/api/internal/search/elastic` now includes a local mockable adapter/client boundary that requires an injected transport and has no default real cluster connection.
- `services/api/internal/persistence` opens the first Noema-native PostgreSQL/GORM source-of-truth seam with minimal `User` and `Article` records plus a repository interface. The slice does not port Forem ActiveRecord callbacks; it only proves local persistence, author integrity, and list-by-author behavior against a disposable DB.
- `services/api/internal/identity` reserves the Ory Kratos-native identity/session/self-service-flow boundary as local DTO/spec types only; it does not create a Kratos HTTP client, run self-service flows, or implement custom long-lived auth.

## Inventory Rows Covered

| Legacy file | Inventory domain | Target | Why cited |
| --- | --- | --- | --- |
| `config/routes.rb` | routing | `services/api/internal/http/router + apps/web routes` | Establishes the native API router seam without porting Rails routes wholesale. |
| `config/routes/api.rb` | routing | `services/api/internal/http/router + apps/web routes` | Establishes native API route ownership. |
| `app/controllers/concerns/api/health_checks_controller.rb` | public-api | `services/api/internal/http/handlers` | Provides the first local health endpoint contract. |
| `app/controllers/api/v1/api_controller.rb` | public-api | `services/api/internal/http/handlers` | Keeps API handler work behind explicit native HTTP boundaries. |
| `config/database.yml` | runtime-config | `deploy/k8s + services/api/internal/config` | Seeds a non-secret config loader without database handoff yet. |
| `app/controllers/search_controller.rb` | search | `services/api/internal/search + apps/web/search` | Establishes the native search boundary, not Rails/Algolia behavior. |
| `app/services/search/article.rb` | search | `services/api/internal/search/{elastic,fallback}` | Establishes document-family/index naming for future provider work. |
| `app/services/search/comment.rb` | search | `services/api/internal/search/{elastic,fallback}` | Establishes document-family/index naming for future provider work. |
| `app/services/search/user.rb` | search | `services/api/internal/search/{elastic,fallback}` | Establishes document-family/index naming for future provider work. |
| `app/services/search/tag.rb` | search | `services/api/internal/search/{elastic,fallback}` | Establishes document-family/index naming for future provider work. |
| `app/workers/algolia_search/search_index_worker.rb` | search | `services/api/internal/search/{elastic,fallback}` | Future async indexing belongs behind the provider seam. |
| `app/models/article.rb` | articles/content | `services/api/internal/articles + search documents` | M0-T28 starts the native source-of-truth Article persistence shape without line-porting the 1852-line ActiveRecord model. |
| `app/models/user.rb` | identity/profile | `services/api/internal/identity` | M0-T28 starts the native User identity persistence shape needed for article author ownership; M0-T31 reserves the Ory Kratos identity/session boundary without line-porting Devise. |
| `app/models/identity.rb` | identity/profile | `services/api/internal/identity` | M0-T31 preserves legacy provider subjects as Kratos admin metadata while excluding tokens/secrets/auth dumps. |
| `app/controllers/omniauth_callbacks_controller.rb` | web-rails-controller | `apps/web routes + services/api handlers` | Future target is Kratos self-service / identity-provider exchange rather than bespoke OAuth callbacks. |
| `app/controllers/sessions_controller.rb` | web-rails-controller | `apps/web routes + services/api handlers` | Future target is Kratos session assertion/revocation rather than Devise/Warden session ownership. |
| `app/controllers/articles_controller.rb` | web-rails-controller | `apps/web routes + services/api handlers` | Article persistence will be consumed by future API handlers rather than Rails controller globals. |
| `app/controllers/users_controller.rb` | web-rails-controller | `apps/web routes + services/api handlers` | User persistence will be consumed by future identity/profile handlers rather than Rails controller globals. |

## Verification

TDD RED was observed before implementation:

```bash
go test ./services/api/...
# pattern ./services/api/...: directory prefix services/api does not contain main module or its selected dependencies
# FAIL ./services/api/... [setup failed]
```

After implementation:

```bash
gofmt -w services/api/cmd/api/main.go services/api/internal/config/config.go services/api/internal/config/config_test.go services/api/internal/http/router.go services/api/internal/http/router_test.go services/api/internal/search/index.go services/api/internal/search/noop.go services/api/internal/search/search_test.go
go test ./services/api/...
# ?   	github.com/agentwego/noema/services/api/cmd/api	[no test files]
# ok  	github.com/agentwego/noema/services/api/internal/config	0.001s
# ok  	github.com/agentwego/noema/services/api/internal/http	0.002s
# ok  	github.com/agentwego/noema/services/api/internal/search	0.001s
```

Local smoke used an unused high port because `18080` was already occupied by a local Neko service:

```bash
PORT=19091 NOEMA_ENV=test SEARCH_PROVIDER=postgres go run ./services/api/cmd/api
curl -fsS http://127.0.0.1:19091/healthz | python -m json.tool
# {
#     "env": "test",
#     "search_provider": "postgres",
#     "service": "noema-api",
#     "status": "ok"
# }
```

The local server was killed after the smoke check.

## M0-T28 Native Persistence Seam

Selected direction: native PostgreSQL/GORM persistence seam. This is the safest next backend migration slice because Article and User are P1 source-of-truth domains in the inventory, and search/feed/import work needs a clean transactional model before any provider-specific indexing or legacy import path can safely mutate data.

Inventory/edge citations used before implementation:

- `app/models/article.rb`: `articles/content`, target `services/api/internal/articles + search documents`, disposition `re-design model semantics, do not line-port ActiveRecord`, 1852 lines, 448 out edges / 204 in edges.
- `app/models/user.rb`: `identity/profile`, target `services/api/internal/identity`, disposition `re-design model semantics, do not line-port ActiveRecord`, 991 lines, 241 out edges / 422 in edges.
- Edge samples: `app/models/user.rb -> app/models/article.rb` and `app/models/article.rb -> app/controllers/search_controller.rb` show why author ownership and article persistence must exist before wiring HTTP/search/import write paths.

Implemented local-only artifacts:

- Minimal `persistence.User` and `persistence.Article` domain records.
- `persistence.Repository` interface with create/get user, upsert/get article, and list-by-author behavior.
- GORM/PostgreSQL repository with explicit `Migrate(ctx)` for local disposable DB tests.
- `NOEMA_DATABASE_URL` config boundary with an empty default, so local verification does not require real credentials.
- `task persistence:test` for targeted config/persistence tests; integration behavior is exercised when `NOEMA_TEST_DATABASE_URL` points to a disposable localhost PostgreSQL DB.

TDD RED evidence:

```text
services/api/internal/config/config_test.go: cfg.Database undefined
github.com/agentwego/noema/services/api/internal/persistence: no non-test Go files
```

GREEN verification used a disposable `pgvector/pgvector:pg13` container on localhost only:

```text
postgres_ready_after=7s
=== RUN   TestGORMRepositoryPersistsArticleWithAuthor
--- PASS: TestGORMRepositoryPersistsArticleWithAuthor
=== RUN   TestGORMRepositoryRejectsArticleWithoutExistingAuthor
--- PASS: TestGORMRepositoryRejectsArticleWithoutExistingAuthor
PASS
ok github.com/agentwego/noema/services/api/internal/persistence
```

No production database, real Secret, Kubernetes apply/deploy, S3, or Elasticsearch endpoint was touched.

## Boundaries

- Database connection code exists only behind the native persistence seam and is verified with disposable local PostgreSQL; no production DB/Secret is configured or contacted.
- A local mockable Elasticsearch adapter/client seam now exists, but it requires an injected fake/test transport and has no default real HTTP transport. No Elasticsearch/OpenSearch cluster is contacted by local verification.
- No Redis/S3 live clients yet.
- No real credentials or Secret values.
- No Kubernetes apply/deploy.
- No attempt to port Rails routes, controllers, callbacks, or Algolia behavior wholesale.

## Rollback

This slice is fully reversible by removing:

- `go.mod`
- `services/api/**`
- this document entry
- the execution-board task row/status log entry
