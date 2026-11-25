//! Pure-Rust in-memory custom `FeedConfig` feed engine for Fastly Edge Compute.
//!
//! This module mirrors Forem's Rails `Articles::Feeds::Custom` + `FeedConfig#score_sql` +
//! `FeedConfig.select_for_feed` + `Feeds::StickyConfig` + `Stories::FeedsController` JSON
//! assembly pipeline entirely in memory with **zero** external crate or database dependencies.
//!
//! Because `forem_core` compiles cleanly to both native targets and `wasm32-wasip1`, the exact
//! same ranking, shuffling, diversity interleaving, HMAC token verification, and JSON card
//! splicing logic can be:
//! 1. Unit-tested natively via `cargo test -p forem_core`.
//! 2. Deployed directly to Fastly Compute (`edge/fastly_feed_compute`) reading mirrored
//!    snapshots, sharded story cards, quantized embeddings, and per-user profiles from
//!    Fastly KV Store.

use std::collections::{HashMap, HashSet};
use std::fmt::Write as _;

use crate::feed::{
    calculate_dynamic_shuffle_count, weighted_shuffle_indices, xorshift64_star_unit_floats,
    AiPreference, FeedScoreWeights, ParsedTimestamp,
};
use crate::json::write_json_string;
use crate::metal::hmac_sha256;

/// `Article.type_of` enum values matching `app/models/article.rb`.
pub const ARTICLE_TYPE_FULL_POST: i32 = 0;
pub const ARTICLE_TYPE_STATUS: i32 = 1;

/// `AiDisclosable::LEVELS` enum values matching `app/models/concerns/ai_disclosable.rb`.
pub const AI_DISCLOSURE_NOT_DISCLOSED: i32 = 0;
pub const AI_DISCLOSURE_NO_AI: i32 = 1;
pub const AI_DISCLOSURE_SOME_AI: i32 = 3;
pub const AI_DISCLOSURE_FULLY_AUTONOMOUS: i32 = 5;

/// `FeedConfig` selection constants matching `app/models/feed_config.rb`.
pub const LOW_IMPRESSION_COUNT: i64 = 25;
pub const TOP_POOL_LIMIT: usize = 15;
pub const DEFAULT_SEMANTIC_CANDIDATE_LIMIT: usize = 200;
pub const MIN_SEMANTIC_CANDIDATE_LIMIT: usize = 100;
pub const MAX_SEMANTIC_CANDIDATE_LIMIT: usize = 1000;
pub const DEFAULT_FEED_LOOKBACK_DAYS: i64 = 10;
pub const MIN_FEED_LOOKBACK_HOURS: i64 = 1;

/// Token prefixes shared between Ruby (`EdgeFeed::TokenSigner`) and Fastly Compute.
pub const EDGE_USER_TOKEN_PREFIX: &str = "eu1";
pub const EDGE_STICKY_CONFIG_TOKEN_PREFIX: &str = "ec1";
pub const EDGE_VISIT_TOKEN_PREFIX: &str = "ev1";

/// Targeting buckets matching `FeedConfig::TARGETING_BUCKETS`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum TargetingBucket {
    All,
    FeedNewUser,
    FeedCasualUser,
    FeedActiveUser,
    FeedPowerUser,
    Digest,
}

impl TargetingBucket {
    pub fn parse(s: &str) -> Self {
        match s {
            "feed_new_user" => Self::FeedNewUser,
            "feed_casual_user" => Self::FeedCasualUser,
            "feed_active_user" => Self::FeedActiveUser,
            "feed_power_user" => Self::FeedPowerUser,
            "digest" => Self::Digest,
            _ => Self::All,
        }
    }

    pub const fn as_str(self) -> &'static str {
        match self {
            Self::All => "all",
            Self::FeedNewUser => "feed_new_user",
            Self::FeedCasualUser => "feed_casual_user",
            Self::FeedActiveUser => "feed_active_user",
            Self::FeedPowerUser => "feed_power_user",
            Self::Digest => "digest",
        }
    }
}

/// Compact scoring representation of one qualified article in the mirrored subforem snapshot.
#[derive(Debug, Clone, PartialEq)]
pub struct EdgeArticleEntry {
    pub id: i64,
    pub user_id: i64,
    pub organization_id: Option<i64>,
    pub subforem_id: Option<i64>,
    pub published_at_sec: i64,
    pub last_comment_at_sec: Option<i64>,
    pub score: f64,
    pub comment_score: f64,
    pub feed_success_score: f64,
    pub clickbait_score: f64,
    pub compellingness_score: f64,
    pub featured: bool,
    pub favorited: bool,
    pub type_of: i32,
    pub ai_disclosure_level: i32,
    pub language: Option<String>,
    pub tags: Vec<String>,
    pub labels: Vec<String>,
    pub url: String,
}

/// Compact representation of an active `FeedConfig` mirrored to Fastly KV.
#[derive(Debug, Clone, PartialEq)]
pub struct EdgeFeedConfig {
    pub id: i64,
    pub targeting_bucket: TargetingBucket,
    pub created_at_sec: i64,
    pub feed_impressions_count: i64,
    pub feed_success_score: f64,
    pub shuffle_weight: f64,
    pub recent_page_views_shuffle_weight: f64,
    pub semantic_candidate_limit: usize,
    pub feed_lookback_hours: i64,
    pub recent_tag_count_min: usize,
    pub recent_tag_count_max: usize,
    pub all_time_tag_count_min: usize,
    pub all_time_tag_count_max: usize,
    pub weights: FeedScoreWeights,
}

impl EdgeFeedConfig {
    /// Effective semantic candidate window size clamped to `[100, 1000]`.
    pub fn effective_semantic_candidate_limit(&self) -> usize {
        let raw = if self.semantic_candidate_limit == 0 {
            DEFAULT_SEMANTIC_CANDIDATE_LIMIT
        } else {
            self.semantic_candidate_limit
        };
        raw.clamp(MIN_SEMANTIC_CANDIDATE_LIMIT, MAX_SEMANTIC_CANDIDATE_LIMIT)
    }

    /// Effective lookback hours matching `FeedConfig#effective_feed_lookback_hours`.
    pub fn effective_feed_lookback_hours(&self, max_hours: i64) -> i64 {
        let clamped_max = max_hours.max(MIN_FEED_LOOKBACK_HOURS);
        if self.feed_lookback_hours <= 0 {
            clamped_max
        } else {
            self.feed_lookback_hours
                .clamp(MIN_FEED_LOOKBACK_HOURS, clamped_max)
        }
    }

    /// Midpoint (hours) of the effective lookback window.
    pub fn published_at_diversity_half_lookback_hours(&self, max_hours: i64) -> f64 {
        (self.effective_feed_lookback_hours(max_hours) as f64) / 2.0
    }
}

/// Subforem-level mirrored snapshot stored under `snapshot:<subforem_id>` in Fastly KV.
#[derive(Debug, Clone, PartialEq)]
pub struct EdgeSubforemSnapshot {
    pub version: u32,
    pub generated_at_sec: i64,
    pub subforem_id: i64,
    pub is_root_subforem: bool,
    pub feed_lookback_days: i64,
    pub feed_strategy: String,
    pub sticky_hours: i64,
    pub sticky_percentage: i64,
    pub pinned_article_id: Option<i64>,
    pub card_shard_count: usize,
    pub configs: Vec<EdgeFeedConfig>,
    pub articles: Vec<EdgeArticleEntry>,
}

impl EdgeSubforemSnapshot {
    pub fn max_feed_lookback_hours(&self) -> i64 {
        let days = if self.feed_lookback_days > 0 {
            self.feed_lookback_days
        } else {
            DEFAULT_FEED_LOOKBACK_DAYS
        };
        days * 24
    }

    pub fn card_shard_for(&self, article_id: i64) -> usize {
        let count = self.card_shard_count.max(1) as i64;
        article_id.rem_euclid(count) as usize
    }
}

/// Symmetric int8-quantized vector for compact embedding mirroring (`embeddings:<subforem_id>`).
#[derive(Debug, Clone, PartialEq)]
pub struct EdgeQuantizedEmbedding {
    pub article_id: i64,
    pub scale: f32,
    pub values: Vec<i8>,
}

/// Collection of quantized article embeddings indexed by `article_id`.
#[derive(Debug, Clone, Default, PartialEq)]
pub struct EdgeEmbeddingTable {
    pub embeddings: HashMap<i64, EdgeQuantizedEmbedding>,
}

impl EdgeEmbeddingTable {
    /// Computes cosine similarity `1 - cosine_distance` against a float query vector.
    ///
    /// Matches pgvector's `1 - (articles.semantic_embedding <=> user_embedding)` up to int8
    /// quantization error (~1e-3).
    pub fn cosine_similarity(&self, article_id: i64, query: &[f32]) -> Option<f64> {
        let entry = self.embeddings.get(&article_id)?;
        if entry.values.len() != query.len() || query.is_empty() || entry.scale <= 0.0 {
            return None;
        }
        Some(cosine_similarity_f32_i8(query, &entry.values, entry.scale))
    }
}

/// Quantizes a float vector to symmetric int8 (`[-127, 127]`) with a per-vector `scale`.
pub fn quantize_embedding_i8(values: &[f32]) -> (f32, Vec<i8>) {
    let max_abs = values.iter().copied().map(f32::abs).fold(0.0_f32, f32::max);
    if max_abs <= f32::EPSILON {
        return (0.0, vec![0i8; values.len()]);
    }
    let scale = max_abs / 127.0;
    let inv_scale = 127.0 / max_abs;
    let q = values
        .iter()
        .map(|&v| (v * inv_scale).round().clamp(-127.0, 127.0) as i8)
        .collect();
    (scale, q)
}

/// Computes cosine similarity between a `f32` query vector and a symmetric-quantized `i8` vector.
///
/// Note that the positive scalar `scale` cancels out in the cosine ratio, so we only check
/// `scale > 0.0` and avoid multiplying every component by `scale` in the inner loop.
pub fn cosine_similarity_f32_i8(query: &[f32], quantized: &[i8], scale: f32) -> f64 {
    if scale <= 0.0 || query.len() != quantized.len() || query.is_empty() {
        return 0.0;
    }
    let mut dot = 0.0_f64;
    let mut norm_q = 0.0_f64;
    let mut norm_a = 0.0_f64;
    for (&q, &a_i8) in query.iter().zip(quantized.iter()) {
        let qf = q as f64;
        let af = a_i8 as f64;
        dot += qf * af;
        norm_q += qf * qf;
        norm_a += af * af;
    }
    let denom = norm_q.sqrt() * norm_a.sqrt();
    if denom <= f64::EPSILON {
        0.0
    } else {
        (dot / denom).clamp(-1.0, 1.0)
    }
}

/// Per-user mirrored feed profile stored under `user:<user_id>` in Fastly KV.
#[derive(Debug, Clone, PartialEq)]
pub struct EdgeUserProfile {
    pub user_id: i64,
    pub targeting_bucket: TargetingBucket,
    pub has_activity_store: bool,
    pub blocked_user_ids: Vec<i64>,
    pub hidden_tags: Vec<String>,
    pub hide_fully_autonomous: bool,
    pub ai_preference: AiPreference,
    pub languages: Vec<String>,
    pub alltime_users: Vec<i64>,
    pub alltime_users_from_activity: bool,
    pub recent_users: Vec<i64>,
    pub alltime_organizations: Vec<i64>,
    pub alltime_organizations_from_activity: bool,
    pub recent_organizations: Vec<i64>,
    pub alltime_subforems: Vec<i64>,
    pub recent_subforems: Vec<i64>,
    pub recent_tags: Vec<String>,
    pub alltime_tags: Vec<String>,
    pub recent_labels: Vec<String>,
    /// `(article_id, viewed_at_utc_sec)` sorted most-recent first (up to 100 entries).
    pub recently_viewed_articles: Vec<(i64, i64)>,
    pub precomputed_selections: Vec<i64>,
    pub interest_embedding: Option<Vec<f32>>,
}

/// Request parameters for executing an edge custom feed request.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct EdgeFeedRequest {
    pub page: usize,
    pub per_page: usize,
    pub preferred_config_id: Option<i64>,
    pub sticky_config_id: Option<i64>,
    pub sticky_expires_at_sec: Option<i64>,
    pub now_sec: i64,
    pub rng_seed: u64,
    /// Mirrors `Articles::Feeds::Custom`: whether to allow sticky config assignment on page 1.
    pub allow_sticky: bool,
}

impl Default for EdgeFeedRequest {
    fn default() -> Self {
        Self {
            page: 1,
            per_page: 35,
            preferred_config_id: None,
            sticky_config_id: None,
            sticky_expires_at_sec: None,
            now_sec: 0,
            rng_seed: 1,
            allow_sticky: true,
        }
    }
}

/// Output of `rank_custom_feed`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct EdgeFeedResult {
    pub selected_config_id: i64,
    pub selected_article_ids: Vec<i64>,
    pub sticky_assigned: bool,
    pub sticky_expires_at_sec: Option<i64>,
}

/// Deterministic xorshift64* PRNG for repeatable, Wasm-safe randomness with no OS entropy calls
/// required inside pure core functions.
#[derive(Debug, Clone)]
struct SimpleRng {
    state: u64,
}

impl SimpleRng {
    fn new(seed: u64) -> Self {
        Self {
            state: if seed == 0 {
                0x9E37_79B9_7F4A_7C15
            } else {
                seed
            },
        }
    }

    fn next_u64(&mut self) -> u64 {
        let mut x = self.state;
        x ^= x >> 12;
        x ^= x << 25;
        x ^= x >> 27;
        self.state = x;
        x.wrapping_mul(0x2545_F491_4F6C_DD1D)
    }

    fn gen_range_usize(&mut self, min_inclusive: usize, max_inclusive: usize) -> usize {
        if min_inclusive >= max_inclusive {
            return min_inclusive;
        }
        let span = (max_inclusive - min_inclusive) + 1;
        min_inclusive + ((self.next_u64() as usize) % span)
    }

    fn shuffle<T>(&mut self, slice: &mut [T]) {
        if slice.len() <= 1 {
            return;
        }
        for i in (1..slice.len()).rev() {
            let j = (self.next_u64() as usize) % (i + 1);
            slice.swap(i, j);
        }
    }
}

/// Selects a `FeedConfig` from the snapshot following the exact exploration/exploitation policy
/// in `FeedConfig.select_for_feed` / `FeedConfig.select_for_targeted_bucket` and
/// `Feeds::StickyConfig#select`.
///
/// Returns `(config_index, sticky_assigned, sticky_expires_at_sec)`.
pub fn select_feed_config(
    snapshot: &EdgeSubforemSnapshot,
    user: &EdgeUserProfile,
    req: &EdgeFeedRequest,
) -> Option<(usize, bool, Option<i64>)> {
    if snapshot.configs.is_empty() {
        return None;
    }

    let mut rng = SimpleRng::new(req.rng_seed ^ 0x517C_C1B7_2722_0A95);

    // 1. Explicit preferred_id overrides everything (e.g. `?item=<id>`).
    if let Some(pref_id) = req.preferred_config_id {
        if let Some(idx) = snapshot.configs.iter().position(|c| c.id == pref_id) {
            return Some((idx, false, None));
        }
    }

    // 2. Sticky config assignment on page 1 (mirrors `Feeds::StickyConfig#select`).
    if req.allow_sticky && req.page <= 1 && snapshot.sticky_hours > 0 {
        let sticky_roll = rng.gen_range_usize(0, 99) as i64;
        if let (Some(sticky_id), Some(exp)) = (req.sticky_config_id, req.sticky_expires_at_sec) {
            if exp > req.now_sec {
                if let Some(idx) = snapshot.configs.iter().position(|c| c.id == sticky_id) {
                    return Some((idx, true, Some(exp)));
                }
            }
        }
        if sticky_roll < snapshot.sticky_percentage {
            let idx =
                select_bucket_config_index(&snapshot.configs, user.targeting_bucket, &mut rng)?;
            let expires_at = req.now_sec + (snapshot.sticky_hours * 3600);
            return Some((idx, true, Some(expires_at)));
        }
    }

    let idx = select_bucket_config_index(&snapshot.configs, user.targeting_bucket, &mut rng)?;
    Some((idx, false, None))
}

fn select_bucket_config_index(
    configs: &[EdgeFeedConfig],
    bucket: TargetingBucket,
    rng: &mut SimpleRng,
) -> Option<usize> {
    // Eligible configs: exact bucket OR `all`, ordering exact bucket ahead of `all`.
    let eligible: Vec<usize> = if bucket == TargetingBucket::All {
        (0..configs.len()).collect()
    } else {
        let mut indices: Vec<usize> = configs
            .iter()
            .enumerate()
            .filter_map(|(i, c)| {
                if c.targeting_bucket == bucket || c.targeting_bucket == TargetingBucket::All {
                    Some(i)
                } else {
                    None
                }
            })
            .collect();
        if indices.is_empty() {
            indices = (0..configs.len()).collect();
        }
        indices
    };

    if eligible.is_empty() {
        return None;
    }

    let bucket_priority = |idx: usize| -> u8 {
        if bucket != TargetingBucket::All && configs[idx].targeting_bucket == bucket {
            1
        } else {
            0
        }
    };

    let roll = rng.gen_range_usize(0, 99);

    // 20%: prioritize newest low-impression configs (bucket-specific preferred over `all`).
    if roll < 20 {
        let mut low_imp: Vec<usize> = eligible
            .iter()
            .copied()
            .filter(|&i| configs[i].feed_impressions_count < LOW_IMPRESSION_COUNT)
            .collect();
        low_imp.sort_by(|&a, &b| {
            bucket_priority(b)
                .cmp(&bucket_priority(a))
                .then_with(|| configs[b].created_at_sec.cmp(&configs[a].created_at_sec))
                .then_with(|| configs[b].id.cmp(&configs[a].id))
        });
        low_imp.truncate(TOP_POOL_LIMIT);

        if !low_imp.is_empty() {
            let bucket_only: Vec<usize> = if bucket != TargetingBucket::All {
                low_imp
                    .iter()
                    .copied()
                    .filter(|&i| configs[i].targeting_bucket == bucket)
                    .collect()
            } else {
                Vec::new()
            };
            let pool = if !bucket_only.is_empty() {
                &bucket_only
            } else {
                &low_imp
            };
            let pick = rng.gen_range_usize(0, pool.len() - 1);
            return Some(pool[pick]);
        }
    } else if roll < 25 {
        // 5%: random config from highest-priority available bucket so none are starved.
        let top_prio = eligible
            .iter()
            .copied()
            .map(bucket_priority)
            .max()
            .unwrap_or(0);
        let pool: Vec<usize> = eligible
            .iter()
            .copied()
            .filter(|&i| bucket_priority(i) == top_prio)
            .collect();
        if !pool.is_empty() {
            let pick = rng.gen_range_usize(0, pool.len() - 1);
            return Some(pool[pick]);
        }
    }

    // Exploitation fallback chain: proven (>= 25 impressions) -> tested (> 0) -> all eligible.
    for min_imp in [LOW_IMPRESSION_COUNT, 1, 0] {
        let mut pool: Vec<usize> = eligible
            .iter()
            .copied()
            .filter(|&i| configs[i].feed_impressions_count >= min_imp)
            .collect();
        if pool.is_empty() {
            continue;
        }
        pool.sort_by(|&a, &b| {
            bucket_priority(b)
                .cmp(&bucket_priority(a))
                .then_with(|| {
                    configs[b]
                        .feed_success_score
                        .total_cmp(&configs[a].feed_success_score)
                })
                .then_with(|| configs[b].id.cmp(&configs[a].id))
        });
        let limit = rng.gen_range_usize(1, TOP_POOL_LIMIT).min(pool.len());
        let pick = rng.gen_range_usize(0, limit - 1);
        return Some(pool[pick]);
    }

    eligible.first().copied()
}

/// Pre-indexed per-request user context so scoring thousands of articles is O(1) per lookup.
struct PreparedScoreContext<'a> {
    user_follow_ids: HashSet<i64>,
    org_follow_ids: HashSet<i64>,
    subforem_follow_ids: HashSet<i64>,
    recent_subforem_counts: HashMap<i64, usize>,
    relevant_tags: HashSet<&'a str>,
    recent_labels: HashSet<&'a str>,
    precomputed_selections: HashSet<i64>,
    recent_article_ids: HashSet<i64>,
    languages: HashSet<&'a str>,
    recent_pageviews_count: usize,
    lookback_window_start_sec: i64,
    lookback_window_end_sec: i64,
    published_since_24h_sec: i64,
    published_since_30d_sec: i64,
    half_lookback_hours: f64,
    random_seed: i64,
    is_root_subforem: bool,
    has_activity_store: bool,
    ai_preference: AiPreference,
}

impl<'a> PreparedScoreContext<'a> {
    fn build(
        snapshot: &EdgeSubforemSnapshot,
        config: &EdgeFeedConfig,
        user: &'a EdgeUserProfile,
        now_sec: i64,
        rng: &mut SimpleRng,
    ) -> Self {
        let mut user_follow_ids = HashSet::new();
        let user_cap = if user.alltime_users_from_activity {
            200
        } else {
            user.alltime_users.len()
        };
        for &id in user.alltime_users.iter().take(user_cap) {
            user_follow_ids.insert(id);
        }
        for &id in &user.recent_users {
            user_follow_ids.insert(id);
        }

        let mut org_follow_ids = HashSet::new();
        let org_cap = if user.alltime_organizations_from_activity {
            200
        } else {
            user.alltime_organizations.len()
        };
        for &id in user.alltime_organizations.iter().take(org_cap) {
            org_follow_ids.insert(id);
        }
        for &id in &user.recent_organizations {
            org_follow_ids.insert(id);
        }

        let subforem_follow_ids: HashSet<i64> = user.alltime_subforems.iter().copied().collect();

        let mut recent_subforem_counts: HashMap<i64, usize> = HashMap::new();
        for &id in &user.recent_subforems {
            *recent_subforem_counts.entry(id).or_insert(0) += 1;
        }

        // Mirrors `FeedConfig#resolve_relevant_tag_names` + `OPTIMIZED_FEED_TAGS_QUERY` cap.
        let recent_tag_count = if config.recent_tag_count_min > 0 && config.recent_tag_count_max > 0
        {
            rng.gen_range_usize(config.recent_tag_count_min, config.recent_tag_count_max)
        } else {
            5
        };
        let all_time_tag_count =
            if config.all_time_tag_count_min > 0 && config.all_time_tag_count_max > 0 {
                rng.gen_range_usize(config.all_time_tag_count_min, config.all_time_tag_count_max)
            } else {
                5
            };
        let tag_limit = if config.weights.tag_follow_weight > 0.0 {
            rng.gen_range_usize(20, 40)
        } else {
            24
        };
        let mut relevant_tags: HashSet<&'a str> = HashSet::new();
        if user.has_activity_store {
            for tag in user
                .recent_tags
                .iter()
                .take(recent_tag_count)
                .chain(user.alltime_tags.iter().take(all_time_tag_count))
                .take(tag_limit)
            {
                relevant_tags.insert(tag.as_str());
            }
        } else {
            for tag in user.alltime_tags.iter().take(tag_limit) {
                relevant_tags.insert(tag.as_str());
            }
        }

        let recent_labels: HashSet<&'a str> =
            user.recent_labels.iter().map(String::as_str).collect();
        let precomputed_selections: HashSet<i64> =
            user.precomputed_selections.iter().copied().collect();
        let recent_article_ids: HashSet<i64> = user
            .recently_viewed_articles
            .iter()
            .map(|&(id, _)| id)
            .collect();
        let languages: HashSet<&'a str> = user.languages.iter().map(String::as_str).collect();

        let published_since_24h_sec = now_sec - 86_400;
        let published_since_30d_sec = now_sec - (30 * 86_400);

        let recent_pageviews_count = user
            .recently_viewed_articles
            .iter()
            .filter(|&&(_, ts)| ts > published_since_24h_sec)
            .count();

        let lookback_window_end_sec = user
            .recently_viewed_articles
            .get(1)
            .map(|&(_, ts)| ts)
            .unwrap_or(now_sec - (4 * 86_400));
        let lookback_window_start_sec = lookback_window_end_sec - (18 * 3600);

        let max_hours = snapshot.max_feed_lookback_hours();
        let half_lookback_hours = config.published_at_diversity_half_lookback_hours(max_hours);

        let random_seed = if config.weights.randomness_weight > 0.0 {
            rng.gen_range_usize(0, 9_999) as i64
        } else {
            0
        };

        Self {
            user_follow_ids,
            org_follow_ids,
            subforem_follow_ids,
            recent_subforem_counts,
            relevant_tags,
            recent_labels,
            precomputed_selections,
            recent_article_ids,
            languages,
            recent_pageviews_count,
            lookback_window_start_sec,
            lookback_window_end_sec,
            published_since_24h_sec,
            published_since_30d_sec,
            half_lookback_hours,
            random_seed,
            is_root_subforem: snapshot.is_root_subforem,
            has_activity_store: user.has_activity_store,
            ai_preference: user.ai_preference,
        }
    }
}

/// Evaluates all non-semantic terms of `FeedConfig#score_sql` for one article in memory.
///
/// Every term matches `FeedConfig#legacy_score_sql` and `feed::build_feed_config_score_sql`.
fn score_article_base(
    article: &EdgeArticleEntry,
    w: &FeedScoreWeights,
    ctx: &PreparedScoreContext<'_>,
    now_sec: i64,
) -> f64 {
    let mut total = 0.0_f64;

    if w.feed_success_weight > 0.0 {
        total += article.feed_success_score * w.feed_success_weight;
    }
    if w.comment_score_weight > 0.0 {
        total += article.comment_score * w.comment_score_weight;
    }
    if w.score_weight > 0.0 {
        total += article.score * w.score_weight;
    }
    if w.organization_follow_weight > 0.0 {
        if let Some(org_id) = article.organization_id {
            if ctx.org_follow_ids.contains(&org_id) {
                total += w.organization_follow_weight;
            }
        }
    }
    if w.user_follow_weight > 0.0 && ctx.user_follow_ids.contains(&article.user_id) {
        total += w.user_follow_weight;
    }
    if w.follow_status_weight > 0.0
        && article.type_of == ARTICLE_TYPE_STATUS
        && ctx.user_follow_ids.contains(&article.user_id)
    {
        total += w.follow_status_weight;
    }
    if w.tag_follow_weight > 0.0
        && !ctx.relevant_tags.is_empty()
        && article
            .tags
            .iter()
            .any(|t| ctx.relevant_tags.contains(t.as_str()))
    {
        total += w.tag_follow_weight;
    }
    if w.subforem_follow_weight > 0.0 && ctx.is_root_subforem {
        if let Some(sf_id) = article.subforem_id {
            if ctx.subforem_follow_ids.contains(&sf_id) {
                total += w.subforem_follow_weight;
            }
        }
    }
    if w.label_match_weight > 0.0
        && !ctx.recent_labels.is_empty()
        && article
            .labels
            .iter()
            .any(|l| ctx.recent_labels.contains(l.as_str()))
    {
        total += w.label_match_weight;
    }
    if w.recency_weight > 0.0 {
        let age_hours = ((now_sec - article.published_at_sec) as f64) / 3600.0;
        let denom = 1.0 + age_hours;
        if denom > f64::EPSILON {
            total += (1.0 / denom) * w.recency_weight;
        }
    }
    if w.comment_recency_weight > 0.0 {
        if let Some(last_comment_sec) = article.last_comment_at_sec {
            let age_hours = ((now_sec - last_comment_sec) as f64) / 3600.0;
            let denom = 1.0 + age_hours;
            if denom > f64::EPSILON {
                total += (1.0 / denom) * w.comment_recency_weight;
            }
        }
    }
    if w.published_at_diversity_weight > 0.0 && ctx.half_lookback_hours > 0.0 {
        let age_hours = ((now_sec - article.published_at_sec) as f64) / 3600.0;
        let dist = ((age_hours - ctx.half_lookback_hours).abs() / ctx.half_lookback_hours).min(1.0);
        total += dist * dist * w.published_at_diversity_weight;
    }
    if w.lookback_window_weight > 0.0
        && article.published_at_sec >= ctx.lookback_window_start_sec
        && article.published_at_sec <= ctx.lookback_window_end_sec
    {
        total += w.lookback_window_weight;
    }
    if w.precomputed_selections_weight > 0.0 && ctx.precomputed_selections.contains(&article.id) {
        total += w.precomputed_selections_weight;
    }
    if w.recent_article_suppression_rate > 0.0
        && ctx.has_activity_store
        && ctx.recent_article_ids.contains(&article.id)
    {
        total -= w.recent_article_suppression_rate;
    }
    if w.published_today_weight > 0.0 && article.published_at_sec >= ctx.published_since_24h_sec {
        total += w.published_today_weight;
    }
    if w.general_past_day_bonus_weight > 0.0
        && article.published_at_sec >= ctx.published_since_24h_sec
    {
        total += w.general_past_day_bonus_weight;
    }
    if w.recently_active_past_day_bonus_weight > 0.0
        && ctx.recent_pageviews_count > 0
        && article.published_at_sec >= ctx.published_since_24h_sec
    {
        total += w.recently_active_past_day_bonus_weight * (ctx.recent_pageviews_count as f64);
    }
    if w.recent_subforem_weight > 0.0 && ctx.is_root_subforem {
        if let Some(sf_id) = article.subforem_id {
            if let Some(&count) = ctx.recent_subforem_counts.get(&sf_id) {
                total += w.recent_subforem_weight * (count as f64);
            }
        }
    }
    if w.ai_disclosure_matching_weight > 0.0 {
        match ctx.ai_preference {
            AiPreference::MinimizeAi => {
                if article.ai_disclosure_level == AI_DISCLOSURE_SOME_AI {
                    total -= w.ai_disclosure_matching_weight;
                } else if article.ai_disclosure_level == AI_DISCLOSURE_FULLY_AUTONOMOUS {
                    total -= w.ai_disclosure_matching_weight * 2.0;
                }
            }
            AiPreference::HideFullyAutonomous => {
                if article.ai_disclosure_level == AI_DISCLOSURE_SOME_AI {
                    total -= w.ai_disclosure_matching_weight;
                }
            }
            AiPreference::ShowAll => {}
        }
    }
    if w.autonomous_ai_penalty_weight > 0.0
        && article.ai_disclosure_level == AI_DISCLOSURE_FULLY_AUTONOMOUS
    {
        total -= w.autonomous_ai_penalty_weight;
    }
    if w.featured_weight > 0.0 && article.featured {
        total += w.featured_weight;
    }
    if w.favorited_weight > 0.0 && article.favorited {
        total += w.favorited_weight;
    }
    if w.status_weight > 0.0 && article.type_of == ARTICLE_TYPE_STATUS {
        total += w.status_weight;
    }
    if w.clickbait_score_weight > 0.0 {
        total -= article.clickbait_score * w.clickbait_score_weight;
    }
    if w.compellingness_score_weight > 0.0 {
        total += article.compellingness_score * w.compellingness_score_weight;
    }
    if w.language_match_weight > 0.0 && w.score_weight > 0.0 {
        if let Some(ref lang) = article.language {
            if ctx.languages.contains(lang.as_str()) {
                total += w.language_match_weight;
            }
        }
    }
    if w.randomness_weight > 0.0 {
        let mod_val = (article.id.wrapping_mul(137).wrapping_add(ctx.random_seed)).rem_euclid(1000);
        total += ((mod_val as f64) / 1000.0) * w.randomness_weight;
    }

    total
}

/// Evaluates whether any non-semantic scoring term can be non-zero for `config`.
fn has_non_zero_base_weights(w: &FeedScoreWeights) -> bool {
    w.feed_success_weight > 0.0
        || w.comment_score_weight > 0.0
        || w.score_weight > 0.0
        || w.organization_follow_weight > 0.0
        || w.user_follow_weight > 0.0
        || w.follow_status_weight > 0.0
        || w.tag_follow_weight > 0.0
        || w.subforem_follow_weight > 0.0
        || w.label_match_weight > 0.0
        || w.recency_weight > 0.0
        || w.comment_recency_weight > 0.0
        || w.published_at_diversity_weight > 0.0
        || w.lookback_window_weight > 0.0
        || w.precomputed_selections_weight > 0.0
        || w.recent_article_suppression_rate > 0.0
        || w.published_today_weight > 0.0
        || w.general_past_day_bonus_weight > 0.0
        || w.recently_active_past_day_bonus_weight > 0.0
        || w.recent_subforem_weight > 0.0
        || w.ai_disclosure_matching_weight > 0.0
        || w.autonomous_ai_penalty_weight > 0.0
        || w.featured_weight > 0.0
        || w.favorited_weight > 0.0
        || w.status_weight > 0.0
        || w.clickbait_score_weight > 0.0
        || w.compellingness_score_weight > 0.0
        || w.language_match_weight > 0.0
        || w.randomness_weight > 0.0
}

/// Runs the complete custom `FeedConfig` home-feed ranking pipeline in memory.
///
/// Mirrors `Articles::Feeds::Custom#execute_feed_query` + `Stories::FeedsController#add_pinned_article`.
pub fn rank_custom_feed(
    snapshot: &EdgeSubforemSnapshot,
    user: &EdgeUserProfile,
    embeddings: Option<&EdgeEmbeddingTable>,
    req: &EdgeFeedRequest,
) -> Option<EdgeFeedResult> {
    let (config_idx, sticky_assigned, sticky_expires_at_sec) =
        select_feed_config(snapshot, user, req)?;
    let config = &snapshot.configs[config_idx];

    let mut rng = SimpleRng::new(req.rng_seed ^ (config.id as u64).wrapping_mul(0x9E37_79B9));

    // 1. Resolve lookback cutoff (`max(config_hours.ago, hard_lookback)`).
    let hard_lookback_hours = snapshot.max_feed_lookback_hours();
    let effective_lookback_hours = config.effective_feed_lookback_hours(hard_lookback_hours);
    let lookback_cutoff_sec = req.now_sec - (effective_lookback_hours * 3600);

    // 2. Apply user & subforem filters (mirrors `apply_user_filters` + `apply_subforem_filters`).
    let blocked_users: HashSet<i64> = user.blocked_user_ids.iter().copied().collect();
    let hidden_tags: HashSet<&str> = user.hidden_tags.iter().map(String::as_str).collect();

    let filtered_indices: Vec<usize> = snapshot
        .articles
        .iter()
        .enumerate()
        .filter_map(|(idx, article)| {
            if article.published_at_sec <= lookback_cutoff_sec {
                return None;
            }
            if blocked_users.contains(&article.user_id) {
                return None;
            }
            if user.hide_fully_autonomous
                && article.ai_disclosure_level == AI_DISCLOSURE_FULLY_AUTONOMOUS
            {
                return None;
            }
            if !hidden_tags.is_empty()
                && article
                    .tags
                    .iter()
                    .any(|t| hidden_tags.contains(t.as_str()))
            {
                return None;
            }
            if snapshot.is_root_subforem && article.type_of != ARTICLE_TYPE_FULL_POST {
                return None;
            }
            Some(idx)
        })
        .collect();

    let ctx = PreparedScoreContext::build(snapshot, config, user, req.now_sec, &mut rng);
    let page = req.page.max(1);
    let per_page = req.per_page.max(1);
    let global_offset = (page - 1) * per_page;

    let semantic_active = config.weights.semantic_similarity_weight > 0.0
        && user
            .interest_embedding
            .as_ref()
            .is_some_and(|v| !v.is_empty())
        && embeddings.is_some();

    let semantic_term = |article: &EdgeArticleEntry| -> f64 {
        if !semantic_active || article.published_at_sec < ctx.published_since_30d_sec {
            return 0.0;
        }
        let Some(table) = embeddings else {
            return 0.0;
        };
        let Some(query) = user.interest_embedding.as_deref() else {
            return 0.0;
        };
        table
            .cosine_similarity(article.id, query)
            .map(|sim| sim * config.weights.semantic_similarity_weight)
            .unwrap_or(0.0)
    };

    // 3. Score + rank + paginate (single-stage or two-stage semantic windowing).
    let mut page_indices: Vec<usize> = if semantic_active
        && has_non_zero_base_weights(&config.weights)
    {
        // Stage 1: rank all filtered articles by base score descending, id descending.
        let mut base_scored: Vec<(usize, f64)> = filtered_indices
            .iter()
            .map(|&idx| {
                (
                    idx,
                    score_article_base(&snapshot.articles[idx], &config.weights, &ctx, req.now_sec),
                )
            })
            .collect();
        base_scored.sort_by(|&(ia, sa), &(ib, sb)| {
            sb.total_cmp(&sa)
                .then_with(|| snapshot.articles[ib].id.cmp(&snapshot.articles[ia].id))
        });

        // Stage 2: rerank within semantic candidate windows matching `apply_semantic_candidate_window`.
        let window_size = config.effective_semantic_candidate_limit();
        let start_window = global_offset / window_size;
        let end_window = (global_offset + per_page - 1) / window_size;
        let window_offset = start_window * window_size;
        let outer_offset = global_offset - window_offset;

        let mut reranked: Vec<usize> = Vec::new();
        for w_idx in start_window..=end_window {
            let slice_start = w_idx * window_size;
            if slice_start >= base_scored.len() {
                break;
            }
            let slice_end = (slice_start + window_size).min(base_scored.len());
            let mut window_items: Vec<(usize, f64)> = base_scored[slice_start..slice_end]
                .iter()
                .map(|&(idx, base_s)| (idx, base_s + semantic_term(&snapshot.articles[idx])))
                .collect();
            window_items.sort_by(|&(ia, sa), &(ib, sb)| {
                sb.total_cmp(&sa)
                    .then_with(|| snapshot.articles[ib].id.cmp(&snapshot.articles[ia].id))
            });
            reranked.extend(window_items.into_iter().map(|(idx, _)| idx));
        }

        reranked
            .into_iter()
            .skip(outer_offset)
            .take(per_page)
            .collect()
    } else {
        let mut scored: Vec<(usize, f64)> = filtered_indices
            .iter()
            .map(|&idx| {
                let article = &snapshot.articles[idx];
                let s = score_article_base(article, &config.weights, &ctx, req.now_sec)
                    + semantic_term(article);
                (idx, s)
            })
            .collect();
        scored.sort_by(|&(ia, sa), &(ib, sb)| {
            sb.total_cmp(&sa)
                .then_with(|| snapshot.articles[ib].id.cmp(&snapshot.articles[ia].id))
        });
        scored
            .into_iter()
            .skip(global_offset)
            .take(per_page)
            .map(|(idx, _)| idx)
            .collect()
    };

    // 4. Post-ranking transforms (exact order from `Articles::Feeds::Custom#execute_feed_query`).
    if config.shuffle_weight > 0.0 && page_indices.len() > 1 {
        let unit_floats = xorshift64_star_unit_floats(rng.next_u64(), page_indices.len());
        if let Some(order) =
            weighted_shuffle_indices(page_indices.len(), config.shuffle_weight, &unit_floats)
        {
            page_indices = order.into_iter().map(|pos| page_indices[pos]).collect();
        }
    }

    // `shuffle_top_five_if_recent`
    if !page_indices.is_empty() {
        let one_week_ago = req.now_sec - (7 * 86_400);
        let all_recent = page_indices
            .iter()
            .all(|&idx| snapshot.articles[idx].published_at_sec > one_week_ago);
        if all_recent {
            let shuffle_count = if config.recent_page_views_shuffle_weight > 0.0 {
                user.recently_viewed_articles
                    .first()
                    .map(|&(_, ts_sec)| {
                        calculate_dynamic_shuffle_count(
                            ParsedTimestamp::from_epoch_and_offset(ts_sec, 0, 0),
                            req.now_sec,
                            0,
                            config.recent_page_views_shuffle_weight,
                        )
                    })
                    .unwrap_or(5)
            } else {
                5
            };
            let split_at = shuffle_count.min(page_indices.len());
            rng.shuffle(&mut page_indices[..split_at]);
        }
    }

    // `apply_published_at_diversity`
    if config.weights.published_at_diversity_weight > 0.0 && page_indices.len() > 2 {
        let lookback_span = ((effective_lookback_hours * 3600) as f64).max(3600.0);
        let strength = config
            .weights
            .published_at_diversity_weight
            .clamp(0.0, 20.0);
        let mut bucket_counts = [0usize; 3];
        let mut keyed: Vec<(f64, usize, usize)> = page_indices
            .iter()
            .enumerate()
            .map(|(index, &art_idx)| {
                let age =
                    ((req.now_sec - snapshot.articles[art_idx].published_at_sec) as f64).max(0.0);
                let ratio = (age / lookback_span).clamp(0.0, 1.0);
                let bucket = if ratio < (1.0 / 3.0) {
                    0
                } else if ratio > (2.0 / 3.0) {
                    2
                } else {
                    1
                };
                let occurrence = bucket_counts[bucket];
                bucket_counts[bucket] += 1;

                let extremity_bonus = ((ratio - 0.5).abs() * 2.0) * (strength * 0.15);
                let saturation_penalty = (occurrence as f64) * (strength * 0.25);
                let sort_key = (index as f64) + saturation_penalty - extremity_bonus;
                (sort_key, index, art_idx)
            })
            .collect();
        keyed.sort_by(|a, b| a.0.total_cmp(&b.0).then_with(|| a.1.cmp(&b.1)));
        page_indices = keyed.into_iter().map(|(_, _, art_idx)| art_idx).collect();
    }

    let mut selected_article_ids: Vec<i64> = page_indices
        .into_iter()
        .map(|idx| snapshot.articles[idx].id)
        .collect();

    // 5. Prepend pinned article when configured and not already in results (matches controller).
    if let Some(pinned_id) = snapshot.pinned_article_id {
        if !selected_article_ids.contains(&pinned_id) {
            selected_article_ids.insert(0, pinned_id);
        }
    }

    Some(EdgeFeedResult {
        selected_config_id: config.id,
        selected_article_ids,
        sticky_assigned,
        sticky_expires_at_sec,
    })
}

/// Assembles the final `/stories/feed/` JSON array from pre-rendered viewer-independent card JSON
/// objects by splicing `"url"`, `"current_user_signed_in"`, and `"feed_config"` at the end of
/// each object (matching `app/views/stories/feeds/show.json.jbuilder`).
pub fn assemble_feed_response_json(
    article_ids: &[i64],
    cards: &HashMap<i64, String>,
    urls: &HashMap<i64, &str>,
    feed_config_id: i64,
    user_signed_in: bool,
) -> String {
    let estimated_bytes = article_ids.len() * 1600 + 32;
    let mut out = String::with_capacity(estimated_bytes);
    out.push('[');
    let mut first = true;

    for &id in article_ids {
        let Some(raw_card) = cards.get(&id) else {
            continue;
        };
        let trimmed = raw_card.trim();
        if !trimmed.starts_with('{') || !trimmed.ends_with('}') {
            continue;
        }
        if !first {
            out.push(',');
        }
        first = false;

        let inner = &trimmed[..trimmed.len() - 1];
        out.push_str(inner);
        if inner.trim_end().len() > 1 {
            out.push(',');
        }
        out.push_str("\"url\":");
        let url = urls.get(&id).copied().unwrap_or("");
        write_json_string(&mut out, url, false);
        out.push_str(",\"current_user_signed_in\":");
        out.push_str(if user_signed_in { "true" } else { "false" });
        out.push_str(",\"feed_config\":");
        let _ = write!(&mut out, "{feed_config_id}");
        out.push('}');
    }

    out.push(']');
    out
}

// ============================================================================
// HMAC-SHA256 Edge Token Signing & Verification
// ============================================================================

const BASE64URL_TABLE: &[u8; 64] =
    b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

/// Encodes bytes as unpadded URL-safe Base64 (RFC 4648 §5).
pub fn base64url_encode(input: &[u8]) -> String {
    let mut out = String::with_capacity(input.len().div_ceil(3) * 4);
    let mut i = 0;
    while i + 3 <= input.len() {
        let n = ((input[i] as u32) << 16) | ((input[i + 1] as u32) << 8) | (input[i + 2] as u32);
        out.push(BASE64URL_TABLE[((n >> 18) & 0x3F) as usize] as char);
        out.push(BASE64URL_TABLE[((n >> 12) & 0x3F) as usize] as char);
        out.push(BASE64URL_TABLE[((n >> 6) & 0x3F) as usize] as char);
        out.push(BASE64URL_TABLE[(n & 0x3F) as usize] as char);
        i += 3;
    }
    let rem = input.len() - i;
    if rem == 1 {
        let n = (input[i] as u32) << 16;
        out.push(BASE64URL_TABLE[((n >> 18) & 0x3F) as usize] as char);
        out.push(BASE64URL_TABLE[((n >> 12) & 0x3F) as usize] as char);
    } else if rem == 2 {
        let n = ((input[i] as u32) << 16) | ((input[i + 1] as u32) << 8);
        out.push(BASE64URL_TABLE[((n >> 18) & 0x3F) as usize] as char);
        out.push(BASE64URL_TABLE[((n >> 12) & 0x3F) as usize] as char);
        out.push(BASE64URL_TABLE[((n >> 6) & 0x3F) as usize] as char);
    }
    out
}

/// Decodes unpadded URL-safe Base64 (RFC 4648 §5).
pub fn base64url_decode(input: &str) -> Option<Vec<u8>> {
    let bytes = input.as_bytes();
    if bytes.len() % 4 == 1 {
        return None;
    }
    let mut out = Vec::with_capacity((bytes.len() * 3) / 4);
    let mut buf: u32 = 0;
    let mut bits: u32 = 0;
    for &b in bytes {
        let val: u32 = match b {
            b'A'..=b'Z' => (b - b'A') as u32,
            b'a'..=b'z' => (b - b'a' + 26) as u32,
            b'0'..=b'9' => (b - b'0' + 52) as u32,
            b'-' => 62,
            b'_' => 63,
            _ => return None,
        };
        buf = (buf << 6) | val;
        bits += 6;
        if bits >= 8 {
            bits -= 8;
            out.push(((buf >> bits) & 0xFF) as u8);
        }
    }
    Some(out)
}

#[inline]
fn constant_time_eq(a: &[u8], b: &[u8]) -> bool {
    if a.len() != b.len() {
        return false;
    }
    let mut diff = 0u8;
    for (&x, &y) in a.iter().zip(b.iter()) {
        diff |= x ^ y;
    }
    diff == 0
}

/// Signs a payload string into `<prefix>.<base64url(payload)>.<base64url(hmac_sha256)>`.
///
/// The HMAC covers `<prefix>.<base64url(payload)>` so tokens of one purpose (`eu1`, `ec1`, `ev1`)
/// cannot be replayed under a different prefix.
pub fn sign_edge_token(prefix: &str, payload: &str, secret: &[u8]) -> String {
    let encoded_payload = base64url_encode(payload.as_bytes());
    let mut signing_input = String::with_capacity(prefix.len() + 1 + encoded_payload.len());
    signing_input.push_str(prefix);
    signing_input.push('.');
    signing_input.push_str(&encoded_payload);
    let mac = hmac_sha256(secret, signing_input.as_bytes());
    let encoded_mac = base64url_encode(&mac);
    signing_input.push('.');
    signing_input.push_str(&encoded_mac);
    signing_input
}

/// Verifies `<prefix>.<base64url(payload)>.<base64url(hmac_sha256)>` in constant time.
pub fn verify_edge_token(prefix: &str, token: &str, secret: &[u8]) -> Option<String> {
    if secret.is_empty() || token.len() > 4096 {
        return None;
    }
    let mut parts = token.split('.');
    let tok_prefix = parts.next()?;
    let encoded_payload = parts.next()?;
    let encoded_sig = parts.next()?;
    if parts.next().is_some() || tok_prefix != prefix {
        return None;
    }

    let provided_sig = base64url_decode(encoded_sig)?;
    let signing_input_len = tok_prefix.len() + 1 + encoded_payload.len();
    let expected_mac = hmac_sha256(secret, &token.as_bytes()[..signing_input_len]);
    if !constant_time_eq(&provided_sig, &expected_mac) {
        return None;
    }

    let payload_bytes = base64url_decode(encoded_payload)?;
    String::from_utf8(payload_bytes).ok()
}

/// Signs an edge identity token (`_forem_edge_uid` cookie).
pub fn sign_edge_user_token(user_id: i64, exp_sec: i64, secret: &[u8]) -> String {
    let payload = format!("{{\"uid\":{user_id},\"exp\":{exp_sec}}}");
    sign_edge_token(EDGE_USER_TOKEN_PREFIX, &payload, secret)
}

/// Verifies an edge identity token and checks `exp > now_sec`, returning `user_id`.
pub fn verify_edge_user_token(token: &str, secret: &[u8], now_sec: i64) -> Option<i64> {
    let payload = verify_edge_token(EDGE_USER_TOKEN_PREFIX, token, secret)?;
    let val = parse_json(&payload).ok()?;
    let uid = val.get_i64("uid")?;
    let exp = val.get_i64("exp")?;
    if uid > 0 && exp > now_sec {
        Some(uid)
    } else {
        None
    }
}

/// Signs a sticky feed config cookie (`_forem_edge_fc`).
pub fn sign_sticky_config_token(
    user_id: i64,
    subforem_id: i64,
    feed_config_id: i64,
    exp_sec: i64,
    secret: &[u8],
) -> String {
    let payload = format!(
        "{{\"uid\":{user_id},\"sid\":{subforem_id},\"fc\":{feed_config_id},\"exp\":{exp_sec}}}"
    );
    sign_edge_token(EDGE_STICKY_CONFIG_TOKEN_PREFIX, &payload, secret)
}

/// Verifies a sticky feed config cookie for `(user_id, subforem_id)`, returning `(feed_config_id, exp_sec)`.
pub fn verify_sticky_config_token(
    token: &str,
    user_id: i64,
    subforem_id: i64,
    secret: &[u8],
    now_sec: i64,
) -> Option<(i64, i64)> {
    let payload = verify_edge_token(EDGE_STICKY_CONFIG_TOKEN_PREFIX, token, secret)?;
    let val = parse_json(&payload).ok()?;
    let uid = val.get_i64("uid")?;
    let sid = val.get_i64("sid")?;
    let fc = val.get_i64("fc")?;
    let exp = val.get_i64("exp")?;
    if uid == user_id && sid == subforem_id && fc > 0 && exp > now_sec {
        Some((fc, exp))
    } else {
        None
    }
}

/// Mints an edge `X-Feed-Visit-Token` (`ev1.<payload>.<sig>`) verified by Rails `Feeds::RecordConfigVisit`.
pub fn sign_edge_visit_token(
    user_id: i64,
    subforem_id: i64,
    feed_config_id: i64,
    expires_at_sec: i64,
    host: &str,
    secret: &[u8],
) -> String {
    let mut payload = String::with_capacity(128 + host.len());
    let _ = write!(
        &mut payload,
        "{{\"user_id\":{user_id},\"subforem_id\":{subforem_id},\"feed_config_id\":{feed_config_id},\"expires_at\":{expires_at_sec},\"host\":"
    );
    write_json_string(&mut payload, host, false);
    payload.push('}');
    sign_edge_token(EDGE_VISIT_TOKEN_PREFIX, &payload, secret)
}

// ============================================================================
// Zero-Dependency JSON Parsing for Mirrored KV Payloads
// ============================================================================

#[derive(Debug, Clone, PartialEq)]
enum JsonVal {
    Null,
    Bool(bool),
    Num(f64),
    Str(String),
    Arr(Vec<JsonVal>),
    Obj(Vec<(String, JsonVal)>),
}

impl JsonVal {
    fn get(&self, key: &str) -> Option<&JsonVal> {
        match self {
            JsonVal::Obj(entries) => entries.iter().find(|(k, _)| k == key).map(|(_, v)| v),
            _ => None,
        }
    }

    fn as_i64(&self) -> Option<i64> {
        match self {
            JsonVal::Num(n) if n.is_finite() => Some(*n as i64),
            _ => None,
        }
    }

    fn as_f64(&self) -> Option<f64> {
        match self {
            JsonVal::Num(n) if n.is_finite() => Some(*n),
            _ => None,
        }
    }

    fn as_bool(&self) -> Option<bool> {
        match self {
            JsonVal::Bool(b) => Some(*b),
            _ => None,
        }
    }

    fn as_str(&self) -> Option<&str> {
        match self {
            JsonVal::Str(s) => Some(s.as_str()),
            _ => None,
        }
    }

    fn as_arr(&self) -> Option<&[JsonVal]> {
        match self {
            JsonVal::Arr(a) => Some(a.as_slice()),
            _ => None,
        }
    }

    fn get_i64(&self, key: &str) -> Option<i64> {
        self.get(key).and_then(JsonVal::as_i64)
    }

    fn get_f64(&self, key: &str) -> Option<f64> {
        self.get(key).and_then(JsonVal::as_f64)
    }

    fn get_bool(&self, key: &str) -> Option<bool> {
        self.get(key).and_then(JsonVal::as_bool)
    }

    fn get_str(&self, key: &str) -> Option<&str> {
        self.get(key).and_then(JsonVal::as_str)
    }

    fn get_i64_vec(&self, key: &str) -> Vec<i64> {
        self.get(key)
            .and_then(JsonVal::as_arr)
            .map(|arr| arr.iter().filter_map(JsonVal::as_i64).collect())
            .unwrap_or_default()
    }

    fn get_string_vec(&self, key: &str) -> Vec<String> {
        self.get(key)
            .and_then(JsonVal::as_arr)
            .map(|arr| {
                arr.iter()
                    .filter_map(JsonVal::as_str)
                    .map(str::to_string)
                    .collect()
            })
            .unwrap_or_default()
    }
}

struct JsonParser<'a> {
    bytes: &'a [u8],
    pos: usize,
}

impl<'a> JsonParser<'a> {
    fn new(input: &'a str) -> Self {
        Self {
            bytes: input.as_bytes(),
            pos: 0,
        }
    }

    fn skip_ws(&mut self) {
        while self.pos < self.bytes.len() {
            match self.bytes[self.pos] {
                b' ' | b'\t' | b'\n' | b'\r' => self.pos += 1,
                _ => break,
            }
        }
    }

    fn peek(&self) -> Option<u8> {
        self.bytes.get(self.pos).copied()
    }

    fn parse_value(&mut self, depth: usize) -> Result<JsonVal, &'static str> {
        if depth > 64 {
            return Err("json nesting limit exceeded");
        }
        self.skip_ws();
        match self.peek().ok_or("unexpected eof")? {
            b'n' => {
                self.expect_literal(b"null")?;
                Ok(JsonVal::Null)
            }
            b't' => {
                self.expect_literal(b"true")?;
                Ok(JsonVal::Bool(true))
            }
            b'f' => {
                self.expect_literal(b"false")?;
                Ok(JsonVal::Bool(false))
            }
            b'"' => self.parse_string().map(JsonVal::Str),
            b'[' => self.parse_array(depth + 1),
            b'{' => self.parse_object(depth + 1),
            b'-' | b'0'..=b'9' => self.parse_number().map(JsonVal::Num),
            _ => Err("unexpected token"),
        }
    }

    fn expect_literal(&mut self, lit: &[u8]) -> Result<(), &'static str> {
        if self.bytes.get(self.pos..self.pos + lit.len()) == Some(lit) {
            self.pos += lit.len();
            Ok(())
        } else {
            Err("invalid literal")
        }
    }

    fn parse_string(&mut self) -> Result<String, &'static str> {
        if self.peek() != Some(b'"') {
            return Err("expected quote");
        }
        self.pos += 1;
        let mut out = String::new();
        while self.pos < self.bytes.len() {
            let b = self.bytes[self.pos];
            if b == b'"' {
                self.pos += 1;
                return Ok(out);
            }
            if b == b'\\' {
                self.pos += 1;
                let esc = *self.bytes.get(self.pos).ok_or("eof in escape")?;
                self.pos += 1;
                match esc {
                    b'"' => out.push('"'),
                    b'\\' => out.push('\\'),
                    b'/' => out.push('/'),
                    b'b' => out.push('\u{0008}'),
                    b'f' => out.push('\u{000C}'),
                    b'n' => out.push('\n'),
                    b'r' => out.push('\r'),
                    b't' => out.push('\t'),
                    b'u' => {
                        let code = self.parse_hex4()?;
                        if (0xD800..=0xDBFF).contains(&code) {
                            if self.bytes.get(self.pos..self.pos + 2) != Some(b"\\u") {
                                return Err("missing low surrogate");
                            }
                            self.pos += 2;
                            let low = self.parse_hex4()?;
                            if !(0xDC00..=0xDFFF).contains(&low) {
                                return Err("invalid low surrogate");
                            }
                            let cp =
                                0x10000 + (((code as u32 - 0xD800) << 10) | (low as u32 - 0xDC00));
                            let ch = char::from_u32(cp).ok_or("invalid unicode scalar")?;
                            out.push(ch);
                        } else {
                            let ch = char::from_u32(code as u32).ok_or("invalid unicode scalar")?;
                            out.push(ch);
                        }
                    }
                    _ => return Err("invalid escape"),
                }
            } else {
                let start = self.pos;
                while self.pos < self.bytes.len()
                    && self.bytes[self.pos] != b'"'
                    && self.bytes[self.pos] != b'\\'
                {
                    self.pos += 1;
                }
                let slice = std::str::from_utf8(&self.bytes[start..self.pos])
                    .map_err(|_| "invalid utf8")?;
                out.push_str(slice);
            }
        }
        Err("unterminated string")
    }

    fn parse_hex4(&mut self) -> Result<u16, &'static str> {
        let slice = self
            .bytes
            .get(self.pos..self.pos + 4)
            .ok_or("short unicode escape")?;
        self.pos += 4;
        let mut val: u16 = 0;
        for &b in slice {
            let d = match b {
                b'0'..=b'9' => (b - b'0') as u16,
                b'a'..=b'f' => (b - b'a' + 10) as u16,
                b'A'..=b'F' => (b - b'A' + 10) as u16,
                _ => return Err("invalid hex"),
            };
            val = (val << 4) | d;
        }
        Ok(val)
    }

    fn parse_number(&mut self) -> Result<f64, &'static str> {
        let start = self.pos;
        if self.peek() == Some(b'-') {
            self.pos += 1;
        }
        while matches!(self.peek(), Some(b'0'..=b'9')) {
            self.pos += 1;
        }
        if self.peek() == Some(b'.') {
            self.pos += 1;
            while matches!(self.peek(), Some(b'0'..=b'9')) {
                self.pos += 1;
            }
        }
        if matches!(self.peek(), Some(b'e' | b'E')) {
            self.pos += 1;
            if matches!(self.peek(), Some(b'+' | b'-')) {
                self.pos += 1;
            }
            while matches!(self.peek(), Some(b'0'..=b'9')) {
                self.pos += 1;
            }
        }
        let s = std::str::from_utf8(&self.bytes[start..self.pos]).map_err(|_| "bad number")?;
        s.parse::<f64>().map_err(|_| "invalid float")
    }

    fn parse_array(&mut self, depth: usize) -> Result<JsonVal, &'static str> {
        self.pos += 1; // '['
        self.skip_ws();
        let mut items = Vec::new();
        if self.peek() == Some(b']') {
            self.pos += 1;
            return Ok(JsonVal::Arr(items));
        }
        loop {
            items.push(self.parse_value(depth)?);
            self.skip_ws();
            match self.peek() {
                Some(b',') => self.pos += 1,
                Some(b']') => {
                    self.pos += 1;
                    return Ok(JsonVal::Arr(items));
                }
                _ => return Err("expected comma or ]"),
            }
        }
    }

    fn parse_object(&mut self, depth: usize) -> Result<JsonVal, &'static str> {
        self.pos += 1; // '{'
        self.skip_ws();
        let mut entries = Vec::new();
        if self.peek() == Some(b'}') {
            self.pos += 1;
            return Ok(JsonVal::Obj(entries));
        }
        loop {
            self.skip_ws();
            let key = self.parse_string()?;
            self.skip_ws();
            if self.peek() != Some(b':') {
                return Err("expected colon");
            }
            self.pos += 1;
            let val = self.parse_value(depth)?;
            entries.push((key, val));
            self.skip_ws();
            match self.peek() {
                Some(b',') => self.pos += 1,
                Some(b'}') => {
                    self.pos += 1;
                    return Ok(JsonVal::Obj(entries));
                }
                _ => return Err("expected comma or }"),
            }
        }
    }
}

fn parse_json(input: &str) -> Result<JsonVal, &'static str> {
    let mut p = JsonParser::new(input);
    let val = p.parse_value(0)?;
    p.skip_ws();
    if p.pos != p.bytes.len() {
        return Err("trailing characters");
    }
    Ok(val)
}

/// Parses the mirrored `host_map` KV JSON (`{"dev.to": 1, ...}`).
pub fn parse_host_map_json(input: &str) -> Result<HashMap<String, i64>, &'static str> {
    let root = parse_json(input)?;
    let JsonVal::Obj(entries) = root else {
        return Err("host_map must be object");
    };
    let mut map = HashMap::with_capacity(entries.len());
    for (host, val) in entries {
        if let Some(id) = val.as_i64() {
            map.insert(host.to_ascii_lowercase(), id);
        }
    }
    Ok(map)
}

/// Parses a sharded card pack JSON (`{"123": { ... }, "456": { ... }}`) while preserving each
/// card's exact raw JSON object substring without re-serializing inner fields.
pub fn parse_card_shard_raw_json(input: &str) -> Result<HashMap<i64, String>, &'static str> {
    let bytes = input.as_bytes();
    let mut pos = 0usize;
    let skip_ws = |p: &mut usize| {
        while *p < bytes.len() && matches!(bytes[*p], b' ' | b'\t' | b'\n' | b'\r') {
            *p += 1;
        }
    };

    skip_ws(&mut pos);
    if bytes.get(pos) != Some(&b'{') {
        return Err("card shard must be object");
    }
    pos += 1;

    let mut out = HashMap::new();
    skip_ws(&mut pos);
    if bytes.get(pos) == Some(&b'}') {
        return Ok(out);
    }

    loop {
        skip_ws(&mut pos);
        if bytes.get(pos) != Some(&b'"') {
            return Err("expected card id key");
        }
        pos += 1;
        let key_start = pos;
        while pos < bytes.len() && bytes[pos] != b'"' {
            pos += 1;
        }
        if pos >= bytes.len() {
            return Err("unterminated card id key");
        }
        let key_str = std::str::from_utf8(&bytes[key_start..pos]).map_err(|_| "utf8")?;
        let article_id = key_str.parse::<i64>().map_err(|_| "invalid card id")?;
        pos += 1; // closing quote

        skip_ws(&mut pos);
        if bytes.get(pos) != Some(&b':') {
            return Err("expected colon");
        }
        pos += 1;

        skip_ws(&mut pos);
        if bytes.get(pos) != Some(&b'{') {
            return Err("card value must be json object");
        }
        let obj_start = pos;
        let mut depth = 0usize;
        let mut in_string = false;
        let mut escaped = false;
        while pos < bytes.len() {
            let b = bytes[pos];
            if in_string {
                if escaped {
                    escaped = false;
                } else if b == b'\\' {
                    escaped = true;
                } else if b == b'"' {
                    in_string = false;
                }
            } else {
                match b {
                    b'"' => in_string = true,
                    b'{' => depth += 1,
                    b'}' => {
                        depth -= 1;
                        if depth == 0 {
                            pos += 1;
                            break;
                        }
                    }
                    _ => {}
                }
            }
            pos += 1;
        }
        if depth != 0 {
            return Err("unterminated card json object");
        }
        let raw_obj = std::str::from_utf8(&bytes[obj_start..pos]).map_err(|_| "utf8")?;
        out.insert(article_id, raw_obj.to_string());

        skip_ws(&mut pos);
        match bytes.get(pos) {
            Some(b',') => pos += 1,
            Some(b'}') => return Ok(out),
            _ => return Err("expected comma or } in card shard"),
        }
    }
}

/// Parses a mirrored `EdgeSubforemSnapshot` JSON document (`snapshot:<subforem_id>`).
pub fn parse_subforem_snapshot_json(input: &str) -> Result<EdgeSubforemSnapshot, &'static str> {
    let root = parse_json(input)?;
    let configs_arr = root
        .get("configs")
        .and_then(JsonVal::as_arr)
        .ok_or("missing configs")?;
    let articles_arr = root
        .get("articles")
        .and_then(JsonVal::as_arr)
        .ok_or("missing articles")?;

    let mut configs = Vec::with_capacity(configs_arr.len());
    for c in configs_arr {
        let w = c.get("weights").unwrap_or(c);
        let weights = FeedScoreWeights {
            feed_success_weight: w.get_f64("feed_success_weight").unwrap_or(0.0),
            comment_score_weight: w.get_f64("comment_score_weight").unwrap_or(0.0),
            score_weight: w.get_f64("score_weight").unwrap_or(0.0),
            organization_follow_weight: w.get_f64("organization_follow_weight").unwrap_or(0.0),
            user_follow_weight: w.get_f64("user_follow_weight").unwrap_or(0.0),
            follow_status_weight: w.get_f64("follow_status_weight").unwrap_or(0.0),
            tag_follow_weight: w.get_f64("tag_follow_weight").unwrap_or(0.0),
            subforem_follow_weight: w.get_f64("subforem_follow_weight").unwrap_or(0.0),
            label_match_weight: w.get_f64("label_match_weight").unwrap_or(0.0),
            recency_weight: w.get_f64("recency_weight").unwrap_or(0.0),
            comment_recency_weight: w.get_f64("comment_recency_weight").unwrap_or(0.0),
            lookback_window_weight: w.get_f64("lookback_window_weight").unwrap_or(0.0),
            precomputed_selections_weight: w
                .get_f64("precomputed_selections_weight")
                .unwrap_or(0.0),
            recent_article_suppression_rate: w
                .get_f64("recent_article_suppression_rate")
                .unwrap_or(0.0),
            published_today_weight: w.get_f64("published_today_weight").unwrap_or(0.0),
            general_past_day_bonus_weight: w
                .get_f64("general_past_day_bonus_weight")
                .unwrap_or(0.0),
            recently_active_past_day_bonus_weight: w
                .get_f64("recently_active_past_day_bonus_weight")
                .unwrap_or(0.0),
            recent_subforem_weight: w.get_f64("recent_subforem_weight").unwrap_or(0.0),
            semantic_similarity_weight: w.get_f64("semantic_similarity_weight").unwrap_or(0.0),
            ai_disclosure_matching_weight: w
                .get_f64("ai_disclosure_matching_weight")
                .unwrap_or(0.0),
            autonomous_ai_penalty_weight: w.get_f64("autonomous_ai_penalty_weight").unwrap_or(0.0),
            featured_weight: w.get_f64("featured_weight").unwrap_or(0.0),
            favorited_weight: w.get_f64("favorited_weight").unwrap_or(0.0),
            status_weight: w.get_f64("status_weight").unwrap_or(0.0),
            clickbait_score_weight: w.get_f64("clickbait_score_weight").unwrap_or(0.0),
            compellingness_score_weight: w.get_f64("compellingness_score_weight").unwrap_or(0.0),
            language_match_weight: w.get_f64("language_match_weight").unwrap_or(0.0),
            randomness_weight: w.get_f64("randomness_weight").unwrap_or(0.0),
            published_at_diversity_weight: w
                .get_f64("published_at_diversity_weight")
                .unwrap_or(0.0),
        };
        configs.push(EdgeFeedConfig {
            id: c.get_i64("id").ok_or("config missing id")?,
            targeting_bucket: TargetingBucket::parse(
                c.get_str("targeting_bucket").unwrap_or("all"),
            ),
            created_at_sec: c.get_i64("created_at_sec").unwrap_or(0),
            feed_impressions_count: c.get_i64("feed_impressions_count").unwrap_or(0),
            feed_success_score: c.get_f64("feed_success_score").unwrap_or(0.0),
            shuffle_weight: c.get_f64("shuffle_weight").unwrap_or(0.0),
            recent_page_views_shuffle_weight: c
                .get_f64("recent_page_views_shuffle_weight")
                .unwrap_or(0.0),
            semantic_candidate_limit: c
                .get_i64("semantic_candidate_limit")
                .unwrap_or(DEFAULT_SEMANTIC_CANDIDATE_LIMIT as i64)
                .max(0) as usize,
            feed_lookback_hours: c.get_i64("feed_lookback_hours").unwrap_or(0),
            recent_tag_count_min: c.get_i64("recent_tag_count_min").unwrap_or(0).max(0) as usize,
            recent_tag_count_max: c.get_i64("recent_tag_count_max").unwrap_or(0).max(0) as usize,
            all_time_tag_count_min: c.get_i64("all_time_tag_count_min").unwrap_or(0).max(0)
                as usize,
            all_time_tag_count_max: c.get_i64("all_time_tag_count_max").unwrap_or(0).max(0)
                as usize,
            weights,
        });
    }

    let mut articles = Vec::with_capacity(articles_arr.len());
    for a in articles_arr {
        articles.push(EdgeArticleEntry {
            id: a.get_i64("id").ok_or("article missing id")?,
            user_id: a.get_i64("user_id").unwrap_or(0),
            organization_id: a.get_i64("organization_id"),
            subforem_id: a.get_i64("subforem_id"),
            published_at_sec: a.get_i64("published_at_sec").unwrap_or(0),
            last_comment_at_sec: a.get_i64("last_comment_at_sec"),
            score: a.get_f64("score").unwrap_or(0.0),
            comment_score: a.get_f64("comment_score").unwrap_or(0.0),
            feed_success_score: a.get_f64("feed_success_score").unwrap_or(0.0),
            clickbait_score: a.get_f64("clickbait_score").unwrap_or(0.0),
            compellingness_score: a.get_f64("compellingness_score").unwrap_or(0.0),
            featured: a.get_bool("featured").unwrap_or(false),
            favorited: a.get_bool("favorited").unwrap_or(false),
            type_of: a.get_i64("type_of").unwrap_or(0) as i32,
            ai_disclosure_level: a.get_i64("ai_disclosure_level").unwrap_or(0) as i32,
            language: a.get_str("language").map(str::to_string),
            tags: a.get_string_vec("tags"),
            labels: a.get_string_vec("labels"),
            url: a.get_str("url").unwrap_or("").to_string(),
        });
    }

    Ok(EdgeSubforemSnapshot {
        version: root.get_i64("version").unwrap_or(1).max(1) as u32,
        generated_at_sec: root.get_i64("generated_at_sec").unwrap_or(0),
        subforem_id: root.get_i64("subforem_id").ok_or("missing subforem_id")?,
        is_root_subforem: root.get_bool("is_root_subforem").unwrap_or(false),
        feed_lookback_days: root
            .get_i64("feed_lookback_days")
            .unwrap_or(DEFAULT_FEED_LOOKBACK_DAYS),
        feed_strategy: root
            .get_str("feed_strategy")
            .unwrap_or("configured")
            .to_string(),
        sticky_hours: root.get_i64("sticky_hours").unwrap_or(0),
        sticky_percentage: root.get_i64("sticky_percentage").unwrap_or(0),
        pinned_article_id: root.get_i64("pinned_article_id"),
        card_shard_count: root.get_i64("card_shard_count").unwrap_or(8).max(1) as usize,
        configs,
        articles,
    })
}

/// Parses a mirrored `EdgeUserProfile` JSON document (`user:<user_id>`).
pub fn parse_user_profile_json(input: &str) -> Result<EdgeUserProfile, &'static str> {
    let root = parse_json(input)?;
    let ai_preference = match root.get_i64("ai_preference").unwrap_or(0) {
        1 => AiPreference::MinimizeAi,
        2 => AiPreference::HideFullyAutonomous,
        _ => AiPreference::ShowAll,
    };

    let recently_viewed_articles = root
        .get("recently_viewed_articles")
        .and_then(JsonVal::as_arr)
        .map(|arr| {
            arr.iter()
                .filter_map(|pair| {
                    let items = pair.as_arr()?;
                    let id = items.first()?.as_i64()?;
                    let ts = items.get(1)?.as_i64()?;
                    Some((id, ts))
                })
                .collect()
        })
        .unwrap_or_default();

    let interest_embedding = root
        .get("interest_embedding")
        .and_then(JsonVal::as_arr)
        .map(|arr| {
            arr.iter()
                .filter_map(JsonVal::as_f64)
                .map(|v| v as f32)
                .collect::<Vec<f32>>()
        })
        .filter(|v| !v.is_empty());

    Ok(EdgeUserProfile {
        user_id: root.get_i64("user_id").ok_or("missing user_id")?,
        targeting_bucket: TargetingBucket::parse(
            root.get_str("targeting_bucket")
                .unwrap_or("feed_casual_user"),
        ),
        has_activity_store: root.get_bool("has_activity_store").unwrap_or(false),
        blocked_user_ids: root.get_i64_vec("blocked_user_ids"),
        hidden_tags: root.get_string_vec("hidden_tags"),
        hide_fully_autonomous: root.get_bool("hide_fully_autonomous").unwrap_or(false),
        ai_preference,
        languages: root.get_string_vec("languages"),
        alltime_users: root.get_i64_vec("alltime_users"),
        alltime_users_from_activity: root
            .get_bool("alltime_users_from_activity")
            .unwrap_or(false),
        recent_users: root.get_i64_vec("recent_users"),
        alltime_organizations: root.get_i64_vec("alltime_organizations"),
        alltime_organizations_from_activity: root
            .get_bool("alltime_organizations_from_activity")
            .unwrap_or(false),
        recent_organizations: root.get_i64_vec("recent_organizations"),
        alltime_subforems: root.get_i64_vec("alltime_subforems"),
        recent_subforems: root.get_i64_vec("recent_subforems"),
        recent_tags: root.get_string_vec("recent_tags"),
        alltime_tags: root.get_string_vec("alltime_tags"),
        recent_labels: root.get_string_vec("recent_labels"),
        recently_viewed_articles,
        precomputed_selections: root.get_i64_vec("precomputed_selections"),
        interest_embedding,
    })
}

/// Parses a mirrored quantized embeddings JSON document (`embeddings:<subforem_id>`).
///
/// Format: `{"entries": [{"id": 1, "scale": 0.01, "q": "<base64url of i8 bytes>"}, ...]}`.
pub fn parse_embedding_table_json(input: &str) -> Result<EdgeEmbeddingTable, &'static str> {
    let root = parse_json(input)?;
    let arr = root
        .get("entries")
        .and_then(JsonVal::as_arr)
        .ok_or("missing entries")?;
    let mut embeddings = HashMap::with_capacity(arr.len());
    for item in arr {
        let article_id = item.get_i64("id").ok_or("embedding missing id")?;
        let scale = item.get_f64("scale").unwrap_or(0.0) as f32;
        let encoded = item.get_str("q").ok_or("embedding missing q")?;
        let raw_bytes = base64url_decode(encoded).ok_or("invalid embedding base64url")?;
        let values: Vec<i8> = raw_bytes.into_iter().map(|b| b as i8).collect();
        embeddings.insert(
            article_id,
            EdgeQuantizedEmbedding {
                article_id,
                scale,
                values,
            },
        );
    }
    Ok(EdgeEmbeddingTable { embeddings })
}

#[cfg(test)]
mod tests {
    use super::*;

    const NOW: i64 = 1_750_000_000;

    fn sample_article(id: i64) -> EdgeArticleEntry {
        EdgeArticleEntry {
            id,
            user_id: 100 + id,
            organization_id: None,
            subforem_id: Some(1),
            published_at_sec: NOW - (2 * 86_400),
            last_comment_at_sec: Some(NOW - 3600),
            score: 10.0,
            comment_score: 5.0,
            feed_success_score: 2.0,
            clickbait_score: 0.0,
            compellingness_score: 0.0,
            featured: false,
            favorited: false,
            type_of: ARTICLE_TYPE_FULL_POST,
            ai_disclosure_level: AI_DISCLOSURE_NOT_DISCLOSED,
            language: Some("en".to_string()),
            tags: vec!["rust".to_string()],
            labels: vec![],
            url: format!("https://dev.to/author/article-{id}"),
        }
    }

    fn sample_config(id: i64, weights: FeedScoreWeights) -> EdgeFeedConfig {
        EdgeFeedConfig {
            id,
            targeting_bucket: TargetingBucket::All,
            created_at_sec: NOW - 86_400,
            feed_impressions_count: 100,
            feed_success_score: 10.0,
            shuffle_weight: 0.0,
            recent_page_views_shuffle_weight: 0.0,
            semantic_candidate_limit: DEFAULT_SEMANTIC_CANDIDATE_LIMIT,
            feed_lookback_hours: 0,
            recent_tag_count_min: 0,
            recent_tag_count_max: 0,
            all_time_tag_count_min: 0,
            all_time_tag_count_max: 0,
            weights,
        }
    }

    fn sample_user() -> EdgeUserProfile {
        EdgeUserProfile {
            user_id: 42,
            targeting_bucket: TargetingBucket::FeedCasualUser,
            has_activity_store: true,
            blocked_user_ids: vec![],
            hidden_tags: vec![],
            hide_fully_autonomous: false,
            ai_preference: AiPreference::ShowAll,
            languages: vec!["en".to_string()],
            alltime_users: vec![],
            alltime_users_from_activity: true,
            recent_users: vec![],
            alltime_organizations: vec![],
            alltime_organizations_from_activity: true,
            recent_organizations: vec![],
            alltime_subforems: vec![],
            recent_subforems: vec![],
            recent_tags: vec![],
            alltime_tags: vec![],
            recent_labels: vec![],
            recently_viewed_articles: vec![],
            precomputed_selections: vec![],
            interest_embedding: None,
        }
    }

    fn sample_snapshot(
        configs: Vec<EdgeFeedConfig>,
        articles: Vec<EdgeArticleEntry>,
    ) -> EdgeSubforemSnapshot {
        EdgeSubforemSnapshot {
            version: 1,
            generated_at_sec: NOW,
            subforem_id: 1,
            is_root_subforem: false,
            feed_lookback_days: 10,
            feed_strategy: "configured".to_string(),
            sticky_hours: 0,
            sticky_percentage: 0,
            pinned_article_id: None,
            card_shard_count: 8,
            configs,
            articles,
        }
    }

    #[test]
    fn ranks_by_score_and_applies_filters_and_lookback() {
        let mut a1 = sample_article(1);
        a1.score = 100.0;
        a1.published_at_sec = NOW - (8 * 86_400); // > 1 week so no top-5 shuffle

        let mut a2 = sample_article(2);
        a2.score = 200.0;
        a2.user_id = 999; // blocked

        let mut a3 = sample_article(3);
        a3.score = 150.0;
        a3.tags = vec!["crypto".to_string()]; // hidden tag

        let mut a4 = sample_article(4);
        a4.score = 120.0;
        a4.ai_disclosure_level = AI_DISCLOSURE_FULLY_AUTONOMOUS; // hidden AI

        let mut a5 = sample_article(5);
        a5.score = 50.0;
        a5.published_at_sec = NOW - (9 * 86_400);

        let mut a6 = sample_article(6);
        a6.score = 500.0;
        a6.published_at_sec = NOW - (12 * 86_400); // older than 10-day lookback

        let weights = FeedScoreWeights {
            score_weight: 1.0,
            ..Default::default()
        };
        let snapshot = sample_snapshot(
            vec![sample_config(7, weights)],
            vec![a1, a2, a3, a4, a5, a6],
        );

        let mut user = sample_user();
        user.blocked_user_ids = vec![999];
        user.hidden_tags = vec!["crypto".to_string()];
        user.hide_fully_autonomous = true;

        let req = EdgeFeedRequest {
            now_sec: NOW,
            ..Default::default()
        };
        let res = rank_custom_feed(&snapshot, &user, None, &req).expect("feed result");
        assert_eq!(res.selected_config_id, 7);
        assert_eq!(res.selected_article_ids, vec![1, 5]);
    }

    #[test]
    fn root_subforem_filters_out_non_full_posts_and_scores_subforem_weights() {
        let mut full = sample_article(10);
        full.published_at_sec = NOW - (8 * 86_400);
        full.subforem_id = Some(2);
        full.score = 1.0;

        let mut full_unfollowed = sample_article(11);
        full_unfollowed.published_at_sec = NOW - (8 * 86_400);
        full_unfollowed.subforem_id = Some(3);
        full_unfollowed.score = 5.0;

        let mut status = sample_article(12);
        status.type_of = ARTICLE_TYPE_STATUS;
        status.score = 999.0;

        let weights = FeedScoreWeights {
            score_weight: 1.0,
            subforem_follow_weight: 10.0,
            recent_subforem_weight: 5.0,
            ..Default::default()
        };
        let mut snapshot = sample_snapshot(
            vec![sample_config(1, weights)],
            vec![full, full_unfollowed, status],
        );
        snapshot.is_root_subforem = true;

        let mut user = sample_user();
        user.alltime_subforems = vec![2];
        // Subforem 2 appears twice -> multiplicity 2 -> +10 bonus
        user.recent_subforems = vec![2, 9, 2];

        let req = EdgeFeedRequest {
            now_sec: NOW,
            ..Default::default()
        };
        let res = rank_custom_feed(&snapshot, &user, None, &req).expect("feed result");
        assert_eq!(res.selected_article_ids, vec![10, 11]);
    }

    #[test]
    fn evaluates_all_scoring_weights_consistently_with_rails_sql() {
        let mut a = sample_article(55);
        a.user_id = 77;
        a.organization_id = Some(88);
        a.subforem_id = Some(3);
        a.published_at_sec = NOW - (12 * 3600); // 12h ago (within 24h & within lookback window)
        a.last_comment_at_sec = Some(NOW - (3 * 3600)); // 3h ago
        a.score = 20.0;
        a.comment_score = 4.0;
        a.feed_success_score = 3.0;
        a.clickbait_score = 2.0;
        a.compellingness_score = 5.0;
        a.featured = true;
        a.favorited = true;
        a.type_of = ARTICLE_TYPE_STATUS;
        a.ai_disclosure_level = AI_DISCLOSURE_SOME_AI;
        a.language = Some("fr".to_string());
        a.tags = vec!["rust".to_string()];
        a.labels = vec!["deep-dive".to_string()];

        let w = FeedScoreWeights {
            feed_success_weight: 1.5,
            comment_score_weight: 2.0,
            score_weight: 0.5,
            organization_follow_weight: 3.0,
            user_follow_weight: 4.0,
            follow_status_weight: 2.5,
            tag_follow_weight: 6.0,
            subforem_follow_weight: 7.0,
            label_match_weight: 8.0,
            recency_weight: 13.0,
            comment_recency_weight: 4.0,
            lookback_window_weight: 5.0,
            precomputed_selections_weight: 9.0,
            recent_article_suppression_rate: 10.0,
            published_today_weight: 1.0,
            general_past_day_bonus_weight: 2.0,
            recently_active_past_day_bonus_weight: 0.5,
            recent_subforem_weight: 1.25,
            semantic_similarity_weight: 0.0,
            ai_disclosure_matching_weight: 3.5,
            autonomous_ai_penalty_weight: 6.0,
            featured_weight: 11.0,
            favorited_weight: 12.0,
            status_weight: 1.5,
            clickbait_score_weight: 2.0,
            compellingness_score_weight: 1.5,
            language_match_weight: 4.5,
            randomness_weight: 0.0,
            published_at_diversity_weight: 8.0,
        };
        let cfg = sample_config(1, w);
        let mut snap = sample_snapshot(vec![cfg.clone()], vec![a.clone()]);
        snap.is_root_subforem = true;
        snap.feed_lookback_days = 10; // half_lookback_hours = 120.0

        let mut user = sample_user();
        user.alltime_users = vec![77];
        user.alltime_organizations = vec![88];
        user.alltime_subforems = vec![3];
        user.recent_subforems = vec![3, 3];
        user.recent_tags = vec!["rust".to_string()];
        user.recent_labels = vec!["deep-dive".to_string()];
        user.precomputed_selections = vec![55];
        user.recently_viewed_articles = vec![
            (55, NOW - 3600),       // within 24h
            (99, NOW - (6 * 3600)), // second view 6h ago -> window [24h ago, 6h ago], includes 12h ago
        ];
        user.ai_preference = AiPreference::MinimizeAi;
        user.languages = vec!["fr".to_string()];

        let mut rng = SimpleRng::new(1);
        let ctx = PreparedScoreContext::build(&snap, &cfg, &user, NOW, &mut rng);
        let actual = score_article_base(&a, &w, &ctx, NOW);

        // Compute expected formula term-by-term from `FeedConfig#legacy_score_sql`:
        let expected = (3.0 * 1.5) // feed_success
            + (4.0 * 2.0) // comment_score
            + (20.0 * 0.5) // score
            + 3.0 // org follow
            + 4.0 // user follow
            + 2.5 // follow status
            + 6.0 // tag follow
            + 7.0 // subforem follow
            + 8.0 // label match
            + (1.0 / (1.0 + 12.0)) * 13.0 // recency
            + (1.0 / (1.0 + 3.0)) * 4.0 // comment recency
            + ((12.0 - 120.0_f64).abs() / 120.0).min(1.0).powi(2) * 8.0 // diversity
            + 5.0 // lookback window
            + 9.0 // precomputed selection
            - 10.0 // recent article suppression
            + 1.0 // published today
            + 2.0 // general past day
            + (0.5 * 2.0) // recently active past day (2 views in past 24h)
            + (1.25 * 2.0) // recent subforem multiplicity = 2
            - 3.5 // MinimizeAi penalty for some_ai
            + 11.0 // featured
            + 12.0 // favorited
            + 1.5 // status
            - (2.0 * 2.0) // clickbait penalty
            + (5.0 * 1.5) // compellingness
            + 4.5; // language match

        assert!(
            (actual - expected).abs() < 1e-9,
            "actual={actual} expected={expected}"
        );
    }

    #[test]
    fn two_stage_semantic_windowing_and_int8_quantization_rerank_correctly() {
        // 3 articles: base score orders [10, 20, 30], but semantic similarity flips 30 above 10
        // within window 0 (size 100).
        let mut a1 = sample_article(10);
        a1.score = 10.0;
        a1.published_at_sec = NOW - (8 * 86_400);
        let mut a2 = sample_article(20);
        a2.score = 9.0;
        a2.published_at_sec = NOW - (8 * 86_400);
        let mut a3 = sample_article(30);
        a3.score = 8.0;
        a3.published_at_sec = NOW - (8 * 86_400);

        let query = vec![1.0_f32, 0.0, 0.0, 0.0];
        let (s1, q1) = quantize_embedding_i8(&[0.0, 1.0, 0.0, 0.0]); // orthogonal -> sim 0
        let (s2, q2) = quantize_embedding_i8(&[0.5, 0.5, 0.0, 0.0]); // ~0.707
        let (s3, q3) = quantize_embedding_i8(&[1.0, 0.0, 0.0, 0.0]); // identical -> sim 1.0

        let mut table = EdgeEmbeddingTable::default();
        table.embeddings.insert(
            10,
            EdgeQuantizedEmbedding {
                article_id: 10,
                scale: s1,
                values: q1,
            },
        );
        table.embeddings.insert(
            20,
            EdgeQuantizedEmbedding {
                article_id: 20,
                scale: s2,
                values: q2,
            },
        );
        table.embeddings.insert(
            30,
            EdgeQuantizedEmbedding {
                article_id: 30,
                scale: s3,
                values: q3,
            },
        );

        let weights = FeedScoreWeights {
            score_weight: 1.0,
            semantic_similarity_weight: 10.0,
            ..Default::default()
        };
        let snapshot = sample_snapshot(vec![sample_config(1, weights)], vec![a1, a2, a3]);
        let mut user = sample_user();
        user.interest_embedding = Some(query);

        let req = EdgeFeedRequest {
            now_sec: NOW,
            ..Default::default()
        };
        let res = rank_custom_feed(&snapshot, &user, Some(&table), &req).expect("ranked");
        // Final scores: a3 = 8+10=18, a2 = 9+7.07=16.07, a1 = 10+0=10
        assert_eq!(res.selected_article_ids, vec![30, 20, 10]);
    }

    #[test]
    fn prepends_pinned_article_once() {
        let mut a1 = sample_article(1);
        a1.published_at_sec = NOW - (8 * 86_400);
        let weights = FeedScoreWeights {
            score_weight: 1.0,
            ..Default::default()
        };
        let mut snap = sample_snapshot(vec![sample_config(1, weights)], vec![a1]);
        snap.pinned_article_id = Some(999);
        let user = sample_user();
        let req = EdgeFeedRequest {
            now_sec: NOW,
            ..Default::default()
        };
        let res = rank_custom_feed(&snap, &user, None, &req).expect("ranked");
        assert_eq!(res.selected_article_ids, vec![999, 1]);
    }

    #[test]
    fn published_at_diversity_interleaves_saturated_fresh_bucket() {
        // 4 fresh articles followed by 1 older article; diversity should pull the older one up.
        let mut articles = Vec::new();
        for i in 0..4 {
            let mut a = sample_article(100 - i);
            a.score = (100 - i) as f64;
            a.published_at_sec = NOW - ((i + 1) * 3600);
            articles.push(a);
        }
        let mut older = sample_article(1);
        older.score = 1.0;
        older.published_at_sec = NOW - (9 * 86_400); // > 1 week so no top-5 shuffle
        articles.push(older);

        let weights = FeedScoreWeights {
            score_weight: 10.0,
            published_at_diversity_weight: 12.0,
            ..Default::default()
        };
        let snap = sample_snapshot(vec![sample_config(1, weights)], articles);
        let user = sample_user();
        let req = EdgeFeedRequest {
            now_sec: NOW,
            ..Default::default()
        };
        let res = rank_custom_feed(&snap, &user, None, &req).expect("ranked");
        let older_pos = res
            .selected_article_ids
            .iter()
            .position(|&id| id == 1)
            .expect("older present");
        assert!(
            older_pos < 4,
            "expected diversity to promote older article from last slot, got {:?}",
            res.selected_article_ids
        );
    }

    #[test]
    fn edge_hmac_tokens_sign_verify_and_reject_tampering_or_expiry() {
        let secret = b"super-secret-edge-key";
        let uid_tok = sign_edge_user_token(42, NOW + 3600, secret);
        assert!(uid_tok.starts_with("eu1."));
        assert_eq!(verify_edge_user_token(&uid_tok, secret, NOW), Some(42));
        assert_eq!(verify_edge_user_token(&uid_tok, secret, NOW + 3601), None);
        assert_eq!(verify_edge_user_token(&uid_tok, b"wrong-key", NOW), None);

        // Tamper one character
        let mut tampered = uid_tok.clone();
        tampered.pop();
        tampered.push(if uid_tok.ends_with('a') { 'b' } else { 'a' });
        assert_eq!(verify_edge_user_token(&tampered, secret, NOW), None);

        // Sticky config token
        let sticky_tok = sign_sticky_config_token(42, 1, 77, NOW + 7200, secret);
        assert_eq!(
            verify_sticky_config_token(&sticky_tok, 42, 1, secret, NOW),
            Some((77, NOW + 7200))
        );
        assert_eq!(
            verify_sticky_config_token(&sticky_tok, 99, 1, secret, NOW),
            None
        );

        // Visit token
        let visit_tok = sign_edge_visit_token(42, 1, 77, NOW + 7200, "dev.to", secret);
        let verified = verify_edge_token(EDGE_VISIT_TOKEN_PREFIX, &visit_tok, secret)
            .expect("visit token verified");
        assert!(verified.contains("\"feed_config_id\":77"));
        assert!(verified.contains("\"host\":\"dev.to\""));
    }

    #[test]
    fn parses_snapshot_user_profile_embeddings_and_assembles_feed_json() {
        let snapshot_json = r#"{
            "version": 1,
            "generated_at_sec": 1750000000,
            "subforem_id": 1,
            "is_root_subforem": false,
            "feed_lookback_days": 10,
            "feed_strategy": "configured",
            "sticky_hours": 12,
            "sticky_percentage": 100,
            "pinned_article_id": null,
            "card_shard_count": 4,
            "configs": [{
                "id": 9,
                "targeting_bucket": "feed_casual_user",
                "created_at_sec": 1749900000,
                "feed_impressions_count": 50,
                "feed_success_score": 1.2,
                "shuffle_weight": 0.0,
                "recent_page_views_shuffle_weight": 0.0,
                "semantic_candidate_limit": 200,
                "feed_lookback_hours": 0,
                "weights": { "score_weight": 1.0 }
            }],
            "articles": [{
                "id": 101,
                "user_id": 5,
                "organization_id": null,
                "subforem_id": 1,
                "published_at_sec": 1749300000,
                "last_comment_at_sec": null,
                "score": 42,
                "comment_score": 0,
                "feed_success_score": 0,
                "clickbait_score": 0,
                "compellingness_score": 0,
                "featured": false,
                "favorited": false,
                "type_of": 0,
                "ai_disclosure_level": 0,
                "language": "en",
                "tags": ["rust"],
                "labels": [],
                "url": "https://dev.to/a/101"
            }]
        }"#;

        let snapshot = parse_subforem_snapshot_json(snapshot_json).expect("snapshot");
        assert_eq!(snapshot.subforem_id, 1);
        assert_eq!(snapshot.configs.len(), 1);
        assert_eq!(snapshot.articles.len(), 1);

        let user_json = r#"{
            "user_id": 42,
            "targeting_bucket": "feed_casual_user",
            "has_activity_store": true,
            "blocked_user_ids": [],
            "hidden_tags": [],
            "hide_fully_autonomous": false,
            "ai_preference": 0,
            "languages": ["en"],
            "alltime_users": [],
            "alltime_users_from_activity": true,
            "recent_users": [],
            "alltime_organizations": [],
            "alltime_organizations_from_activity": true,
            "recent_organizations": [],
            "alltime_subforems": [],
            "recent_subforems": [],
            "recent_tags": ["rust"],
            "alltime_tags": ["ruby"],
            "recent_labels": [],
            "recently_viewed_articles": [[200, 1749999000]],
            "precomputed_selections": []
        }"#;
        let user = parse_user_profile_json(user_json).expect("user");
        assert_eq!(user.user_id, 42);
        assert_eq!(user.recently_viewed_articles, vec![(200, 1_749_999_000)]);

        let shard_json = r#"{"101":{"id":101,"title":"Hello \"World\""}}"#;
        let cards = parse_card_shard_raw_json(shard_json).expect("cards");
        let mut urls = HashMap::new();
        urls.insert(101, "https://dev.to/a/101");

        let body = assemble_feed_response_json(&[101], &cards, &urls, 9, true);
        assert_eq!(
            body,
            r#"[{"id":101,"title":"Hello \"World\"","url":"https://dev.to/a/101","current_user_signed_in":true,"feed_config":9}]"#
        );
    }

    #[test]
    fn parses_quantized_embeddings_json() {
        let (scale, q) = quantize_embedding_i8(&[0.5, -0.5, 0.25, 0.0]);
        let bytes: Vec<u8> = q.iter().map(|&v| v as u8).collect();
        let encoded = base64url_encode(&bytes);
        let json = format!(r#"{{"entries":[{{"id":101,"scale":{scale},"q":"{encoded}"}}]}}"#);
        let table = parse_embedding_table_json(&json).expect("table");
        let sim = table
            .cosine_similarity(101, &[0.5, -0.5, 0.25, 0.0])
            .expect("sim");
        assert!(
            sim > 0.999,
            "expected near-1.0 cosine similarity, got {sim}"
        );
    }
}
