# Noema Native Rewrite Strategy

> **For Hermes:** Treat this as the technical direction for the post-Forem rewrite. Use `subagent-driven-development` for implementation phases after each spike has explicit acceptance criteria.

**Goal:** Rebuild Noema as a cross-platform knowledge community product using Solito/NativeWind clients, a Go/Gin/GORM backend, and native Elasticsearch-backed discovery.

**Architecture:** Keep the Forem fork as a legacy reference and migration source, but do not attempt a line-by-line in-place technology migration. Build a Noema-native backend and clients in parallel, import legacy data through explicit migration tools, then cut traffic over when the new stack passes product and data checks.

**Tech Stack:** Solito / NativeWind / Next.js / React Native Android / React Native Windows spike / Go / Gin / GORM / PostgreSQL / Redis / Elasticsearch / S3-compatible object storage / Kubernetes / GitOps.

---

## Decision Summary

This is a **rewrite**, not a normal stack migration.

The target backend must include **native Elasticsearch support** as a first-class Noema module, not as an optional late plugin bolted onto handlers. PostgreSQL search may exist as a fallback or bootstrap mode, but production discovery should be designed around Elasticsearch indexes, analyzers, reindexing, and operational rollback from the beginning.

## Scope

### Clients

- Web: Solito + Next.js + NativeWind.
- Android: Solito + React Native + NativeWind.
- Windows: React Native Windows compatibility spike first; do not let Windows block Web/Android MVP.

### Backend

- Go API using Gin.
- GORM for PostgreSQL persistence.
- Redis for sessions, cache, rate limits, queues, and short-lived coordination.
- Native Elasticsearch integration for article/comment/user/tag discovery.
- S3-compatible object storage for uploads and media assets.

### Legacy Compatibility

- Forem remains a reference for product semantics and legacy import only.
- Noema should define its own clean domain model.
- Data migration should be explicit: `Forem legacy DB/export -> importer -> Noema DB + Elasticsearch indexes`.

## Backend Module Layout

Recommended initial shape:

```text
services/api/
  cmd/api/main.go
  cmd/worker/main.go
  internal/
    config/
    db/
    http/
    identity/
    articles/
    comments/
    reactions/
    feed/
    notifications/
    moderation/
    media/
    search/
    legacyimport/
```

The `search` module should be deep: callers should not know Elasticsearch request bodies, index aliases, analyzer details, or retry semantics.

```text
internal/search/
  index.go          # domain-facing interface
  documents.go      # ArticleDocument, CommentDocument, UserDocument, TagDocument
  elastic/
    client.go       # Elasticsearch client construction
    mappings.go     # index mappings/settings/analyzers
    indexer.go      # bulk indexing and document upserts
    query.go        # query builders and result hydration
    aliases.go      # alias swap and versioned index operations
  fallback/
    postgres.go     # optional fallback provider for bootstrap/degraded mode
```

## Native Elasticsearch Requirements

### Search Provider Interface

Noema backend should expose a stable internal interface similar to:

```go
type Provider interface {
    Search(ctx context.Context, req SearchRequest) (*SearchResult, error)
    UpsertArticle(ctx context.Context, article ArticleDocument) error
    DeleteArticle(ctx context.Context, id string) error
    BulkIndex(ctx context.Context, batch []Document) error
    EnsureIndexes(ctx context.Context) error
}
```

The rest of the backend calls the `Provider`; only the Elasticsearch adapter knows index names, aliases, mappings, analyzers, bulk API shapes, and retry behavior.

### Indexes

Initial index family:

```text
noema-articles-v1
noema-comments-v1
noema-users-v1
noema-tags-v1
```

Expose aliases for runtime queries:

```text
noema-articles-read
noema-comments-read
noema-users-read
noema-tags-read
```

Backfills should write a versioned index and atomically swap aliases after validation.

### Chinese Search

Elasticsearch must support Chinese tokenization as a first-class requirement. Candidate analyzers:

1. IK analyzer if plugin management is acceptable in the cluster.
2. SmartCN if plugin availability is simpler but precision tradeoffs are acceptable.
3. N-gram fallback for compatibility and mixed-language recall.

Analyzer decision must be documented before production indexing. The first spike should verify actual cluster/plugin availability rather than assuming IK exists.

### Reindexing

Required worker paths:

- full reindex from PostgreSQL to Elasticsearch;
- per-article upsert on publish/update/delete;
- comment index update on create/update/delete/moderation;
- tag/user profile index update;
- dead-letter logging for failed bulk operations;
- idempotent retry.

### Consistency Model

Use PostgreSQL as the source of truth. Elasticsearch is a derived read model.

Expected behavior:

- API writes commit to PostgreSQL first.
- Search indexing is async by default.
- User-facing search may be eventually consistent.
- Critical admin actions can request synchronous index refresh only when necessary.

### Operations

Required configuration:

```text
ELASTICSEARCH_URL
ELASTICSEARCH_USERNAME
ELASTICSEARCH_PASSWORD
ELASTICSEARCH_INDEX_PREFIX=noema
ELASTICSEARCH_ENABLE=true
ELASTICSEARCH_BULK_SIZE
ELASTICSEARCH_REQUEST_TIMEOUT
SEARCH_PROVIDER=elasticsearch|postgres
```

Required observability:

- search request latency;
- Elasticsearch error rate;
- bulk indexing success/failure counts;
- queue lag;
- index document counts;
- alias target versions;
- failed indexing dead-letter counts.

## MVP Vertical Slice

First functional slice should prove:

1. Create article through Go API.
2. Persist article in PostgreSQL.
3. Queue indexing job.
4. Index article into Elasticsearch.
5. Query article by Chinese and English terms.
6. Render search results in Solito web.
7. Verify fallback/degraded mode if Elasticsearch is disabled.

## Spikes

### Spike 1: Go API Skeleton

Acceptance:

```text
GET /api/health returns 200
GET /api/search?q=test returns 200 with empty result set
PostgreSQL connection is configured through environment variables
Redis connection is configured through environment variables
```

### Spike 2: Elasticsearch Adapter

Acceptance:

```text
EnsureIndexes creates versioned article index
BulkIndex inserts sample articles
Search returns Chinese and English matches
Alias points to the expected versioned index
```

### Spike 3: Client Search Screen

Acceptance:

```text
Web search screen queries Go API
Android search screen renders the same shared Solito screen
NativeWind styles apply on both targets
```

### Spike 4: Windows Compatibility

Acceptance:

```text
React Native Windows project builds
A minimal shared screen renders
If NativeWind is incompatible, document fallback styling path
```

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Treating Elasticsearch as optional too long | Search architecture becomes bolted-on | Build `internal/search` provider seam in the first backend skeleton |
| Analyzer/plugin mismatch | Chinese search quality or deployment breaks | Verify real Elasticsearch cluster/plugin support in a spike |
| GORM model leakage into API/search | Tight coupling and hard migrations | Keep domain documents separate from GORM models |
| Windows support blocks MVP | Schedule blow-up | Web/Android first; Windows spike as Tier 2 |
| Legacy Forem schema copied blindly | New system inherits old complexity | Use explicit importer and clean Noema domain model |

## First Branches

Recommended order:

```text
1. docs/noema-native-rewrite-strategy
2. spike/native-stack-skeleton
3. spike/go-api-gorm-postgres-redis
4. spike/elasticsearch-provider
5. spike/solito-web-android-search
6. spike/react-native-windows
```

Each branch should land one coherent artifact with real verification output.
