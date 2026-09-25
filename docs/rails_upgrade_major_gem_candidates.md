# Rails Upgrade: Major Gem Upgrade Candidates

_Last reviewed: 2026-03-04_

This list is an initial pass over `Gemfile`/`Gemfile.lock` to identify gems that are both:

1. pinned to an older major version in Forem, and
2. likely to matter for future Rails upgrades (runtime framework, middleware, background jobs, auth, or core test tooling).

## Candidate gems

| Gem | Current (lockfile) | Latest (RubyGems) | Major gap | Why this helps Rails upgrades |
|---|---:|---:|---:|---|
| `rails` | `7.0.8.7` | `8.1.2` | +1 | Direct framework upgrade path; drives compatibility requirements across the dependency graph. |
| `puma` | `5.6.9` | `7.2.0` | +2 | App server compatibility often tracks Rack/Rails changes and Ruby upgrades. |
| `rack-cors` | `1.1.1` | `3.0.0` | +2 | Rack middleware with a very old pinned major (`1.x`); likely to intersect with Rack/Rails request stack changes. |
| `devise` | `4.9.4` | `5.0.2` | +1 | Authentication layer tightly coupled to Rails internals and controller/session behavior. |
| `ransack` | `3.2.1` | `4.4.1` | +1 | AR query integration; upgrading early reduces query API friction during Rails upgrades. |
| `sidekiq` | `6.5.12` | `8.1.1` | +2 | Background jobs + Redis integration; Sidekiq major bumps typically align with newer Ruby/Rails ecosystems. |
| `redis` | `4.7.1` | `5.4.1` | +1 | Shared dependency for Sidekiq/session/caching paths; older client versions can block transitive upgrades. |
| `flipper` (+ adapters/UI) | `0.25.4` | `1.4.0` | +1 | Feature flagging touches controller/view/service code paths broadly; upgrade surface is easier before Rails jump. |
| `i18n-js` | `3.9.2` | `4.2.4` | +1 | Rails i18n integration between backend/frontend; keeping this current lowers upgrade coordination overhead. |
| `rspec-rails` | `6.1.1` | `8.0.3` | +2 | Test framework compatibility with new Rails versions is critical for safe iterative framework upgrades. |

## Suggested order (smallest-risk first)

1. `rack-cors`, `redis`, `flipper`, `i18n-js`
2. `ransack`, `devise`
3. `puma`, `sidekiq`
4. `rspec-rails`
5. `rails`

This sequencing keeps infrastructure/supporting libraries closer to current majors before attempting the framework major upgrade.
