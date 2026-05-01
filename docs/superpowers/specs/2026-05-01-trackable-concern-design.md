# Trackable Concern with Pluggable Adapters

**Status:** Draft
**Date:** 2026-05-01

## Summary

Introduce a `Trackable` model concern to Forem, modeled after the one in `~/core`,
that emits lifecycle events (create / update / destroy) for adopting models through
a pluggable adapter registry. Ship a Customer.io CDP adapter as the first
destination. Leave the registry open so other contributors can add their own
adapters (Segment, PostHog, internal pipelines, etc.) without modifying core code.

This PR ships **infrastructure only**. No model in Forem adopts the concern in this
change — adoption is intentionally deferred so each model's `trackable_user_ids`
and payload shape can be reviewed in isolation, and per-model job-storm risk can be
assessed (per `AGENTS.md`).

## Goals

- Provide a Rails concern that turns any ActiveRecord model into a source of
  lifecycle track events.
- Provide a registry pattern for tracking destinations so future adapters are a
  drop-in addition.
- Provide one working destination — Customer.io CDP — out of the box.
- Stay aligned with Forem's platform philosophy (no DEV-specific hardcoding) and
  Sidekiq conventions.

## Non-goals

- Adopting the concern on existing models (`Article`, `Comment`, `User`, etc.).
- Admin UI for managing tracking configuration. ENV-driven for now.
- AASM state-transition tracking. Forem doesn't lean on AASM the way `~/core` does.
- Association-change tracking (`previous_changes_including_associations`). Models
  that need it can compute it inside `trackable_payload`.

## Architecture

```
┌───────────────────────┐    after_commit     ┌───────────────────────┐
│ Model includes        │────────────────────▶│ Trackable::Dispatch   │
│ Trackable             │  (create/update/    │ Worker (Sidekiq)      │
│ - trackable_user_ids  │   destroy + skip    │                       │
│ - trackable_payload   │   guard + touch-    │ - looks up active     │
│   (optional)          │   only suppression) │   adapters            │
└───────────────────────┘                     │ - calls each .track   │
                                              └──────────┬────────────┘
                                                         │
                              ┌──────────────────────────┼──────────────────────────┐
                              ▼                          ▼                          ▼
                     ┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐
                     │ Trackers::Null   │      │ Trackers::       │      │ Future contrib   │
                     │ (default, no-op) │      │ CustomerioCdp    │      │ adapters         │
                     │                  │      │ (analytics-ruby  │      │                  │
                     │                  │      │  → cdp.customer  │      │                  │
                     │                  │      │  .io)            │      │                  │
                     └──────────────────┘      └──────────────────┘      └──────────────────┘
```

### Files added

- `app/models/concerns/trackable.rb` — the concern.
- `app/workers/trackable/dispatch_worker.rb` — Sidekiq job; fans out to active
  adapters.
- `app/services/trackable/registry.rb` — registry; `register`, `lookup`, `active`.
- `app/services/trackers/base.rb` — adapter interface.
- `app/services/trackers/null.rb` — default no-op adapter.
- `app/services/trackers/customerio_cdp.rb` — Customer.io CDP adapter.
- `config/initializers/trackable.rb` — registers `:null` and `:customerio_cdp`.
- `spec/support/shared_examples/trackable.rb` — shared examples for adopting
  models.
- `spec/models/concerns/trackable_spec.rb`
- `spec/workers/trackable/dispatch_worker_spec.rb`
- `spec/services/trackers/customerio_cdp_spec.rb`
- `spec/services/trackable/registry_spec.rb`

### Gemfile

Add `gem "analytics-ruby"`. Used by the Customer.io CDP adapter, pointed at
`cdp.customer.io`. Customer.io's Pipelines API is Segment-compatible, and there is
no official Customer.io CDP Ruby SDK (verified against
[customerio's GitHub org](https://github.com/customerio) — they ship official CDP
clients for JS, Python, Go, Swift, and Kotlin, but not Ruby).

### Configuration (ENV)

| Variable | Purpose | Default |
| --- | --- | --- |
| `TRACKABLE_ADAPTERS` | Comma-separated list of registered adapter names to fan out to. | `null` |
| `CUSTOMERIO_CDP_WRITE_KEY` | Required for the Customer.io CDP adapter to be `enabled?`. | unset (adapter disabled) |
| `CUSTOMERIO_CDP_HOST` | CDP ingestion host. | `cdp.customer.io` |

A fresh Forem install with this PR merged emits no events: the default adapter is
`Null`, and `CustomerioCdp` is registered but `enabled?` returns false until the
write key is set.

## Concern API

### Minimum case

```ruby
class Article < ApplicationRecord
  include Trackable

  def trackable_user_ids
    user_id
  end
end
```

This is all that's needed to fire `article_created`, `article_updated`,
`article_destroyed` events through every active adapter, with `as_json` (minus a
default ignore-list) as the payload.

### Optional payload shaping

```ruby
def trackable_payload
  as_json(only: %i[id title slug published published_at user_id organization_id])
end
```

Default implementation is `as_json.except(*Trackable::DEFAULT_EXCLUDED_KEYS)` where
`DEFAULT_EXCLUDED_KEYS` is `%w[created_at updated_at]`. Models override when they
want a curated payload.

### Skip toggle

```ruby
article.skip_trackable_events = true
article.update!(...)         # no events fired

Article.skip_trackable_events { ... }  # block-scoped, class-level
```

Default is `false` (events fire). In `Rails.env.test?`, the default is `true` so
the suite is not accidentally chatty; specs opt in via a `with_trackable_events`
helper or by including the shared examples.

### Public instance methods

- `track(event_name, properties_override = {})` — fire if there are non-touch-only
  changes. Returns `true` / `false`.
- `track!(event_name, properties_override = {})` — force-fire regardless of
  changes.
- `trackable_payload` — overridable; defaults to `as_json` minus the default
  excluded keys.
- `trackable_user_ids` — must be implemented; raises `NotImplementedError`
  otherwise.

## Data flow

On a single update:

1. Model's `after_commit` (on update) calls `track_updated`.
2. `track` collects:
   - `previous_changes` filtered to keys present in `trackable_payload`.
   - If the only changed keys are in `TOUCH_ONLY_KEYS` (`updated_at`,
     `engaged_at`), abort — no event.
3. `Trackable::DispatchWorker.perform_async(adapter_name, event_name, user_ids,
   properties, timestamp)` is enqueued once per active adapter.
4. Worker calls `adapter.track(event_name:, user_ids:, properties:, timestamp:)`.
5. Adapter iterates `user_ids` and emits one CDP `track` call per user.

Two key invariants:

- **Payload is snapshotted in the `after_commit` on the web thread**, before the
  worker enqueues. By the time the job runs, associations may have changed; we
  capture the state at commit time.
- **Events fire from `after_commit`, not `after_save`.** Rolled-back transactions
  never enqueue jobs.

## Adapter interface

```ruby
module Trackers
  class Base
    def track(event_name:, user_ids:, properties:, timestamp: nil)
      raise NotImplementedError
    end

    def enabled?
      true
    end
  end
end
```

`#track` is the entire required surface. Adapters that need credentials override
`#enabled?` so they can be registered safely without breaking installs that
haven't configured them.

## Registry

```ruby
module Trackable
  module Registry
    def self.register(name, adapter_class); end
    def self.lookup(name); end
    def self.active; end  # parses TRACKABLE_ADAPTERS, filters by enabled?
  end
end
```

`Registry.active` memoizes adapter **instances** per process so that
`analytics-ruby`'s internal batching/flushing thread can accumulate events across
many jobs (rather than every Sidekiq job constructing a fresh client and losing
the batch buffer on GC).

## Customer.io CDP adapter

```ruby
module Trackers
  class CustomerioCdp < Base
    def enabled?
      ApplicationConfig["CUSTOMERIO_CDP_WRITE_KEY"].present?
    end

    def track(event_name:, user_ids:, properties:, timestamp: nil)
      Array.wrap(user_ids).each do |user_id|
        client.track(
          user_id: user_id.to_s,
          event: event_name,
          properties: properties,
          timestamp: timestamp,
        )
      end
    end

    private

    def client
      @client ||= Segment::Analytics.new(
        write_key: ApplicationConfig["CUSTOMERIO_CDP_WRITE_KEY"],
        host: ApplicationConfig["CUSTOMERIO_CDP_HOST"].presence || "cdp.customer.io",
      )
    end
  end
end
```

The `analytics-ruby` `host` parameter is documented and supported; we use it to
point the Segment client at Customer.io's CDP endpoint.

## Worker

`Trackable::DispatchWorker`:

- Uses Forem's modern Sidekiq pattern: `include Sidekiq::Job`.
- Does **not** use `lock: :until_executing` — events fired by the same job args are
  not deduplicatable; each represents a distinct change. If a specific
  high-frequency adopting model needs debouncing, that's a model-level concern
  (per `AGENTS.md` job-storm guidance), handled at the `track`-call site.
- Looks up the adapter from `Trackable::Registry`. If `enabled?` is now false (env
  changed mid-deploy, etc.), no-op.
- Wraps the adapter call in `rescue StandardError` per adapter, logs to
  `Rails.logger.error` with adapter name, event name, exception. Re-raises only if
  every adapter failed, so Sidekiq retries trigger for genuine outages but one
  flaky destination doesn't take down others.

## Error handling

- **Adapter errors are isolated per-adapter, per-call.**
- **`analytics-ruby` HTTP failures** are absorbed by the gem's internal retry loop;
  its logger is wired to `Rails.logger`.
- **`trackable_user_ids` returning empty** — short-circuit before enqueueing.
- **`enabled?` returning false** — adapter filtered at `Registry.active`, never
  enqueued. Adding `CUSTOMERIO_CDP_WRITE_KEY` later flips it on with no model
  changes.
- **Missing `trackable_user_ids`** — raises `NotImplementedError` at first event
  fire. Caught by the shared examples on model adoption.

## Edge cases

- **Touch-only suppression.** `previous_changes.keys -
  Trackable::TOUCH_ONLY_KEYS` empty → no event. Direct port from `~/core`.
- **Destroy ordering.** `before_destroy` snapshots `trackable_user_ids` to an
  instance variable; `after_commit on: :destroy` reads it. `after_rollback` resets
  it.
- **Test environment.** `skip_trackable_events` defaults to `true` in tests.
  `with_trackable_events` helper flips it for specs that need to assert tracking.

## Testing

1. **`spec/models/concerns/trackable_spec.rb`** — concern in isolation: callback
   firing, touch-only suppression, skip toggle, `track` / `track!`, destroy flow,
   rollback safety. Uses anonymous classes (`Class.new(ApplicationRecord)`) or a
   simple existing model with no production tracking adoption. **No `OpenStruct`,
   no `receive_message_chain`** (per `AGENTS.md`).
2. **`spec/support/shared_examples/trackable.rb`** — adapted from `~/core`. Drop-in
   `it_behaves_like "trackable"` for any future adopting model.
3. **`spec/services/trackers/customerio_cdp_spec.rb`** — stubs
   `Segment::Analytics.new` with an instance double; asserts `track` shape per
   user. Tests `enabled?` true/false based on ENV.
4. **`spec/services/trackable/registry_spec.rb`** — registration, lookup,
   `active` filters, ENV parsing.
5. **`spec/workers/trackable/dispatch_worker_spec.rb`** — adapter lookup, error
   isolation, no-op when adapter disabled.

Strict partial-double verification (per `AGENTS.md`) — adapter specs use real
adapter instances with stubbed HTTP clients, not stubbed adapter methods.

## What this PR does not change

- No migrations.
- No locale file updates (no user-facing text).
- No new Fastly safe-params (no new GET params).
- No model adopts `Trackable`.
- No admin UI.

## Sources

- `~/core/app/models/concerns/trackable.rb` — reference implementation.
- [Customer.io Pipelines API Reference](https://docs.customer.io/integrations/api/cdp/)
- [analytics-ruby on GitHub](https://github.com/segmentio/analytics-ruby)
- [Segment Ruby docs (host configuration)](https://segment.com/docs/connections/sources/catalog/libraries/server/ruby/)
