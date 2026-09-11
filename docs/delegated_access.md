# Delegated API access

Forem can accept short-lived RFC 9068 access-token JWTs from one trusted
delegation service. This is an alternative to an API key when the trusted
service has authorized a request; it does not change account linking or
browser sign-in.

## Configuration

Set all of the following values before enabling delegated access:

```text
DELEGATED_ACCESS_ENABLED=true
DELEGATED_ACCESS_ISSUER=https://api.example.com
DELEGATED_ACCESS_AUDIENCE=https://community.example.com
DELEGATED_ACCESS_IDENTITY_PROVIDER=external-provider
DELEGATED_ACCESS_OWNER_CLAIM=https://api.example.com/claims/dev_user_id
DELEGATED_ACCESS_JWKS_URI=https://api.example.com/.well-known/jwks.json
```

The issuer, audience, identity provider, owner claim, and JWKS URI are exact
deployment trust settings. The JWKS URI and issuer must be HTTPS and are never
selected from token claims or headers. Forem does not require a copied public
PEM, active key ID, or OAuth client ID.

These optional safety bounds have conservative defaults:

```text
DELEGATED_ACCESS_JWKS_MAX_AGE_SECONDS=300
DELEGATED_ACCESS_MAX_TOKEN_LIFETIME_SECONDS=60
```

`DELEGATED_ACCESS_JWKS_MAX_AGE_SECONDS` is the lifetime of each Puma worker's
in-process key cache. Forem never uses an expired entry if the next fetch fails.

## Token and key contract

This contract follows [RFC 9068](https://www.rfc-editor.org/rfc/rfc9068.html),
particularly its resource-server checks for explicit access-token typing,
issuer, audience, signature, and expiration. The Core-to-Forem contract narrows
the permitted form to RS256 with `typ: at+jwt` and a non-blank `kid`, and also
requires bounded `sub`, `exp`, `iat`, `nbf`, `jti`, and the configured owner
claim. Session-purpose `sid` and `nonce` claims are rejected. Core remains
responsible for issuing the complete RFC 9068 claim set, including `client_id`
and `scope` where applicable; Forem does not use either claim for authorization.

The `jwt` gem parses the token and JWK Set, selects the matching `kid`, verifies
the RS256 signature, and enforces the registered issuer, audience, and time
claims. Forem's surrounding code supplies the access-token profile checks, the
maximum token lifetime, and a bounded fetch from the configured JWKS URI.

The configured JWKS endpoint must return JSON with a top-level `keys` array. It
must contain at least one unique RSA public signing key marked `use: sig` and
`alg: RS256`, with a modulus of at least 2048 bits. Other public keys are
ignored; private RSA parameters invalidate the complete response.

Authorization remains inside the delegated-access service. Forem does not map
controller actions to scopes or reinterpret which OAuth clients may exercise a
grant. An endpoint that uses API-key authentication may accept a verified
delegated token; the trusted issuer must only mint that token when the grant
authorizes the requested operation.

## Failures, caching, and rotation

Malformed tokens, invalid claims or signatures, and unknown key IDs return `401
Unauthorized`. When no usable cache entry exists and the configured trust
endpoint is unavailable or invalid, Forem returns `503 Service Unavailable`.
Neither case falls back from a presented Bearer token to API-key authentication.

Fresh known keys are used without a request. An unknown key ID does not
invalidate the cache or contact the issuer, preventing attacker-selected IDs
from amplifying JWKS traffic. For rotation, publish both the old and successor
keys, wait at least one configured cache lifetime, and only then begin signing
with the successor.

During a suspected key compromise, an operator can invalidate the in-process
key cache immediately from a Rails console:

```ruby
Rails.application.config.x.delegated_access.invalidate_cache!
```

Run this command in every Forem application process, or restart the application
processes, after the compromised public key has been removed from the issuer's
JWKS. The cache contains only validated public key material and is not durable.
