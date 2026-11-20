//! Proof-of-concept Fastly Compute service serving Forem's signed-in custom
//! `FeedConfig`-derived home feed (`/stories/feed/?page=N&type_of=discover`)
//! directly from Fastly Edge POPs using mirrored Fastly KV Store data.
//!
//! All non-eligible requests (signed-out, tags, timeframes, `following`,
//! `curated`, missing KV data, missing user profile, or any unexpected error)
//! transparently fail open to the `forem_origin` backend.

use std::collections::{HashMap, HashSet};
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use fastly::cache::simple as pop_cache;
use fastly::http::{header, Method, StatusCode};
use fastly::{Error, KVStore, Request, Response, SecretStore};
use forem_core::edge_feed::{
    assemble_feed_response_json, parse_card_shard_raw_json, parse_embedding_table_json,
    parse_host_map_json, parse_subforem_snapshot_json, parse_user_profile_json, rank_custom_feed,
    sign_edge_visit_token, sign_sticky_config_token, verify_edge_user_token,
    verify_sticky_config_token, EdgeFeedRequest,
};

const ORIGIN_BACKEND: &str = "forem_origin";
const KV_STORE_NAME: &str = "forem_feed_mirror";
const SECRET_STORE_NAME: &str = "forem_edge_secrets";
const SECRET_KEY_NAME: &str = "edge_feed_secret";

const USER_COOKIE_NAME: &str = "_forem_edge_uid";
const STICKY_CONFIG_COOKIE_NAME: &str = "_forem_edge_fc";
const DEFAULT_PER_PAGE: usize = 35;

/// In-POP Simple Cache TTLs so 99%+ of edge requests avoid KV round-trips.
const HOST_MAP_POP_TTL: Duration = Duration::from_secs(60);
const SNAPSHOT_POP_TTL: Duration = Duration::from_secs(30);
const CARD_SHARD_POP_TTL: Duration = Duration::from_secs(30);
const EMBEDDINGS_POP_TTL: Duration = Duration::from_secs(60);

#[fastly::main]
fn main(mut req: Request) -> Result<Response, Error> {
    match try_serve_edge_feed(&req) {
        Ok(EdgeOutcome::Served(resp)) => Ok(resp),
        Ok(EdgeOutcome::PassThrough { reason, edge_miss }) => {
            if let Some(miss_tag) = edge_miss {
                req.set_header("X-Forem-Edge-Miss", miss_tag);
            }
            let mut resp = req.send(ORIGIN_BACKEND)?;
            resp.set_header("X-Forem-Edge-Feed", format!("fallback:{reason}"));
            Ok(resp)
        }
        Err(_) => {
            let mut resp = req.send(ORIGIN_BACKEND)?;
            resp.set_header("X-Forem-Edge-Feed", "fallback:error");
            Ok(resp)
        }
    }
}

enum EdgeOutcome {
    Served(Response),
    PassThrough {
        reason: &'static str,
        edge_miss: Option<&'static str>,
    },
}

fn pass(reason: &'static str) -> EdgeOutcome {
    EdgeOutcome::PassThrough {
        reason,
        edge_miss: None,
    }
}

fn pass_with_miss(reason: &'static str, edge_miss: &'static str) -> EdgeOutcome {
    EdgeOutcome::PassThrough {
        reason,
        edge_miss: Some(edge_miss),
    }
}

fn try_serve_edge_feed(req: &Request) -> Result<EdgeOutcome, Error> {
    // 1. Only intercept GET /stories/feed or /stories/feed/
    if req.get_method() != Method::GET {
        return Ok(pass("method"));
    }
    let path = req.get_path();
    if path != "/stories/feed" && path != "/stories/feed/" {
        return Ok(pass("path"));
    }

    // 2. Parse query params; restrict to default signed-in `discover` home feed.
    let params = parse_query_params(req.get_query_str().unwrap_or(""));
    if params.get("tag").is_some_and(|v| !v.is_empty())
        || params.get("timeframe").is_some_and(|v| !v.is_empty())
        || params.get("passed_domain").is_some_and(|v| !v.is_empty())
    {
        return Ok(pass("unsupported-filter"));
    }
    if let Some(type_of) = params.get("type_of") {
        if !type_of.is_empty() && type_of != "discover" {
            return Ok(pass("non-discover"));
        }
    }
    if let Some(mode) = params.get("mode") {
        if !mode.is_empty() && mode != "configured" {
            return Ok(pass("non-configured-mode"));
        }
    }

    let page: usize = params
        .get("page")
        .and_then(|v| v.parse::<usize>().ok())
        .unwrap_or(1)
        .max(1);
    let preferred_config_id: Option<i64> = params
        .get("item")
        .and_then(|v| v.parse::<i64>().ok())
        .filter(|&id| id > 0);

    // 3. Require signed-in viewer with verified HMAC edge identity cookie.
    let cookie_header = req
        .get_header_str(header::COOKIE)
        .unwrap_or("");
    if !cookie_header.contains("remember_user_token") {
        return Ok(pass("signed-out"));
    }
    let Some(edge_uid_cookie) = extract_cookie(cookie_header, USER_COOKIE_NAME) else {
        return Ok(pass_with_miss("no-edge-cookie", "edge-cookie"));
    };

    let secret_bytes = match load_edge_secret() {
        Some(s) => s,
        None => return Ok(pass("missing-secret")),
    };
    let now_sec = current_unix_secs();
    let Some(user_id) = verify_edge_user_token(edge_uid_cookie, &secret_bytes, now_sec) else {
        return Ok(pass_with_miss("invalid-edge-cookie", "edge-cookie"));
    };

    // 4. Open Fastly KV Store and resolve subforem from request host.
    let Some(kv) = KVStore::open(KV_STORE_NAME)? else {
        return Ok(pass("missing-kv-store"));
    };
    let request_host = resolve_request_host(req);
    let Some(host_map_raw) = kv_get_cached(&kv, "host_map", HOST_MAP_POP_TTL)? else {
        return Ok(pass("missing-host-map"));
    };
    let Ok(host_map) = parse_host_map_json(&host_map_raw) else {
        return Ok(pass("bad-host-map"));
    };
    let Some(&subforem_id) = host_map.get(&request_host) else {
        return Ok(pass("unknown-host"));
    };

    // 5. Load subforem scoring snapshot (POP-cached).
    let snap_key = format!("snapshot:{subforem_id}");
    let Some(snapshot_raw) = kv_get_cached(&kv, &snap_key, SNAPSHOT_POP_TTL)? else {
        return Ok(pass("missing-snapshot"));
    };
    let Ok(snapshot) = parse_subforem_snapshot_json(&snapshot_raw) else {
        return Ok(pass("bad-snapshot"));
    };
    if snapshot.feed_strategy != "configured" || snapshot.configs.is_empty() {
        return Ok(pass("strategy-not-configured"));
    }

    // 6. Load per-user feed profile (direct KV lookup; on miss, origin warms it).
    let user_key = format!("user:{user_id}");
    let Some(user_raw) = kv_get_direct(&kv, &user_key)? else {
        return Ok(pass_with_miss("missing-user-profile", "user-profile"));
    };
    let Ok(user_profile) = parse_user_profile_json(&user_raw) else {
        return Ok(pass_with_miss("bad-user-profile", "user-profile"));
    };

    // 7. Check sticky FeedConfig cookie on page 1.
    let (sticky_config_id, sticky_expires_at_sec) = if page == 1 && preferred_config_id.is_none() {
        extract_cookie(cookie_header, STICKY_CONFIG_COOKIE_NAME)
            .and_then(|tok| {
                verify_sticky_config_token(tok, user_id, subforem_id, &secret_bytes, now_sec)
            })
            .map(|(fc, exp)| (Some(fc), Some(exp)))
            .unwrap_or((None, None))
    } else {
        (None, None)
    };

    // 8. Optionally load quantized embeddings only if user has an interest vector AND any
    //    active config uses semantic similarity.
    let needs_embeddings = user_profile.interest_embedding.is_some()
        && snapshot
            .configs
            .iter()
            .any(|c| c.weights.semantic_similarity_weight > 0.0);
    let embedding_table = if needs_embeddings {
        let emb_key = format!("embeddings:{subforem_id}");
        kv_get_cached(&kv, &emb_key, EMBEDDINGS_POP_TTL)?
            .and_then(|raw| parse_embedding_table_json(&raw).ok())
    } else {
        None
    };

    // 9. Rank the feed entirely in memory via `forem_core::edge_feed`.
    let rng_seed = build_request_seed(now_sec, user_id, page, req.get_header_str("x-request-id"));
    let feed_req = EdgeFeedRequest {
        page,
        per_page: DEFAULT_PER_PAGE,
        preferred_config_id,
        sticky_config_id,
        sticky_expires_at_sec,
        now_sec,
        rng_seed,
        allow_sticky: page == 1 && preferred_config_id.is_none(),
    };

    let Some(result) = rank_custom_feed(&snapshot, &user_profile, embedding_table.as_ref(), &feed_req) else {
        return Ok(pass("ranking-failed"));
    };

    // 10. Load only the needed card shards (POP-cached) for the winning article IDs.
    let needed_shards: HashSet<usize> = result
        .selected_article_ids
        .iter()
        .map(|&id| snapshot.card_shard_for(id))
        .collect();

    let mut cards: HashMap<i64, String> = HashMap::with_capacity(result.selected_article_ids.len());
    for shard in needed_shards {
        let shard_key = format!("cards:{subforem_id}:{shard}");
        let Some(shard_raw) = kv_get_cached(&kv, &shard_key, CARD_SHARD_POP_TTL)? else {
            return Ok(pass("missing-card-shard"));
        };
        let Ok(mut shard_cards) = parse_card_shard_raw_json(&shard_raw) else {
            return Ok(pass("bad-card-shard"));
        };
        for &art_id in &result.selected_article_ids {
            if let Some(card_json) = shard_cards.remove(&art_id) {
                cards.insert(art_id, card_json);
            }
        }
    }

    // If any winning article is missing its card (e.g. mid-sync skew), fail open to origin.
    if result
        .selected_article_ids
        .iter()
        .any(|id| !cards.contains_key(id))
    {
        return Ok(pass("incomplete-cards"));
    }

    // 11. Splice per-request fields (`url`, `current_user_signed_in`, `feed_config`) into cards.
    let urls: HashMap<i64, &str> = snapshot
        .articles
        .iter()
        .map(|a| (a.id, a.url.as_str()))
        .collect();
    let body = assemble_feed_response_json(
        &result.selected_article_ids,
        &cards,
        &urls,
        result.selected_config_id,
        true,
    );

    let mut resp = Response::from_status(StatusCode::OK)
        .with_header(header::CONTENT_TYPE, "application/json; charset=utf-8")
        .with_header(header::CACHE_CONTROL, "private, no-store")
        .with_header("X-Forem-Edge-Feed", "hit")
        .with_body(body);

    // 12. Emit sticky cookie & `X-Feed-Visit-Token` when a sticky config is active on page 1.
    if result.sticky_assigned && !result.selected_article_ids.is_empty() {
        if let Some(exp_sec) = result.sticky_expires_at_sec {
            let visit_token = sign_edge_visit_token(
                user_id,
                subforem_id,
                result.selected_config_id,
                exp_sec,
                &request_host,
                &secret_bytes,
            );
            resp.set_header("X-Feed-Visit-Token", visit_token);

            // Set/refresh signed sticky cookie only when newly assigned.
            if sticky_config_id != Some(result.selected_config_id) {
                let max_age = (exp_sec - now_sec).max(0);
                let sticky_cookie = sign_sticky_config_token(
                    user_id,
                    subforem_id,
                    result.selected_config_id,
                    exp_sec,
                    &secret_bytes,
                );
                resp.append_header(
                    header::SET_COOKIE,
                    format!(
                        "{STICKY_CONFIG_COOKIE_NAME}={sticky_cookie}; Path=/; Max-Age={max_age}; HttpOnly; Secure; SameSite=Lax"
                    ),
                );
            }
        }
    }

    Ok(EdgeOutcome::Served(resp))
}

fn load_edge_secret() -> Option<Vec<u8>> {
    let store = SecretStore::open(SECRET_STORE_NAME).ok()?;
    let secret = store.get(SECRET_KEY_NAME)?;
    let bytes = secret.plaintext().to_vec();
    if bytes.is_empty() {
        None
    } else {
        Some(bytes)
    }
}

fn kv_get_direct(kv: &KVStore, key: &str) -> Result<Option<String>, Error> {
    match kv.lookup(key)? {
        Some(mut body) => Ok(Some(body.into_string())),
        None => Ok(None),
    }
}

fn kv_get_cached(kv: &KVStore, key: &str, ttl: Duration) -> Result<Option<String>, Error> {
    let cache_key = format!("edge_feed_kv:{key}");
    if let Some(body) = pop_cache::get(cache_key.as_str())? {
        return Ok(Some(body.into_string()));
    }
    match kv_get_direct(kv, key)? {
        Some(val) => {
            let _ = pop_cache::set(cache_key.as_str(), val.as_bytes(), ttl);
            Ok(Some(val))
        }
        None => Ok(None),
    }
}

fn resolve_request_host(req: &Request) -> String {
    let raw = req
        .get_header_str("x-req-host")
        .or_else(|| req.get_header_str("x-forem-original-host"))
        .or_else(|| req.get_header_str(header::HOST))
        .unwrap_or("");
    raw.split(':').next().unwrap_or("").to_ascii_lowercase()
}

fn extract_cookie<'a>(cookie_header: &'a str, name: &str) -> Option<&'a str> {
    for part in cookie_header.split(';') {
        let trimmed = part.trim();
        if let Some((k, v)) = trimmed.split_once('=') {
            if k.trim() == name {
                let val = v.trim();
                if !val.is_empty() {
                    return Some(val);
                }
            }
        }
    }
    None
}

fn parse_query_params(query: &str) -> HashMap<String, String> {
    let mut map = HashMap::new();
    for pair in query.split('&') {
        if pair.is_empty() {
            continue;
        }
        let (k, v) = pair.split_once('=').unwrap_or((pair, ""));
        map.insert(k.to_string(), v.to_string());
    }
    map
}

fn current_unix_secs() -> i64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs() as i64)
        .unwrap_or(0)
}

fn build_request_seed(now_sec: i64, user_id: i64, page: usize, req_id: Option<&str>) -> u64 {
    let mut h: u64 = 0xCBF2_9CE4_8422_2325;
    for byte in now_sec
        .to_le_bytes()
        .into_iter()
        .chain(user_id.to_le_bytes())
        .chain((page as u64).to_le_bytes())
        .chain(req_id.unwrap_or("").bytes())
    {
        h ^= byte as u64;
        h = h.wrapping_mul(0x0000_0100_0000_01B3);
    }
    h
}
