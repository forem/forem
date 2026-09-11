# Temporary external authentication return

This bridge supports the Core/DevRelay account-relationship workflow until Forem's
generic OIDC consumer supports third-party initiated login and `target_link_uri`.
It is temporary and must be removed as part of that rollout.

## Enablement

The bridge is disabled by default. Both settings are required:

```dotenv
FOREM_EXTERNAL_RETURN_ENABLED=true
FOREM_EXTERNAL_RETURN_URL=https://www.mlh.test/oauth/dev
```

Use the receiving application's actual HTTPS endpoint. The URL must have a path
and no credentials, query, or fragment. Only the exact flag value `true` enables
the bridge; configuring the URL alone does not enable it. Disable it by removing
the flag or setting it to `false`.

The gate covers both continuation redirects and stored external destinations,
including returns after account-switch confirmation. When disabled, normal
Forem sign-in and onboarding routing applies. When enabled, the external return
can precede onboarding; it does not mark onboarding or terms acceptance complete.
The receiving application remains responsible for validating its continuation
and verifying the account relationship before resuming its authorization.

## Removal with OIDC

Replace this bridge with generic third-party initiated login as defined by
[OpenID Connect Core section 4](https://openid.net/specs/openid-connect-core-1_0.html#ThirdPartyInitiatedLogin).
Core will supply its return URL, including its opaque continuation, through
`target_link_uri`. Forem will validate and retain the destination as part of its
own login transaction without interpreting Core's continuation.

The rollout must migrate Core's login initiation, preserve destination validation
and account-switch behavior, and explicitly define when onboarding completes
relative to the return. Remove `Authentication::ExternalReturn`, its callback and
stored-destination branches, the custom continuation field in account-switch
state, and both environment settings. Replace bridge tests with generic OIDC
destination and disabled/unconfigured-provider coverage. Core retains its
continuation validation and relationship checks; navigation back is not proof
of successful account linking.
