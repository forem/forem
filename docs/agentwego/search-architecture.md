# Noema Search Architecture

> **For Hermes:** Search is a first-class Noema backend module. Do not let the legacy Rails Algolia/PostgreSQL search shape become the native architecture by accident.

## Goal

Design Noema search as a derived read model backed by Elasticsearch, with PostgreSQL as source of truth and a PostgreSQL fallback provider only for bootstrap/degraded mode.

## Source of Truth and Consistency

- PostgreSQL stores canonical users, articles, comments, tags, organizations, and moderation state.
- Elasticsearch stores denormalized searchable documents.
- API writes commit to PostgreSQL first.
- Search indexing is async by default.
- User-facing search may be eventually consistent.
- Critical admin flows may request synchronous refresh only when explicitly justified.

## Provider Boundary

The rest of the backend should call a stable interface, not Elasticsearch request bodies.

`SearchRequest` normalization is part of the provider seam: trim query whitespace, default empty/non-positive limits to `DefaultSearchLimit` (`20`), and clamp excessive limits to `MaxSearchLimit` (`100`). No provider should bypass this contract.

```go
type Provider interface {
    Search(ctx context.Context, req SearchRequest) (*SearchResult, error)
    UpsertArticle(ctx context.Context, article ArticleDocument) error
    DeleteArticle(ctx context.Context, id string) error
    UpsertComment(ctx context.Context, comment CommentDocument) error
    DeleteComment(ctx context.Context, id string) error
    UpsertUser(ctx context.Context, user UserDocument) error
    UpsertTag(ctx context.Context, tag TagDocument) error
    BulkIndex(ctx context.Context, batch []Document) error
    EnsureIndexes(ctx context.Context) error
}
```

The first HTTP route using this seam is intentionally narrow: `GET /search?q=<query>&limit=<n>` parses query parameters, rejects non-integer `limit` with `400 {"error":"invalid limit"}`, delegates to the selected provider, and returns the provider-normalized JSON contract `{provider, query, limit, hits}`. Unsupported methods return `405 {"error":"method not allowed"}` and provider failures return `503 {"error":"search unavailable"}` without leaking backend error details. It is a local contract stub, not a production-ranking implementation.

Only `internal/search/elastic` should know index names, aliases, mappings, analyzers, bulk API shapes, retry/backoff, and alias swaps.

## Native Module Layout

```text
services/api/internal/search/
  index.go
  documents.go
  errors.go
  elastic/
    client.go
    mappings.go
    indexer.go
    query.go
    aliases.go
    reindex.go
  fallback/
    postgres.go
```

## Index Family

Versioned write targets:

```text
noema-articles-v1
noema-comments-v1
noema-users-v1
noema-tags-v1
```

Runtime read aliases:

```text
noema-articles-read
noema-comments-read
noema-users-read
noema-tags-read
```

Future write aliases, if needed:

```text
noema-articles-write
noema-comments-write
noema-users-write
noema-tags-write
```

Backfills write to a new versioned index and atomically swap aliases after validation.

## Document Families

### ArticleDocument

Fields should include at minimum:

- id
- slug/path
- title
- body excerpt/search text
- tags
- author id/username/name
- organization id/name/slug
- published state
- published_at
- score/signals needed for ranking
- language
- moderation visibility flags

### CommentDocument

- id
- article id
- user id/username
- body text
- created_at
- score
- visibility/moderation flags

### UserDocument

- id
- username
- name
- profile summary
- organization memberships if needed for search
- visibility/suspension flags

### TagDocument

- id/name
- alias
- short summary
- supported/suggested flags
- hotness or ranking score

## Chinese and Mixed-Language Analyzer Requirement

Chinese search is a production requirement candidate and must be verified against the actual Elasticsearch/OpenSearch cluster before production indexing.

Candidate analyzers:

1. IK analyzer if plugin management is acceptable and available.
2. SmartCN if plugin availability is simpler but precision tradeoffs are acceptable.
3. N-gram fallback for compatibility and mixed Chinese/English recall.

Spike acceptance:

```text
EnsureIndexes creates versioned article index
BulkIndex inserts sample Chinese and English articles
Search returns Chinese and English matches
Alias points to expected versioned index
Analyzer decision is documented with real cluster/plugin evidence
```

## Reindexing and Incremental Updates

Required native worker paths:

- full reindex from PostgreSQL to Elasticsearch;
- per-article upsert on publish/update/delete;
- comment upsert/delete on create/update/delete/moderation;
- user/profile index update;
- tag index update;
- dead-letter logging for failed bulk operations;
- idempotent retry;
- alias swap validation.

Every native write path must declare post-commit side effects explicitly. Avoid Rails-style hidden callback cascades.

## Runtime Config

```text
SEARCH_PROVIDER=elasticsearch|postgres
ELASTICSEARCH_ENABLE=true
ELASTICSEARCH_URL
ELASTICSEARCH_USERNAME
ELASTICSEARCH_PASSWORD
ELASTICSEARCH_INDEX_PREFIX=noema
ELASTICSEARCH_BULK_SIZE
ELASTICSEARCH_REQUEST_TIMEOUT
```

## Observability

Expose metrics/logs for:

- search request latency;
- Elasticsearch error rate;
- bulk indexing success/failure counts;
- indexing queue lag;
- index document counts;
- alias target versions;
- dead-letter counts;
- fallback-provider activation.

## Legacy Search Rows to Cover

Use the inventory CSV before implementing search slices. Initial high-value legacy references:

| Legacy file | Reason |
| --- | --- |
| `app/controllers/search_controller.rb` | route semantics, params, result families |
| `app/services/search/article.rb` | article search behavior reference |
| `app/services/search/comment.rb` | comment search behavior reference |
| `app/services/search/user.rb` | user search behavior reference |
| `app/services/search/username.rb` | username autocomplete/search reference |
| `app/services/search/tag.rb` | tag search behavior reference |
| `app/services/search/reading_list.rb` | reading-list search/reference behavior |
| `app/models/concerns/algolia_searchable/**` | legacy index fields and anti-patterns to avoid |
| `app/workers/algolia_search/search_index_worker.rb` | async indexing behavior reference |

## Fallback Provider

`fallback/postgres.go` should be intentionally limited:

- bootstrap empty search route;
- degraded operation when Elasticsearch disabled;
- simple title/body/tag lookup;
- no attempt to reproduce ES ranking fully.

Any production use of fallback should be visible in metrics/logs.

## Risks

1. Treating Elasticsearch as optional too long will make it bolted-on.
2. Analyzer/plugin mismatch can break Chinese search quality or deployment.
3. GORM model leakage into search docs will couple write schema to read model.
4. Rails callbacks hide indexing and cache effects; native writes must make effects explicit.
5. Legacy Algolia behavior may include product semantics worth preserving, but Algolia implementation should not be ported as architecture.
