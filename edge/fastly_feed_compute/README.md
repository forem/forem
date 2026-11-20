# Forem Edge Feed Compute Service (Proof of Concept)

This Fastly Compute (Rust -> `wasm32-wasip1`) service evaluates Forem's signed-in custom
`FeedConfig`-derived home feed (`GET /stories/feed/?page=N&type_of=discover`) directly at
Fastly Edge POPs using snapshots mirrored into a **Fastly KV Store** by Rails background jobs.

All ranking, filtering, two-stage semantic scoring, shuffling, diversity interleaving, HMAC
token verification, and JSON card assembly live in the shared pure-Rust crate
[`gems/forem_native/crates/forem_core/src/edge_feed.rs`](../../gems/forem_native/crates/forem_core/src/edge_feed.rs).

## Fastly Resources Required

1. **Backend:** `forem_origin` pointing to your Forem Rails origin.
2. **KV Store:** `forem_feed_mirror` linked to this Compute service. Set its ID in Rails as `FASTLY_FEED_KV_STORE_ID`.
3. **Secret Store:** `forem_edge_secrets` containing key `edge_feed_secret`. Set the exact same secret in Rails as `FASTLY_EDGE_FEED_SECRET`.

## Local Development

```bash
# Install the wasm32-wasip1 target if not installed
rustup target add wasm32-wasip1

# Build the Wasm binary
cd edge/fastly_feed_compute
fastly compute build

# Run locally against a local Forem origin + local_kv.json
fastly compute serve
```

## Response Headers

- `X-Forem-Edge-Feed: hit` — served completely at the edge without hitting Rails.
- `X-Forem-Edge-Feed: fallback:<reason>` — transparently proxied to `forem_origin`.
- `X-Forem-Edge-Miss: user-profile` (request header to origin) — signals `Stories::FeedsController` to enqueue `EdgeFeed::SyncUserProfileWorker` for that signed-in user.
