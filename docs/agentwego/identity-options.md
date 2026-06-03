# Noema Identity Options and Ory Kratos Boundary

## Scope

This document records the M0-T31 identity posture for Noema. It is a local-only architecture/spec artifact and does not configure, contact, or deploy Ory Kratos.

Safety boundary:

- no production access;
- no real Secret reads or writes;
- no external database, S3, Elasticsearch/OpenSearch, or Kratos calls;
- no Kubernetes apply/deploy;
- no irreversible user, identity, or session operations.

## Decision posture

Noema auth/session/user identity work should converge on native Ory Kratos integration instead of building a long-lived custom authentication system.

The target boundary names are Ory-native:

- Kratos identity;
- Kratos session / `/sessions/whoami` assertion;
- Kratos self-service flows for login, registration, settings, recovery, and verification;
- Kratos public API vs admin API separation.

M0-T31 only creates local DTO/spec seams and fixtures. It does not implement a Kratos HTTP client, self-service UI, cookie/session middleware, or admin lifecycle operations.

## Authoritative Ory concepts used

The boundary follows Ory Kratos terminology from these docs:

- Session management overview: <https://www.ory.com/docs/kratos/session-management/overview>
- Self-service flows: <https://www.ory.com/docs/kratos/self-service>
- Identity metadata: <https://www.ory.com/docs/kratos/manage-identities/managing-users-identities-metadata>
- User/admin session management: <https://www.ory.com/docs/kratos/session-management/list-revoke-get-sessions>

Important implications for Noema:

- identity traits are the durable user identity schema surface;
- public metadata can be exposed through session reads, while admin metadata belongs behind privileged identity lifecycle operations;
- browser sessions are asserted through Kratos session semantics rather than Devise/Warden session keys;
- user-facing login/registration/settings/recovery/verification are self-service flows, not ad-hoc Noema auth endpoints.

## M0-T31 local DTO/spec shape

Native package:

```text
services/api/internal/identity
```

Local DTOs:

- `KratosIdentityImport`
  - `ID`
  - `SchemaID`
  - `State`
  - `Traits`
  - `MetadataPublic`
  - `MetadataAdmin`
  - `CreatedAt`
  - `UpdatedAt`
- `KratosTraits`
  - `Email`
  - `Username`
  - `Name`
- `KratosSession`
  - `ID`
  - `Active`
  - `IdentityID`
  - `AuthenticatedAt`
  - `IssuedAt`
  - `ExpiresAt`
- `KratosSelfServiceFlowKind`
  - `login`
  - `registration`
  - `settings`
  - `recovery`
  - `verification`

The default schema id for local import previews is `noema-user-v1`.

## Forem → Kratos import bridge

Native package:

```text
services/api/internal/legacyimport
```

M0-T31 adds `MapForemUserIdentity`, which combines:

- clean `UserDTO` from `MapForemUser`;
- email as Kratos identity trait data;
- legacy external provider subjects as Kratos admin metadata;
- public profile image as Kratos public metadata.

This intentionally excludes legacy OAuth tokens, secrets, encrypted passwords, Devise lock/remember/recover state, and raw OmniAuth dumps. Those fields are credentials or framework state; they should not enter the clean import DTO path.

## Inventory and edge evidence

Relevant legacy sources from the AgentWeGo inventory:

| Legacy file | Meaning for identity boundary |
| --- | --- |
| `app/models/user.rb` | Large Forem account/profile/business aggregate; do not line-port into Kratos. |
| `app/models/identity.rb` | Legacy OmniAuth provider binding (`provider`, `uid`, token/secret dump); maps only provider subject hints into Kratos admin metadata in M0-T31. |
| `app/controllers/omniauth_callbacks_controller.rb` | Current OAuth callback flow; future target is Kratos self-service or identity-provider exchange boundary. |
| `app/controllers/sessions_controller.rb` | Current Devise session wrapper; future target is Kratos session assertion/revocation. |
| `app/controllers/concerns/session_current_user.rb` | Reads Warden session key; future target is Kratos `/sessions/whoami` identity assertion. |
| `app/models/settings/authentication.rb` | Legacy auth policy/config; should become an auth policy/config boundary, not user DTO fields. |

## Verification

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

These tests use only checked-in fixtures and pure Go DTO mapping. They do not connect to Kratos, PostgreSQL, S3, Elasticsearch/OpenSearch, Kubernetes, or any external service.

## Deferred work

- Real Kratos public/admin API client with explicit injectable transport.
- `/sessions/whoami` middleware and browser cookie/session verification.
- Self-service flow initialization/return handling for login, registration, settings, recovery, and verification.
- Identity schema JSON and Kratos deployment/runtime configuration.
- Account linking, invite-only policy, email verification posture, and admin recovery bootstrap.
- Data migration jobs that create/update real Kratos identities.

Each deferred item must stay explicit, mockable, and locally verified before any production integration.
