# Feed impression accounting

## Metric contract

The home-feed chart sums `feed_events.counts_for` where `category = 0` and
`context_type = 'home'`. It measures authenticated article-card impressions,
with authentication evaluated when the request reaches Forem. It is not a
visit count, a distinct-article count, or a measure of attention time.

A visible document queues an impression once per DOM card when at least 25%
of the card intersects the viewport. A card revisited in the same DOM lifetime
does not generate a second impression. The server suppresses another event
with the same user, article, category, context and feed configuration within five
minutes. Other surfaces and configurations cannot suppress a home impression.

Legacy clients and digest delivery can omit `event_id`. New browser events carry
a UUID that stays unchanged through retries. Receipts remember both inserted and
suppressed IDs. The receipt and event insertion share a transaction, so retrying
an acknowledged event cannot turn a prior suppression into an impression after
the five-minute window. Per-user PostgreSQL transaction advisory locks serialize
the lookup and insert across web processes. Different users can ingest in parallel.

## Confirmed defects repaired

- The single-event path queried records older than the timebox: it could insert
  recent duplicates and suppress legitimate repeat impressions indefinitely.
  Every batch size now uses the same recent-event check.
- The suppression key ignored context, allowing sidebar/email/tag events to hide
  home impressions. The key now includes context and feed configuration.
- Concurrent check-then-insert operations could both insert. User locks now cover
  both operations; multiple users' locks are acquired in stable order.
- The browser cleared its queue before delivery and ignored HTTP failures. Normal
  delivery now awaits acknowledgement and preserves the IDs of transient failures.
  Retries use full jitter, a five-second base and a five-minute cap, with at most
  six transmissions per batch. Outage backoff survives batch eviction/exhaustion
  and resets after acknowledgement. A ten-second timeout bounds a stalled fetch.
- Permanent HTTP errors (including stale-CSRF 422) discard only that batch.
  Network/abort errors, 408, 429 and 5xx can retry; Retry-After seconds and HTTP
  dates are honored. Click, queue-size and exit sends all respect the deadline.
- Queues are capped at 200 events, dropping oldest impressions first and then
  oldest remaining events if necessary. Normal retries pause offline or hidden;
  the online event and foreground interval resume them without bypassing backoff.
- An exit beacon is not a storage acknowledgement. At most one batch is attempted
  on exit, within the same retry budget and deadline. Refused/unavailable beacons
  fall back to keepalive fetch. A queued beacon retains IDs until acknowledgement
  or retry exhaustion. Repeated visibility/pagehide events cannot bypass backoff.
- Observer queueing is now synchronous, removing an unnecessary microtask
  between the visibility callback and the event queue.
- Background documents could generate geometry-based impressions. Hidden documents
  are ignored and cards are reobserved when the document becomes visible.
- A concurrent deletion could discard an entire valid batch with a successful
  response. Ingestion now retries reference checks once; repeated database errors
  propagate rather than receiving a success acknowledgement.
- Missing categories could reach a NOT NULL failure. They are now filtered before
  insertion. New UUIDs are validated before type casting so malformed IDs cannot
  silently lose their replay protection.
- Batch counter refreshes sampled five articles, leaving other touched article
  counters stale. Every inserted article now gets a throttled refresh.

- Batched engagement previously bypassed scoring, config evolution and experiment
  callbacks. BulkUpsert now uses bulk inserts without model callbacks. After
  all enclosing transactions commit, one FeedEvents::FeedbackWorker job receives
  the newly inserted IDs. It refreshes counters before applying the same engagement
  methods used by model callbacks, retaining category/bucket/spawn throttles.
- Expensive scoring and config updates no longer execute under ingestion's user
  locks or article/config row locks. A worker timeout cannot roll back accepted
  events or receipts. Sidekiq allows up to ten retries for feedback failures. Identical
  queued jobs coalesce (until_executing/replace); different accepted batches retain
  their engagement IDs and rely on existing counter/spawn throttles. Receipt-only
  replays enqueue no additional work.

## Admission and incident controls

The browser endpoint accepts at most 20 events per request and 120 requests per
minute per authenticated user. The fixed-window budget uses Rack::Attack's cache
and applies equally to session and JWT authentication, avoiding a shared-IP/NAT
limit. Oversized batches return 413; malformed shapes return 400; budget exhaustion
returns 429 with Retry-After: 60 before any receipt is reserved. Per-event validation
still filters invalid events and acknowledges the rest. Trusted digest ingestion
calls BulkUpsert directly and does not use browser admission limits.

Operators can enable the Flipper flag `disable_browser_feed_events` to
acknowledge and discard browser batches without ingestion, then disable it to
resume. Normal feature-flag cache propagation applies. This is intentional shedding
of analytics during an incident, not a pause with eventual replay.

## Deployment

Apply both migrations before deploying code that accepts `event_id`. The first
adds the nullable UUID and a separate receipt table; the second builds the unique
accepted-event index concurrently. Existing records need no backfill. The first
migration is deliberately irreversible because dropping receipts would destroy
replay protection. Deploy the worker and ensure the low_priority queue is running
before serving the new browser bundle. Serve that bundle after all server instances
support receipts. During a rolling upgrade old server instances still have the
old capture behavior.

Receipts intentionally have no article foreign key and are not purged. They contain
only event UUIDs and ingestion timestamps. Removing them weakens replay protection;
size and retention must be considered before introducing any cleanup job.

The Metabase query continues to sum `counts_for`; receipts never count as impressions.
All current capture paths leave `counts_for` at its default of one. Existing model
counters count event rows, so future weighted rollups must update those consumers
as part of the same change. No such feed-event rollup currently exists.

## Boundaries and remaining risks

100% observation is impossible to establish from browser-only analytics. JavaScript
may never execute, an observer may never run, the browser/process can die, and
connectivity can disappear. Delivery is best effort through brief failures: retry exhaustion and queue
overflow intentionally lose events to protect application load. The retry queue
is in memory; a full page replacement
or closed browser can destroy unacknowledged events. Beacons improve exit delivery
but cannot prove it. No historical missing events can be reconstructed from this
table alone. Existing counts may already include both missed events and duplicates.

Feedback is asynchronous, so config maturity and scores can lag event storage.
There is no transactional DB-to-Redis outbox. If enqueue fails after commit, the
request still acknowledges durable storage and Rails.error reports the inserted
IDs for replay with FeedEvents::FeedbackWorker.perform_async(ids). Monitor these
reports and the worker retry/dead queues. Sidekiq is at-least-once delivery; partial
feedback failures can repeat effects, governed by the existing spawn throttles.
An event receipt guarantees storage idempotency, not exactly-once external effects.

The stored timestamp is ingestion time, not the browser's observation time. Delayed
requests can cross a day boundary. Date buckets in the SQL must use the same timezone
as the report's date boundaries. Very tall cards can fail to reach 25% visible area,
and there is no dwell-time or occlusion test. These are metric-definition limits.

Deleting an article still cascades to its feed events, so historical totals can
shrink. Stable lifetime reporting would require an independent retained aggregate
with an explicit retention policy. User deletion nullifies user IDs on retained
feed events; that does not mean those were anonymous impressions.

The browser E2E suite is currently skipped because of flaky scrolling. The focused
unit tests exercise real observer callbacks and transport behavior, and backend
regressions cover windows, contexts/configs, spawning from mixed batches, replay
receipts, authentication and separate concurrent database connections. Real-browser manual review remains necessary for
scrolling, tab switches, back/forward cache and mobile process termination. Production
coverage and error rates need independent observation; event rows alone cannot
measure their own missing denominator.
