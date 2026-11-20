//! Pure-Rust kernels for the Forem `FeedEvent` ingestion, deduplication, and
//! `FeedConfig` counter/freshness scoring pipeline.
//!
//! Tier 1 composable primitives:
//! - [`feed_event_category_code`] / [`feed_event_context_code`]
//! - [`feed_events_timebox_lookup_sql`]
//! - [`article_freshness_multiplier`]
//!
//! Tier 2 single-pass pipeline kernels:
//! - [`deduplicate_feed_event_indices`]
//! - [`aggregate_feed_config_counters`]

use std::collections::{HashMap, HashSet};
use std::fmt::Write as _;

pub const CATEGORY_IMPRESSION: u8 = 0;
pub const CATEGORY_CLICK: u8 = 1;
pub const CATEGORY_REACTION: u8 = 2;
pub const CATEGORY_COMMENT: u8 = 3;
pub const CATEGORY_EXTENDED_PAGEVIEW: u8 = 4;

pub const CONTEXT_HOME: u8 = 0;
pub const CONTEXT_SEARCH: u8 = 1;
pub const CONTEXT_TAG: u8 = 2;
pub const CONTEXT_EMAIL: u8 = 3;
pub const CONTEXT_SIDEBAR: u8 = 4;

pub const REACTION_SCORE_MULTIPLIER: f64 = 6.0;
pub const COMMENT_SCORE_MULTIPLIER: f64 = 12.0;
pub const FRESHNESS_MAX_MULTIPLIER: f64 = 1.5;
pub const FRESHNESS_MIN_MULTIPLIER: f64 = 1.0;
pub const FRESHNESS_MAX_BONUS_HOURS: f64 = 12.0;
pub const DEFAULT_FRESHNESS_LOOKBACK_DAYS: i64 = 10;
pub const FRESHNESS_DECAY_STEEPNESS: f64 = 4.0;

/// Maps a `FeedEvent` category name byte slice to its ActiveRecord enum integer.
#[inline]
pub fn feed_event_category_code(bytes: &[u8]) -> Option<u8> {
    match bytes {
        b"impression" => Some(CATEGORY_IMPRESSION),
        b"click" => Some(CATEGORY_CLICK),
        b"reaction" => Some(CATEGORY_REACTION),
        b"comment" => Some(CATEGORY_COMMENT),
        b"extended_pageview" => Some(CATEGORY_EXTENDED_PAGEVIEW),
        _ => None,
    }
}

/// Maps a `FeedEvent` context_type name byte slice to a compact integer code.
#[inline]
pub fn feed_event_context_code(bytes: &[u8]) -> Option<u8> {
    match bytes {
        b"home" => Some(CONTEXT_HOME),
        b"search" => Some(CONTEXT_SEARCH),
        b"tag" => Some(CONTEXT_TAG),
        b"email" => Some(CONTEXT_EMAIL),
        b"sidebar" => Some(CONTEXT_SIDEBAR),
        _ => None,
    }
}

/// Builds the PostgreSQL tuple `IN (...)` predicate for `FeedEvents::BulkUpsert`
/// timebox lookups, deduplicating `(article_id, COALESCE(user_id, 0), category)`
/// triples in insertion order.
///
/// Returns `None` if `triples` is empty.
pub fn feed_events_timebox_lookup_sql(triples: &[(i64, i64, u8)]) -> Option<String> {
    if triples.is_empty() {
        return None;
    }

    let mut seen: HashSet<(i64, i64, u8)> = HashSet::with_capacity(triples.len());
    // Prefix is 52 bytes; each tuple is roughly 20 bytes on average.
    let mut out = String::with_capacity(54 + triples.len() * 20);
    out.push_str("(article_id, COALESCE(user_id, 0), category) IN (");

    let mut first = true;
    for &triple in triples {
        if !seen.insert(triple) {
            continue;
        }
        if !first {
            out.push(',');
        }
        first = false;
        let _ = write!(out, "({},{},{})", triple.0, triple.1, triple.2);
    }

    out.push(')');
    Some(out)
}

/// Suppression uniqueness key matching `FeedEvents::BulkUpsert`:
/// `(user_id, category, article_id, context_type, feed_config_id)`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct FeedEventDedupeKey {
    pub user_id: Option<i64>,
    pub category: u8,
    pub article_id: i64,
    pub context_type: u8,
    pub feed_config_id: Option<i64>,
}

/// Returns the indices of `candidate_keys` that are not present in `existing_keys`
/// and have not appeared earlier in `candidate_keys`.
pub fn deduplicate_feed_event_indices(
    candidate_keys: &[FeedEventDedupeKey],
    existing_keys: &[FeedEventDedupeKey],
) -> Vec<usize> {
    if candidate_keys.is_empty() {
        return Vec::new();
    }

    let mut seen: HashSet<FeedEventDedupeKey> =
        HashSet::with_capacity(existing_keys.len() + candidate_keys.len());
    for &key in existing_keys {
        seen.insert(key);
    }

    let mut kept = Vec::with_capacity(candidate_keys.len());
    for (idx, &key) in candidate_keys.iter().enumerate() {
        if seen.insert(key) {
            kept.push(idx);
        }
    }
    kept
}

/// Computes `FeedEvent.article_freshness_multiplier` using exact IEEE-754 `f64`
/// arithmetic matching the Ruby implementation.
#[inline]
pub fn article_freshness_multiplier(
    published_at_epoch: Option<f64>,
    event_time_epoch: Option<f64>,
    lookback_days_setting: i64,
) -> f64 {
    let (Some(published_at), Some(event_time)) = (published_at_epoch, event_time_epoch) else {
        return FRESHNESS_MIN_MULTIPLIER;
    };

    let age_in_hours = (event_time - published_at) / 3600.0;
    if age_in_hours <= FRESHNESS_MAX_BONUS_HOURS {
        return FRESHNESS_MAX_MULTIPLIER;
    }

    let lookback_days = if lookback_days_setting > 0 {
        lookback_days_setting
    } else {
        DEFAULT_FRESHNESS_LOOKBACK_DAYS
    };
    let lookback_hours = (lookback_days as f64) * 24.0;
    if age_in_hours >= lookback_hours || lookback_hours <= FRESHNESS_MAX_BONUS_HOURS {
        return FRESHNESS_MIN_MULTIPLIER;
    }

    let decay_window = lookback_hours - FRESHNESS_MAX_BONUS_HOURS;
    let progress = (age_in_hours - FRESHNESS_MAX_BONUS_HOURS) / decay_window;
    let raw_decay = 1.0 / (1.0 + (FRESHNESS_DECAY_STEEPNESS * progress));
    let min_decay = 1.0 / (1.0 + FRESHNESS_DECAY_STEEPNESS);
    let normalized_decay = (raw_decay - min_decay) / (1.0 - min_decay);

    FRESHNESS_MIN_MULTIPLIER
        + ((FRESHNESS_MAX_MULTIPLIER - FRESHNESS_MIN_MULTIPLIER) * normalized_decay)
}

/// A single row from `FeedEvent.where(feed_config_id: ...).left_joins(:article).pluck(...)`.
#[derive(Debug, Clone, Copy)]
pub struct FeedConfigCounterRow {
    pub category: u8,
    pub user_id: Option<i64>,
    pub article_position: i64,
    pub event_time_epoch: Option<f64>,
    pub published_at_epoch: Option<f64>,
}

/// Result of aggregating feed config counters across all events for a `FeedConfig`.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct FeedConfigCounters {
    pub impressions_total: i64,
    pub score: f64,
    pub impression_users: Option<i64>,
}

/// Tracks the maximum freshness score per `Option<i64>` user ID while preserving
/// first-seen insertion order so `sum()` matches Ruby `Hash#values.sum` bit-for-bit.
#[derive(Default)]
struct OrderedUserBestFreshness {
    index_by_user: HashMap<Option<i64>, usize>,
    values: Vec<f64>,
}

impl OrderedUserBestFreshness {
    #[inline]
    fn record(&mut self, user_id: Option<i64>, freshness: f64) {
        if let Some(&idx) = self.index_by_user.get(&user_id) {
            if freshness > self.values[idx] {
                self.values[idx] = freshness;
            }
        } else {
            let idx = self.values.len();
            self.index_by_user.insert(user_id, idx);
            self.values.push(freshness);
        }
    }

    /// Matches CRuby's `Array#sum` (Kahan-Babuška-Neumaier compensated summation)
    /// so float totals match Ruby bit-for-bit across all inputs.
    #[inline]
    fn sum(&self) -> f64 {
        let mut sum = 0.0_f64;
        let mut c = 0.0_f64;
        for &x in &self.values {
            let t = sum + x;
            if sum.abs() >= x.abs() {
                c += (sum - t) + x;
            } else {
                c += (x - t) + sum;
            }
            sum = t;
        }
        sum + c
    }
}

/// Single-pass aggregation kernel for `FeedEvent.calculate_feed_config_counters`.
pub fn aggregate_feed_config_counters(
    rows: &[FeedConfigCounterRow],
    lookback_days_setting: i64,
) -> FeedConfigCounters {
    let mut impressions_total: i64 = 0;
    let mut impression_users: HashSet<Option<i64>> = HashSet::new();
    let mut clicks_score: f64 = 0.0;
    let mut reaction_best = OrderedUserBestFreshness::default();
    let mut comment_best = OrderedUserBestFreshness::default();
    let mut pageview_best = OrderedUserBestFreshness::default();

    for row in rows {
        match row.category {
            CATEGORY_IMPRESSION => {
                impressions_total += 1;
                impression_users.insert(row.user_id);
            }
            CATEGORY_CLICK => {
                let freshness = article_freshness_multiplier(
                    row.published_at_epoch,
                    row.event_time_epoch,
                    lookback_days_setting,
                );
                let position_weight = (2.0_f64 / 3.0_f64).powf((row.article_position - 1) as f64);
                clicks_score += position_weight * freshness;
            }
            CATEGORY_REACTION => {
                let freshness = article_freshness_multiplier(
                    row.published_at_epoch,
                    row.event_time_epoch,
                    lookback_days_setting,
                );
                reaction_best.record(row.user_id, freshness);
            }
            CATEGORY_COMMENT => {
                let freshness = article_freshness_multiplier(
                    row.published_at_epoch,
                    row.event_time_epoch,
                    lookback_days_setting,
                );
                comment_best.record(row.user_id, freshness);
            }
            CATEGORY_EXTENDED_PAGEVIEW => {
                let freshness = article_freshness_multiplier(
                    row.published_at_epoch,
                    row.event_time_epoch,
                    lookback_days_setting,
                );
                pageview_best.record(row.user_id, freshness);
            }
            _ => {}
        }
    }

    if impressions_total == 0 {
        return FeedConfigCounters {
            impressions_total: 0,
            score: 0.0,
            impression_users: None,
        };
    }

    let reactions_score = reaction_best.sum() * REACTION_SCORE_MULTIPLIER * 2.0;
    let comments_score = comment_best.sum() * COMMENT_SCORE_MULTIPLIER * 2.0;
    let pageviews_score = pageview_best.sum();
    let distinct_users = impression_users.len() as i64;
    let score = (clicks_score + pageviews_score + reactions_score + comments_score)
        / (distinct_users as f64);

    FeedConfigCounters {
        impressions_total,
        score,
        impression_users: Some(distinct_users),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_category_and_context_codes() {
        assert_eq!(feed_event_category_code(b"impression"), Some(0));
        assert_eq!(feed_event_category_code(b"click"), Some(1));
        assert_eq!(feed_event_category_code(b"reaction"), Some(2));
        assert_eq!(feed_event_category_code(b"comment"), Some(3));
        assert_eq!(feed_event_category_code(b"extended_pageview"), Some(4));
        assert_eq!(feed_event_category_code(b"unknown"), None);

        assert_eq!(feed_event_context_code(b"home"), Some(0));
        assert_eq!(feed_event_context_code(b"search"), Some(1));
        assert_eq!(feed_event_context_code(b"tag"), Some(2));
        assert_eq!(feed_event_context_code(b"email"), Some(3));
        assert_eq!(feed_event_context_code(b"sidebar"), Some(4));
        assert_eq!(feed_event_context_code(b"invalid"), None);
    }

    #[test]
    fn test_feed_events_timebox_lookup_sql_deduplicates_in_order() {
        assert_eq!(feed_events_timebox_lookup_sql(&[]), None);
        assert_eq!(
            feed_events_timebox_lookup_sql(&[(10, 42, 0), (10, 42, 0), (11, 0, 1), (10, 42, 1)]),
            Some(
                "(article_id, COALESCE(user_id, 0), category) IN ((10,42,0),(11,0,1),(10,42,1))"
                    .to_string()
            )
        );
    }

    #[test]
    fn test_deduplicate_feed_event_indices() {
        let k1 = FeedEventDedupeKey {
            user_id: Some(7),
            category: CATEGORY_IMPRESSION,
            article_id: 100,
            context_type: CONTEXT_HOME,
            feed_config_id: Some(5),
        };
        let k2 = FeedEventDedupeKey {
            context_type: CONTEXT_SIDEBAR,
            ..k1
        };
        let k3 = FeedEventDedupeKey {
            user_id: None,
            feed_config_id: None,
            ..k1
        };

        assert_eq!(
            deduplicate_feed_event_indices(&[k1, k2, k2, k3, k1], &[k1]),
            vec![1, 3]
        );
    }

    #[test]
    fn test_article_freshness_multiplier_boundaries() {
        let base = 1_700_000_000.0;
        assert_eq!(article_freshness_multiplier(None, Some(base), 10), 1.0);
        assert_eq!(article_freshness_multiplier(Some(base), None, 10), 1.0);
        assert_eq!(
            article_freshness_multiplier(Some(base - 3600.0), Some(base), 10),
            1.5
        );
        assert_eq!(
            article_freshness_multiplier(Some(base - 12.0 * 3600.0), Some(base), 10),
            1.5
        );
        assert_eq!(
            article_freshness_multiplier(Some(base - 10.0 * 86400.0), Some(base), 10),
            1.0
        );
        assert_eq!(
            article_freshness_multiplier(Some(base - 5.0 * 86400.0), Some(base), 5),
            1.0
        );
        // Zero/negative lookback falls back to DEFAULT_FRESHNESS_LOOKBACK_DAYS (10)
        let mid_default = article_freshness_multiplier(Some(base - 3.0 * 86400.0), Some(base), 0);
        let mid_explicit = article_freshness_multiplier(Some(base - 3.0 * 86400.0), Some(base), 10);
        assert_eq!(mid_default, mid_explicit);
        assert!(mid_default > 1.0 && mid_default < 1.5);
    }

    #[test]
    fn test_aggregate_feed_config_counters() {
        let t = 1_700_000_000.0;
        let fresh_pub = Some(t - 3600.0);
        let rows = vec![
            FeedConfigCounterRow {
                category: CATEGORY_IMPRESSION,
                user_id: Some(1),
                article_position: 1,
                event_time_epoch: Some(t),
                published_at_epoch: fresh_pub,
            },
            FeedConfigCounterRow {
                category: CATEGORY_IMPRESSION,
                user_id: Some(2),
                article_position: 1,
                event_time_epoch: Some(t),
                published_at_epoch: fresh_pub,
            },
            FeedConfigCounterRow {
                category: CATEGORY_CLICK,
                user_id: Some(1),
                article_position: 1,
                event_time_epoch: Some(t),
                published_at_epoch: fresh_pub,
            },
            FeedConfigCounterRow {
                category: CATEGORY_REACTION,
                user_id: Some(1),
                article_position: 1,
                event_time_epoch: Some(t),
                published_at_epoch: fresh_pub,
            },
            FeedConfigCounterRow {
                category: CATEGORY_COMMENT,
                user_id: Some(2),
                article_position: 1,
                event_time_epoch: Some(t),
                published_at_epoch: fresh_pub,
            },
            FeedConfigCounterRow {
                category: CATEGORY_EXTENDED_PAGEVIEW,
                user_id: Some(2),
                article_position: 1,
                event_time_epoch: Some(t),
                published_at_epoch: fresh_pub,
            },
        ];

        let counters = aggregate_feed_config_counters(&rows, 10);
        // clicks: 1 * 1.5 = 1.5
        // reactions: 1.5 * 6 * 2 = 18.0
        // comments: 1.5 * 12 * 2 = 36.0
        // pageviews: 1.5
        // total = 57.0 / 2 = 28.5
        assert_eq!(counters.impressions_total, 2);
        assert_eq!(counters.impression_users, Some(2));
        assert_eq!(counters.score, 28.5);

        // Zero impressions returns [0, 0.0] (impression_users = None)
        let empty = aggregate_feed_config_counters(&rows[2..], 10);
        assert_eq!(empty.impressions_total, 0);
        assert_eq!(empty.score, 0.0);
        assert_eq!(empty.impression_users, None);
    }
}
