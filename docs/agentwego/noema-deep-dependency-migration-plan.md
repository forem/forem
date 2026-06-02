# Noema Deep Dependency and File-by-File Migration Plan

> **For Hermes:** This is the detailed migration planning artifact for the Forem-derived Noema codebase. Use `subagent-driven-development` only after a phase is selected; every implementation task should cite the inventory CSV rows it covers.

**Goal:** Convert the Forem-derived Rails/Preact codebase into Noema's native Solito/NativeWind + Go/Gin/GORM/PostgreSQL/Redis/Elasticsearch/S3 architecture without pretending this is a line-by-line port.

**Architecture:** Keep the current repository as a legacy reference and migration input. Build deep Noema modules around stable seams: `identity`, `articles`, `comments`, `reactions`, `feed`, `search`, `notifications`, `media`, `moderation`, `admin`, and `legacyimport`. PostgreSQL is source of truth; Elasticsearch is a derived read model; Redis is cache/session/queue coordination; S3-compatible storage is the media backend.

**Generated from:** codegraph SQLite index + native `mcp_codegraph_*` checks + git tracked file inventory in `/home/yun/Desktop/noema`.

---

## Generated companion files

| File | Purpose |
| --- | --- |
| `docs/agentwego/noema-file-migration-inventory.csv` | One row per migrated/reviewed code/config/test file: source file, line count, domain, target module, disposition, phase, symbol count, dependency fan-in/out. |
| `docs/agentwego/noema-file-dependency-edges.csv` | File-to-file dependency edges from codegraph: source, target, edge counts, and domains/phases. |
| `docs/agentwego/noema-domain-dependency-summary.csv` | Aggregated domain-to-domain dependency graph. |
| `docs/agentwego/noema-model-dependency-map.csv` | Rails model associations/callbacks/scopes/includes for schema/import planning. |
| `docs/agentwego/noema-controller-map.csv` | Controller filters and service calls for route/API contract planning. |
| `docs/agentwego/noema-worker-map.csv` | Sidekiq worker queue options and service-call hints for worker rewrite planning. |

## Repository coverage

- Git tracked files: **6816**
- Code/config/test files in migration inventory: **5900**
- Codegraph indexed files: **4638**
- Codegraph nodes: **28438**
- Codegraph edges: **45297**
- Legacy DB tables found in `db/schema.rb`: **124**
- Rails route nodes found by codegraph: **1100**

### Inventory by phase

| Phase | Files | Meaning |
| --- | --- | --- |
| P2 | 1740 | Presentation/content/media/notifications/workers. |
| P6 | 1727 | Test conversion. |
| P0 | 1301 | Legacy schema/runtime extraction: routes, DB schema, env, CI, deploy mapping. |
| P1 | 525 | Core domain/API/search slice. |
| P3 | 348 | Secondary platform modules. |
| P9 | 143 | Manual review/unknown platform leftovers. |
| P4 | 86 | Admin/backoffice rebuild. |
| P5 | 30 | External integrations and monetization providers. |

### Inventory by domain

| Domain | Files | Approx lines | Symbols | Primary target | Phase mix |
| --- | --- | --- | --- | --- | --- |
| tests | 1536 | 214553 | 10658 | services/api tests + apps/* tests | P6:1536 |
| presentation | 917 | 40435 | 358 | apps/web screens/components | P2:917 |
| legacy-schema | 915 | 9788 | 2862 | services/api/internal/legacyimport/schema-map | P0:915 |
| frontend | 585 | 63333 | 3814 | apps/web + packages/ui Solito/NativeWind | P2:306, P6:189, P1:90 |
| runtime-config | 344 | 36469 | 213 | deploy/k8s + services/api/internal/config | P0:344 |
| service | 184 | 13604 | 1600 | services/api/internal/<domain> | P3:140, P1:44 |
| assets | 182 | 30040 | 145 | apps/web/public + S3/static assets | P2:182 |
| shared-lib | 178 | 3707 | 757 | services/api/internal/platform or packages | P3:178 |
| platform | 143 | 33576 | 438 | legacy/reference | P9:143 |
| jobs | 129 | 3744 | 556 | services/api/cmd/worker + internal/jobs | P2:129 |
| web-rails-controller | 104 | 9291 | 869 | apps/web routes + services/api handlers | P2:82, P1:22 |
| domain-model | 86 | 4976 | 556 | services/api/internal/domain + gorm models | P1:86 |
| public-api | 84 | 3532 | 572 | services/api/internal/http/handlers | P1:84 |
| content-rendering | 80 | 4793 | 528 | services/api/internal/contentrender + client embeds | P2:80 |
| admin | 63 | 4755 | 581 | apps/web/admin + services/api/internal/admin | P4:63 |
| integrations | 41 | 4680 | 375 | services/api/internal/integrations/<provider> | P5:30, P1:11 |
| authorization | 38 | 1496 | 303 | services/api/internal/authz | P1:38 |
| notifications | 37 | 1612 | 244 | services/api/internal/notifications + worker | P2:34, P1:3 |
| devops | 35 | 1921 | 0 | deploy/gitops + CI | P0:35 |
| email | 30 | 2562 | 211 | services/api/internal/email + templates | P3:30 |
| admin-ui | 25 | 1882 | 213 | apps/web + packages/ui Solito/NativeWind | P4:23, P6:2 |
| identity/profile | 24 | 2116 | 235 | services/api/internal/identity | P1:24 |
| articles/feed | 23 | 1950 | 211 | services/api/internal/articles + feed + search | P1:23 |
| articles/content | 18 | 3686 | 276 | services/api/internal/articles + search documents | P1:18 |
| search | 17 | 963 | 96 | services/api/internal/search/{elastic,fallback} | P1:17 |
| query-read-model | 17 | 996 | 132 | services/api/internal/<domain>/queries | P1:17 |
| media | 10 | 702 | 83 | services/api/internal/media + S3 adapter | P2:10 |
| api-serialization | 9 | 191 | 27 | services/api/internal/http/dto | P1:9 |
| validation | 9 | 281 | 40 | services/api/internal/<domain>/validation | P1:9 |
| settings | 7 | 789 | 46 | services/api/internal/settings | P1:7 |
| monetization | 5 | 937 | 73 | services/api/internal/monetization (post-MVP) | P1:5 |
| comments | 5 | 578 | 74 | services/api/internal/comments | P1:5 |
| organizations | 5 | 503 | 56 | services/api/internal/organizations | P1:5 |
| media/podcasts | 5 | 238 | 30 | services/api/internal/media (post-MVP) | P1:5 |
| routing | 4 | 898 | 1104 | services/api/internal/http/router + apps/web routes | P0:4 |
| reactions | 3 | 383 | 51 | services/api/internal/reactions | P1:3 |
| legacy-data | 3 | 3425 | 48 | services/api/internal/legacyimport | P0:3 |

---

## Dependency structure: high-level seams

### 1. Rails global shell

The current app is centered on Rails global runtime state: `ApplicationController`, `ApplicationMetalController`, `ApplicationRecord`, `config/routes*.rb`, `Settings::*`, `ApplicationConfig`, `RequestStore`, `Rails.cache`, `current_user`, Pundit, and Sidekiq.

**Migration rule:** Do not port this shell. Extract behavior contracts and rebuild explicit Go interfaces:

```text
services/api/internal/http/router
services/api/internal/config
services/api/internal/authn
services/api/internal/authz
services/api/internal/cache
services/api/internal/jobs
```

### 2. Core content graph

```text
User ─┬─ Article ─┬─ Comment ── Mention/Notification
      │           ├─ Reaction
      │           ├─ Tag / Collection / FeedConfig / PinnedArticle
      │           └─ Organization/Subforem context
      ├─ Follow ── User | Tag | Organization | Podcast
      ├─ ReadingList via Reaction category
      └─ NotificationSubscription / Settings / Profile
```

In Rails this graph is spread across ActiveRecord models, callbacks, service objects, decorators, serializers, and controllers. In Noema it should become a small number of deep modules with explicit APIs.

### 3. Search/read-model path

Observed legacy path:

```text
SearchController#feed_content
  ├─ Search::Article.search_documents
  │   └─ Homepage::ArticlesQuery.call
  │       └─ ActiveRecord relation + search_articles
  ├─ Search::Comment/User/Organization/PodcastEpisode/Tag
  └─ Algolia presence can short-circuit non-homepage results
```

**Migration rule:** Search becomes `services/api/internal/search` with Elasticsearch provider and PostgreSQL fallback.

### 4. Async side effects

Sidekiq currently hides notification creation/update/removal, feed/cache busting, image/social preview generation, follows/audience segments, digest/email, data scripts, and scheduled automations.

**Migration rule:** Replace Sidekiq class-per-job with typed Go jobs. Every native write path must declare post-commit effects explicitly.

### 5. Frontend/presentation

Current UI is Rails ERB + Preact packs + global DOM helpers. Target is Solito + NativeWind shared screens. Extract page contracts and DTO shapes; rewrite UI components.

---

## Top dependency hotspots

| File | Phase | Domain | Symbols | Out | In | Target |
| --- | --- | --- | --- | --- | --- | --- |
| spec/lib/request_store_spec.rb | P6 | tests | 4 | 4 | 1160 | services/api tests + apps/* tests |
| config/routes.rb | P0 | routing | 617 | 378 | 20 | services/api/internal/http/router + apps/web routes |
| spec/models/article_spec.rb | P6 | tests | 297 | 300 | 355 | services/api tests + apps/* tests |
| app/controllers/concerns/api/profile_images_controller.rb | P1 | public-api | 7 | 8 | 840 | services/api/internal/http/handlers |
| app/models/article.rb | P1 | articles/content | 128 | 448 | 204 | services/api/internal/articles + search documents |
| app/models/user.rb | P1 | identity/profile | 97 | 241 | 422 | services/api/internal/identity |
| config/routes/admin.rb | P0 | routing | 376 | 213 | 7 | services/api/internal/http/router + apps/web routes |
| app/liquid_tags/agent_session_tag.rb | P2 | content-rendering | 6 | 14 | 522 | services/api/internal/contentrender + client embeds |
| app/controllers/application_controller.rb | P2 | web-rails-controller | 53 | 199 | 276 | apps/web routes + services/api handlers |
| spec/services/markdown_processor/parser_spec.rb | P6 | tests | 158 | 158 | 173 | services/api tests + apps/* tests |
| app/decorators/notification_decorator.rb | P2 | presentation | 50 | 110 | 327 | apps/web screens/components |
| app/lib/url.rb | P9 | platform | 19 | 70 | 383 | legacy/reference |
| spec/services/analytics_service_spec.rb | P6 | tests | 147 | 148 | 153 | services/api tests + apps/* tests |
| app/services/github/oauth_client.rb | P5 | integrations | 16 | 41 | 376 | services/api/internal/integrations/<provider> |
| app/javascript/utilities/podcastPlayback.js | P2 | frontend | 40 | 189 | 182 | apps/web + packages/ui Solito/NativeWind |
| spec/models/billboard_spec.rb | P6 | tests | 118 | 118 | 165 | services/api tests + apps/* tests |
| app/models/comment.rb | P1 | comments | 59 | 174 | 163 | services/api/internal/comments |
| app/controllers/stories_controller.rb | P2 | web-rails-controller | 49 | 244 | 97 | apps/web routes + services/api handlers |
| app/controllers/admin/users_controller.rb | P4 | admin | 47 | 241 | 73 | apps/web/admin + services/api/internal/admin |
| spec/requests/api/v1/articles_spec.rb | P6 | tests | 114 | 115 | 127 | services/api tests + apps/* tests |
| app/services/reaction_handler.rb | P1 | service | 27 | 98 | 219 | services/api/internal/<domain> |
| app/helpers/application_helper.rb | P2 | presentation | 61 | 186 | 78 | apps/web screens/components |
| app/services/notification_subscriptions/subscribe.rb | P3 | service | 10 | 18 | 289 | services/api/internal/<domain> |
| app/models/organization.rb | P1 | organizations | 40 | 100 | 170 | services/api/internal/organizations |
| spec/requests/api/v0/articles_spec.rb | P6 | tests | 99 | 102 | 105 | services/api tests + apps/* tests |
| app/controllers/application_metal_controller.rb | P2 | web-rails-controller | 7 | 12 | 285 | apps/web routes + services/api handlers |
| app/controllers/api/v1/admin/base_controller.rb | P1 | public-api | 9 | 12 | 260 | services/api/internal/http/handlers |
| app/models/billboard.rb | P1 | monetization | 46 | 136 | 95 | services/api/internal/monetization (post-MVP) |
| app/assets/javascripts/lib/xss.js | P2 | assets | 3 | 4 | 265 | apps/web/public + S3/static assets |
| app/services/analytics_service.rb | P3 | service | 35 | 156 | 74 | services/api/internal/<domain> |

## Route and schema anchors

### Route source files

| File | Route nodes |
| --- | --- |
| config/routes.rb | 612 |
| config/routes/admin.rb | 371 |
| config/routes/api.rb | 91 |
| config/routes/listing.rb | 18 |
| spec/requests/api/v0/api_controller_spec.rb | 7 |
| spec/requests/api/v1/admin/base_controller_spec.rb | 1 |

### Largest schema tables by column/index count

| Table | Columns | Indexes |
| --- | --- | --- |
| articles | 125 | 0 |
| users | 116 | 0 |
| display_ads | 57 | 0 |
| organizations | 54 | 0 |
| feed_configs | 38 | 0 |
| comments | 34 | 0 |
| tags | 30 | 0 |
| podcast_episodes | 29 | 0 |
| users_settings | 29 | 0 |
| tweets | 28 | 0 |
| podcasts | 26 | 0 |
| events | 24 | 0 |
| pages | 23 | 0 |
| ahoy_messages | 22 | 0 |
| classified_listings | 22 | 0 |
| notifications | 22 | 0 |
| ai_audits | 19 | 0 |
| github_repos | 19 | 0 |
| users_notification_settings | 19 | 0 |
| page_views | 18 | 0 |
| feed_import_logs | 17 | 0 |
| polls | 17 | 0 |
| scheduled_automations | 17 | 0 |
| user_activities | 17 | 0 |
| feed_sources | 16 | 0 |
| feedback_messages | 16 | 0 |
| reactions | 16 | 0 |
| taggings | 16 | 0 |
| trends | 16 | 0 |
| user_queries | 16 | 0 |

---

## Migration module map

### Target backend layout

```text
services/api/
  cmd/api/main.go
  cmd/worker/main.go
  internal/
    config/ db/ http/ authn/ authz/
    identity/ articles/ comments/ reactions/ follows/ feed/
    notifications/ moderation/ media/ search/ organizations/
    settings/ admin/ integrations/ legacyimport/ jobs/
```

### Target client layout

```text
apps/web/
apps/mobile/
packages/ui/
packages/api-client/
packages/content-render/
```

---

## File-by-file disposition policy

The inventory CSV uses these disposition categories:

1. `re-design model semantics, do not line-port ActiveRecord` — model files become domain structs, importer mappings, validation tests, and repository methods.
2. `reimplement REST contract selectively` — API controllers become Gin handlers and request/response DTOs.
3. `split SSR/client routing from API semantics` — web controllers become client routes plus backend endpoints.
4. `replace with provider seam + ES indexes` — `app/services/search/**` and Algolia-related files become the Noema search provider module.
5. `rewrite as Solito/Next UI` — ERB/helpers/decorators/Preact become shared screens/components.
6. `replace Sidekiq with Go workers/queue abstraction` — workers become typed jobs with idempotent handlers.
7. `derive importer mappings/seed fixtures` — schema/seeds/migrations are input to `legacyimport`, not replayed wholesale.
8. `convert high-value behavior specs` — specs/cypress are triaged into behavior tests, contract tests, and discarded Rails-coupled tests.

---

## Phase plan

### Phase P0 — Extract legacy contracts and runtime facts

**Objective:** Freeze the legacy semantics before writing native modules.

**Files covered:** `config/routes*.rb`, `db/schema.rb`, `db/migrate/**`, `db/seeds*`, deployment/config files, CI files.

**Tasks:**
1. Generate route matrix from `config/routes.rb`, `config/routes/api.rb`, `config/routes/admin.rb`, `config/routes/listing.rb`.
2. Generate schema map from `db/schema.rb` and migration history.
3. Define legacy-import table mapping: legacy table → Noema table/entity → import priority → validation query.
4. Translate runtime env to `services/api/internal/config` and GitOps Secret shape.
5. Decide what legacy routes are public API compatibility vs UI-only pages.

### Phase P1 — Core vertical slice

**Objective:** Prove Noema native backend with identity, articles, comments, reactions, follows, organizations, and search.

**Source file classes:** `app/models/article.rb`, `app/models/user.rb`, `app/models/comment.rb`, `app/models/reaction.rb`, `app/models/follow.rb`, `app/models/organization.rb`, `app/models/tag.rb`, API controllers/concerns, `app/services/articles/**`, `app/services/search/**`, `app/queries/homepage/**`, `app/serializers/**`, `app/policies/**`, `app/validators/**`.

**Noema target modules:** `internal/identity`, `internal/articles`, `internal/comments`, `internal/reactions`, `internal/follows`, `internal/organizations`, `internal/feed`, `internal/search`, `internal/authz`, `internal/http/handlers`.

**Implementation order:** config/db/http skeleton → identity/auth → articles → comments → reactions/bookmarks → follows → search provider/ES indexes → feed → contract tests.

### Phase P2 — UI, content rendering, media, notifications, workers

**Objective:** Replace Rails/Preact presentation and Sidekiq with native client screens and Go workers.

**Source file classes:** `app/views/**`, `app/helpers/**`, `app/decorators/**`, most `app/javascript/**`, `app/liquid_tags/**`, `app/workers/**`, `app/services/notifications/**`, media/image services.

### Phase P3 — Secondary platform modules

**Objective:** Rebuild email, analytics, miscellaneous services, and shared libraries only after core usage is stable.

### Phase P4 — Admin/backoffice

**Objective:** Rebuild admin as a separate web surface backed by explicit admin APIs.

### Phase P5 — External integrations / monetization

**Objective:** Re-add provider-specific integrations after core Noema is stable.

### Phase P6 — Test conversion

**Objective:** Convert legacy tests into native behavior/contract tests. Preserve behavior tests for article lifecycle, auth, comments, reactions, follows, moderation, search, import validation, and permission checks.

---

## Domain-by-domain hotspots

### tests

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| spec/lib/request_store_spec.rb | P6 | 4 | 4 | 1160 | services/api tests + apps/* tests | convert high-value behavior specs, drop framework-coupled tests |
| spec/models/article_spec.rb | P6 | 297 | 300 | 355 | services/api tests + apps/* tests | convert high-value behavior specs, drop framework-coupled tests |
| spec/services/markdown_processor/parser_spec.rb | P6 | 158 | 158 | 173 | services/api tests + apps/* tests | convert high-value behavior specs, drop framework-coupled tests |
| spec/services/analytics_service_spec.rb | P6 | 147 | 148 | 153 | services/api tests + apps/* tests | convert high-value behavior specs, drop framework-coupled tests |
| spec/models/billboard_spec.rb | P6 | 118 | 118 | 165 | services/api tests + apps/* tests | convert high-value behavior specs, drop framework-coupled tests |
| spec/requests/api/v1/articles_spec.rb | P6 | 114 | 115 | 127 | services/api tests + apps/* tests | convert high-value behavior specs, drop framework-coupled tests |
| spec/requests/api/v0/articles_spec.rb | P6 | 99 | 102 | 105 | services/api tests + apps/* tests | convert high-value behavior specs, drop framework-coupled tests |
| spec/services/authentication/authenticator_spec.rb | P6 | 83 | 83 | 83 | services/api tests + apps/* tests | convert high-value behavior specs, drop framework-coupled tests |

### public-api

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/controllers/concerns/api/profile_images_controller.rb | P1 | 7 | 8 | 840 | services/api/internal/http/handlers | reimplement REST contract selectively |
| app/controllers/api/v1/admin/base_controller.rb | P1 | 9 | 12 | 260 | services/api/internal/http/handlers | reimplement REST contract selectively |
| app/controllers/concerns/api/health_checks_controller.rb | P1 | 8 | 17 | 128 | services/api/internal/http/handlers | reimplement REST contract selectively |
| app/controllers/api/v1/agent_sessions_controller.rb | P1 | 20 | 94 | 28 | services/api/internal/http/handlers | reimplement REST contract selectively |
| app/controllers/concerns/api/organizations_controller.rb | P1 | 9 | 12 | 118 | services/api/internal/http/handlers | reimplement REST contract selectively |
| app/controllers/api/v1/audience_segments_controller.rb | P1 | 15 | 37 | 58 | services/api/internal/http/handlers | reimplement REST contract selectively |
| app/controllers/api/v1/api_controller.rb | P1 | 14 | 22 | 70 | services/api/internal/http/handlers | reimplement REST contract selectively |
| app/controllers/concerns/api/admin/users_controller.rb | P1 | 16 | 66 | 20 | services/api/internal/http/handlers | reimplement REST contract selectively |

### articles/content

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/models/article.rb | P1 | 128 | 448 | 204 | services/api/internal/articles + search documents | re-design model semantics, do not line-port ActiveRecord |
| app/models/pinned_article.rb | P1 | 12 | 24 | 207 | services/api/internal/articles + search documents | re-design model semantics, do not line-port ActiveRecord |
| app/models/article_activity.rb | P1 | 26 | 72 | 47 | services/api/internal/articles + search documents | re-design model semantics, do not line-port ActiveRecord |
| app/models/tag.rb | P1 | 24 | 54 | 35 | services/api/internal/articles + search documents | re-design model semantics, do not line-port ActiveRecord |
| app/models/articles/feeds/relevancy_lever.rb | P1 | 16 | 33 | 25 | services/api/internal/articles + search documents | re-design model semantics, do not line-port ActiveRecord |
| app/models/collection.rb | P1 | 6 | 21 | 17 | services/api/internal/articles + search documents | re-design model semantics, do not line-port ActiveRecord |
| app/models/articles/feeds/lever_catalog_builder.rb | P1 | 11 | 17 | 12 | services/api/internal/articles + search documents | re-design model semantics, do not line-port ActiveRecord |
| app/models/tag_adjustment.rb | P1 | 6 | 19 | 14 | services/api/internal/articles + search documents | re-design model semantics, do not line-port ActiveRecord |

### identity/profile

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/models/user.rb | P1 | 97 | 241 | 422 | services/api/internal/identity | re-design model semantics, do not line-port ActiveRecord |
| app/models/user_query.rb | P1 | 18 | 65 | 30 | services/api/internal/identity | re-design model semantics, do not line-port ActiveRecord |
| app/models/users/deleted_user.rb | P1 | 18 | 20 | 60 | services/api/internal/identity | re-design model semantics, do not line-port ActiveRecord |
| app/models/profile.rb | P1 | 14 | 28 | 48 | services/api/internal/identity | re-design model semantics, do not line-port ActiveRecord |
| app/models/settings/user_experience.rb | P1 | 3 | 3 | 66 | services/api/internal/identity | re-design model semantics, do not line-port ActiveRecord |
| app/models/user_subscription.rb | P1 | 9 | 19 | 20 | services/api/internal/identity | re-design model semantics, do not line-port ActiveRecord |
| app/models/users/setting.rb | P1 | 10 | 17 | 20 | services/api/internal/identity | re-design model semantics, do not line-port ActiveRecord |
| app/models/user_block.rb | P1 | 6 | 10 | 25 | services/api/internal/identity | re-design model semantics, do not line-port ActiveRecord |

### content-rendering

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/liquid_tags/agent_session_tag.rb | P2 | 6 | 14 | 522 | services/api/internal/contentrender + client embeds | port sanitizer/embed whitelist carefully |
| app/liquid_tags/dotnet_fiddle_tag.rb | P2 | 7 | 14 | 118 | services/api/internal/contentrender + client embeds | port sanitizer/embed whitelist carefully |
| app/liquid_tags/liquid_tag_base.rb | P2 | 10 | 15 | 112 | services/api/internal/contentrender + client embeds | port sanitizer/embed whitelist carefully |
| app/liquid_tags/forem_tag.rb | P2 | 9 | 23 | 59 | services/api/internal/contentrender + client embeds | port sanitizer/embed whitelist carefully |
| app/liquid_tags/unified_embed/tag.rb | P2 | 12 | 49 | 19 | services/api/internal/contentrender + client embeds | port sanitizer/embed whitelist carefully |
| app/liquid_tags/feed_tag.rb | P2 | 17 | 42 | 20 | services/api/internal/contentrender + client embeds | port sanitizer/embed whitelist carefully |
| app/liquid_tags/github_tag/github_readme_tag.rb | P2 | 12 | 43 | 18 | services/api/internal/contentrender + client embeds | port sanitizer/embed whitelist carefully |
| app/liquid_tags/bandcamp_tag.rb | P2 | 8 | 41 | 13 | services/api/internal/contentrender + client embeds | port sanitizer/embed whitelist carefully |

### web-rails-controller

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/controllers/application_controller.rb | P2 | 53 | 199 | 276 | apps/web routes + services/api handlers | split SSR/client routing from API semantics |
| app/controllers/stories_controller.rb | P2 | 49 | 244 | 97 | apps/web routes + services/api handlers | split SSR/client routing from API semantics |
| app/controllers/application_metal_controller.rb | P2 | 7 | 12 | 285 | apps/web routes + services/api handlers | split SSR/client routing from API semantics |
| app/controllers/moderations_controller.rb | P2 | 7 | 25 | 230 | apps/web routes + services/api handlers | split SSR/client routing from API semantics |
| app/controllers/users_controller.rb | P1 | 32 | 136 | 87 | apps/web routes + services/api handlers | split SSR/client routing from API semantics |
| app/controllers/subforems_controller.rb | P2 | 31 | 132 | 59 | apps/web routes + services/api handlers | split SSR/client routing from API semantics |
| app/controllers/articles_controller.rb | P1 | 27 | 111 | 76 | apps/web routes + services/api handlers | split SSR/client routing from API semantics |
| app/controllers/comments_controller.rb | P1 | 26 | 115 | 67 | apps/web routes + services/api handlers | split SSR/client routing from API semantics |

### presentation

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/decorators/notification_decorator.rb | P2 | 50 | 110 | 327 | apps/web screens/components | rewrite as Solito/Next UI; preserve copy/UX selectively |
| app/helpers/application_helper.rb | P2 | 61 | 186 | 78 | apps/web screens/components | rewrite as Solito/Next UI; preserve copy/UX selectively |
| app/decorators/article_decorator.rb | P2 | 20 | 46 | 55 | apps/web screens/components | rewrite as Solito/Next UI; preserve copy/UX selectively |
| app/helpers/comments_helper.rb | P2 | 21 | 57 | 23 | apps/web screens/components | rewrite as Solito/Next UI; preserve copy/UX selectively |
| app/helpers/authentication_helper.rb | P2 | 17 | 41 | 20 | apps/web screens/components | rewrite as Solito/Next UI; preserve copy/UX selectively |
| app/decorators/user_decorator.rb | P2 | 12 | 38 | 12 | apps/web screens/components | rewrite as Solito/Next UI; preserve copy/UX selectively |
| app/helpers/agent_sessions_helper.rb | P2 | 11 | 30 | 20 | apps/web screens/components | rewrite as Solito/Next UI; preserve copy/UX selectively |
| app/helpers/articles_helper.rb | P2 | 12 | 38 | 11 | apps/web screens/components | rewrite as Solito/Next UI; preserve copy/UX selectively |

### platform

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/lib/url.rb | P9 | 19 | 70 | 383 | legacy/reference | review |
| app/lib/constants/settings/general.rb | P9 | 5 | 4 | 169 | legacy/reference | review |
| app/lib/menu.rb | P9 | 15 | 17 | 63 | legacy/reference | review |
| app/lib/redcarpet/render/html_rouge.rb | P9 | 12 | 23 | 60 | legacy/reference | review |
| bin/generate-css-utility-classes-docs.js | P9 | 18 | 26 | 43 | legacy/reference | review |
| app/sanitizers/rendered_markdown_scrubber.rb | P9 | 9 | 31 | 15 | legacy/reference | review |
| app/lib/reverse_markdown/converters/custom_text.rb | P9 | 11 | 25 | 16 | legacy/reference | review |
| app/view_objects/twitch_parser.rb | P9 | 10 | 26 | 15 | legacy/reference | review |

### integrations

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/services/github/oauth_client.rb | P5 | 16 | 41 | 376 | services/api/internal/integrations/<provider> | classify and port if in MVP path |
| app/services/mailchimp/bot.rb | P5 | 17 | 103 | 44 | services/api/internal/integrations/<provider> | classify and port if in MVP path |
| app/services/ai/image_generator.rb | P5 | 16 | 90 | 46 | services/api/internal/integrations/<provider> | classify and port if in MVP path |
| app/services/ai/community_copy.rb | P5 | 22 | 89 | 36 | services/api/internal/integrations/<provider> | classify and port if in MVP path |
| app/services/ai/forem_tags.rb | P1 | 21 | 85 | 36 | services/api/internal/integrations/<provider> | classify and port if in MVP path |
| app/services/ai/trend_detector.rb | P5 | 11 | 65 | 18 | services/api/internal/integrations/<provider> | classify and port if in MVP path |
| app/services/ai/github_repo_recap.rb | P5 | 14 | 54 | 21 | services/api/internal/integrations/<provider> | classify and port if in MVP path |
| app/services/ai/subforem_finder.rb | P5 | 11 | 40 | 15 | services/api/internal/integrations/<provider> | classify and port if in MVP path |

### frontend

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/javascript/utilities/podcastPlayback.js | P2 | 40 | 189 | 182 | apps/web + packages/ui Solito/NativeWind | rewrite UI behaviour, keep API/UX reference |
| app/javascript/articles/Article.jsx | P1 | 7 | 24 | 230 | apps/web + packages/ui Solito/NativeWind | rewrite UI behaviour, keep API/UX reference |
| app/javascript/article-form/articleForm.jsx | P1 | 45 | 97 | 79 | apps/web + packages/ui Solito/NativeWind | rewrite UI behaviour, keep API/UX reference |
| app/javascript/analytics/dashboard.js | P2 | 31 | 91 | 74 | apps/web + packages/ui Solito/NativeWind | rewrite UI behaviour, keep API/UX reference |
| app/javascript/packs/followButtons.js | P2 | 23 | 86 | 62 | apps/web + packages/ui Solito/NativeWind | rewrite UI behaviour, keep API/UX reference |
| app/javascript/actionsPanel/actionsPanel.js | P2 | 25 | 70 | 53 | apps/web + packages/ui Solito/NativeWind | rewrite UI behaviour, keep API/UX reference |
| app/javascript/crayons/MarkdownToolbar/markdownSyntaxFormatters.jsx | P2 | 32 | 58 | 50 | apps/web + packages/ui Solito/NativeWind | rewrite UI behaviour, keep API/UX reference |
| app/javascript/readingList/readingList.jsx | P1 | 27 | 65 | 47 | apps/web + packages/ui Solito/NativeWind | rewrite UI behaviour, keep API/UX reference |

### admin

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/controllers/admin/users_controller.rb | P4 | 47 | 241 | 73 | apps/web/admin + services/api/internal/admin | reimplement after core MVP |
| app/controllers/admin/badge_automations_controller.rb | P4 | 15 | 26 | 187 | apps/web/admin + services/api/internal/admin | reimplement after core MVP |
| app/controllers/admin/organizations_controller.rb | P4 | 12 | 73 | 19 | apps/web/admin + services/api/internal/admin | reimplement after core MVP |
| app/controllers/admin/articles_controller.rb | P4 | 15 | 48 | 33 | apps/web/admin + services/api/internal/admin | reimplement after core MVP |
| app/controllers/admin/pages_controller.rb | P4 | 12 | 45 | 24 | apps/web/admin + services/api/internal/admin | reimplement after core MVP |
| app/controllers/admin/feedback_messages_controller.rb | P4 | 13 | 47 | 20 | apps/web/admin + services/api/internal/admin | reimplement after core MVP |
| app/controllers/admin/application_controller.rb | P4 | 6 | 7 | 59 | apps/web/admin + services/api/internal/admin | reimplement after core MVP |
| app/controllers/admin/subforems_controller.rb | P4 | 15 | 36 | 21 | apps/web/admin + services/api/internal/admin | reimplement after core MVP |

### service

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/services/reaction_handler.rb | P1 | 27 | 98 | 219 | services/api/internal/<domain> | classify and port if in MVP path |
| app/services/notification_subscriptions/subscribe.rb | P3 | 10 | 18 | 289 | services/api/internal/<domain> | classify and port if in MVP path |
| app/services/analytics_service.rb | P3 | 35 | 156 | 74 | services/api/internal/<domain> | classify and port if in MVP path |
| app/services/spam/handler.rb | P3 | 24 | 127 | 57 | services/api/internal/<domain> | classify and port if in MVP path |
| app/services/moderator/manage_activity_and_roles.rb | P3 | 26 | 107 | 70 | services/api/internal/<domain> | classify and port if in MVP path |
| app/services/broadcasts/welcome_notification/generator.rb | P3 | 31 | 98 | 70 | services/api/internal/<domain> | classify and port if in MVP path |
| app/services/user_query_executor.rb | P3 | 23 | 74 | 69 | services/api/internal/<domain> | classify and port if in MVP path |
| app/services/feeds/import.rb | P1 | 18 | 102 | 37 | services/api/internal/<domain> | classify and port if in MVP path |

### assets

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/assets/javascripts/lib/xss.js | P2 | 3 | 4 | 265 | apps/web/public + S3/static assets | migrate selected assets; regenerate pipeline |
| app/assets/javascripts/initializers/initScrolling.js | P2 | 29 | 60 | 50 | apps/web/public + S3/static assets | migrate selected assets; regenerate pipeline |
| app/assets/javascripts/initializers/initializeReadingListIcons.js | P2 | 13 | 29 | 29 | apps/web/public + S3/static assets | migrate selected assets; regenerate pipeline |
| app/assets/javascripts/utilities/browserStoreCache.js | P2 | 7 | 12 | 19 | apps/web/public + S3/static assets | migrate selected assets; regenerate pipeline |
| app/assets/javascripts/utilities/sendFetch.js | P2 | 3 | 13 | 22 | apps/web/public + S3/static assets | migrate selected assets; regenerate pipeline |
| app/assets/javascripts/initializers/initializeBaseUserData.js | P2 | 6 | 14 | 11 | apps/web/public + S3/static assets | migrate selected assets; regenerate pipeline |
| app/assets/javascripts/initializers/initializeBroadcast.js | P2 | 6 | 13 | 11 | apps/web/public + S3/static assets | migrate selected assets; regenerate pipeline |
| app/assets/javascripts/utilities/localDateTime.js | P2 | 6 | 10 | 11 | apps/web/public + S3/static assets | migrate selected assets; regenerate pipeline |

### validation

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/validators/profile_validator.rb | P1 | 9 | 34 | 213 | services/api/internal/<domain>/validation | port validation invariants |
| app/validators/cross_model_slug_validator.rb | P1 | 8 | 32 | 12 | services/api/internal/<domain>/validation | port validation invariants |
| app/validators/email_safe_html_validator.rb | P1 | 4 | 15 | 4 | services/api/internal/<domain>/validation | port validation invariants |
| app/validators/enabled_countries_hash_validator.rb | P1 | 3 | 14 | 2 | services/api/internal/<domain>/validation | port validation invariants |
| app/validators/bytesize_validator.rb | P1 | 4 | 10 | 3 | services/api/internal/<domain>/validation | port validation invariants |
| app/validators/valid_domain_csv_validator.rb | P1 | 3 | 6 | 2 | services/api/internal/<domain>/validation | port validation invariants |
| app/validators/color_contrast_validator.rb | P1 | 3 | 5 | 2 | services/api/internal/<domain>/validation | port validation invariants |
| app/validators/emoji_only_validator.rb | P1 | 3 | 5 | 2 | services/api/internal/<domain>/validation | port validation invariants |

### domain-model

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/models/subforem.rb | P1 | 21 | 81 | 134 | services/api/internal/domain + gorm models | re-design model semantics, do not line-port ActiveRecord |
| app/models/application_record.rb | P1 | 14 | 30 | 150 | services/api/internal/domain + gorm models | re-design model semantics, do not line-port ActiveRecord |
| app/models/page.rb | P1 | 20 | 52 | 80 | services/api/internal/domain + gorm models | re-design model semantics, do not line-port ActiveRecord |
| app/models/forem_instance.rb | P1 | 16 | 28 | 67 | services/api/internal/domain + gorm models | re-design model semantics, do not line-port ActiveRecord |
| app/models/tweet.rb | P1 | 10 | 85 | 16 | services/api/internal/domain + gorm models | re-design model semantics, do not line-port ActiveRecord |
| app/models/scheduled_automation.rb | P1 | 19 | 54 | 33 | services/api/internal/domain + gorm models | re-design model semantics, do not line-port ActiveRecord |
| app/models/agent_session.rb | P1 | 19 | 37 | 36 | services/api/internal/domain + gorm models | re-design model semantics, do not line-port ActiveRecord |
| app/models/badge.rb | P1 | 5 | 6 | 70 | services/api/internal/domain + gorm models | re-design model semantics, do not line-port ActiveRecord |

### notifications

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/models/notification.rb | P1 | 26 | 109 | 98 | services/api/internal/notifications | re-design model semantics, do not line-port ActiveRecord |
| app/services/notifications/new_comment/send.rb | P2 | 12 | 53 | 15 | services/api/internal/notifications + worker | port async semantics |
| app/services/notifications/reactions/send.rb | P2 | 10 | 49 | 13 | services/api/internal/notifications + worker | port async semantics |
| app/services/notifications/milestone/send.rb | P2 | 12 | 30 | 17 | services/api/internal/notifications + worker | port async semantics |
| app/services/notifications/new_follower/send.rb | P2 | 8 | 27 | 23 | services/api/internal/notifications + worker | port async semantics |
| app/services/notifications/new_mention/send.rb | P2 | 8 | 33 | 9 | services/api/internal/notifications + worker | port async semantics |
| app/services/notifications/notifiable_action/send.rb | P2 | 8 | 32 | 9 | services/api/internal/notifications + worker | port async semantics |
| app/services/notifications/moderation/send.rb | P2 | 8 | 23 | 9 | services/api/internal/notifications + worker | port async semantics |

### authorization

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/policies/authorizer.rb | P1 | 36 | 78 | 85 | services/api/internal/authz | port policy rules as tests first |
| app/policies/application_policy.rb | P1 | 25 | 44 | 95 | services/api/internal/authz | port policy rules as tests first |
| app/policies/article_policy.rb | P1 | 23 | 66 | 43 | services/api/internal/authz | port policy rules as tests first |
| app/policies/comment_policy.rb | P1 | 21 | 40 | 24 | services/api/internal/authz | port policy rules as tests first |
| app/policies/response_template_policy.rb | P1 | 16 | 40 | 23 | services/api/internal/authz | port policy rules as tests first |
| app/policies/subforem_policy.rb | P1 | 14 | 25 | 22 | services/api/internal/authz | port policy rules as tests first |
| app/policies/agent_session_policy.rb | P1 | 12 | 30 | 13 | services/api/internal/authz | port policy rules as tests first |
| app/policies/user_policy.rb | P1 | 13 | 24 | 16 | services/api/internal/authz | port policy rules as tests first |

### shared-lib

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| lib/tasks/sidekiq_scaler.rake | P3 | 15 | 16 | 163 | services/api/internal/platform or packages | port only if still needed |
| lib/slack/notifier/util/link_formatter.rb | P3 | 6 | 6 | 145 | services/api/internal/platform or packages | port only if still needed |
| lib/data_update_scripts/20260316120000_reprocess_markdown_feed_imports.rb | P3 | 10 | 51 | 21 | services/api/internal/platform or packages | port only if still needed |
| lib/memory_first_cache.rb | P3 | 9 | 29 | 39 | services/api/internal/platform or packages | port only if still needed |
| lib/tasks/add_navigation_links.rake | P3 | 20 | 22 | 20 | services/api/internal/platform or packages | port only if still needed |
| lib/tasks/read_only_database.rake | P3 | 5 | 4 | 50 | services/api/internal/platform or packages | port only if still needed |
| lib/tasks/seed_analytics.rake | P3 | 19 | 18 | 18 | services/api/internal/platform or packages | port only if still needed |
| lib/data_update_scripts/fix_negative_reaction_counters.rb | P3 | 7 | 29 | 10 | services/api/internal/platform or packages | port only if still needed |

### admin-ui

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/javascript/admin/controllers/config_controller.js | P4 | 40 | 81 | 66 | apps/web + packages/ui Solito/NativeWind | rewrite UI behaviour, keep API/UX reference |
| app/javascript/admin/controllers/confirmation_modal_controller.js | P4 | 14 | 30 | 20 | apps/web + packages/ui Solito/NativeWind | rewrite UI behaviour, keep API/UX reference |
| app/javascript/admin/controllers/reaction_controller.js | P4 | 12 | 19 | 16 | apps/web + packages/ui Solito/NativeWind | rewrite UI behaviour, keep API/UX reference |
| app/javascript/admin/controllers/data_update_script_controller.js | P4 | 10 | 19 | 17 | apps/web + packages/ui Solito/NativeWind | rewrite UI behaviour, keep API/UX reference |
| app/javascript/admin/controllers/admin_surveys_controller.js | P4 | 10 | 15 | 14 | apps/web + packages/ui Solito/NativeWind | rewrite UI behaviour, keep API/UX reference |
| app/javascript/admin/controllers/article_controller.js | P4 | 12 | 13 | 12 | apps/web + packages/ui Solito/NativeWind | rewrite UI behaviour, keep API/UX reference |
| app/javascript/admin/controllers/svg_icon_upload_controller.js | P4 | 8 | 14 | 12 | apps/web + packages/ui Solito/NativeWind | rewrite UI behaviour, keep API/UX reference |
| app/javascript/admin/controllers/image_upload_controller.js | P4 | 9 | 13 | 11 | apps/web + packages/ui Solito/NativeWind | rewrite UI behaviour, keep API/UX reference |

### query-read-model

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/queries/consumer_apps/find_or_create_by_query.rb | P1 | 8 | 11 | 121 | services/api/internal/<domain>/queries | replace AR scopes with SQL/GORM read queries |
| app/queries/billboards/filtered_ads_query.rb | P1 | 24 | 40 | 30 | services/api/internal/<domain>/queries | replace AR scopes with SQL/GORM read queries |
| app/queries/admin/users_query.rb | P1 | 10 | 45 | 23 | services/api/internal/<domain>/queries | replace AR scopes with SQL/GORM read queries |
| app/queries/consumer_apps/rpush_app_query.rb | P1 | 8 | 34 | 11 | services/api/internal/<domain>/queries | replace AR scopes with SQL/GORM read queries |
| app/queries/users/suggest_prominent.rb | P1 | 8 | 23 | 10 | services/api/internal/<domain>/queries | replace AR scopes with SQL/GORM read queries |
| app/queries/articles/api_search_query.rb | P1 | 10 | 13 | 11 | services/api/internal/<domain>/queries | replace AR scopes with SQL/GORM read queries |
| app/queries/audit_log/unpublish_alls_query.rb | P1 | 7 | 16 | 10 | services/api/internal/<domain>/queries | replace AR scopes with SQL/GORM read queries |
| app/queries/organizations/suggest_prominent.rb | P1 | 8 | 16 | 9 | services/api/internal/<domain>/queries | replace AR scopes with SQL/GORM read queries |

### search

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/controllers/search_controller.rb | P1 | 16 | 57 | 64 | services/api/internal/search + apps/web/search | split SSR/client routing from API semantics |
| app/services/search/username.rb | P1 | 8 | 24 | 11 | services/api/internal/search/{elastic,fallback} | replace with provider seam + ES indexes |
| app/services/search/article.rb | P1 | 5 | 10 | 26 | services/api/internal/search/{elastic,fallback} | replace with provider seam + ES indexes |
| app/services/search/reading_list.rb | P1 | 7 | 24 | 10 | services/api/internal/search/{elastic,fallback} | replace with provider seam + ES indexes |
| app/services/search/user.rb | P1 | 7 | 19 | 15 | services/api/internal/search/{elastic,fallback} | replace with provider seam + ES indexes |
| app/services/search/podcast_episode.rb | P1 | 6 | 15 | 8 | services/api/internal/search/{elastic,fallback} | replace with provider seam + ES indexes |
| app/services/algolia_insights_service.rb | P1 | 4 | 18 | 6 | services/api/internal/search/{elastic,fallback} | replace with provider seam + ES indexes |
| app/services/search/comment.rb | P1 | 5 | 10 | 12 | services/api/internal/search/{elastic,fallback} | replace with provider seam + ES indexes |

### media

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/services/images/generate_social_image_magickally.rb | P2 | 15 | 91 | 28 | services/api/internal/media + S3 adapter | classify and port if in MVP path |
| app/services/images/optimizer.rb | P2 | 15 | 39 | 37 | services/api/internal/media + S3 adapter | classify and port if in MVP path |
| app/services/images/generate_subforem_images.rb | P2 | 13 | 48 | 22 | services/api/internal/media + S3 adapter | classify and port if in MVP path |
| app/services/html/image_uri.rb | P2 | 9 | 16 | 12 | services/api/internal/media + S3 adapter | classify and port if in MVP path |
| app/services/podcasts/get_media_url.rb | P2 | 8 | 12 | 12 | services/api/internal/media + S3 adapter | classify and port if in MVP path |
| app/services/podcasts/update_episode_media_url.rb | P2 | 6 | 14 | 6 | services/api/internal/media + S3 adapter | classify and port if in MVP path |
| app/services/giphy/image.rb | P2 | 4 | 11 | 6 | services/api/internal/media + S3 adapter | classify and port if in MVP path |
| app/services/images/safe_remote_profile_image_url.rb | P2 | 4 | 7 | 8 | services/api/internal/media + S3 adapter | classify and port if in MVP path |

### email

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/mailers/notify_mailer.rb | P3 | 20 | 48 | 52 | services/api/internal/email + templates | reimplement when SMTP posture chosen |
| spec/mailers/notify_mailer_spec.rb | P3 | 19 | 20 | 73 | services/api/internal/email + templates | reimplement when SMTP posture chosen |
| spec/mailers/previews/notify_mailer_preview.rb | P3 | 17 | 61 | 16 | services/api/internal/email + templates | reimplement when SMTP posture chosen |
| app/mailers/application_mailer.rb | P3 | 11 | 32 | 33 | services/api/internal/email + templates | reimplement when SMTP posture chosen |
| app/mailers/devise_mailer.rb | P3 | 10 | 36 | 12 | services/api/internal/email + templates | reimplement when SMTP posture chosen |
| spec/mailers/custom_mailer_spec.rb | P3 | 19 | 19 | 20 | services/api/internal/email + templates | reimplement when SMTP posture chosen |
| spec/mailers/digest_mailer_spec.rb | P3 | 19 | 19 | 19 | services/api/internal/email + templates | reimplement when SMTP posture chosen |
| spec/mailers/devise_mailer_spec.rb | P3 | 14 | 14 | 15 | services/api/internal/email + templates | reimplement when SMTP posture chosen |

### articles/feed

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/services/articles/feeds/variant_query.rb | P1 | 21 | 54 | 29 | services/api/internal/articles + feed + search | port semantics into deep modules |
| app/services/articles/updater.rb | P1 | 15 | 58 | 24 | services/api/internal/articles + feed + search | port semantics into deep modules |
| app/services/articles/detect_code_block_languages.rb | P1 | 16 | 44 | 25 | services/api/internal/articles + feed + search | port semantics into deep modules |
| app/services/articles/feeds/large_forem_experimental.rb | P1 | 15 | 38 | 24 | services/api/internal/articles + feed + search | port semantics into deep modules |
| app/services/articles/feeds/custom.rb | P1 | 15 | 36 | 22 | services/api/internal/articles + feed + search | port semantics into deep modules |
| app/services/articles/builder.rb | P1 | 14 | 41 | 17 | services/api/internal/articles + feed + search | port semantics into deep modules |
| app/services/articles/creator.rb | P1 | 13 | 39 | 17 | services/api/internal/articles + feed + search | port semantics into deep modules |
| app/queries/homepage/articles_query.rb | P1 | 9 | 21 | 35 | services/api/internal/articles + feed + search | port semantics into deep modules |

### runtime-config

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| config/initializers/session_store.rb | P0 | 11 | 11 | 49 | deploy/k8s + services/api/internal/config | translate env/runtime config; drop Rails-only |
| config/initializers/ahoy_email.rb | P0 | 11 | 39 | 17 | deploy/k8s + services/api/internal/config | translate env/runtime config; drop Rails-only |
| config/initializers/sidekiq.rb | P0 | 13 | 19 | 20 | deploy/k8s + services/api/internal/config | translate env/runtime config; drop Rails-only |
| config/initializers/carrierwave_monkeypatch.rb | P0 | 6 | 6 | 37 | deploy/k8s + services/api/internal/config | translate env/runtime config; drop Rails-only |
| config/application.rb | P0 | 11 | 18 | 18 | deploy/k8s + services/api/internal/config | translate env/runtime config; drop Rails-only |
| config/initializers/carrierwave.rb | P0 | 7 | 28 | 11 | deploy/k8s + services/api/internal/config | translate env/runtime config; drop Rails-only |
| config/initializers/devise.rb | P0 | 9 | 12 | 24 | deploy/k8s + services/api/internal/config | translate env/runtime config; drop Rails-only |
| config/initializers/0_application_config.rb | P0 | 8 | 19 | 12 | deploy/k8s + services/api/internal/config | translate env/runtime config; drop Rails-only |

### jobs

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/workers/emails/send_user_digest_worker.rb | P2 | 4 | 58 | 5 | services/api/cmd/worker + internal/jobs | replace Sidekiq with Go workers/queue abstraction |
| app/workers/emails/enqueue_custom_batch_send_worker.rb | P2 | 9 | 41 | 16 | services/api/cmd/worker + internal/jobs | replace Sidekiq with Go workers/queue abstraction |
| app/workers/follows/update_points_worker.rb | P2 | 10 | 40 | 15 | services/api/cmd/worker + internal/jobs | replace Sidekiq with Go workers/queue abstraction |
| app/workers/reaction_counter_sync_worker.rb | P2 | 11 | 31 | 20 | services/api/cmd/worker + internal/jobs | replace Sidekiq with Go workers/queue abstraction |
| app/workers/scheduled_automations/process_worker.rb | P2 | 6 | 46 | 7 | services/api/cmd/worker + internal/jobs | replace Sidekiq with Go workers/queue abstraction |
| app/workers/articles/handle_spam_worker.rb | P2 | 7 | 33 | 11 | services/api/cmd/worker + internal/jobs | replace Sidekiq with Go workers/queue abstraction |
| app/workers/organizations/track_promotional_billboard_impressions_worker.rb | P2 | 6 | 32 | 8 | services/api/cmd/worker + internal/jobs | replace Sidekiq with Go workers/queue abstraction |
| app/workers/articles/quality_reaction_worker.rb | P2 | 8 | 24 | 10 | services/api/cmd/worker + internal/jobs | replace Sidekiq with Go workers/queue abstraction |

### legacy-schema

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| db/migrate/20170325040822_create_tweets.rb | P0 | 3 | 34 | 2 | services/api/internal/legacyimport/schema-map | read for schema semantics; do not replay in native DB |
| db/migrate/20200304164719_install_blazer.rb | P0 | 3 | 30 | 2 | services/api/internal/legacyimport/schema-map | read for schema semantics; do not replay in native DB |
| db/migrate/20190717220437_create_doorkeeper_tables.rb | P0 | 3 | 26 | 2 | services/api/internal/legacyimport/schema-map | read for schema semantics; do not replay in native DB |
| db/migrate/20210222102503_create_users_settings.rb | P0 | 3 | 20 | 2 | services/api/internal/legacyimport/schema-map | read for schema semantics; do not replay in native DB |
| db/migrate/20160201012919_add_devise_to_users.rb | P0 | 4 | 17 | 3 | services/api/internal/legacyimport/schema-map | read for schema semantics; do not replay in native DB |
| db/migrate/20200712150048_devise_invitable_add_to_users.rb | P0 | 4 | 17 | 3 | services/api/internal/legacyimport/schema-map | read for schema semantics; do not replay in native DB |
| db/migrate/20210222102602_create_users_notification_settings.rb | P0 | 3 | 19 | 2 | services/api/internal/legacyimport/schema-map | read for schema semantics; do not replay in native DB |
| db/migrate/20170521154826_create_blocks.rb | P0 | 3 | 18 | 2 | services/api/internal/legacyimport/schema-map | read for schema semantics; do not replay in native DB |

### api-serialization

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/serializers/application_serializer.rb | P1 | 2 | 1 | 10 | services/api/internal/http/dto | replace serializers with explicit DTOs |
| app/serializers/search/podcast_episode_serializer.rb | P1 | 4 | 5 | 4 | services/api/internal/http/dto | replace serializers with explicit DTOs |
| app/serializers/search/comment_serializer.rb | P1 | 3 | 3 | 3 | services/api/internal/http/dto | replace serializers with explicit DTOs |
| app/serializers/search/nested_user_serializer.rb | P1 | 3 | 3 | 3 | services/api/internal/http/dto | replace serializers with explicit DTOs |
| app/serializers/search/organization_serializer.rb | P1 | 3 | 3 | 3 | services/api/internal/http/dto | replace serializers with explicit DTOs |
| app/serializers/search/reading_list_article_serializer.rb | P1 | 3 | 3 | 3 | services/api/internal/http/dto | replace serializers with explicit DTOs |
| app/serializers/search/simple_user_serializer.rb | P1 | 3 | 3 | 3 | services/api/internal/http/dto | replace serializers with explicit DTOs |
| app/serializers/search/tag_serializer.rb | P1 | 3 | 3 | 3 | services/api/internal/http/dto | replace serializers with explicit DTOs |

### devops

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| .buildkite/pipeline.containers.yml | P0 | 0 | 0 | 0 | deploy/gitops + CI | replace with Kubernetes/GitOps pipeline |
| .devcontainer/devcontainer.json | P0 | 0 | 0 | 0 | deploy/gitops + CI | replace with Kubernetes/GitOps pipeline |
| .devcontainer/postAttachCommand-init.sh | P0 | 0 | 0 | 0 | deploy/gitops + CI | replace with Kubernetes/GitOps pipeline |
| .devcontainer/postCreateCommand-init.sh | P0 | 0 | 0 | 0 | deploy/gitops + CI | replace with Kubernetes/GitOps pipeline |
| .github/ISSUE_TEMPLATE/config.yml | P0 | 0 | 0 | 0 | deploy/gitops + CI | replace with Kubernetes/GitOps pipeline |
| .github/dependabot.yml | P0 | 0 | 0 | 0 | deploy/gitops + CI | replace with Kubernetes/GitOps pipeline |
| .github/workflows/build-base-ruby-image.yml | P0 | 0 | 0 | 0 | deploy/gitops + CI | replace with Kubernetes/GitOps pipeline |
| .github/workflows/buildkite.yml | P0 | 0 | 0 | 0 | deploy/gitops + CI | replace with Kubernetes/GitOps pipeline |

### settings

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/models/settings/base.rb | P1 | 18 | 69 | 158 | services/api/internal/settings | re-design model semantics, do not line-port ActiveRecord |
| app/models/settings/community.rb | P1 | 3 | 3 | 94 | services/api/internal/settings | re-design model semantics, do not line-port ActiveRecord |
| app/models/feed_config.rb | P1 | 4 | 69 | 14 | services/api/internal/settings | re-design model semantics, do not line-port ActiveRecord |
| app/models/settings/rate_limit.rb | P1 | 5 | 8 | 37 | services/api/internal/settings | re-design model semantics, do not line-port ActiveRecord |
| app/models/settings/smtp.rb | P1 | 7 | 12 | 17 | services/api/internal/settings | re-design model semantics, do not line-port ActiveRecord |
| app/models/settings/general.rb | P1 | 7 | 11 | 7 | services/api/internal/settings | re-design model semantics, do not line-port ActiveRecord |
| app/models/config.rb | P1 | 2 | 2 | 1 | services/api/internal/settings | re-design model semantics, do not line-port ActiveRecord |

### comments

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/models/comment.rb | P1 | 59 | 174 | 163 | services/api/internal/comments | re-design model semantics, do not line-port ActiveRecord |
| app/models/mention.rb | P1 | 5 | 14 | 15 | services/api/internal/comments | re-design model semantics, do not line-port ActiveRecord |
| app/models/concerns/algolia_searchable/searchable_comment.rb | P1 | 5 | 9 | 4 | services/api/internal/comments | re-design model semantics, do not line-port ActiveRecord |
| app/models/context_note.rb | P1 | 3 | 5 | 4 | services/api/internal/comments | re-design model semantics, do not line-port ActiveRecord |
| app/models/context_notification.rb | P1 | 2 | 2 | 4 | services/api/internal/comments | re-design model semantics, do not line-port ActiveRecord |

### organizations

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/models/organization.rb | P1 | 40 | 100 | 170 | services/api/internal/organizations | re-design model semantics, do not line-port ActiveRecord |
| app/models/organization_membership.rb | P1 | 8 | 21 | 34 | services/api/internal/organizations | re-design model semantics, do not line-port ActiveRecord |
| app/models/concerns/algolia_searchable/searchable_organization.rb | P1 | 4 | 7 | 3 | services/api/internal/organizations | re-design model semantics, do not line-port ActiveRecord |
| app/models/organization_lead_form.rb | P1 | 2 | 2 | 3 | services/api/internal/organizations | re-design model semantics, do not line-port ActiveRecord |
| app/models/trend_membership.rb | P1 | 2 | 2 | 1 | services/api/internal/organizations | re-design model semantics, do not line-port ActiveRecord |

### monetization

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/models/billboard.rb | P1 | 46 | 136 | 95 | services/api/internal/monetization (post-MVP) | re-design model semantics, do not line-port ActiveRecord |
| app/models/billboard_placement_area_config.rb | P1 | 14 | 46 | 26 | services/api/internal/monetization (post-MVP) | re-design model semantics, do not line-port ActiveRecord |
| app/models/campaign.rb | P1 | 6 | 10 | 26 | services/api/internal/monetization (post-MVP) | re-design model semantics, do not line-port ActiveRecord |
| app/models/billboard_event.rb | P1 | 4 | 10 | 12 | services/api/internal/monetization (post-MVP) | re-design model semantics, do not line-port ActiveRecord |
| app/models/settings/campaign.rb | P1 | 3 | 3 | 2 | services/api/internal/monetization (post-MVP) | re-design model semantics, do not line-port ActiveRecord |

### media/podcasts

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/models/podcast_episode.rb | P1 | 16 | 28 | 35 | services/api/internal/media (post-MVP) | re-design model semantics, do not line-port ActiveRecord |
| app/models/podcast.rb | P1 | 6 | 19 | 6 | services/api/internal/media (post-MVP) | re-design model semantics, do not line-port ActiveRecord |
| app/models/concerns/algolia_searchable/searchable_podcast_episode.rb | P1 | 4 | 7 | 3 | services/api/internal/media (post-MVP) | re-design model semantics, do not line-port ActiveRecord |
| app/models/podcast_ownership.rb | P1 | 2 | 2 | 2 | services/api/internal/media (post-MVP) | re-design model semantics, do not line-port ActiveRecord |
| app/models/podcast_episode_appearance.rb | P1 | 2 | 2 | 1 | services/api/internal/media (post-MVP) | re-design model semantics, do not line-port ActiveRecord |

### routing

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| config/routes.rb | P0 | 617 | 378 | 20 | services/api/internal/http/router + apps/web routes | derive route matrix and contracts |
| config/routes/admin.rb | P0 | 376 | 213 | 7 | services/api/internal/http/router + apps/web routes | derive route matrix and contracts |
| config/routes/api.rb | P0 | 92 | 45 | 0 | services/api/internal/http/router + apps/web routes | derive route matrix and contracts |
| config/routes/listing.rb | P0 | 19 | 12 | 0 | services/api/internal/http/router + apps/web routes | derive route matrix and contracts |

### reactions

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| app/models/reaction.rb | P1 | 33 | 97 | 108 | services/api/internal/reactions | re-design model semantics, do not line-port ActiveRecord |
| app/models/reaction_category.rb | P1 | 16 | 28 | 68 | services/api/internal/reactions | re-design model semantics, do not line-port ActiveRecord |
| app/models/privileged_reaction.rb | P1 | 2 | 2 | 1 | services/api/internal/reactions | re-design model semantics, do not line-port ActiveRecord |

### legacy-data

| File | Phase | Symbols | Out | In | Target | Disposition |
| --- | --- | --- | --- | --- | --- | --- |
| db/seeds.rb | P0 | 45 | 44 | 87 | services/api/internal/legacyimport | derive importer mappings/seed fixtures |
| db/seeds_staging.rb | P0 | 2 | 1 | 1 | services/api/internal/legacyimport | derive importer mappings/seed fixtures |
| db/schema.rb | P0 | 1 | 0 | 0 | services/api/internal/legacyimport | derive importer mappings/seed fixtures |

---

## How to use the per-file inventory

For any implementation PR, select rows from `noema-file-migration-inventory.csv` and mark them in the PR description. Then check `noema-file-dependency-edges.csv` for adjacent files before declaring the slice complete.

Example:

```text
Covered legacy files:
- app/models/article.rb -> internal/articles, internal/search documents
- app/controllers/concerns/api/articles_controller.rb -> internal/http/handlers/articles
- spec/requests/api/v1/articles_spec.rb -> services/api/internal/articles contract tests
```

## Verification commands

```bash
cd /home/yun/Desktop/noema
python -c "import csv; files=list(csv.DictReader(open('docs/agentwego/noema-file-migration-inventory.csv'))); assert len(files)==5900; assert any(r['file']=='app/models/article.rb' for r in files); assert any(r['file']=='app/controllers/search_controller.rb' for r in files); assert any(r['file']=='config/routes.rb' for r in files); print('inventory ok', len(files))"

test -s docs/agentwego/noema-file-dependency-edges.csv
test -s docs/agentwego/noema-domain-dependency-summary.csv
test -s docs/agentwego/noema-model-dependency-map.csv
test -s docs/agentwego/noema-controller-map.csv
test -s docs/agentwego/noema-worker-map.csv
```

## Important risk notes

1. `app/controllers/concerns/api/profile_images_controller.rb` shows abnormal fan-in in codegraph. Treat it as a parser/index artifact or dynamic constant ambiguity until manually verified; do not design around that fan-in alone.
2. Rails callbacks and Sidekiq workers hide many side effects. Every native write path must declare post-commit effects explicitly: search indexing, notifications, cache invalidation, feed refresh, and audit logs.
3. Do not replay all Rails migrations into the native schema. Use them to understand historical fields and data quirks, then design a clean Noema schema plus importer.
4. S3-compatible endpoint support remains a runtime spike. Media module should expose an object-storage adapter from day one.
5. Chinese search/analyzer choice must be verified against the real Elasticsearch/OpenSearch cluster before production indexing.
