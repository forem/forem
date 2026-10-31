# Disposable local Redis cache

Forem can run one bounded Redis process alongside Puma on each web host. This
accelerates **Rails.cache** reads over a private Unix socket. Hosted Redis remains
the authoritative cache; local data is disposable. This is a separate process,
shared by Puma workers, rather than Redis embedded in the Ruby heap.

Sessions, Sidekiq, distributed locks and the independent Redis clients retain
their existing configuration. Cached role names, tag/subforem moderator scopes,
user-block lists and subscription checks use L1. Trusted-role checks, admin API
keys, Googlebot rate-limit exemptions, deletion tokens, feedback-email suppression
and coordination reads explicitly pass `local_cache: false`
to retain authoritative reads. This bypasses both Redis L1 and Rails request
memory, including `fetch_multi`. Rails.cache raw reads (including rate-limit
counters), writes, increments, decrements and NX operations go to hosted Redis.
The default deployment is unchanged unless `LOCAL_REDIS_URL` is set.

## Requirements

- A single authoritative Redis endpoint in `REDISCLOUD_URL`, falling back to
  `REDIS_URL`. TLS (`rediss://`) and credentials are handled by the Redis clients.
- Hosted Redis must support **RESP3 and `CLIENT TRACKING ON BCAST`**. Redis Open
  Source supports this from 6.0. Redis Cloud requires database version **7.4+** and
  RESP3 enabled. The daemon uses one connection, without `REDIRECT` (which Redis
  Cloud does not support). Verify your specific database version and ACLs before
  enabling. Unsupported tracking leaves L1 disabled, with a warning in logs.
- Hosted ACLs must allow HELLO/AUTH, CLIENT TRACKING, PING, and the application's
  existing cache operations, plus EVAL/GET/PTTL for atomic read-through fills.
- `redis-server` on each web host. The dedicated local database must **never**
  contain sessions, jobs, locks, or other durable/shared data: it is flushed on
  startup, reconnect, and loss of the health lease. The launcher and clients reject
  a source Unix socket matching the local socket, including symlink and hard-link aliases, before
  starting or connecting to the disposable cache. This does not replace the
  requirement to provision a dedicated local database.

References: [Redis tracking protocol](https://redis.io/docs/latest/develop/reference/client-side-caching/)
and [Redis Cloud compatibility](https://redis.io/docs/latest/operate/rs/references/compatibility/client-side-caching/).

## Heroku setup

For classic buildpack deployments, add the
[Heroku community Apt buildpack](https://elements.heroku.com/buildpacks/heroku/heroku-buildpack-apt)
**before** `heroku/ruby`. The committed `Aptfile` installs `redis-server`.
For container deployments the production `Containerfile` installs it directly.
No Redis buildpack, hivemind installation, or Redis persistence volume is needed.

Set:

```text
LOCAL_REDIS_URL=unix:///tmp/forem-cache.sock
LOCAL_REDIS_MAXMEMORY=128mb
```

The Procfile's `bundle exec ruby bin/web` starts Redis, a lightweight Ruby sync
daemon (without booting Rails), and Puma. Without `LOCAL_REDIS_URL`, it directly
executes the original Puma command. The production `Containerfile` passes its
original `rails server -b 0.0.0.0 -p 3000` command to `bin/web` the same way.
Release tasks and worker commands are unchanged.
Workers may inherit `LOCAL_REDIS_URL` from app-wide configuration; without a local
socket they fall back to authoritative Redis. Their writes still invalidate web
caches through server-side tracking, including during mixed-version rolling deploys.

No initial download or hot-key registry is required. Fresh dynos warm on demand,
including batched collection reads. Frequent deploys have the same cold-cache
behavior. Warm-up duration and hit rate depend on actual traffic; measure them.

128 MB is the conservative default, **per dyno**, not per Puma worker. With measured
headroom you can set `LOCAL_REDIS_MAXMEMORY=1536mb`, for example, without changing
application code. Redis uses `allkeys-lfu`, has no TCP listener, restricts its Unix
socket to its owner, and disables both RDB and AOF persistence. Redis maxmemory is
an eviction budget, **not an RSS ceiling**: allow for fragmentation, buffers,
large batch operations, the sync Ruby process, and Puma's peak allocations.
Do not allocate all currently free memory.

## Coherence and failure behavior

- Redis server-assisted BCAST tracking observes all writers, including ordinary
  RedisCacheStore clients, old releases, scripts, deletes, expiry, eviction and
  flushes. Application code does not need to remember to publish invalidations.
- The daemon processes invalidations and PING replies in order on the **same
  RESP3 connection**, with automatic reconnection disabled. It invalidates L1
  and explicitly re-establishes tracking on reconnect.
- A local health lease lasts at most **3 seconds** and is refreshed only by a
  timely PING reply from that stream. An unavailable, stalled or killed daemon
  causes reads to bypass L1 after that lease. Delayed replies cannot renew it for
  a full new interval. Expired/evicted leases flush L1 before enabling it again.
- Local Lua scripts check the lease and generation atomically with reads/fills.
  Each processed invalidation advances the generation, preventing a slow remote
  read from refilling a key after its invalidation was processed.
- A source Lua script reads each missing value and its PTTL atomically, pipelined
  in a single round trip for a batch. Fills subtract elapsed time and use at most
  the source's remaining TTL, capped at **30 seconds**, even for non-expiring keys.
  Nil misses are not cached. Rails still checks entry expiry, version, compression
  and serialization exactly as for hosted cache entries.
- Writes and deletes evict synchronously on the writing host. Remote write errors
  retain Rails RedisCacheStore's existing error handling. A local connection or
  pool failure falls back to hosted Redis. No subscriber threads live in Puma,
  so preloading and worker forks do not create duplicate subscriptions.
- The supervisor restarts failed cache auxiliaries with backoff while Puma stays
  running. Web exit shuts down auxiliaries; TERM/INT are forwarded to all children,
  with a 28-second shutdown deadline to fit Heroku's 30-second window.

This is **eventually consistent cache acceleration**, not synchronous replication.
A read may briefly see the pre-write value until an invalidation arrives; a lost
connection can leave a previously cached value readable until the lease expires.
A read concurrent with an update may return the prior value. It does not make
sessions or distributed coordination safe to move to L1. Role/scope, blocking and
subscription checks explicitly accept these delayed updates; trusted-role checks
and admin API-key exemptions remain authoritative.
Anything requiring authoritative reads must use `local_cache: false`, `raw: true` (for raw values), an independent Redis
client, or retain the standard RedisCacheStore. Rack::Attack has an explicit
subclass adapter so its raw counter encoding and pattern-reset API are preserved.

## Observe and roll back

Each Puma worker reports `local_redis_cache.hits`, `local_redis_cache.misses`
and `local_redis_cache.bypasses` counts through `ForemStatsClient` (Datadog and/or
Better Stack) at most once a minute. A bypass is a read served by hosted Redis
because the health lease was missing or local Redis was unreachable. The store
counts in memory under one mutex (about 0.2µs and no allocations per read) rather
than subscribing to notifications (about 4µs per read). Up to a minute of counts
is dropped when a worker exits. Sum across dynos; the bypass share should stay
near zero once dynos have started.

`read.local_redis_cache` ActiveSupport notifications also report `hits` and
`misses` without exposing keys/values, and `bypass.local_redis_cache` marks a
bypass. Nothing in the app subscribes to them. These are separate from Rails'
existing logical `cache_read` notifications (which report hits from either tier).
A tracking failure logs `LocalRedis sync disconnected` and its error class.

Inspect local Redis with `redis-cli -s /tmp/forem-cache.sock INFO memory` and
`INFO stats` for actual RSS, evictions and hit behavior. Check the health lease
with `SCAN 0 MATCH forem:l1:lease:*` followed by `PTTL <key>`; a continuously
absent lease means acceleration is off.
There is one additional hosted connection per web dyno for tracking, plus the
existing Rails connection pools. BCAST receives changes for all keys on the
source endpoint; use a dedicated hosted cache where possible and measure
invalidation traffic if it shares an instance with other workloads. Compare request latency, remote command volume,
L1 hit ratio and peak dyno RSS before increasing the memory allocation.

To roll back, unset `LOCAL_REDIS_URL` and restart/deploy. All cache values and
writes remain in the original hosted cache; no data migration is necessary.

## Other hosts and future Rust services

The same launcher, socket, scripts, and hosted endpoint work on a regional VM or
container. For a persistent sidecar, run `bundle exec ruby bin/redis-local-server` and
`bundle exec ruby bin/redis-local-sync` under the host supervisor and start Puma directly; mount the
socket directory into the application container with appropriate ownership. Never
run two sync daemons against the same local Redis database.

A Rust reader can use the same Redis protocol without a Ruby-specific coherence
mechanism: `forem:l1:lease:<origin>` holds the generation; data keys are
`forem:l1:data:<origin>:<normalized source key>`. `<origin>` is the SHA-256 hex
digest of the exact authoritative URL, including its database and credentials.
This prevents old workers reading another backend's payloads when a sidecar is
reused during endpoint migration. Credential rotation may cause a cold cache. The READ/FILL/INVALIDATE/HEARTBEAT scripts
in `lib/local_redis/cache.rb` define the atomic protocol. It must use those lease
and generation checks rather than directly GETting data keys. Payloads remain
serialized Rails cache entries; sharing those payloads with Rust requires an
explicit compatible codec or a separate namespace. This change does not pretend
that Rails serialization becomes language-independent.

Every region still uses the same authoritative endpoint. Cross-region misses and
writes incur network latency; partition behavior remains the lease-based fallback
above. Regional databases and active-active cache semantics are separate work.

## Regression tests

Install a Redis 6+ executable (`REDIS_SERVER` may override its path), then run:

```sh
bundle exec rspec spec/lib/active_support/cache/local_redis_cache_store*spec.rb spec/lib/local_redis/
```

The specs start isolated Redis servers under `/tmp`, disable fakeredis for these
examples, and clean up their processes and files. They exercise actual Lua, TTLs,
RESP3 invalidations, old-version writers, connection loss and process supervision.

## Compatibility boundaries and audit

| Configuration | Status |
| --- | --- |
| Forem's Rails 8.0.5, redis 4.7.1, redis-client 0.31.0 | Regression-tested with real local Redis 8.2.3 |
| Standard RedisCacheStore, MemoryStore and NullStore with L1 disabled | Existing behavior; extra per-call bypass option is ignored by standard stores |
| Single URL for standalone Redis, authenticated/TLS Redis, or a managed proxy | Supported protocol design; provider must support RESP3 BCAST and the stated ACLs |
| Redis Cloud | Requires 7.4+, RESP3 and provider validation; not exercised against the production instance |
| URL arrays, Redis::Distributed, custom injected clients, Sentinel, Cluster client routing | Rejected explicitly: the daemon cannot safely infer every node or custom connection's invalidation stream |
| Native Redis Cluster, read replicas, active-active multi-primary writes | Not validated or claimed supported by this implementation |
| Rust or other languages | Same coherence protocol; Rails payload decoding still needs an explicit codec agreement |

One dedicated local Redis database and one sync daemon serve one authoritative
endpoint. Multiple backend origins on the same sidecar are isolated for safety,
but their reset operations can evict each other's data; this is not a recommended
steady-state deployment. Do not point the local socket at a database used for
anything else. Custom TLS certificates, routing, or connection overrides must be
implemented in both clients before that topology is enabled.

The audit covered cache read/fetch/exist and multi APIs, raw reads and counters,
NX/bulk writes and deletes, namespace/long-key handling, request-local memory,
source identity, tracking reconnect/lease loss, Puma forks, process supervision,
and Rack::Attack's adapter selection. Sessions, Sidekiq, and separate Redis clients
keep their existing wiring. Their independent regression suites are not replaced
by the cache integration tests.

Googlebot prefixes govern a Rack::Attack exemption and feedback-response markers
suppress duplicate emails, so both bypass L1 and request memory. Delegated-access
JWT keys use their own MemoryStore and are unaffected. Feedback suppression and
ThrottledCall retain their existing fetch-based behavior; this does not turn them
into atomic distributed locks.

Existing `MemoryFirstCache`, Flipper memory stores, and Settings/RequestStore
memoization remain separate layers with their existing invalidation semantics.
This feature does not promise to invalidate values already retained by those
layers. Future Rails, Redis client, or Rack::Attack upgrades must rerun the
integration contract tests; protocol portability is not a guarantee of arbitrary
future API compatibility.
