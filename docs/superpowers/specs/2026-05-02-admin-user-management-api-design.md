# Admin User Management API — Design

**Status**: Proposed
**Date**: 2026-05-02
**Author**: Jon Gottfried (with Claude)
**Audience**: Forem maintainers; MLH Core integrators

## Summary

Expose an admin-only HTTP API on Forem (`/api/v1/admin/users/...`) that lets a trusted caller (initially MLH Core, our user data warehouse) read users, update profiles, change moderation status, merge accounts, manage admin notes, and link/unlink third-party identity records.

The primary driver is letting MLH Core record "this Forem user is MLH Core ID 12345" so that subsequent MyMLH OAuth sign-ins resolve to the right Forem account, and so Core can build out user sync the way OHQ has.

The implementation reuses Forem's existing service objects (`Moderator::MergeUser`, `Moderator::ManageActivityAndRoles`, `Users::Update`, the `Note` and `Identity` models) and follows Forem's established API conventions (concern + thin V1 wrapper + JBuilder views + `authenticate!` + `authorize_super_admin`). No new auth plumbing.

## Goals

- Provide programmatic, auditable equivalents to a focused subset of the admin user-management UI.
- Enable Core→Forem user sync, especially identity claim ("this Forem user is MLH ID X").
- Match existing Forem API conventions exactly so integrators recognize the patterns.
- Stay strict about conflicts: callers resolve ambiguity explicitly.

## Non-goals (explicit)

- Banishing users, full-deleting users, unpublishing all of a user's articles via API. (Existing UI flows remain.)
- Role management (already handled by `Api::V1::UserRolesController`).
- Reputation modifier, max_score, credit adjustments. (Narrow admin tools, not Core-sync concerns.)
- Async merge with status polling.
- Editing `profile_image` or broad `Profile` bio fields (`employment_title`, `education`, etc.).
- Adding a V0 surface. (V0 is deprecated; new admin functionality ships V1-only.)
- Building a Forem-side outbound client to push events back to Core. (May come later; mirrors the OHQ→Core pattern but is a separate spec.)

## Use case context

MLH Core is the canonical source of truth for MLH user identity. OHQ already syncs to Core via Doorkeeper-authed OAuth client credentials and `after_commit` propagation jobs. Forem currently has no equivalent. The first step toward Forem↔Core sync is letting Core *push identity mappings into Forem* via an admin API. Forem→Core outbound sync (events, propagation jobs) is out of scope here and will be its own spec.

The API caller is a super_admin Forem user dedicated to Core (a service account), authenticating with an `ApiSecret` API key.

## Architecture

### Conventions matched from existing Forem API code

- **Shared concern + thin version wrapper**. Logic in `app/controllers/concerns/api/admin/<resource>_controller.rb`. V1 class in `app/controllers/api/v1/admin/<resource>_controller.rb` — subclasses `Api::V1::ApiController`, includes the concern, declares `before_action`s.
- **JBuilder views** for response shapes, in `app/views/api/v1/admin/<resource>/*.json.jbuilder`. (Forem does not use serializer POROs for API responses; `app/serializers/` is nearly empty.)
- **Per-action auth** via `before_action :authenticate!` (defined on `Api::V1::ApiController` as `authenticate_with_api_key_or_current_user!`) and `before_action :authorize_super_admin`. This matches the existing `Api::V1::Admin::UsersController` and lets a service-account API key OR a logged-in super_admin browser session call the API.
- **Audit logging** via `Audit::Logger.log(:admin_api, current_user, payload)` from an `after_action` on each writing action.

### File layout

```
app/controllers/concerns/api/admin/
  users_controller.rb           # extended (currently has only `create` for invites)
  user_notes_controller.rb      # new
  user_identities_controller.rb # new

app/controllers/api/v1/admin/
  base_controller.rb            # new shared base (rescue_from, audit helper)
  users_controller.rb           # existing — extended with new before_actions / actions
  user_notes_controller.rb      # new
  user_identities_controller.rb # new

app/views/api/v1/admin/
  users/{index,show,update,merge}.json.jbuilder
  user_notes/{index,create}.json.jbuilder
  user_identities/{index,create}.json.jbuilder
```

### Authentication & authorization

- **Auth**: `authenticate!` (existing wrapper on `Api::V1::ApiController`, equivalent to `authenticate_with_api_key_or_current_user!`). Service callers (Core) send `api-key: <secret>` header; an `ApiSecret` belongs to a Forem `User`, who becomes `current_user`. A logged-in super_admin browser session also passes (useful for testing/curl).
- **Authorization**: `authorize_super_admin` (existing). Returns `403 forbidden` unless `current_user.super_admin?`.
- **Service account**: a dedicated super_admin Forem user is created for MLH Core; an `ApiSecret` is generated for it; the secret is stored in Core's vault.

### Reuse map

| Concern | Reused service / model |
|---|---|
| Merge | `Moderator::MergeUser.call(admin:, keep_user:, delete_user_id:)` |
| Status change | `Moderator::ManageActivityAndRoles.handle_user_roles(admin:, user:, user_params:)` |
| Profile update (incl. username) | `Users::Update.call(user, user: {...}, profile: {...})` (same path as admin UI's `update_profile`) |
| Email change | `@user.update_columns(email: new_email)` directly (mirrors admin UI's `update_email`; bypasses Devise confirmation by design — Core is trusted) |
| Notes | `Note` model directly (`noteable: user`, `author: current_user`) |
| Identity link/unlink | `Identity` model directly (no service exists; new logic is small) |
| Audit | `Audit::Logger.log(:admin_api, current_user, payload)` + existing `AuditLog` model |

## Endpoint specification

All paths under `/api/v1/admin/`. All require `api-key` header + super_admin caller.

### Users

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/users` | List/search users. Query params: `email`, `username`, `identity_provider`+`identity_uid`, `page`, `per_page` (max 100). Order: `created_at DESC`. |
| `GET` | `/users/:id` | Fetch single user (full admin payload incl. identities). |
| `PATCH` | `/users/:id` | Update profile fields: `name`, `username`, `summary`, `location`, `website_url`. PATCH semantics — only present fields update. |
| `PUT` | `/users/:id/email` | Change email. Body: `{email}`. **Skips Devise confirmation** (uses `update_columns`, mirroring admin UI). |
| `PUT` | `/users/:id/status` | Change moderation status. Body: `{status, note?}`. `status` ∈ `{"Good standing", "Suspended", "Spam", "Warned", "Comment Suspended", "Trusted", "Limited"}` — the moderation-status subset of `Moderator::ManageActivityAndRoles`'s accepted roles. Admin/Super Moderator/Tech Admin role grants are deliberately **not** accepted here; those go through `Api::V1::UserRolesController`. |
| `POST` | `/users/:id/merge` | Merge another user **into** `:id`. Body: `{merge_user_id}`. Delegates to `Moderator::MergeUser.call(keep_user: User.find(:id), delete_user_id: merge_user_id)`. **Synchronous**. |

### User notes

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/users/:user_id/notes` | List notes for a user, newest first. |
| `POST` | `/users/:user_id/notes` | Create. Body: `{content, reason?}`. Default `reason: "misc_note"`. Append-only — no edit/delete. |

### User identities

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/users/:user_id/identities` | List identities. Returns provider, uid, created_at; **never** tokens. |
| `POST` | `/users/:user_id/identities` | Link identity. Body: `{provider, uid, username?}`. Strict — see below. |
| `DELETE` | `/users/:user_id/identities/:id` | Unlink. Mirrors UI side effects (null `<provider>_username`; destroy `github_repos` if provider is github). |

### Sample response — `GET /users/:id`

```json
{
  "id": 1234,
  "username": "jane",
  "name": "Jane Doe",
  "email": "jane@example.com",
  "registered_at": "2024-01-15T10:30:00Z",
  "status": "good_standing",
  "profile": {
    "summary": "...",
    "location": "...",
    "website_url": "..."
  },
  "identities": [
    {"id": 99, "provider": "mlh", "uid": "12345", "created_at": "2024-01-15T10:30:01Z"}
  ],
  "counts": {"articles": 4, "comments": 12, "reactions": 88}
}
```

### Sample response — `GET /users` (list)

```json
{
  "users": [ /* same shape, possibly trimmed */ ],
  "page": 1,
  "per_page": 25,
  "total": 1043
}
```

### Status codes

- `200` — successful read or update
- `201` — successful create (notes, identities)
- `204` — successful delete (unlink identity)
- `400` — malformed request
- `401` — missing/invalid API key
- `403` — caller is not super_admin
- `404` — user/identity/note not found
- `409` — conflict (identity already linked, username taken, merge-into-self, etc.)
- `422` — validation failure or invalid enum/provider

## Identity linking semantics (safety-critical)

`POST /users/:user_id/identities` body `{provider, uid, username?}`. Behavior in order:

1. **User exists?** No → `404 user_not_found`.
2. **Provider valid?** Must be in `Authentication::Providers.available` (e.g., `mlh`, `github`, `twitter`, `apple`, `facebook`, `google_oauth2`). Unknown → `422 unknown_provider`.
3. **Same `(user_id, provider)` exists with same uid?** → `200 OK`, idempotent (returns existing identity).
4. **Same `(user_id, provider)` exists with different uid?** → `409 user_already_has_identity_for_provider`. Caller must `DELETE` the existing identity first.
5. **Same `(provider, uid)` linked to a *different* user?** → `409 identity_uid_taken`. Caller must call merge or delete the other linkage first.
6. Otherwise create the `Identity` row. If `username` provided, set `user.<provider>_username` (e.g., `mlh_username`). Return `201`.

**Concurrency**: pre-checks 4 + 5 + create wrapped in a transaction. Confirm a unique index on `Identity(provider, uid)` exists; if not, add a migration in its own commit (using `algorithm: :concurrently`, `disable_ddl_transaction!` per AGENTS.md).

**No tokens**. API-linked identities do not get `token`, `secret`, or `auth_data_dump`. Those fields are populated on first real OAuth login. The API is a *claim* of the mapping, not a session credential.

**OAuth-login compatibility**: when a user later signs in via the corresponding OAuth provider (e.g., MyMLH), Forem's existing omniauth callback is expected to use `find_or_create_by(provider:, uid:)` semantics on `Identity`, so the pre-existing API-linked row is found and OAuth tokens are populated on it (no new user, no duplicate row). **Implementation must verify this round-trip behavior** in the OAuth callback code path before shipping the link endpoint — see "Open implementation tasks" below.

### Unlink behavior

`DELETE /users/:user_id/identities/:id` — must mirror the existing admin UI's `remove_identity` action:

```
identity.destroy
user.update("#{identity.provider}_username" => nil)
user.github_repos.destroy_all if identity.provider.to_sym == :github
```

No "last identity" guard — the existing UI doesn't have one either. Admin caller is trusted; audit log captures the action.

## Audit logging

Every successful write emits one `AuditLog` row via `Audit::Logger.log(:admin_api, current_user, payload)`. Reads are not logged. Failed requests are not logged.

Mechanism: shared `after_action` in `Api::V1::Admin::BaseController`, conditional on `response.successful?`. Each writing action declares its slug + payload via a small helper (e.g., `audit!(slug:, data:)`).

| Action | slug | data payload (jsonb) |
|---|---|---|
| `PATCH /users/:id` | `update_user` | `{target_user_id, changed: {field: [old, new], ...}}` |
| `PUT /users/:id/email` | `update_user_email` | `{target_user_id, old_email, new_email}` |
| `PUT /users/:id/status` | `update_user_status` | `{target_user_id, old_status, new_status, note}` |
| `POST /users/:id/merge` | `merge_users` | `{keep_user_id, deleted_user_id}` |
| `POST /users/:user_id/notes` | `add_user_note` | `{target_user_id, note_id, reason}` (content omitted; in `notes` table) |
| `POST /users/:user_id/identities` | `link_identity` | `{target_user_id, identity_id, provider, uid}` |
| `DELETE /users/:user_id/identities/:id` | `unlink_identity` | `{target_user_id, identity_id, provider, uid}` |

The category `admin_api.audit.log` already exists in Forem — used by `Api::V1::UserRolesController`. The existing admin UI's user audit log tab (which uses `AuditLog.on_user(user)`) will surface API-driven actions alongside UI-driven ones automatically.

**Caller identity granularity**: a single Core service account API key means the audit log records "Core service account" rather than the human operator behind the action. Acceptable for MVP. Future enhancement could honor an `X-Caller-Identity` header to record the upstream actor without changing auth.

## Error handling

Standard envelope, returned for every error:

```json
{
  "error": "Human-readable message",
  "error_code": "snake_case_machine_code",
  "status": 409
}
```

For `422 validation_failed`, additionally include `errors:` with field-level AR error details:

```json
{
  "error": "Validation failed: Username has already been taken",
  "error_code": "validation_failed",
  "status": 422,
  "errors": {"username": ["has already been taken"]}
}
```

### Error code catalog

| HTTP | error_code | When |
|---|---|---|
| 400 | `bad_request` | Malformed JSON, missing required body |
| 400 | `invalid_param` | Bad value (e.g., negative `per_page`, malformed email format pre-validation) |
| 401 | `unauthenticated` | No / invalid api-key header |
| 403 | `forbidden` | Authenticated but not super_admin |
| 404 | `user_not_found` | `:user_id` doesn't exist |
| 404 | `identity_not_found` | `:id` doesn't exist or isn't owned by `:user_id` |
| 404 | `note_not_found` | Note ID lookup failed |
| 409 | `username_taken` | Username conflict on update |
| 409 | `email_taken` | Email already used |
| 409 | `user_already_has_identity_for_provider` | State 3: user has different uid for same provider |
| 409 | `identity_uid_taken` | State 4: (provider, uid) belongs to another user |
| 409 | `cannot_merge_user_into_itself` | `merge_user_id == :id` |
| 409 | `merge_identity_conflict` | `Moderator::MergeUser` raised mid-merge identity collision |
| 422 | `unknown_provider` | Provider not in `Authentication::Providers.available` |
| 422 | `invalid_status` | Status not in allowed enum |
| 422 | `validation_failed` | ActiveRecord validation failure (catch-all) |
| 500 | `internal_error` | Unhandled exception (logged) |

### Plumbing

`Api::V1::Admin::BaseController`:

- `rescue_from ActiveRecord::RecordNotFound` → 404 with appropriate `error_code` based on resource
- `rescue_from ActiveRecord::RecordInvalid` → 422 with `errors:`
- `rescue_from ActionController::ParameterMissing` → 400
- `rescue_from Api::Admin::ConflictError` (new) → 409 with code from the error
- `rescue_from Moderator::MergeUser::DuplicateIdentityError` (and similar) → 409 `merge_identity_conflict`
- Unhandled `StandardError` → 500 + Rails logger

Each controller raises typed errors (`raise Api::Admin::ConflictError.new(:identity_uid_taken, "...")`) instead of inlining `render`. Error envelope rendering centralized in the base controller.

## Testing strategy

Per AGENTS.md: regression tests mandatory; FactoryBot; RSpec; no `receive_message_chain`/`OpenStruct`; strict partial-double verification.

### Spec layout

```
spec/requests/api/v1/admin/users_spec.rb
spec/requests/api/v1/admin/user_notes_spec.rb
spec/requests/api/v1/admin/user_identities_spec.rb
```

### Baseline cases per endpoint

1. **No api-key** → `401 unauthenticated`.
2. **Valid api-key, non-super_admin** → `403 forbidden`.
3. **Valid super_admin api-key** → proceeds.
4. **Happy path**: status + jbuilder shape (assert keys + types, not exact strings).
5. **Not found**: invalid `:user_id` → `404 user_not_found`.
6. **Audit**: assert `AuditLog.count` increased by exactly 1 with expected `category`, `slug`, `data`.

### Endpoint-specific cases

| Endpoint | Cases beyond baseline |
|---|---|
| `GET /users` | filters: `email` exact, `username` exact, `identity_provider`+`identity_uid` reverse lookup, pagination boundaries, `per_page > 100` clamped |
| `GET /users/:id` | unregistered user vs registered, identities listed, no token leakage in JSON |
| `PATCH /users/:id` | calls `Users::Update.call` with the right param shape, profile fields persisted (via the `Profile` model), username change persists, validation errors → `422` with `errors:` |
| `PUT /users/:id/email` | persists via `update_columns`, **no** Devise confirmation email (`ActionMailer::Base.deliveries.empty?`), conflict (duplicate email) → `409 email_taken` |
| `PUT /users/:id/status` | each accepted moderation-status value, real call to `Moderator::ManageActivityAndRoles`, invalid status (including admin-role values like `"Admin"` or `"Super Moderator"`) → `422 invalid_status` |
| `POST /users/:id/merge` | end-to-end merge with factory content (articles/comments/reactions move; loser soft-destroyed), self-merge → `409 cannot_merge_user_into_itself`, mid-merge identity conflict → `409 merge_identity_conflict` |
| `POST /notes` | persists with correct `noteable`/`author`/default reason; custom reason |
| `GET /notes` | newest-first ordering |
| `GET /identities` | no `token`/`secret`/`auth_data_dump` in response |
| `POST /identities` | each of 4 conflict states (clean→201, idempotent→200, state 3→409, state 4→409), unknown provider→422, optional `username` populates `user.<provider>_username`, race-safety via DB unique index |
| `DELETE /identities/:id` | identity destroyed, `<provider>_username` nulled, github case destroys `github_repos`, identity belonging to different user → `404 identity_not_found` |

### OAuth callback round-trip spec

In `spec/requests/users/omniauth_callbacks_spec.rb` (or wherever the existing callback specs live): pre-create an `Identity` via the API for `provider: "mlh"`, `uid: "12345"`, `user: jane`. Stub `omniauth-mlh` payload returning `uid: "12345"`. Trigger the OAuth callback. Assert: `jane` is signed in (no new user, no duplicate Identity, tokens populated on existing row). This is the canary that the API and OAuth login agree on the linkage.

### Don't

- Mock `Moderator::MergeUser` — call it with factory data.
- Mock `current_user` chains — use a real `ApiSecret` factory + header.
- Use `OpenStruct` payloads — real models or anonymous classes.

### Documentation

If Forem maintains an OpenAPI/Swagger spec for the admin API, regenerate it. Verify during implementation.

## Operational considerations

- **Fastly safe params**: `GET /users` query params (`email`, `username`, `identity_provider`, `identity_uid`, `page`, `per_page`) are all on an admin-authenticated path, so Fastly stripping should not apply (admin paths aren't edge-cached). Verify when wiring routes — if any are cached, add the params to `config/fastly/snippets/safe_params_list.vcl` per AGENTS.md.
- **i18n**: error messages and human-readable strings should be added to all locale files in `config/locales` per AGENTS.md.
- **DB index**: confirm `index_identities_on_provider_and_uid` (unique) exists. If not, add a separate migration with `algorithm: :concurrently` and `disable_ddl_transaction!`.
- **Job storm prevention**: none of these endpoints enqueue events that could storm. (Merge does enqueue cleanup jobs, but it's a rare admin operation, not a per-user-update trigger.) No debounce locks needed.

## Open implementation tasks

These are not design decisions but verifications/work items the implementation plan must cover:

1. **OAuth callback round-trip** — verify Forem's omniauth callback uses `find_or_create_by(provider:, uid:)` semantics so an API-pre-created `Identity` is reused on first OAuth login. Adjust the callback if needed (out of scope for this design; would be a follow-up).
2. **Identity unique index** — verify `(provider, uid)` is unique-indexed at the DB level. Add migration if missing.
3. **Service account creation** — runbook step (not code) for creating the Core service account super_admin user and generating its API secret. Document for ops.
4. **OpenAPI/Swagger regeneration** — confirm whether Forem publishes one and update if so.

## References

- Existing admin UI controller: `app/controllers/admin/users_controller.rb`
- Existing admin API concern: `app/controllers/concerns/api/admin/users_controller.rb`
- Existing admin API V1 wrapper: `app/controllers/api/v1/admin/users_controller.rb`
- Merge service: `app/services/moderator/merge_user.rb`
- Status service: `app/services/moderator/manage_activity_and_roles.rb`
- Audit logger: `app/services/audit/logger.rb`, model `app/models/audit_log.rb`
- Authentication providers registry: `app/services/authentication/providers/`
- API conventions reference: `app/controllers/api/v1/users_controller.rb`, `app/controllers/concerns/api/users_controller.rb`
- AGENTS.md (project instructions, repo root)
