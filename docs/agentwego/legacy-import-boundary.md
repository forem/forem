# Noema Legacy Import Boundary

## Scope

This document records the local-only Forem → Noema import boundary introduced for M0-T30.

The boundary is intentionally narrow:

- no production access;
- no real Secret reads or writes;
- no external PostgreSQL, S3, Elasticsearch, or OpenSearch connections;
- no Kubernetes apply/deploy;
- no irreversible data operations;
- local fixtures and Go tests only.

## M0-T30: Forem article/user → Noema clean domain DTO

### Inventory evidence

M0-T30 covers the first legacy import seam for the high-coupling article/user graph:

| Legacy file | Inventory domain | Target | Disposition |
| --- | --- | --- | --- |
| `app/models/article.rb` | `articles/content` | `services/api/internal/articles + search documents` | re-design model semantics, do not line-port ActiveRecord |
| `app/models/user.rb` | `identity/profile` | `services/api/internal/identity` | re-design model semantics, do not line-port ActiveRecord |
| `app/services/exporter/articles.rb` | `service` | `services/api/internal/<domain>` | classify and port if in MVP path |
| `app/services/search/user.rb` | `search` | `services/api/internal/search/{elastic,fallback}` | replace with provider seam + ES indexes |
| `app/services/feeds/import.rb` | `service` | `services/api/internal/<domain>` | classify and port if in MVP path |

Important edge implications from `docs/agentwego/noema-file-dependency-edges.csv`:

- `Article` and `User` are high-coupling legacy models; do not import raw ActiveRecord shape into Noema.
- `app/services/exporter/articles.rb` identifies the article export surface: `body_markdown`, `cached_tag_list`, `cached_user_name`, `cached_user_username`, `published_at`, `canonical_url`, `feed_source_url`, `main_image`, `slug`, `title`, and counters.
- `app/services/search/user.rb` identifies the minimal public/search user projection: `id`, `name`, `profile_image`, `username`.
- `app/services/feeds/import.rb` is a legacy import/service boundary; Noema should keep import DTOs separate from persistence and search projections.

### Clean DTO contract

The native package is:

```text
services/api/internal/legacyimport
```

It accepts only small Forem-facing shapes:

- `ForemUser`
  - `id`
  - `username`
  - `name`
  - `profile_image`
  - `created_at`
  - `updated_at`
- `ForemArticle`
  - `id`
  - `user_id`
  - `title`
  - `body_markdown`
  - `slug`
  - `published`
  - `published_at`
  - `created_at`
  - `updated_at`
  - `cached_tag_list` or `tag_list`
  - optional embedded `user`

It outputs clean Noema DTOs:

- `UserDTO`
  - `ID`
  - `Username`
  - `DisplayName`
  - `ProfileImage`
  - `CreatedAt`
  - `UpdatedAt`
- `ArticleDTO`
  - `ID`
  - `AuthorID`
  - `Slug`
  - `Title`
  - `BodyMarkdown`
  - `Published`
  - `PublishedAt`
  - `CreatedAt`
  - `UpdatedAt`
  - `Tags`

The DTOs can project into existing Noema seams without importing legacy shape:

- `UserDTO.ToPersistence()` → `persistence.User`
- `ArticleDTO.ToPersistence()` → `persistence.Article`
- `UserDTO.ToSearchDocument()` → `search.UserDocument`
- `ArticleDTO.ToSearchDocument()` → `search.ArticleDocument`

### Validation rules

The mapper rejects malformed local fixture/input data before it can reach domain services:

- missing user id;
- missing username;
- missing article id;
- missing article user/author id;
- missing article slug;
- missing article title;
- missing article `body_markdown`.

If `ForemArticle.user_id` is absent but an embedded `user.id` exists, M0-T30 uses the embedded user id as the author id. This matches local fixture/import ergonomics without depending on a live DB.

### Local fixture

The first import fixture lives at:

```text
services/api/internal/legacyimport/testdata/forem_article_with_user.json
```

It represents one article with one embedded author and is used only by Go tests.

### Verification

Targeted local verification:

```bash
task legacyimport:test
```

Equivalent direct command:

```bash
GOFLAGS=-mod=mod go test ./services/api/internal/legacyimport -count=1 -v
```

This test suite covers:

- `MapForemUser` core field mapping;
- `MapForemArticle` fixture-based article mapping;
- projection into persistence/search documents;
- malformed article rejection.

M0-T30 is also wired into `task verify:local`, but the M0-T30 acceptance step should prefer targeted verification unless broader local gates are needed for touched files.

## M0-T31: Forem user identity → Ory Kratos boundary DTO

M0-T31 extends the legacy import boundary just far enough to reserve the target auth/identity architecture. It does not implement a login system, Kratos client, session middleware, or data migration job.

### Inventory evidence

Relevant legacy auth/user files:

| Legacy file | Boundary decision |
| --- | --- |
| `app/models/user.rb` | Treat as account/profile/business aggregate; import only clean user identity fields. |
| `app/models/identity.rb` | Treat as legacy OmniAuth provider binding; preserve provider subjects as Kratos admin metadata, not credentials. |
| `app/controllers/omniauth_callbacks_controller.rb` | Future replacement target for Kratos self-service / identity-provider exchange flows. |
| `app/controllers/sessions_controller.rb` | Future replacement target for Kratos session assertion/revocation. |
| `app/controllers/concerns/session_current_user.rb` | Current Warden session-key lookup; future target is Kratos `/sessions/whoami`. |
| `app/models/settings/authentication.rb` | Auth policy/config; keep out of user import DTOs. |

### Clean import contract

New native package:

```text
services/api/internal/identity
```

It defines local-only Ory-named DTOs:

- `KratosIdentityImport`
- `KratosTraits`
- `KratosSession`
- `KratosSelfServiceFlowKind`

The legacy import package adds:

- `ForemExternalIdentity`
- `ForemUserIdentity`
- `UserIdentityBoundary`
- `MapForemUserIdentity`

Mapping rules:

- `MapForemUserIdentity` reuses `MapForemUser` so user id/username/display-name validation remains single-source.
- Email maps to `KratosIdentityImport.Traits.Email`.
- Username maps to `KratosIdentityImport.Traits.Username`.
- Display name maps to `KratosIdentityImport.Traits.Name`.
- Profile image maps to `metadata_public.profile_image`.
- Legacy Forem user id maps to `metadata_admin.legacy_forem_user_id`.
- External provider subjects map to `metadata_admin.legacy_identity_<provider>` using `<provider>:<uid>`.
- OAuth tokens, secrets, encrypted passwords, recovery/remember/lock fields, and raw auth dumps are intentionally excluded.

### Verification

Targeted local verification:

```bash
task identity:test
task legacyimport:test
```

Direct commands:

```bash
GOFLAGS=-mod=mod go test ./services/api/internal/identity -count=1 -v
GOFLAGS=-mod=mod go test ./services/api/internal/legacyimport -run 'TestMapForemUserIdentityToKratosBoundary' -count=1 -v
```

This remains fixture-only and local-only: no production DB, real Secret, S3, Elasticsearch/OpenSearch, Kratos, deploy, or irreversible mutation.

## Boundaries deferred to later slices

M0-T30 does not attempt to import or map:

- legacy authentication fields, encrypted passwords, OAuth usernames, roles, or moderation flags;
- real Kratos public/admin API calls, self-service flows, session cookies, or identity schema deployment;
- full Forem article counters/scoring/moderation fields;
- comments, reactions, organizations, collections, tags as domain entities, media, or notifications;
- real DB reads/writes or replay/import jobs;
- real search indexing or Elasticsearch/OpenSearch I/O.

Those fields need separate Noema-native owners before entering the import path.
