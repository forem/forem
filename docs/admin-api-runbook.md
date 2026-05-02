# Admin API — Operations Runbook

The admin API at `/api/admin/users/...` lets a trusted caller (initially MLH Core)
programmatically read users, update profile / email / status, merge accounts,
manage admin notes, and link/unlink third-party identities.

Spec: `docs/superpowers/specs/2026-05-02-admin-user-management-api-design.md`
Plan: `docs/superpowers/plans/2026-05-02-admin-user-management-api.md`

## Creating a service account for MLH Core

1. In a Rails console (production), create a dedicated super_admin user:

   ```ruby
   user = User.create!(
     email: "core-service@mlh.io",
     username: "core_service",
     name: "MLH Core Service Account",
     password: SecureRandom.hex(32),
     password_confirmation: SecureRandom.hex(32),
     registered: true, registered_at: Time.current,
   )
   user.skip_confirmation!
   user.save!
   user.add_role(:super_admin)
   ```

2. Generate an API secret for the user:

   ```ruby
   secret = ApiSecret.create!(user: user, description: "MLH Core sync — initial issue")
   puts secret.secret
   ```

3. Store the secret in MLH Core's secrets vault. Rotate by creating a new ApiSecret record and deleting the old one.

## Authentication

All admin API requests must include:

```
api-key: <secret>
Accept: application/vnd.forem.api-v1+json
```

The Accept header is required — without it, requests fall through to the default API version and these endpoints will return 404.

## Endpoints

All under `/api/admin/`. Strict-fail-closed semantics on conflicts.

| Method | Path | Purpose |
|---|---|---|
| GET    | `/users`                          | List/search users (filters: email, username, identity_provider+identity_uid, page, per_page) |
| GET    | `/users/:id`                      | Fetch single user |
| PATCH  | `/users/:id`                      | Update profile fields (name, username, summary, location, website_url) |
| PUT    | `/users/:id/email`                | Change email (skips Devise confirmation) |
| PUT    | `/users/:id/status`               | Change moderation status (Good standing/Suspended/Spam/Warned/Comment Suspended/Trusted/Limited) |
| POST   | `/users/:id/merge`                | Merge another user INTO :id (synchronous) |
| GET    | `/users/:user_id/notes`           | List admin notes |
| POST   | `/users/:user_id/notes`           | Create admin note |
| GET    | `/users/:user_id/identities`      | List third-party identities |
| POST   | `/users/:user_id/identities`      | Link identity (provider + uid + optional username) |
| DELETE | `/users/:user_id/identities/:id`  | Unlink identity (also nulls user.<provider>_username, cascades github_repos for github) |

## Audit log

Every successful write emits an `AuditLog` row with `category: "admin_api.audit.log"`. View via the existing admin UI's user audit log tab, or query directly:

```ruby
AuditLog.where(category: "admin_api.audit.log").on_user(user).order(created_at: :desc)
```

## Error envelope

All errors return:

```json
{ "error": "Human-readable message", "error_code": "snake_case_code", "status": 409 }
```

Validation errors (422) additionally include an `errors:` hash with field-level AR errors.

Common error codes:
- `unauthenticated` (401), `forbidden` (403)
- `not_found` (404), `user_not_found`, `identity_not_found`
- `user_already_has_identity_for_provider`, `identity_uid_taken` (409 conflicts)
- `cannot_merge_user_into_itself`, `merge_identity_conflict` (409)
- `unknown_provider`, `invalid_status` (422)
- `validation_failed` (422)
- `email_taken` (409)

## Identity linking — important behavior

Linking via `POST /users/:user_id/identities` creates an `Identity` row WITHOUT
populating OAuth tokens. When the user later signs in via the corresponding
OAuth provider (e.g., MyMLH), Forem's omniauth callback finds the existing
`(provider, uid)` row and populates token / secret / auth_data_dump in place.
No duplicate user is created.

This is verified by `spec/requests/authenticator_api_link_round_trip_spec.rb`.
