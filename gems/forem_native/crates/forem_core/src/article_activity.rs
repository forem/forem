//! `ArticleActivity#recompute_all!` rollup encoder and recompute SQL builder.
//!
//! `Articles::UpdateArticleActivityWorker` rebuilds an article's analytics cache row from
//! three grouped aggregate queries (page views by day+domain, reactions by day, scored
//! comments by day). The legacy Ruby path loaded the full `article_activities` row (four
//! potentially multi-hundred-KB `jsonb` columns), deserialized the old values for dirty
//! tracking, rebuilt nested `Hash`es per row, and re-encoded them through
//! `ActiveSupport::JSON`.
//!
//! - Tier 1: [`build_article_activity_rollup`] folds the plucked aggregate rows into the four
//!   `jsonb` documents and three totals in a single pass, reproducing Ruby `Hash` insertion
//!   order and overwrite semantics exactly.
//! - Tier 2: [`article_activity_recompute_sql`] emits the single `UPDATE` statement that
//!   writes the rollup. Each `jsonb` column is only replaced when its value actually
//!   changed (`CASE WHEN col = new THEN col ELSE new END`), mirroring ActiveRecord's partial
//!   writes so unchanged TOASTed values are not rewritten.
//!
//! Strict fast-path domain (returns `None` so Ruby falls back to the legacy path):
//! - any string containing a NUL byte (`jsonb` rejects `\u0000`)
//! - any running sum overflowing `i64`, or a total outside PostgreSQL `integer` range
//! - non-positive record id or an out-of-range timestamp

use std::collections::HashMap;
use std::fmt::Write;

use crate::json::write_json_string;
use crate::metal::push_quoted_utc_timestamp;

/// Reaction categories in `ArticleActivity::REACTION_CATEGORIES` order.
pub const REACTION_CATEGORIES: [&str; 6] = [
    "like",
    "readinglist",
    "unicorn",
    "exploding_head",
    "raised_hands",
    "fire",
];

/// One `(DATE(created_at), domain)` group from `page_views`.
#[derive(Debug, Clone, Copy)]
pub struct PageViewRollupRow<'a> {
    pub iso: &'a str,
    pub domain: Option<&'a str>,
    pub total: i64,
    pub sum_read_seconds: i64,
    pub logged_in_count: i64,
}

/// One `DATE(created_at)` group from `reactions`.
#[derive(Debug, Clone, Copy)]
pub struct ReactionRollupRow<'a> {
    pub iso: &'a str,
    pub total: i64,
    /// Counts in [`REACTION_CATEGORIES`] order.
    pub categories: [i64; 6],
    pub reactor_ids: &'a [i64],
}

/// One `DATE(created_at)` group from scored `comments`.
#[derive(Debug, Clone, Copy)]
pub struct CommentRollupRow<'a> {
    pub iso: &'a str,
    pub count: i64,
}

/// Encoded `jsonb` documents and totals for one `article_activities` row.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ArticleActivityRollup {
    pub daily_page_views: String,
    pub daily_reactions: String,
    pub daily_comments: String,
    pub daily_referrers: String,
    pub total_page_views: i64,
    pub total_reactions: i64,
    pub total_comments: i64,
}

#[derive(Debug)]
struct PageViewDay<'a> {
    iso: &'a str,
    total: i64,
    sum_read_seconds: i64,
    logged_in_count: i64,
    /// `(domain, total)` in first-seen order. `nil` and `""` are distinct Ruby `Hash` keys
    /// here; they only collapse when encoded (see [`write_referrer_day`]).
    referrers: Vec<(Option<&'a str>, i64)>,
}

#[inline]
fn has_nul(s: &str) -> bool {
    s.as_bytes().contains(&0)
}

#[inline]
fn fits_pg_integer(n: i64) -> bool {
    (i64::from(i32::MIN)..=i64::from(i32::MAX)).contains(&n)
}

#[inline]
fn push_int(out: &mut String, n: i64) {
    let _ = write!(out, "{n}");
}

#[inline]
fn push_key(out: &mut String, key: &str) {
    write_json_string(out, key, false);
    out.push(':');
}

/// Folds page-view rows into per-day counters plus per-day referrer buckets.
fn fold_page_views<'a>(rows: &[PageViewRollupRow<'a>]) -> Option<Vec<PageViewDay<'a>>> {
    let mut days: Vec<PageViewDay<'a>> = Vec::new();
    let mut day_index: HashMap<&'a str, usize> = HashMap::new();
    let mut referrer_index: HashMap<(usize, Option<&'a str>), usize> = HashMap::new();

    for row in rows {
        let domain = row.domain;
        if has_nul(row.iso) || domain.is_some_and(has_nul) {
            return None;
        }
        let idx = *day_index.entry(row.iso).or_insert_with(|| {
            days.push(PageViewDay {
                iso: row.iso,
                total: 0,
                sum_read_seconds: 0,
                logged_in_count: 0,
                referrers: Vec::new(),
            });
            days.len() - 1
        });
        let day = &mut days[idx];
        day.total = day.total.checked_add(row.total)?;
        day.sum_read_seconds = day.sum_read_seconds.checked_add(row.sum_read_seconds)?;
        day.logged_in_count = day.logged_in_count.checked_add(row.logged_in_count)?;

        // `(referrers[iso] ||= {})[domain] = total` — later rows overwrite the value in place.
        match referrer_index.get(&(idx, domain)) {
            Some(&r) => day.referrers[r].1 = row.total,
            None => {
                referrer_index.insert((idx, domain), day.referrers.len());
                day.referrers.push((domain, row.total));
            }
        }
    }
    Some(days)
}

/// Encodes one day's `{ domain => total }` hash the way ActiveSupport does: `Hash#as_json`
/// stringifies keys (`nil.to_s == ""`) and rebuilds the hash, so when both `nil` and `""`
/// are present the merged `""` entry sits at the earlier key's position and carries the
/// value of whichever key was inserted later.
fn write_referrer_day(out: &mut String, referrers: &[(Option<&str>, i64)]) {
    let nil_pos = referrers.iter().position(|(d, _)| d.is_none());
    let empty_pos = referrers.iter().position(|(d, _)| *d == Some(""));
    let (merged_at, skip, merged_value) = match (nil_pos, empty_pos) {
        (Some(a), Some(b)) => {
            let (first, last) = if a < b { (a, b) } else { (b, a) };
            (Some(first), Some(last), referrers[last].1)
        }
        _ => (None, None, 0),
    };

    out.push('{');
    let mut first = true;
    for (j, (domain, total)) in referrers.iter().enumerate() {
        if Some(j) == skip {
            continue;
        }
        if !first {
            out.push(',');
        }
        first = false;
        push_key(out, domain.unwrap_or(""));
        push_int(
            out,
            if Some(j) == merged_at {
                merged_value
            } else {
                *total
            },
        );
    }
    out.push('}');
}

/// Returns the index of the last row for each distinct `iso`, in first-seen order — the
/// `hash[iso] = value` overwrite semantics of a Ruby `Hash`.
fn last_row_per_day<'a, T>(rows: &[T], iso: impl Fn(&T) -> &'a str) -> Option<Vec<usize>> {
    let mut order: Vec<usize> = Vec::with_capacity(rows.len());
    let mut index: HashMap<&'a str, usize> = HashMap::with_capacity(rows.len());
    for (i, row) in rows.iter().enumerate() {
        let key = iso(row);
        if has_nul(key) {
            return None;
        }
        match index.get(key) {
            Some(&slot) => order[slot] = i,
            None => {
                index.insert(key, order.len());
                order.push(i);
            }
        }
    }
    Some(order)
}

/// Tier 1: folds the three grouped aggregate result sets into the `daily_*` `jsonb`
/// documents and totals written by `ArticleActivity#recompute_all!`.
///
/// Output is byte-identical to `JSON.generate` of the legacy Ruby hashes (after
/// ActiveSupport's `as_json` key stringification), so `jsonb` equality is guaranteed.
pub fn build_article_activity_rollup(
    page_views: &[PageViewRollupRow<'_>],
    reactions: &[ReactionRollupRow<'_>],
    comments: &[CommentRollupRow<'_>],
) -> Option<ArticleActivityRollup> {
    let days = fold_page_views(page_views)?;
    let reaction_order = last_row_per_day(reactions, |r| r.iso)?;
    let comment_order = last_row_per_day(comments, |c| c.iso)?;

    let mut total_page_views: i64 = 0;
    let mut daily_page_views = String::with_capacity(2 + days.len() * 72);
    let mut daily_referrers = String::with_capacity(2 + page_views.len() * 32);
    daily_page_views.push('{');
    daily_referrers.push('{');
    for (i, day) in days.iter().enumerate() {
        total_page_views = total_page_views.checked_add(day.total)?;
        if i > 0 {
            daily_page_views.push(',');
            daily_referrers.push(',');
        }
        push_key(&mut daily_page_views, day.iso);
        daily_page_views.push_str("{\"total\":");
        push_int(&mut daily_page_views, day.total);
        daily_page_views.push_str(",\"sum_read_seconds\":");
        push_int(&mut daily_page_views, day.sum_read_seconds);
        daily_page_views.push_str(",\"logged_in_count\":");
        push_int(&mut daily_page_views, day.logged_in_count);
        daily_page_views.push('}');

        push_key(&mut daily_referrers, day.iso);
        write_referrer_day(&mut daily_referrers, &day.referrers);
    }
    daily_page_views.push('}');
    daily_referrers.push('}');

    let mut total_reactions: i64 = 0;
    let reactor_count: usize = reaction_order
        .iter()
        .map(|&i| reactions[i].reactor_ids.len())
        .sum();
    let mut daily_reactions =
        String::with_capacity(2 + reaction_order.len() * 160 + reactor_count * 9);
    daily_reactions.push('{');
    for (n, &i) in reaction_order.iter().enumerate() {
        let row = &reactions[i];
        total_reactions = total_reactions.checked_add(row.total)?;
        if n > 0 {
            daily_reactions.push(',');
        }
        push_key(&mut daily_reactions, row.iso);
        daily_reactions.push_str("{\"total\":");
        push_int(&mut daily_reactions, row.total);
        for (name, count) in REACTION_CATEGORIES.iter().zip(row.categories) {
            daily_reactions.push_str(",\"");
            daily_reactions.push_str(name);
            daily_reactions.push_str("\":");
            push_int(&mut daily_reactions, count);
        }
        daily_reactions.push_str(",\"reactor_ids\":[");
        for (k, id) in row.reactor_ids.iter().enumerate() {
            if k > 0 {
                daily_reactions.push(',');
            }
            push_int(&mut daily_reactions, *id);
        }
        daily_reactions.push_str("]}");
    }
    daily_reactions.push('}');

    let mut total_comments: i64 = 0;
    let mut daily_comments = String::with_capacity(2 + comment_order.len() * 20);
    daily_comments.push('{');
    for (n, &i) in comment_order.iter().enumerate() {
        let row = &comments[i];
        total_comments = total_comments.checked_add(row.count)?;
        if n > 0 {
            daily_comments.push(',');
        }
        push_key(&mut daily_comments, row.iso);
        push_int(&mut daily_comments, row.count);
    }
    daily_comments.push('}');

    Some(ArticleActivityRollup {
        daily_page_views,
        daily_reactions,
        daily_comments,
        daily_referrers,
        total_page_views,
        total_reactions,
        total_comments,
    })
}

/// Appends `s` as a standard-conforming SQL string literal (`'` doubled), matching
/// `ActiveRecord::ConnectionAdapters::Quoting#quote` for PostgreSQL.
fn push_sql_literal(out: &mut String, s: &str) {
    out.reserve(s.len() + 2);
    out.push('\'');
    let mut start = 0;
    for (i, b) in s.bytes().enumerate() {
        if b == b'\'' {
            out.push_str(&s[start..=i]);
            out.push('\'');
            start = i + 1;
        }
    }
    out.push_str(&s[start..]);
    out.push('\'');
}

const JSONB_COLUMNS: [(&str, &str); 4] = [
    ("daily_page_views", "pv"),
    ("daily_reactions", "rx"),
    ("daily_comments", "cm"),
    ("daily_referrers", "rf"),
];

/// Tier 2: builds the single `UPDATE "article_activities"` statement persisting `rollup`.
///
/// `jsonb` columns are only replaced when their stored value differs (`jsonb` equality is
/// key-order-insensitive, like Ruby `Hash#==` in ActiveRecord dirty tracking); totals,
/// `last_aggregated_at`, and `updated_at` are always written.
pub fn article_activity_recompute_sql(
    id: i64,
    rollup: &ArticleActivityRollup,
    now_sec: i64,
    now_usec: u32,
) -> Option<String> {
    if id <= 0
        || !fits_pg_integer(rollup.total_page_views)
        || !fits_pg_integer(rollup.total_reactions)
        || !fits_pg_integer(rollup.total_comments)
    {
        return None;
    }
    let mut ts = String::with_capacity(30);
    push_quoted_utc_timestamp(&mut ts, now_sec, now_usec)?;

    let docs = [
        &rollup.daily_page_views,
        &rollup.daily_reactions,
        &rollup.daily_comments,
        &rollup.daily_referrers,
    ];
    let mut out = String::with_capacity(640 + docs.iter().map(|d| d.len() + 16).sum::<usize>());
    out.push_str("UPDATE \"article_activities\" SET ");
    for (column, alias) in JSONB_COLUMNS {
        let _ = write!(
            out,
            "\"{column}\" = CASE WHEN \"article_activities\".\"{column}\" = v.{alias} THEN \"article_activities\".\"{column}\" ELSE v.{alias} END, "
        );
    }
    let _ = write!(
        out,
        "\"total_page_views\" = {}, \"total_reactions\" = {}, \"total_comments\" = {}, \"last_aggregated_at\" = {ts}, \"updated_at\" = {ts} FROM (SELECT ",
        rollup.total_page_views, rollup.total_reactions, rollup.total_comments,
    );
    for (n, ((_, alias), doc)) in JSONB_COLUMNS.iter().zip(docs).enumerate() {
        if n > 0 {
            out.push_str(", ");
        }
        push_sql_literal(&mut out, doc);
        let _ = write!(out, "::jsonb AS {alias}");
    }
    let _ = write!(out, ") AS v WHERE \"article_activities\".\"id\" = {id}");
    Some(out)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn pv<'a>(
        iso: &'a str,
        domain: Option<&'a str>,
        t: i64,
        s: i64,
        l: i64,
    ) -> PageViewRollupRow<'a> {
        PageViewRollupRow {
            iso,
            domain,
            total: t,
            sum_read_seconds: s,
            logged_in_count: l,
        }
    }

    #[test]
    fn empty_rollup_encodes_empty_objects() {
        let r = build_article_activity_rollup(&[], &[], &[]).unwrap();
        assert_eq!(r.daily_page_views, "{}");
        assert_eq!(r.daily_reactions, "{}");
        assert_eq!(r.daily_comments, "{}");
        assert_eq!(r.daily_referrers, "{}");
        assert_eq!(
            (r.total_page_views, r.total_reactions, r.total_comments),
            (0, 0, 0)
        );
    }

    #[test]
    fn page_views_accumulate_per_day_and_bucket_referrers() {
        let rows = [
            pv("2026-03-01", Some("a.com"), 3, 20, 1),
            pv("2026-03-02", Some("a.com"), 1, 0, 0),
            pv("2026-03-01", Some("b.com"), 2, 50, 0),
            pv("2026-03-01", None, 1, 0, 0),
        ];
        let r = build_article_activity_rollup(&rows, &[], &[]).unwrap();
        assert_eq!(
            r.daily_page_views,
            r#"{"2026-03-01":{"total":6,"sum_read_seconds":70,"logged_in_count":1},"2026-03-02":{"total":1,"sum_read_seconds":0,"logged_in_count":0}}"#
        );
        assert_eq!(
            r.daily_referrers,
            r#"{"2026-03-01":{"a.com":3,"b.com":2,"":1},"2026-03-02":{"a.com":1}}"#
        );
        assert_eq!(r.total_page_views, 7);
    }

    #[test]
    fn nil_and_empty_domain_collapse_keeping_first_position_last_value() {
        let rows = [
            pv("d", None, 1, 0, 0),
            pv("d", Some("x"), 2, 0, 0),
            pv("d", Some(""), 5, 0, 0),
        ];
        let r = build_article_activity_rollup(&rows, &[], &[]).unwrap();
        assert_eq!(r.daily_referrers, r#"{"d":{"":5,"x":2}}"#);
        assert_eq!(r.total_page_views, 8);
    }

    #[test]
    fn nil_and_empty_domain_merge_uses_later_key_not_later_row() {
        // Ruby: {"" => 3 (overwrote 1), nil => 2} -> as_json keeps "" position, nil's value.
        let rows = [
            pv("d", Some(""), 1, 0, 0),
            pv("d", None, 2, 0, 0),
            pv("d", Some(""), 3, 0, 0),
            pv("d", Some("x"), 4, 0, 0),
        ];
        let r = build_article_activity_rollup(&rows, &[], &[]).unwrap();
        assert_eq!(r.daily_referrers, r#"{"d":{"":2,"x":4}}"#);
        assert_eq!(r.total_page_views, 10);
    }

    #[test]
    fn reactions_and_comments_overwrite_duplicate_days() {
        let ids = [7, 9];
        let rx = [
            ReactionRollupRow {
                iso: "d1",
                total: 2,
                categories: [1, 1, 0, 0, 0, 0],
                reactor_ids: &ids,
            },
            ReactionRollupRow {
                iso: "d2",
                total: 1,
                categories: [0, 0, 0, 0, 0, 1],
                reactor_ids: &[],
            },
            ReactionRollupRow {
                iso: "d1",
                total: 4,
                categories: [4, 0, 0, 0, 0, 0],
                reactor_ids: &ids[..1],
            },
        ];
        let cm = [
            CommentRollupRow {
                iso: "d1",
                count: 2,
            },
            CommentRollupRow {
                iso: "d1",
                count: 3,
            },
        ];
        let r = build_article_activity_rollup(&[], &rx, &cm).unwrap();
        assert_eq!(
            r.daily_reactions,
            r#"{"d1":{"total":4,"like":4,"readinglist":0,"unicorn":0,"exploding_head":0,"raised_hands":0,"fire":0,"reactor_ids":[7]},"d2":{"total":1,"like":0,"readinglist":0,"unicorn":0,"exploding_head":0,"raised_hands":0,"fire":1,"reactor_ids":[]}}"#
        );
        assert_eq!(r.total_reactions, 5);
        assert_eq!(r.daily_comments, r#"{"d1":3}"#);
        assert_eq!(r.total_comments, 3);
    }

    #[test]
    fn escapes_unicode_and_quotes_in_keys() {
        let rows = [pv("2026-01-01", Some("ex\"ä'😀.com"), 1, 0, 0)];
        let r = build_article_activity_rollup(&rows, &[], &[]).unwrap();
        assert_eq!(r.daily_referrers, "{\"2026-01-01\":{\"ex\\\"ä'😀.com\":1}}");
    }

    #[test]
    fn out_of_domain_inputs_return_none() {
        assert!(
            build_article_activity_rollup(&[pv("d", Some("a\0b"), 1, 0, 0)], &[], &[]).is_none()
        );
        assert!(build_article_activity_rollup(&[pv("d\0", None, 1, 0, 0)], &[], &[]).is_none());
        let overflow = [pv("a", None, i64::MAX, 0, 0), pv("a", None, 1, 0, 0)];
        assert!(build_article_activity_rollup(&overflow, &[], &[]).is_none());
        let cm = [CommentRollupRow {
            iso: "x\0",
            count: 1,
        }];
        assert!(build_article_activity_rollup(&[], &[], &cm).is_none());
    }

    #[test]
    fn recompute_sql_shape() {
        let rows = [pv("2026-03-01", Some("o'neil.com"), 4, 30, 1)];
        let r = build_article_activity_rollup(&rows, &[], &[]).unwrap();
        let sql = article_activity_recompute_sql(42, &r, 1_772_366_400, 123).unwrap();
        assert!(sql.starts_with("UPDATE \"article_activities\" SET \"daily_page_views\" = CASE WHEN \"article_activities\".\"daily_page_views\" = v.pv THEN"));
        assert!(sql
            .contains("\"total_page_views\" = 4, \"total_reactions\" = 0, \"total_comments\" = 0"));
        assert!(sql.contains("\"last_aggregated_at\" = '2026-03-01 12:00:00.000123', \"updated_at\" = '2026-03-01 12:00:00.000123'"));
        assert!(sql.contains("'{\"2026-03-01\":{\"o''neil.com\":4}}'::jsonb AS rf"));
        assert!(sql.ends_with(") AS v WHERE \"article_activities\".\"id\" = 42"));
    }

    #[test]
    fn recompute_sql_rejects_out_of_range() {
        let mut r = build_article_activity_rollup(&[], &[], &[]).unwrap();
        assert!(article_activity_recompute_sql(0, &r, 1_772_366_400, 0).is_none());
        assert!(article_activity_recompute_sql(1, &r, 1_772_366_400, 1_000_000).is_none());
        r.total_page_views = i64::from(i32::MAX) + 1;
        assert!(article_activity_recompute_sql(1, &r, 1_772_366_400, 0).is_none());
    }
}
