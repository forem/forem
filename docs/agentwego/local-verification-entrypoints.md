# Noema Local Verification Entrypoints

## Scope

This document records the local-only verification tasks added for Noema M0 work. These commands are intentionally safe:

- no production access;
- no real Secret reads or writes;
- no database/user/bucket/index creation;
- no Kubernetes apply/deploy;
- no irreversible data operations.

## Taskfile Entrypoints

`Taskfile.yml` adds the following commands:

| Task | Purpose | Side effects |
| --- | --- | --- |
| `task go:fmt` | Format native Go API skeleton files. | Rewrites local Go files only. |
| `task go:test` | Run `go test ./services/api/...`. | None beyond Go test cache. |
| `task api:smoke` | Run `scripts/noema_api_smoke.py`: build the native API to `/tmp`, start it on unused local ports, verify `/healthz`, `/healthz` unsupported-method JSON `405`, `/search`, `/search` JSON error paths (`invalid limit`, `missing query`, unsupported method), `POST /legacy-import/preview`, `POST /legacy-import/batch-preview`, unsupported-method JSON `405`, unknown-route JSON `404`, and unknown-provider fallback to noop, then terminate each process group and remove the temp binary. | Starts and kills local processes; writes a temporary `/tmp/noema-api-smoke-*` binary. |
| `task agentwego:gates` | Check inventory counts and control-plane docs. | Read-only. |
| `task k8s:render` | Render `deploy/k8s/base` to `/tmp/noema-rendered.yaml`. | Writes `/tmp/noema-rendered.yaml`; never applies. |
| `task search:manifest` | Render the native search index manifest to `/tmp/noema-search-index-manifest.json` and validate schema/family coverage. | Writes a local `/tmp` JSON artifact only; never contacts Elasticsearch. |
| `task search:bootstrap-plan` | Render the native search bootstrap plan to `/tmp/noema-search-bootstrap-plan.json` and validate review-only step coverage. | Writes a local `/tmp` JSON artifact only; never contacts Elasticsearch or mutates aliases/indexes. |
| `task search:rollback-plan` | Render the native search rollback plan to `/tmp/noema-search-rollback-plan.json` and validate reverse review-only step coverage. | Writes a local `/tmp` JSON artifact only; never contacts Elasticsearch or deletes/mutates aliases/indexes. |
| `task search:adapter-test` | Run the local fake-transport Elasticsearch adapter/client contract tests for `EnsureIndexes`, `BulkIndex`, and `Search`. | Go test cache only; never contacts Elasticsearch/OpenSearch or reads credentials. |
| `task persistence:test` | Run config and native persistence tests. Persistence integration tests are active only when `NOEMA_TEST_DATABASE_URL` points to a disposable local PostgreSQL database; otherwise they skip DB mutation. | Local Go test cache; optional disposable localhost DB only when explicitly supplied. |
| `task legacyimport:test` | Run local Forem article/user to Noema clean domain DTO mapping tests, including the composed article/user/Kratos-boundary import bundle. | Local Go test cache and checked-in `testdata` fixture only; never reads an external DB/S3/Elasticsearch/Kratos or credentials. |
| `task identity:test` | Run local Ory Kratos identity/session boundary DTO tests. | Local Go test cache and checked-in `testdata` fixture only; never contacts Kratos or reads credentials. |
| `task import:preview-test` | Run the M0-T34 local import preview tests across `identity`, `legacyimport`, and `http`: Kratos target adapter spec, preview service, and `POST /legacy-import/preview` route. | Local Go test cache and checked-in fixtures only; never writes DB/search, contacts Kratos, or reads credentials. |
| `task import:batch-preview-test` | Run the M0-T35 local batch preview and KratosOperationPlan tests across `identity`, `legacyimport`, and `http`: review-only Admin/Public operation plans, mixed batch preview, and `POST /legacy-import/batch-preview` route. | Local Go test cache and checked-in fixtures only; never writes DB/search, executes self-service flows, contacts Kratos, or reads credentials. |
| `task compose:config` | Validate `compose.noema.yml` for the native Noema API, PostgreSQL, Redis, and optional Elasticsearch profile without starting services. | Writes `/tmp/noema-compose-config.yaml`; does not create containers, volumes, DBs, indexes, or Secrets. |
| `task compose:up` / `task compose:down` | Start/stop the local native API profile; `compose:up` auto-selects a free `127.0.0.1:19093-19149` port unless `NOEMA_API_PORT` is set. | Starts disposable API/PostgreSQL/Redis containers and removes containers/network on `compose:down`; named dev volumes are left intact for explicit operator cleanup. |
| `task container:api-build` | Build the native API image from `services/api/Dockerfile` with the repository root as build context. | Uses local Docker/BuildKit cache and produces a local `ghcr.io/agentwego/noema-api:sha-<short>` image; no push. |
| `task container:api-smoke` | Run the locally built native API image on a dynamic localhost port and verify `/healthz`. | Starts one disposable Docker container and removes it via trap; no DB/search writes. |
| `task ci:workflow-lint` | Parse checked-in GitHub Actions workflow YAML locally. | Read-only except Python/YAML import cache. |
| `task verify:local` | Run the current low-risk local validation chain. | Formatting, local test cache, temporary local process, `/tmp` manifest/bootstrap-plan/rollback-plan/render/compose output. |

## Verification Output

`task --list` parsed the Taskfile and listed all entries:

```text
* agentwego:gates
* api:smoke
* ci:workflow-lint
* compose:config
* compose:down
* compose:up
* container:api-build
* container:api-smoke
* go:fmt
* go:test
* identity:test
* import:batch-preview-test
* import:preview-test
* k8s:render
* legacyimport:test
* persistence:test
* search:adapter-test
* search:bootstrap-plan
* search:manifest
* search:rollback-plan
* verify:local
```

Full local verification passed:

```bash
task verify:local
```

Key outputs:

```text
?   	github.com/agentwego/noema/services/api/cmd/api	[no test files]
ok  	github.com/agentwego/noema/services/api/cmd/search-manifest	(cached)
ok  	github.com/agentwego/noema/services/api/internal/config	(cached)
ok  	github.com/agentwego/noema/services/api/internal/http	(cached)
ok  	github.com/agentwego/noema/services/api/internal/search	(cached)
ok  	github.com/agentwego/noema/services/api/internal/search/elastic	(cached)
ok  	github.com/agentwego/noema/services/api/internal/search/fallback	(cached)
search manifest ok 4
search bootstrap plan ok 12
```

Native API smoke output:

```json
{
  "env": "test",
  "search_provider": "postgres",
  "service": "noema-api",
  "status": "ok"
}
{
  "error": "method not allowed"
}
{
  "hits": [],
  "limit": 100,
  "provider": "postgres",
  "query": "go native"
}
{
  "error": "invalid limit"
}
{
  "error": "missing query"
}
{
  "error": "method not allowed"
}
{
  "error": "not found"
}
{
  "env": "test",
  "search_provider": "noop",
  "service": "noema-api",
  "status": "ok"
}
{
  "error": "method not allowed"
}
{
  "hits": [],
  "limit": 100,
  "provider": "noop",
  "query": "go native"
}
{
  "error": "invalid limit"
}
{
  "error": "missing query"
}
{
  "error": "method not allowed"
}
{
  "error": "not found"
}
```

AgentWeGo gate output included:

```text
inventory ok 5900
```

Kubernetes render-only output included the expected non-applied resources:

```text
kind: Namespace
kind: Service
kind: Deployment
kind: Deployment
kind: Job
```

Final whitespace check:

```bash
git diff --check
# exits 0
```

## Rollback

Remove `Taskfile.yml`, this document, and the corresponding M0-T8/M0-T11/M0-T13/M0-T15/M0-T16/M0-T17/M0-T18/M0-T19/M0-T20/M0-T21/M0-T22/M0-T23/M0-T24/M0-T25 execution-board references. If only rolling back manifest export, remove `task search:manifest`, the `verify:local` manifest step, and the M0-T11 references. If only rolling back bootstrap-plan preview, remove `task search:bootstrap-plan`, the `verify:local` bootstrap-plan step, and the M0-T13 references. If only rolling back rollback-plan preview, remove `task search:rollback-plan`, the `verify:local` rollback-plan step, and the M0-T15 references. If only rolling back adapter fake-transport coverage, remove `task search:adapter-test`, the `verify:local` adapter step, and the M0-T29 references. If only rolling back legacy import DTO mapping, remove `task legacyimport:test`, the `verify:local` legacy import step, `docs/agentwego/legacy-import-boundary.md`, `services/api/internal/legacyimport/**`, and the M0-T30 references. If only rolling back the local search HTTP contract, remove `/search` handling, the search smoke check, unknown-provider fallback smoke, local/test fallback boundary, empty-query rejection, unknown-route JSON 404 handling, `/healthz` unsupported-method JSON handling, and the M0-T17/M0-T18/M0-T19/M0-T20/M0-T21/M0-T22/M0-T23/M0-T24/M0-T25 references.

## M0-T28 Persistence Seam Verification

The native persistence slice adds `task persistence:test` and is included in `task verify:local`. The aggregate gate runs it without `NOEMA_TEST_DATABASE_URL`, so DB mutation is skipped by default. The targeted integration check uses only a disposable local PostgreSQL container:

```bash
docker run -d --name noema-t28-postgres -e POSTGRES_HOST_AUTH_METHOD=trust -e POSTGRES_USER=postgres -p 127.0.0.1:25433:5432 pgvector/pgvector:pg13
for i in $(seq 1 90); do
  docker exec noema-t28-postgres psql -U postgres -d postgres -c 'drop database if exists noema_t28_test' >/dev/null 2>&1 && \
  docker exec noema-t28-postgres psql -U postgres -d postgres -c 'create database noema_t28_test' >/dev/null 2>&1 && break
  sleep 1
done
NOEMA_TEST_DATABASE_URL='postgres://postgres@127.0.0.1:25433/noema_t28_test?sslmode=disable' GOFLAGS=-mod=mod go test ./services/api/internal/persistence -run 'TestGORMRepository' -count=1 -v
docker rm -f noema-t28-postgres
```

This path does not contact production, read real Secrets, apply Kubernetes manifests, or mutate external DB/S3/Elasticsearch resources.

## M0-T29 Elasticsearch Adapter Contract Verification

The native Elasticsearch adapter/client slice adds `task search:adapter-test` and includes it in `task verify:local`:

```bash
task search:adapter-test
```

Expected local-only output shape:

```text
=== RUN   TestElasticsearchProviderRequiresExplicitTransport
--- PASS: TestElasticsearchProviderRequiresExplicitTransport
=== RUN   TestElasticsearchProviderEnsureIndexesUsesMockableTransport
--- PASS: TestElasticsearchProviderEnsureIndexesUsesMockableTransport
=== RUN   TestElasticsearchProviderBulkIndexUsesWriteAliasesAndNDJSON
--- PASS: TestElasticsearchProviderBulkIndexUsesWriteAliasesAndNDJSON
=== RUN   TestElasticsearchProviderSearchParsesHitsFromMockTransport
--- PASS: TestElasticsearchProviderSearchParsesHitsFromMockTransport
PASS
ok github.com/agentwego/noema/services/api/internal/search/elastic
```

This path uses only a fake in-memory `search.Transport`; it does not contact Elasticsearch/OpenSearch, read real Secrets, create indexes, move aliases, deploy, or mutate external data.

## M0-T30 Legacy Import DTO Verification

The legacy import boundary slice adds `task legacyimport:test` and includes it in `task verify:local`:

```bash
task legacyimport:test
```

Equivalent direct command:

```bash
GOFLAGS=-mod=mod go test ./services/api/internal/legacyimport -count=1 -v
```

Expected local-only output shape:

```text
=== RUN   TestMapForemUserToCleanDomainDTO
--- PASS: TestMapForemUserToCleanDomainDTO
=== RUN   TestMapForemArticleToCleanDomainDTOFromFixture
--- PASS: TestMapForemArticleToCleanDomainDTOFromFixture
=== RUN   TestMapForemArticleRejectsMissingRequiredFields
--- PASS: TestMapForemArticleRejectsMissingRequiredFields
PASS
ok github.com/agentwego/noema/services/api/internal/legacyimport
```

The fixture path is `services/api/internal/legacyimport/testdata/forem_article_with_user.json`. This path uses checked-in local fixture data only; it does not read external DB/S3/Elasticsearch, open network connections, read real Secrets, deploy, or mutate external data.

## M0-T31 Ory Kratos Identity Boundary Verification

The identity boundary slice adds `task identity:test` and includes it in `task verify:local`:

```bash
task identity:test
```

Equivalent direct commands:

```bash
GOFLAGS=-mod=mod go test ./services/api/internal/identity -count=1 -v
GOFLAGS=-mod=mod go test ./services/api/internal/legacyimport -run 'TestMapForemUserIdentityToKratosBoundary' -count=1 -v
```

Expected local-only output shape:

```text
=== RUN   TestKratosIdentityImportFromFixture
--- PASS: TestKratosIdentityImportFromFixture
=== RUN   TestKratosSessionBoundaryFromFixture
--- PASS: TestKratosSessionBoundaryFromFixture
=== RUN   TestSelfServiceFlowKindsAreOryNamed
--- PASS: TestSelfServiceFlowKindsAreOryNamed
PASS
ok github.com/agentwego/noema/services/api/internal/identity
```

The fixture path is `services/api/internal/identity/testdata/kratos_identity_session.json`. This path is pure DTO/spec verification for Ory Kratos identity/session/self-service flow naming; it does not contact Kratos, run self-service flows, read real Secrets, deploy, or mutate identities/sessions.

## M0-T32 Legacy Import Bundle Verification

The composed legacy import bundle slice continues to use `task legacyimport:test`:

```bash
task legacyimport:test
```

Focused direct command:

```bash
GOFLAGS=-mod=mod go test ./services/api/internal/legacyimport -run 'TestBuildForemArticleUserIdentityBundleComposesCleanDTOsAndKratosBoundary' -count=1 -v
```

Expected local-only output shape:

```text
=== RUN   TestBuildForemArticleUserIdentityBundleComposesCleanDTOsAndKratosBoundary
--- PASS: TestBuildForemArticleUserIdentityBundleComposesCleanDTOsAndKratosBoundary
PASS
ok github.com/agentwego/noema/services/api/internal/legacyimport
```

The bundle composes `UserDTO`, `ArticleDTO`, and the Ory Kratos `UserIdentityBoundary` from checked-in fixture data only. It does not contact Kratos, PostgreSQL, S3, Elasticsearch/OpenSearch, Kubernetes, or any external service.

## M0-T33 Explicit Forem User Bundle Verification

The legacy import boundary keeps using `task legacyimport:test`, with a focused guard for split article/user export inputs:

```bash
GOFLAGS=-mod=mod go test ./services/api/internal/legacyimport -run 'TestBuildForemArticleUserIdentityBundleAcceptsExplicitForemUser|TestBuildForemArticleUserIdentityBundleComposesCleanDTOsAndKratosBoundary' -count=1 -v
```

Expected local-only output shape:

```text
=== RUN   TestBuildForemArticleUserIdentityBundleComposesCleanDTOsAndKratosBoundary
--- PASS: TestBuildForemArticleUserIdentityBundleComposesCleanDTOsAndKratosBoundary
=== RUN   TestBuildForemArticleUserIdentityBundleAcceptsExplicitForemUser
--- PASS: TestBuildForemArticleUserIdentityBundleAcceptsExplicitForemUser
PASS
ok github.com/agentwego/noema/services/api/internal/legacyimport
```

The M0-T33 guard verifies that `ForemArticleUserIdentityImport.User` can carry the Forem author/user input explicitly while the bundle still emits clean Noema domain DTOs and an Ory Kratos identity mapping boundary. It does not contact Kratos, PostgreSQL, S3, Elasticsearch/OpenSearch, Kubernetes, or any external service.

## M0-T34 Local Import Preview Service/API Verification

The feature batch adds `task import:preview-test` and includes it in `task verify:local`:

```bash
task import:preview-test
```

Equivalent direct command:

```bash
GOFLAGS=-mod=mod go test ./services/api/internal/identity ./services/api/internal/legacyimport ./services/api/internal/http -run 'TestLocalKratosAdapter|TestPreviewService|TestRouterLegacyImportPreview' -count=1 -v
```

Expected local-only output shape:

```text
=== RUN   TestLocalKratosAdapterPreviewsIdentitySessionAndSelfServiceFlows
--- PASS: TestLocalKratosAdapterPreviewsIdentitySessionAndSelfServiceFlows
=== RUN   TestLocalKratosAdapterRejectsIdentityPreviewWithSensitiveAdminMetadata
--- PASS: TestLocalKratosAdapterRejectsIdentityPreviewWithSensitiveAdminMetadata
=== RUN   TestPreviewServiceBuildsLocalImportPlanFromFixture
--- PASS: TestPreviewServiceBuildsLocalImportPlanFromFixture
=== RUN   TestPreviewServiceReturnsValidationErrorWithoutPlan
--- PASS: TestPreviewServiceReturnsValidationErrorWithoutPlan
=== RUN   TestRouterLegacyImportPreviewBuildsLocalPlanWithoutExternalDependencies
--- PASS: TestRouterLegacyImportPreviewBuildsLocalPlanWithoutExternalDependencies
=== RUN   TestRouterLegacyImportPreviewReturnsJSONErrors
--- PASS: TestRouterLegacyImportPreviewReturnsJSONErrors
PASS
```

The API smoke path now also verifies `POST /legacy-import/preview` and expects `schema_version = noema.legacy-import.preview/v1`, `side_effects = none-local-preview-only`, clean article/user DTO output, and Ory Kratos identity/session/self-service flow preview data. This endpoint is still a local test/preview entry: no production DB, real Secret, S3, Elasticsearch/OpenSearch, live Kratos, deploy, or irreversible mutation.

## M0-T35 Batch Preview + KratosOperationPlan Verification

The next feature batch adds `task import:batch-preview-test` and includes it in `task verify:local`:

```bash
task import:batch-preview-test
```

Equivalent direct command:

```bash
GOFLAGS=-mod=mod go test ./services/api/internal/identity ./services/api/internal/legacyimport ./services/api/internal/http -run 'TestLocalKratosAdapterBuildsReviewOnlyOperationPlans|TestLocalKratosAdapterRejectsSensitiveOperationPlanInput|TestPreviewServiceBuildsBatchWithPerItemErrorsAndOperationPlans|TestPreviewServiceRejectsEmptyBatch|TestRouterLegacyImportBatchPreview' -count=1 -v
```

Expected local-only output shape:

```text
=== RUN   TestLocalKratosAdapterBuildsReviewOnlyOperationPlans
--- PASS: TestLocalKratosAdapterBuildsReviewOnlyOperationPlans
=== RUN   TestLocalKratosAdapterRejectsSensitiveOperationPlanInput
--- PASS: TestLocalKratosAdapterRejectsSensitiveOperationPlanInput
=== RUN   TestPreviewServiceBuildsBatchWithPerItemErrorsAndOperationPlans
--- PASS: TestPreviewServiceBuildsBatchWithPerItemErrorsAndOperationPlans
=== RUN   TestPreviewServiceRejectsEmptyBatch
--- PASS: TestPreviewServiceRejectsEmptyBatch
=== RUN   TestRouterLegacyImportBatchPreviewBuildsMixedLocalPlan
--- PASS: TestRouterLegacyImportBatchPreviewBuildsMixedLocalPlan
=== RUN   TestRouterLegacyImportBatchPreviewReturnsJSONErrors
--- PASS: TestRouterLegacyImportBatchPreviewReturnsJSONErrors
PASS
```

The API smoke path now also verifies `POST /legacy-import/batch-preview` and expects `schema_version = noema.legacy-import.batch-preview/v1`, `side_effects = none-local-preview-only`, partial-success counts, per-item error preservation, and `operation_plans` with `execution = review-only`. This endpoint is still a local test/preview entry: no production DB, real Secret, S3, Elasticsearch/OpenSearch, live Kratos, self-service flow execution, session cookies/tokens, deploy, or irreversible mutation.
