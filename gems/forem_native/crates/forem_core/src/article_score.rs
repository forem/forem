//! `Article#update_score` / `BlackBox.article_hotness_score` kernels.
//!
//! Tier 1 primitives:
//! - [`tag_list_includes`]: zero-allocation `cached_tag_list.split(", ").include?(tag)`.
//! - [`article_hotness_score`]: `BlackBox.article_hotness_score` integer math.
//!
//! Tier 2 kernels:
//! - [`article_score_aggregates_sql`]: one `SELECT` that gathers the ten
//!   aggregates `Article#update_score` used to fetch with ten separate queries.
//! - [`article_update_score`]: the score / comment score arithmetic.
//!
//! Every function returns `None` outside its fast-path domain. The Ruby caller then
//! runs the legacy code, which keeps the legacy errors (e.g. `Math::DomainError`
//! for a negative badge weight sum, or `ArgumentError` for a `nil` `max_score`).

use std::fmt::Write as _;

/// Integer inputs must stay within `±2^40`. Partial sums of 16 such values stay far
/// below `2^53`, so `f64` accumulation matches Ruby `Integer` / `Float` arithmetic.
pub const MAX_ABS_INPUT: i64 = 1 << 40;

const MAX_EXACT_F64: f64 = 9_007_199_254_740_992.0; // 2^53

/// A Ruby numeric that is added into the score total: either an `Integer` or a `Float`.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum ScoreNum {
    Int(i64),
    Float(f64),
}

impl ScoreNum {
    fn to_f64(self) -> Option<f64> {
        match self {
            ScoreNum::Int(v) if v.abs() <= MAX_ABS_INPUT => Some(v as f64),
            ScoreNum::Float(v) if v.is_finite() => Some(v),
            _ => None,
        }
    }
}

/// Flat inputs for [`article_update_score`]. The addends are listed in the order
/// `Article#update_score` sums them.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct ArticleScoreInputs {
    pub reaction_points: ScoreNum,
    pub spam_adjustment: ScoreNum,
    pub user_reaction_points: ScoreNum,
    pub base_subscriber_adjustment: ScoreNum,
    pub featured_count: i64,
    pub negative_count: i64,
    pub context_note_count: ScoreNum,
    pub automod_adjustment: ScoreNum,
    pub badge_bonus_weight_sum: i64,
    pub organization_baseline_score: ScoreNum,
    pub established_user_adjustment: ScoreNum,
    pub favorited: bool,
    pub max_score: i64,
    pub user_max_score: i64,
    pub baseline_score: i64,
    pub comment_score_sum: i64,
}

fn in_range(v: i64) -> bool {
    v.abs() <= MAX_ABS_INPUT
}

/// Ruby `Float#to_i` (truncate toward zero), limited to values that are exact in `f64`.
fn trunc_to_i64(v: f64) -> Option<i64> {
    if !v.is_finite() || v.abs() >= MAX_EXACT_F64 {
        return None;
    }
    Some(v.trunc() as i64)
}

/// `([count, cap].min + Math.log(count + 1)).to_i`
fn capped_log_adjustment(count: i64, cap: i64) -> Option<i64> {
    trunc_to_i64(count.min(cap) as f64 + ((count + 1) as f64).ln())
}

/// Computes `[score, comment_score]` exactly as `Article#update_score` does.
pub fn article_update_score(inputs: &ArticleScoreInputs) -> Option<(i64, i64)> {
    let ints = [
        inputs.featured_count,
        inputs.negative_count,
        inputs.badge_bonus_weight_sum,
        inputs.max_score,
        inputs.user_max_score,
        inputs.baseline_score,
        inputs.comment_score_sum,
    ];
    if !ints.iter().all(|&v| in_range(v)) {
        return None;
    }
    // Negative counts or badge weight sums would hit `Math.log(0)` / `Math.sqrt(-n)`
    // in Ruby; let the legacy path produce the legacy result (or error).
    if inputs.featured_count < 0 || inputs.negative_count < 0 || inputs.badge_bonus_weight_sum < 0 {
        return None;
    }

    let featured_adjustment = capped_log_adjustment(inputs.featured_count, 10)?;
    let negative_adjustment = if inputs.negative_count > 0 {
        -capped_log_adjustment(inputs.negative_count, 3)?
    } else {
        0
    };
    let badge_bonus = trunc_to_i64((inputs.badge_bonus_weight_sum as f64).sqrt())?;

    // Same left-to-right order as the Ruby expression.
    let mut total = inputs.reaction_points.to_f64()?;
    total += inputs.spam_adjustment.to_f64()?;
    total += inputs.user_reaction_points.to_f64()?;
    total += inputs.base_subscriber_adjustment.to_f64()?;
    total += featured_adjustment as f64;
    total += negative_adjustment as f64;
    total += inputs.context_note_count.to_f64()?;
    total += inputs.automod_adjustment.to_f64()?;
    total += badge_bonus as f64;
    total += inputs.organization_baseline_score.to_f64()?;
    total += inputs.established_user_adjustment.to_f64()?;

    // `self.score = total` casts through ActiveModel::Type::Integer (`to_i`).
    let mut score = trunc_to_i64(total)?;
    if inputs.favorited {
        score = trunc_to_i64(score as f64 * 1.1)?.checked_add(10)?;
    }

    let mut accepted_max = inputs.max_score.min(inputs.user_max_score);
    if accepted_max == 0 {
        accepted_max = inputs.max_score.max(inputs.user_max_score);
    }
    if inputs.baseline_score > 0 && score < inputs.baseline_score {
        score = inputs.baseline_score;
    }
    if accepted_max > 0 && score > accepted_max {
        score = accepted_max;
    }

    let comment_score = if accepted_max > 0 && accepted_max < inputs.comment_score_sum {
        accepted_max
    } else {
        inputs.comment_score_sum
    };

    Some((score, comment_score))
}

/// `(list || "").split(", ").include?(tag)` without allocating.
pub fn tag_list_includes(list: &[u8], tag: &[u8]) -> bool {
    if list.len() < tag.len() {
        return false;
    }
    let mut rest = list;
    loop {
        match find_separator(rest) {
            Some(idx) => {
                if &rest[..idx] == tag {
                    return true;
                }
                rest = &rest[idx + 2..];
            }
            None => return rest == tag,
        }
    }
}

fn find_separator(haystack: &[u8]) -> Option<usize> {
    haystack.windows(2).position(|w| w == b", ")
}

/// Flat inputs for [`article_hotness_score`]. Times are integer nanoseconds since the
/// Unix epoch (`time.to_i * 1_000_000_000 + time.nsec`).
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct HotnessInputs {
    pub published_at_ns: i64,
    pub crossposted_at_ns: Option<i64>,
    pub now_ns: i64,
    /// `BlackBox::OUR_EPOCH_NUMBER`, resolved in Ruby (it depends on the process TZ).
    pub our_epoch: i64,
    pub score: i64,
    pub comment_score: i64,
    pub featured: bool,
    pub favorited: bool,
    pub watercooler: bool,
}

const NS_PER_SEC: i128 = 1_000_000_000;
const NS_PER_HOUR: i128 = 3_600 * NS_PER_SEC;

/// `BlackBox.article_hotness_score` for a published article, with a single `now`
/// and a UTC zone (so `4.days.ago` is exactly 96 hours).
pub fn article_hotness_score(inputs: &HotnessInputs) -> Option<i64> {
    if !in_range(inputs.score) || !in_range(inputs.comment_score) || !in_range(inputs.our_epoch) {
        return None;
    }
    let usable = i128::from(inputs.crossposted_at_ns.unwrap_or(inputs.published_at_ns));
    let now = i128::from(inputs.now_ns);
    let newer_than = |hours: i128| usable > now - hours * NS_PER_HOUR;
    let older_than = |hours: i128| usable < now - hours * NS_PER_HOUR;

    let super_super_recent_bonus = if newer_than(1) { 28 } else { 0 };
    let super_recent_bonus = if newer_than(8) { 81 } else { 0 };
    let recency_bonus = if newer_than(12) { 280 } else { 0 };
    let today_bonus = if newer_than(26) { 795 } else { 0 };
    let two_day_bonus = if newer_than(48) { 830 } else { 0 };
    let four_day_bonus = if newer_than(96) { 930 } else { 0 };
    let curation_bonus =
        if inputs.featured { 200 } else { 0 } + if inputs.favorited { 200 } else { 0 };

    // Ruby Integer division floors toward negative infinity.
    let mut reaction_points = inputs.score;
    if older_than(96) {
        reaction_points = reaction_points.div_euclid(2);
    }
    if older_than(168) {
        reaction_points = reaction_points.div_euclid(4);
    }
    if inputs.watercooler {
        reaction_points = trunc_to_i64(reaction_points as f64 * 0.8)?;
    }

    let published_sec = i128::from(inputs.published_at_ns).div_euclid(NS_PER_SEC);
    let score_from_epoch = published_sec - i128::from(inputs.our_epoch);
    let article_hotness = score_from_epoch.div_euclid(1000)
        + i128::from(inputs.score.min(650) * 2)
        + i128::from(inputs.comment_score.min(650) * 2);

    let total = article_hotness
        + i128::from(reaction_points)
        + recency_bonus
        + super_recent_bonus
        + super_super_recent_bonus
        + today_bonus
        + two_day_bonus
        + four_day_bonus
        + curation_bonus;
    i64::try_from(total).ok()
}

fn valid_category(slug: &str) -> bool {
    !slug.is_empty()
        && slug
            .bytes()
            .all(|b| b.is_ascii_lowercase() || b.is_ascii_digit() || b == b'_')
}

/// Builds the single aggregate `SELECT` used by `Article#update_score`.
///
/// Columns, in order:
/// `reaction_points, privileged_reaction_points, user_reaction_points, featured_count,
///  negative_count, context_note_count, badge_bonus_weight_sum,
///  organization_baseline_score, comment_score_sum, null_comment_scores`.
///
/// `comment_score_sum` is `SUM(GREATEST(score, -1))`, the server-side form of
/// `comments.pluck(:score).sum { |value| [value, -1].max }`; `null_comment_scores`
/// lets the caller defer to the legacy pluck when a `NULL` score would make Ruby raise.
pub fn article_score_aggregates_sql(
    article_id: i64,
    user_id: i64,
    organization_id: Option<i64>,
    privileged_categories: &[&str],
) -> Option<String> {
    if !privileged_categories.iter().all(|c| valid_category(c)) {
        return None;
    }
    let mut sql = String::with_capacity(1_400);
    let _ = write!(
        sql,
        "SELECT \
(SELECT COALESCE(SUM(\"reactions\".\"points\"), 0) FROM \"reactions\" WHERE \"reactions\".\"reactable_id\" = {article_id} AND \"reactions\".\"reactable_type\" = 'Article') AS reaction_points, "
    );
    if privileged_categories.is_empty() {
        sql.push_str("0.0::float8 AS privileged_reaction_points, ");
    } else {
        let _ = write!(
            sql,
            "(SELECT COALESCE(SUM(\"reactions\".\"points\"), 0) FROM \"reactions\" WHERE \"reactions\".\"reactable_id\" = {article_id} AND \"reactions\".\"reactable_type\" = 'Article' AND \"reactions\".\"category\" IN ("
        );
        for (i, category) in privileged_categories.iter().enumerate() {
            if i > 0 {
                sql.push_str(", ");
            }
            let _ = write!(sql, "'{category}'");
        }
        sql.push_str(")) AS privileged_reaction_points, ");
    }
    let _ = write!(
        sql,
        "(SELECT COALESCE(SUM(\"reactions\".\"points\"), 0) FROM \"reactions\" WHERE \"reactions\".\"reactable_id\" = {user_id} AND \"reactions\".\"reactable_type\" = 'User') AS user_reaction_points, \
(SELECT COUNT(*) FROM \"articles\" WHERE \"articles\".\"user_id\" = {user_id} AND \"articles\".\"featured\" = TRUE) AS featured_count, \
(SELECT COUNT(*) FROM \"articles\" WHERE \"articles\".\"user_id\" = {user_id} AND (score < -10)) AS negative_count, \
(SELECT COUNT(*) FROM \"context_notes\" WHERE \"context_notes\".\"article_id\" = {article_id}) AS context_note_count, \
(SELECT COALESCE(SUM(\"badges\".\"bonus_weight\"), 0) FROM \"badges\" INNER JOIN \"badge_achievements\" ON \"badges\".\"id\" = \"badge_achievements\".\"badge_id\" WHERE \"badge_achievements\".\"user_id\" = {user_id}) AS badge_bonus_weight_sum, "
    );
    match organization_id {
        Some(org_id) => {
            let _ = write!(
                sql,
                "(SELECT \"organizations\".\"baseline_score\" FROM \"organizations\" WHERE \"organizations\".\"id\" = {org_id}) AS organization_baseline_score, "
            );
        }
        None => sql.push_str("NULL::integer AS organization_baseline_score, "),
    }
    let _ = write!(
        sql,
        "comment_totals.comment_score_sum, comment_totals.null_comment_scores \
FROM (SELECT COALESCE(SUM(GREATEST(\"comments\".\"score\", -1)), 0) AS comment_score_sum, \
COUNT(*) FILTER (WHERE \"comments\".\"score\" IS NULL) AS null_comment_scores \
FROM \"comments\" WHERE \"comments\".\"commentable_id\" = {article_id} AND \"comments\".\"commentable_type\" = 'Article') AS comment_totals"
    );
    Some(sql)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn base_inputs() -> ArticleScoreInputs {
        ArticleScoreInputs {
            reaction_points: ScoreNum::Int(10),
            spam_adjustment: ScoreNum::Int(0),
            user_reaction_points: ScoreNum::Float(0.0),
            base_subscriber_adjustment: ScoreNum::Int(0),
            featured_count: 0,
            negative_count: 0,
            context_note_count: ScoreNum::Int(0),
            automod_adjustment: ScoreNum::Int(0),
            badge_bonus_weight_sum: 0,
            organization_baseline_score: ScoreNum::Int(0),
            established_user_adjustment: ScoreNum::Int(0),
            favorited: false,
            max_score: 0,
            user_max_score: 0,
            baseline_score: 0,
            comment_score_sum: 3,
        }
    }

    #[test]
    fn natural_score() {
        assert_eq!(article_update_score(&base_inputs()), Some((10, 3)));
    }

    #[test]
    fn spam_and_favorited() {
        let mut i = base_inputs();
        i.spam_adjustment = ScoreNum::Int(-500);
        assert_eq!(article_update_score(&i), Some((-490, 3)));
        let mut i = base_inputs();
        i.favorited = true;
        assert_eq!(article_update_score(&i), Some((21, 3)));
        // Negative favorited score truncates toward zero: (-490 * 1.1).to_i + 10
        let mut i = base_inputs();
        i.spam_adjustment = ScoreNum::Int(-500);
        i.favorited = true;
        assert_eq!(article_update_score(&i), Some((-529, 3)));
    }

    #[test]
    fn featured_and_negative_adjustments() {
        let mut i = base_inputs();
        i.featured_count = 5;
        assert_eq!(article_update_score(&i).unwrap().0, 16);
        i.featured_count = 52;
        assert_eq!(article_update_score(&i).unwrap().0, 23);
        let mut i = base_inputs();
        i.negative_count = 5;
        assert_eq!(article_update_score(&i).unwrap().0, 6);
        i.negative_count = 52;
        assert_eq!(article_update_score(&i).unwrap().0, 4);
    }

    #[test]
    fn badge_bonus_is_sqrt() {
        let mut i = base_inputs();
        i.badge_bonus_weight_sum = 16;
        assert_eq!(article_update_score(&i).unwrap().0, 14);
        i.badge_bonus_weight_sum = 17;
        assert_eq!(article_update_score(&i).unwrap().0, 14);
        i.badge_bonus_weight_sum = -1;
        assert_eq!(article_update_score(&i), None);
    }

    #[test]
    fn max_and_baseline_clamps() {
        let mut i = base_inputs();
        i.max_score = 2;
        assert_eq!(article_update_score(&i), Some((2, 2)));
        let mut i = base_inputs();
        i.baseline_score = 15;
        assert_eq!(article_update_score(&i).unwrap().0, 15);
        let mut i = base_inputs();
        i.baseline_score = 15;
        i.max_score = 12;
        assert_eq!(article_update_score(&i).unwrap().0, 12);
        let mut i = base_inputs();
        i.max_score = 10;
        i.user_max_score = 5;
        assert_eq!(article_update_score(&i).unwrap().0, 5);
        let mut i = base_inputs();
        i.max_score = 0;
        i.user_max_score = 20;
        i.comment_score_sum = 25;
        assert_eq!(article_update_score(&i), Some((10, 20)));
    }

    #[test]
    fn float_reaction_points_truncate() {
        let mut i = base_inputs();
        i.reaction_points = ScoreNum::Float(-0.7);
        assert_eq!(article_update_score(&i).unwrap().0, 0);
        i.reaction_points = ScoreNum::Float(7.9);
        assert_eq!(article_update_score(&i).unwrap().0, 7);
    }

    #[test]
    fn out_of_domain_inputs() {
        let mut i = base_inputs();
        i.reaction_points = ScoreNum::Float(f64::NAN);
        assert_eq!(article_update_score(&i), None);
        let mut i = base_inputs();
        i.reaction_points = ScoreNum::Float(1e300);
        assert_eq!(article_update_score(&i), None);
        let mut i = base_inputs();
        i.reaction_points = ScoreNum::Int(1 << 50);
        assert_eq!(article_update_score(&i), None);
        let mut i = base_inputs();
        i.negative_count = -1;
        assert_eq!(article_update_score(&i), None);
    }

    #[test]
    fn tag_list_membership() {
        assert!(tag_list_includes(b"watercooler", b"watercooler"));
        assert!(tag_list_includes(b"ruby, watercooler", b"watercooler"));
        assert!(tag_list_includes(b"watercooler, ruby", b"watercooler"));
        assert!(!tag_list_includes(b"ruby,watercooler", b"watercooler"));
        assert!(!tag_list_includes(b"watercoolers", b"watercooler"));
        assert!(!tag_list_includes(b" watercooler", b"watercooler"));
        assert!(!tag_list_includes(b"", b"watercooler"));
        assert!(tag_list_includes(b"a, , watercooler, ", b"watercooler"));
        assert!(tag_list_includes(
            "日本, watercooler".as_bytes(),
            b"watercooler"
        ));
    }

    fn hot(published_offset_h: i64, score: i64) -> HotnessInputs {
        let now_ns = 1_795_000_000_000_000_000;
        HotnessInputs {
            published_at_ns: now_ns - published_offset_h * 3_600_000_000_000,
            crossposted_at_ns: None,
            now_ns,
            our_epoch: 1_262_304_001,
            score,
            comment_score: 0,
            featured: false,
            favorited: false,
            watercooler: false,
        }
    }

    #[test]
    fn hotness_recency_bonuses() {
        let fresh = article_hotness_score(&hot(0, 0)).unwrap();
        let day = article_hotness_score(&hot(25, 0)).unwrap();
        let old = article_hotness_score(&hot(24 * 30, 0)).unwrap();
        // The epoch component shrinks by 3.6 per hour, so compare bonuses loosely.
        assert!(fresh > day && day > old);
        let base = (1_795_000_000 - 1_262_304_001) / 1000;
        assert_eq!(fresh, base + 28 + 81 + 280 + 795 + 830 + 930);
    }

    #[test]
    fn hotness_floor_division_for_negative_scores() {
        let mut i = hot(24 * 8, -7);
        let published_sec = i.published_at_ns / 1_000_000_000;
        let base = (published_sec - i.our_epoch).div_euclid(1000);
        // -7 / 2 = -4 (floor), -4 / 4 = -1; min(-7, 650) * 2 = -14
        assert_eq!(article_hotness_score(&i), Some(base - 14 - 1));
        i.watercooler = true;
        // (-1 * 0.8).to_i = 0
        assert_eq!(article_hotness_score(&i), Some(base - 14));
    }

    #[test]
    fn hotness_uses_crossposted_at_for_bonuses_only() {
        let mut i = hot(24 * 30, 0);
        let old = article_hotness_score(&i).unwrap();
        i.crossposted_at_ns = Some(i.now_ns);
        let crossposted = article_hotness_score(&i).unwrap();
        assert_eq!(crossposted - old, 28 + 81 + 280 + 795 + 830 + 930);
    }

    #[test]
    fn hotness_curation_bonus() {
        let mut i = hot(0, 99);
        let base = article_hotness_score(&i).unwrap();
        i.featured = true;
        i.favorited = true;
        assert_eq!(article_hotness_score(&i).unwrap() - base, 400);
    }

    #[test]
    fn aggregates_sql_shape() {
        let sql = article_score_aggregates_sql(42, 7, Some(3), &["thumbsup", "vomit"]).unwrap();
        assert!(sql.contains(
            "\"reactions\".\"reactable_id\" = 42 AND \"reactions\".\"reactable_type\" = 'Article'"
        ));
        assert!(sql.contains("\"category\" IN ('thumbsup', 'vomit')"));
        assert!(sql.contains(
            "\"reactions\".\"reactable_id\" = 7 AND \"reactions\".\"reactable_type\" = 'User'"
        ));
        assert!(sql.contains("\"organizations\".\"id\" = 3"));
        assert!(sql.contains("GREATEST(\"comments\".\"score\", -1)"));
        let no_org = article_score_aggregates_sql(42, 7, None, &[]).unwrap();
        assert!(no_org.contains("NULL::integer AS organization_baseline_score"));
        assert!(no_org.contains("0.0::float8 AS privileged_reaction_points"));
        assert_eq!(
            article_score_aggregates_sql(1, 1, None, &["x'; DROP"]),
            None
        );
        assert_eq!(article_score_aggregates_sql(1, 1, None, &[""]), None);
    }
}
