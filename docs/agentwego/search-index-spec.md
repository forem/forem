# Noema Elasticsearch Index Spec Builder

## Scope

This slice adds a local-only Elasticsearch index specification builder under `services/api/internal/search/elastic`.

It does **not**:

- connect to Elasticsearch/OpenSearch;
- create indexes or aliases;
- require analyzer plugins;
- read credentials or real Secrets;
- deploy or mutate production.

It prepares the native provider seam from `docs/agentwego/search-architecture.md` by making index names, read aliases, article document fields, and analyzer choices testable before any real cluster smoke.

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

- `services/api/internal/search/elastic/mappings.go`
- `services/api/internal/search/elastic/mappings_test.go`

Current API:

```go
elastic.ArticleIndexSpec(search.IndexFamily{Prefix: "noema", Version: "v1"}, elastic.AnalyzerNGram)
elastic.ArticleIndexSpec(search.IndexFamily{Prefix: "noema", Version: "v1"}, elastic.AnalyzerIK)
```

The spec returns:

- `IndexName`: `noema-articles-v1`
- `ReadAlias`: `noema-articles-read`
- `DocumentFamily`: `articles`
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

## Rollback

Remove:

- `services/api/internal/search/elastic/**`
- this document
- M0-T9 execution-board references

No external state exists to roll back.
