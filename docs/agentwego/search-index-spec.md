# Noema Elasticsearch Index Spec Builder

## Scope

This slice adds a local-only Elasticsearch index specification builder under `services/api/internal/search/elastic`.

It does **not**:

- connect to Elasticsearch/OpenSearch;
- create indexes or aliases;
- require analyzer plugins;
- read credentials or real Secrets;
- deploy or mutate production.

It prepares the native provider seam from `docs/agentwego/search-architecture.md` by making index names, read aliases, document fields, and analyzer choices testable before any real cluster smoke.

## Inventory Rows Covered

| Legacy file | Inventory domain | Target | Why cited |
| --- | --- | --- | --- |
| `app/controllers/search_controller.rb` | search | `services/api/internal/search + apps/web/search` | Search remains behind a native provider seam, not Rails controller behavior. |
| `app/services/search/article.rb` | search | `services/api/internal/search/{elastic,fallback}` | Article document/index field semantics begin here. |
| `app/services/search/comment.rb` | search | `services/api/internal/search/{elastic,fallback}` | Keeps the shared index-family pattern ready for comments. |
| `app/services/search/user.rb` | search | `services/api/internal/search/{elastic,fallback}` | Keeps the shared index-family pattern ready for users. |
| `app/services/search/tag.rb` | search | `services/api/internal/search/{elastic,fallback}` | Keeps the shared index-family pattern ready for tags. |
| `app/workers/algolia_search/search_index_worker.rb` | search | `services/api/internal/search/{elastic,fallback}` | Future indexing workers should consume this provider/index seam rather than legacy Algolia callbacks. |

## Implemented Shape

Files:

- `services/api/internal/search/elastic/client.go`
- `services/api/internal/search/elastic/client_test.go`
- `services/api/internal/search/elastic/mappings.go`
- `services/api/internal/search/elastic/mappings_test.go`
- `services/api/internal/search/elastic/manifest.go`
- `services/api/cmd/search-manifest/main.go`
- `services/api/cmd/search-manifest/main_test.go`
- `services/api/internal/search/elastic/bootstrap_plan.go`
- `services/api/cmd/search-bootstrap-plan/main.go`
- `services/api/cmd/search-bootstrap-plan/main_test.go`
- `services/api/cmd/search-rollback-plan/main.go`
- `services/api/cmd/search-rollback-plan/main_test.go`

Current API:

```go
elastic.ArticleIndexSpec(search.IndexFamily{Prefix: "noema", Version: "v1"}, elastic.AnalyzerNGram)
elastic.ArticleIndexSpec(search.IndexFamily{Prefix: "noema", Version: "v1"}, elastic.AnalyzerIK)
elastic.CommentIndexSpec(search.IndexFamily{Prefix: "noema", Version: "v1"}, elastic.AnalyzerNGram)
elastic.UserIndexSpec(search.IndexFamily{Prefix: "noema", Version: "v1"}, elastic.AnalyzerNGram)
elastic.TagIndexSpec(search.IndexFamily{Prefix: "noema", Version: "v1"}, elastic.AnalyzerNGram)
elastic.AllIndexSpecs(search.IndexFamily{Prefix: "noema", Version: "v1"}, elastic.AnalyzerNGram)
elastic.BuildManifest(search.IndexFamily{Prefix: "noema", Version: "v1"}, elastic.AnalyzerNGram)
elastic.ManifestJSON(search.IndexFamily{Prefix: "noema", Version: "v1"}, elastic.AnalyzerNGram)
elastic.ValidateManifest(elastic.BuildManifest(search.IndexFamily{Prefix: "noema", Version: "v1"}, elastic.AnalyzerNGram))
elastic.BuildBootstrapPlan(search.IndexFamily{Prefix: "noema", Version: "v1"}, elastic.AnalyzerNGram)
elastic.BootstrapPlanJSON(search.IndexFamily{Prefix: "noema", Version: "v1"}, elastic.AnalyzerNGram)
elastic.BuildRollbackPlan(search.IndexFamily{Prefix: "noema", Version: "v1"}, elastic.AnalyzerNGram)
elastic.RollbackPlanJSON(search.IndexFamily{Prefix: "noema", Version: "v1"}, elastic.AnalyzerNGram)
elastic.NewProvider(search.ProviderOptions{IndexFamily: family, Analyzer: elastic.AnalyzerNGram, Transport: fakeTransport})
```

The fifth search slice adds a local CLI for reviewable manifest output:

```bash
go run ./services/api/cmd/search-manifest -prefix noema -version v1 -analyzer ngram
```

`task search:manifest` writes the generated JSON to `/tmp/noema-search-index-manifest.json` and checks the schema/family coverage without touching Elasticsearch.

Each spec returns:

- `IndexName`: versioned index such as `noema-articles-v1`, `noema-comments-v1`, `noema-users-v1`, `noema-tags-v1`
- `ReadAlias`: read alias such as `noema-articles-read`, `noema-comments-read`, `noema-users-read`, `noema-tags-read`
- `WriteAlias`: write alias such as `noema-articles-write`, `noema-comments-write`, `noema-users-write`, `noema-tags-write`
- `DocumentFamily`: one of `articles`, `comments`, `users`, `tags`
- JSON-serializable `Mapping`

The article mapping includes these initial fields:

- `id`
- `path`
- `title`
- `body`
- `tags`
- `author_id`
- `author_username`
- `organization_id`
- `language`
- `published`
- `published_at`
- `score`
- `visible`

The fourth slice extended coverage to all current native search document families:

| Family | Initial required fields |
| --- | --- |
| `comments` | `id`, `article_id`, `body`, `author_id`, `published`, `created_at`, `visible` |
| `users` | `id`, `username`, `name`, `summary`, `joined_at`, `active` |
| `tags` | `id`, `name`, `hotness_score`, `supported`, `created_at` |

## Reviewable Manifest Shape

`BuildManifest` wraps the all-family specs in a stable JSON envelope:

```json
{
  "schema_version": "noema.search.index-manifest/v1",
  "prefix": "noema",
  "version": "v1",
  "analyzer": "ngram",
  "indexes": [
    {
      "document_family": "articles",
      "index_name": "noema-articles-v1",
      "read_alias": "noema-articles-read",
      "mapping": {}
    }
  ]
}
```

The committed CLI prints this manifest to stdout only. The Taskfile validation writes it to `/tmp/noema-search-index-manifest.json` for local review and JSON parsing, deliberately avoiding a committed generated file until the bootstrap/reindex workflow is ready.

`ValidateManifest` adds a local guard before manifest JSON is emitted. It rejects:

- empty schema/prefix/version/analyzer/index list;
- unknown analyzer modes;
- duplicate `document_family`, `index_name`, or `read_alias` values;
- missing/non-JSON mapping objects;
- mappings whose `dynamic` value is not `strict`;
- empty mapping properties.

This catches drift in the local spec builder without contacting an Elasticsearch cluster. Example validation errors covered by tests include `duplicate index_name noema-articles-v1` and `articles mapping dynamic must be strict`.

## Review-Only Bootstrap Plan

`BuildBootstrapPlan` turns the validated manifest into an ordered local preview for future bootstrap/reindex automation. The plan is explicitly marked `review-only` and currently emits three intended steps per document family:

1. `create_index` with the generated mapping;
2. `point_read_alias` to the versioned index;
3. `point_write_alias` to the same versioned index.

The CLI is local-only:

```bash
go run ./services/api/cmd/search-bootstrap-plan -prefix noema -version v1 -analyzer ngram
```

`task search:bootstrap-plan` writes `/tmp/noema-search-bootstrap-plan.json` and validates the schema, safety marker, four-family manifest coverage, and 12 planned steps. It does not contact Elasticsearch, create indexes, move aliases, deploy, read Secrets, or mutate data.

## M0-T29 Mockable Elasticsearch Adapter Boundary

M0-T29 turns the previous review-only specs into the first executable Elasticsearch adapter boundary without contacting a cluster. `services/api/internal/search/elastic/client.go` registers the `elasticsearch` provider and requires an explicit injected `search.Transport`. There is deliberately no default real HTTP transport in this slice, so tests and future wiring must choose their transport intentionally.

Covered operations:

- `EnsureIndexes(ctx)` validates the generated manifest, sends `PUT /<versioned-index>` with the strict mapping, then sends `POST /_aliases` for the read and write aliases of each family.
- `BulkIndex(ctx, docs)` writes Elasticsearch NDJSON to `POST /_bulk` and targets per-family write aliases such as `noema-articles-write` and `noema-users-write`.
- `Search(ctx, req)` normalizes the provider request, queries `POST /noema-articles-read/_search`, and decodes Elasticsearch hits into the stable `search.SearchResult` contract.

The TDD tests use a fake in-memory transport to assert request method/path/body and response decoding. They do not connect to Elasticsearch/OpenSearch, read credentials, create indexes, move aliases, deploy, or mutate external data.

Inventory/edge coverage stays on the search migration path: `app/services/search/article.rb`, `app/services/search/user.rb`, `app/controllers/search_controller.rb`, and `app/workers/algolia_search/search_index_worker.rb` all target `services/api/internal/search/{elastic,fallback}` in the inventory. Dependency edges also show `config/routes.rb -> app/controllers/search_controller.rb`, `app/services/article_api_index_service.rb -> app/services/search/article.rb`, and `app/controllers/search_controller.rb -> app/services/search/tag.rb`, so this slice moves the search controller/service/indexing worker seam forward rather than re-running validation only.

Verification entrypoint:

```bash
task search:adapter-test
# go test ./services/api/internal/search/elastic -run 'TestElasticsearchProvider' -count=1
```

Safety: no endpoint URL, credential, Secret, external Elasticsearch/OpenSearch process, index creation, alias mutation, deployment, or data write is used by this adapter test slice.

## Analyzer Posture

Two local spec modes are supported:

| Mode | Purpose | External requirement |
| --- | --- | --- |
| `AnalyzerNGram` | Safe fallback for mixed Chinese/English recall when plugin availability is unknown. | Built-in tokenizer only. |
| `AnalyzerIK` | Candidate production Chinese analyzer when an actual cluster has IK installed. | Requires real cluster/plugin verification before use. |

This keeps the analyzer decision testable without pretending the real cluster supports IK.

## Verification

TDD RED was observed first:

```bash
go test ./services/api/internal/search/elastic
# github.com/agentwego/noema/services/api/internal/search/elastic: no non-test Go files ...
# FAIL github.com/agentwego/noema/services/api/internal/search/elastic [build failed]
```

GREEN:

```bash
gofmt -w services/api/internal/search/elastic/mappings.go services/api/internal/search/elastic/mappings_test.go
go test ./services/api/internal/search/elastic
go test ./services/api/...
```

Result:

```text
ok  	github.com/agentwego/noema/services/api/internal/search/elastic	0.002s
ok  	github.com/agentwego/noema/services/api/internal/search/elastic	(cached)
```

Full local gate:

```bash
task verify:local
# exits 0
```

Additional cleanup checks after smoke:

```text
no stale smoke processes or listeners
no scripts/__pycache__
```

The all-family extension used the same local-only TDD loop:

```bash
go test ./services/api/internal/search/elastic
# undefined: elastic.AllIndexSpecs / CommentIndexSpec / UserIndexSpec / TagIndexSpec

go test ./services/api/internal/search/elastic
go test ./services/api/...
task verify:local
```

Result:

```text
ok  	github.com/agentwego/noema/services/api/internal/search/elastic	0.002s
no stale smoke processes/listeners; no scripts/__pycache__
```

Manifest export slice verification:

```bash
go test ./services/api/cmd/search-manifest ./services/api/internal/search/elastic
go test ./services/api/...
task search:manifest
task verify:local
```

Observed output:

```text
ok  	github.com/agentwego/noema/services/api/cmd/search-manifest	0.002s
ok  	github.com/agentwego/noema/services/api/internal/search/elastic	(cached)
search manifest ok 4
```

`task search:manifest` only writes `/tmp/noema-search-index-manifest.json`; it does not create indexes, contact a cluster, or leave repository artifacts.

Manifest validation guard slice verification:

```bash
go test ./services/api/internal/search/elastic ./services/api/cmd/search-manifest
go test ./services/api/...
task verify:local
```

Observed output:

```text
ok  	github.com/agentwego/noema/services/api/internal/search/elastic	0.002s
ok  	github.com/agentwego/noema/services/api/cmd/search-manifest	0.001s
search manifest ok 4
```

The RED step was a compile failure for missing `ValidateManifest`; the GREEN behavior covers generated-manifest acceptance, duplicate `index_name` rejection, and non-`strict` mapping rejection.

## Rollback

Remove:

- `services/api/internal/search/elastic/**`
- `services/api/cmd/search-manifest/**`
- this document
- M0-T9 execution-board references
- M0-T10 execution-board references if rolling back the all-family extension
- M0-T11 execution-board references if rolling back the manifest exporter
- M0-T12 execution-board references if rolling back the manifest validation guard
- M0-T13 execution-board references if rolling back the bootstrap-plan preview
- `services/api/cmd/search-rollback-plan/**`, `services/api/internal/search/elastic/rollback_plan.go`, `task search:rollback-plan`, and M0-T15 execution-board references if rolling back the rollback-plan preview

No external state exists to roll back.
