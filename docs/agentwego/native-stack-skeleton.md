# Noema Native Stack Skeleton

## Scope

This artifact opens the first native Go API seam under `services/api` without touching production, real Secrets, databases, Redis, S3, Elasticsearch, Kubernetes, or irreversible data.

The skeleton is intentionally small:

- `go.mod` at repo root with module `github.com/agentwego/noema`.
- `services/api/cmd/api` starts a local HTTP server.
- `services/api/internal/config` reads non-secret env knobs only.
- `services/api/internal/http` exposes `/healthz` for local smoke checks and a minimal `/search` contract endpoint backed by the search provider seam. Health reports the actual injected provider identity via `Provider.Name()`, including local/test unknown-provider fallback to noop; non-local envs fail fast on unavailable providers.
- `services/api/internal/search` defines the native search provider/index seam and a no-op provider for bootstrap tests.

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

## Boundaries

- No database connection code yet.
- No Redis/S3/Elasticsearch clients yet.
- No real credentials or Secret values.
- No Kubernetes apply/deploy.
- No attempt to port Rails routes, controllers, callbacks, or Algolia behavior wholesale.

## Rollback

This slice is fully reversible by removing:

- `go.mod`
- `services/api/**`
- this document entry
- the execution-board task row/status log entry
