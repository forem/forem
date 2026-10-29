//! Feed ranking, user activity window analysis, and SQL scoring expression builders.
//!
//! This module establishes the coarse-grained service & query-pipeline pattern for
//! `forem_core`:
//! - **Composable domain primitives** (`parse_timestamp`, `count_distinct_activity_days`,
//!   `count_pageviews_since`, `calculate_dynamic_shuffle_count`, `weighted_shuffle_indices`,
//!   `sql_int_list`, `sql_string_array_literal`, `sql_vector_literal`, `sql_squish`,
//!   `format_video_duration`) that can be reused across any feed, digest, notification,
//!   or recommendation service.
//! - **Single-pass pipeline kernel** (`build_feed_config_score_sql`) that composes those
//!   primitives to compile `FeedConfig#score_sql` in a single pre-allocated buffer with
//!   zero intermediate Ruby array/string allocations.

use std::borrow::Cow;
use std::fmt::Write;

/// A parsed timestamp with UTC epoch seconds, nanosecond subseconds, and the
/// calendar day index (`days_from_civil`) in the timestamp's own local offset.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ParsedTimestamp {
    pub utc_sec: i64,
    pub subsec_nanos: u32,
    pub local_days: i64,
}

impl ParsedTimestamp {
    /// Constructs a [`ParsedTimestamp`] from UTC epoch seconds, subsecond nanoseconds,
    /// and a timezone offset in seconds east of UTC.
    #[inline]
    pub const fn from_epoch_and_offset(
        utc_sec: i64,
        subsec_nanos: u32,
        utc_offset_sec: i64,
    ) -> Self {
        let local_days = (utc_sec + utc_offset_sec).div_euclid(86_400);
        Self {
            utc_sec,
            subsec_nanos,
            local_days,
        }
    }

    /// Returns the timestamp as floating-point seconds since the Unix epoch.
    #[inline]
    pub fn to_f64_seconds(self) -> f64 {
        (self.utc_sec as f64) + (self.subsec_nanos as f64) * 1e-9
    }

    /// Returns `true` if `self` is greater than or equal to `(cutoff_sec, cutoff_nanos)`.
    #[inline]
    pub const fn ge_instant(self, cutoff_sec: i64, cutoff_nanos: u32) -> bool {
        self.utc_sec > cutoff_sec
            || (self.utc_sec == cutoff_sec && self.subsec_nanos >= cutoff_nanos)
    }

    /// Returns `true` if `self` is strictly greater than `(cutoff_sec, cutoff_nanos)`.
    #[inline]
    pub const fn gt_instant(self, cutoff_sec: i64, cutoff_nanos: u32) -> bool {
        self.utc_sec > cutoff_sec
            || (self.utc_sec == cutoff_sec && self.subsec_nanos > cutoff_nanos)
    }
}

/// Converts a proleptic Gregorian calendar date `(year, month, day)` to days since
/// `1970-01-01` using Howard Hinnant's civil date algorithm.
#[inline]
pub const fn days_from_civil(year: i32, month: u32, day: u32) -> i64 {
    let y = (year as i64) - if month <= 2 { 1 } else { 0 };
    let era = if y >= 0 { y } else { y - 399 } / 400;
    let yoe = (y - era * 400) as u64; // [0, 399]
    let m = month as u64;
    let d = day as u64;
    let doy = (153 * (if m > 2 { m - 3 } else { m + 9 }) + 2) / 5 + d - 1; // [0, 365]
    let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy; // [0, 146096]
    era * 146_097 + (doe as i64) - 719_468
}

/// Converts days since `1970-01-01` to a proleptic Gregorian calendar date
/// `(year, month, day)` using Howard Hinnant's inverse civil date algorithm.
#[inline]
pub const fn civil_from_days(days: i64) -> (i32, u32, u32) {
    let z = days + 719_468;
    let era = if z >= 0 { z } else { z - 146_096 } / 146_097;
    let doe = (z - era * 146_097) as u64; // [0, 146096]
    let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365; // [0, 399]
    let y = (yoe as i64) + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100); // [0, 365]
    let mp = (5 * doy + 2) / 153; // [0, 11]
    let d = doy - (153 * mp + 2) / 5 + 1; // [1, 31]
    let m = if mp < 10 { mp + 3 } else { mp - 9 }; // [1, 12]
    let year = y + if m <= 2 { 1 } else { 0 };
    (year as i32, m as u32, d as u32)
}

#[inline]
const fn is_leap_year(year: i32) -> bool {
    (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
}

#[inline]
const fn days_in_month(year: i32, month: u32) -> u32 {
    match month {
        1 | 3 | 5 | 7 | 8 | 10 | 12 => 31,
        4 | 6 | 9 | 11 => 30,
        2 => {
            if is_leap_year(year) {
                29
            } else {
                28
            }
        }
        _ => 0,
    }
}

#[inline]
const fn parse_2_digits(bytes: &[u8], offset: usize) -> Option<u32> {
    let b0 = bytes[offset].wrapping_sub(b'0');
    let b1 = bytes[offset + 1].wrapping_sub(b'0');
    if b0 <= 9 && b1 <= 9 {
        Some((b0 as u32) * 10 + (b1 as u32))
    } else {
        None
    }
}

#[inline]
const fn parse_4_digits(bytes: &[u8], offset: usize) -> Option<i32> {
    let b0 = bytes[offset].wrapping_sub(b'0');
    let b1 = bytes[offset + 1].wrapping_sub(b'0');
    let b2 = bytes[offset + 2].wrapping_sub(b'0');
    let b3 = bytes[offset + 3].wrapping_sub(b'0');
    if b0 <= 9 && b1 <= 9 && b2 <= 9 && b3 <= 9 {
        Some((b0 as i32) * 1000 + (b1 as i32) * 100 + (b2 as i32) * 10 + (b3 as i32))
    } else {
        None
    }
}

/// Parses an ISO-8601 or SQL timestamp byte slice in-place without heap allocation.
///
/// Supported formats include:
/// - `"2026-10-27T14:23:45Z"` / `"2026-10-27T14:23:45.123456Z"`
/// - `"2026-10-27T10:23:45-04:00"` / `"2026-10-27 10:23:45 -0400"`
/// - `"2026-10-27 14:23:45 UTC"` / `"2026-10-27 14:23:45"`
/// - `"2026-10-27"`
pub fn parse_timestamp(input: &[u8]) -> Option<ParsedTimestamp> {
    let mut start = 0;
    let mut end = input.len();
    while start < end && input[start].is_ascii_whitespace() {
        start += 1;
    }
    while end > start && input[end - 1].is_ascii_whitespace() {
        end -= 1;
    }
    let bytes = &input[start..end];
    if bytes.len() < 10 {
        return None;
    }

    if bytes[4] != b'-' || bytes[7] != b'-' {
        return None;
    }

    let year = parse_4_digits(bytes, 0)?;
    let month = parse_2_digits(bytes, 5)?;
    let day = parse_2_digits(bytes, 8)?;
    if !(1..=12).contains(&month) || day < 1 || day > days_in_month(year, month) {
        return None;
    }

    let local_days = days_from_civil(year, month, day);
    if bytes.len() == 10 {
        return Some(ParsedTimestamp {
            utc_sec: local_days * 86_400,
            subsec_nanos: 0,
            local_days,
        });
    }

    let sep = bytes[10];
    if sep != b'T' && sep != b't' && sep != b' ' {
        return None;
    }
    if bytes.len() < 19 || bytes[13] != b':' || bytes[16] != b':' {
        return None;
    }

    let hour = parse_2_digits(bytes, 11)?;
    let min = parse_2_digits(bytes, 14)?;
    let sec = parse_2_digits(bytes, 17)?;
    if hour > 23 || min > 59 || sec > 60 {
        return None;
    }

    let mut pos = 19;
    let mut subsec_nanos: u32 = 0;

    if pos < bytes.len() && (bytes[pos] == b'.' || bytes[pos] == b',') {
        pos += 1;
        let frac_start = pos;
        let mut scale: u32 = 100_000_000;
        while pos < bytes.len() {
            let d = bytes[pos].wrapping_sub(b'0');
            if d > 9 {
                break;
            }
            if scale > 0 {
                subsec_nanos += (d as u32) * scale;
                scale /= 10;
            }
            pos += 1;
        }
        if pos == frac_start {
            return None;
        }
    }

    while pos < bytes.len() && bytes[pos] == b' ' {
        pos += 1;
    }

    let rem = &bytes[pos..];
    let offset_sec: i64 = match rem {
        b"" | b"Z" | b"z" | b"UTC" | b"utc" | b"GMT" | b"gmt" => 0,
        [sign @ (b'+' | b'-'), rest @ ..] => {
            let sign_mul: i64 = if *sign == b'-' { -1 } else { 1 };
            match rest.len() {
                2 => {
                    let hh = parse_2_digits(rest, 0)?;
                    if hh > 23 {
                        return None;
                    }
                    sign_mul * (hh as i64) * 3600
                }
                4 => {
                    let hh = parse_2_digits(rest, 0)?;
                    let mm = parse_2_digits(rest, 2)?;
                    if hh > 23 || mm > 59 {
                        return None;
                    }
                    sign_mul * ((hh as i64) * 3600 + (mm as i64) * 60)
                }
                5 if rest[2] == b':' => {
                    let hh = parse_2_digits(rest, 0)?;
                    let mm = parse_2_digits(rest, 3)?;
                    if hh > 23 || mm > 59 {
                        return None;
                    }
                    sign_mul * ((hh as i64) * 3600 + (mm as i64) * 60)
                }
                8 if rest[2] == b':' && rest[5] == b':' => {
                    let hh = parse_2_digits(rest, 0)?;
                    let mm = parse_2_digits(rest, 3)?;
                    let ss = parse_2_digits(rest, 6)?;
                    if hh > 23 || mm > 59 || ss > 59 {
                        return None;
                    }
                    sign_mul * ((hh as i64) * 3600 + (mm as i64) * 60 + (ss as i64))
                }
                _ => return None,
            }
        }
        _ => return None,
    };

    let local_sec = local_days * 86_400 + (hour as i64) * 3600 + (min as i64) * 60 + (sec as i64);
    let utc_sec = local_sec - offset_sec;

    Some(ParsedTimestamp {
        utc_sec,
        subsec_nanos,
        local_days,
    })
}

/// Formats UTC epoch seconds as `"YYYY-MM-DD HH:MM:SS"` (matching Rails `.utc.to_fs(:db)`).
pub fn write_utc_db_timestamp(out: &mut String, utc_sec: i64) {
    let days = utc_sec.div_euclid(86_400);
    let secs_of_day = utc_sec.rem_euclid(86_400) as u32;
    let (year, month, day) = civil_from_days(days);
    let hour = secs_of_day / 3600;
    let min = (secs_of_day % 3600) / 60;
    let sec = secs_of_day % 60;
    let _ = write!(
        out,
        "{year:04}-{month:02}-{day:02} {hour:02}:{min:02}:{sec:02}"
    );
}

/// Returns `"YYYY-MM-DD HH:MM:SS"` in UTC (matching Rails `.utc.to_fs(:db)`).
pub fn format_utc_db_timestamp(utc_sec: i64) -> String {
    let mut out = String::with_capacity(19);
    write_utc_db_timestamp(&mut out, utc_sec);
    out
}

/// Counts distinct local calendar days among `timestamps` whose instant is `>= cutoff`.
///
/// Mirrors the `FeedConfig.active_user?` calculation:
/// ```ruby
/// recent_views.filter_map { |entry|
///   dt = entry[1].to_datetime
///   dt.to_date if dt >= cutoff
/// }.uniq.size
/// ```
pub fn count_distinct_activity_days(
    timestamps: &[ParsedTimestamp],
    cutoff_sec: i64,
    cutoff_nanos: u32,
) -> usize {
    let mut stack_days = [0_i64; 128];
    let mut stack_len = 0_usize;
    let mut overflow_days: Vec<i64> = Vec::new();

    for ts in timestamps {
        if !ts.ge_instant(cutoff_sec, cutoff_nanos) {
            continue;
        }
        let day = ts.local_days;
        if stack_days[..stack_len].contains(&day) {
            continue;
        }
        if stack_len < stack_days.len() {
            stack_days[stack_len] = day;
            stack_len += 1;
        } else if !overflow_days.contains(&day) {
            overflow_days.push(day);
        }
    }

    stack_len + overflow_days.len()
}

/// Counts how many `timestamps` are strictly greater than `(cutoff_sec, cutoff_nanos)`.
///
/// Mirrors `recently_viewed_articles.count { |_, ts| ts.to_datetime > 24.hours.ago }`.
#[inline]
pub fn count_pageviews_since(
    timestamps: &[ParsedTimestamp],
    cutoff_sec: i64,
    cutoff_nanos: u32,
) -> usize {
    timestamps
        .iter()
        .filter(|ts| ts.gt_instant(cutoff_sec, cutoff_nanos))
        .count()
}

/// Computes the recency-weighted top-article shuffle count in `[5, 20]`.
///
/// Mirrors `Articles::Feeds::Custom#calculate_dynamic_shuffle_count`:
/// ```ruby
/// hours_since_last_view = ((Time.current - most_recent_timestamp) / 1.hour).ceil
/// base_shuffle_count = [21 - hours_since_last_view, 5].max
/// weighted_shuffle_count = (base_shuffle_count * weight).round
/// [[weighted_shuffle_count, 5].max, 20].min
/// ```
pub fn calculate_dynamic_shuffle_count(
    most_recent: ParsedTimestamp,
    now_sec: i64,
    now_nanos: u32,
    shuffle_weight: f64,
) -> usize {
    if !shuffle_weight.is_finite() {
        return 5;
    }
    let now_f64 = (now_sec as f64) + (now_nanos as f64) * 1e-9;
    let recent_f64 = most_recent.to_f64_seconds();
    let hours_since_last_view = ((now_f64 - recent_f64) / 3600.0).ceil() as i64;
    let base_shuffle_count = (21 - hours_since_last_view).max(5);
    let weighted = ((base_shuffle_count as f64) * shuffle_weight).round();
    if !weighted.is_finite() {
        return 5;
    }
    (weighted as i64).clamp(5, 20) as usize
}

/// Generates `count` uniform random floats in `[0.0, 1.0)` using `xorshift64*`.
pub fn xorshift64_star_unit_floats(seed: u64, count: usize) -> Vec<f64> {
    let mut state = if seed == 0 {
        0x9E37_79B9_7F4A_7C15_u64
    } else {
        seed
    };
    let mut out = Vec::with_capacity(count);
    for _ in 0..count {
        state ^= state >> 12;
        state ^= state << 25;
        state ^= state >> 27;
        let r = state.wrapping_mul(0x2545_F491_4F6C_DD1D_u64);
        // 53-bit precision float in [0.0, 1.0)
        let unit = ((r >> 11) as f64) * (1.0 / ((1_u64 << 53) as f64));
        out.push(unit);
    }
    out
}

/// Computes the reordered index permutation for `Articles::Feeds::Custom#weighted_shuffle`:
///
/// ```ruby
/// articles.each_with_index.sort_by do |_, index|
///   random_offset = rand * (4 * shuffle_weight) - (2 * shuffle_weight)
///   index + random_offset
/// end.map(&:first)
/// ```
pub fn weighted_shuffle_indices(
    len: usize,
    shuffle_weight: f64,
    randoms: &[f64],
) -> Option<Vec<usize>> {
    if len <= 1 || shuffle_weight <= 0.0 || !shuffle_weight.is_finite() {
        return Some((0..len).collect());
    }
    if randoms.len() < len {
        return None;
    }

    let span = 4.0 * shuffle_weight;
    let half_span = 2.0 * shuffle_weight;
    if !span.is_finite() || !half_span.is_finite() {
        return None;
    }

    let mut keyed: Vec<(f64, usize)> = Vec::with_capacity(len);
    for (index, &r) in randoms.iter().take(len).enumerate() {
        if !r.is_finite() {
            return None;
        }
        let key = (index as f64) + (r * span - half_span);
        if !key.is_finite() {
            return None;
        }
        keyed.push((key, index));
    }

    keyed.sort_by(|a, b| a.0.total_cmp(&b.0).then_with(|| a.1.cmp(&b.1)));
    Some(keyed.into_iter().map(|(_, idx)| idx).collect())
}

/// Formats a video duration in seconds as `"MM:SS"` or `"H:MM:SS"`, matching
/// `Article#video_duration_in_minutes` (`ActiveSupport::Duration.build(seconds).parts`).
///
/// Returns `None` for negative durations so callers can fall back if needed.
pub fn format_video_duration(seconds: i64) -> Option<String> {
    if seconds < 0 {
        return None;
    }
    if seconds == 0 {
        return Some("00:00".to_string());
    }

    // Match ActiveSupport::Duration::PARTS_IN_SECONDS decomposition:
    // years: 31_556_952, months: 2_629_746, weeks: 604_800, days: 86_400
    let mut rem = seconds as u64;
    if rem >= 86_400 {
        rem %= 31_556_952;
        rem %= 2_629_746;
        rem %= 604_800;
        rem %= 86_400;
    }

    let hours = rem / 3600;
    rem %= 3600;
    let minutes = rem / 60;
    let secs = rem % 60;

    let mut out = String::with_capacity(8);
    if hours < 1 {
        let _ = write!(out, "{minutes:02}:{secs:02}");
    } else {
        let _ = write!(out, "{hours}:{minutes:02}:{secs:02}");
    }
    Some(out)
}

/// Writes `val` into `out` matching Ruby's `Float#to_s` representation in the decimal
/// (non-scientific) range `val == 0.0 || (1e-4 <= val.abs() && val.abs() < 1e15)`.
///
/// Returns `false` if `val` is `NaN`, infinite, or outside the decimal range so the caller
/// can fall back to Ruby's formatter.
#[inline]
pub fn write_ruby_float(out: &mut String, val: f64) -> bool {
    if !val.is_finite() {
        return false;
    }
    let abs = val.abs();
    if abs != 0.0 && !(1e-4..1e15).contains(&abs) {
        return false;
    }
    let start = out.len();
    let _ = write!(out, "{val}");
    if !out[start..].contains('.') {
        out.push_str(".0");
    }
    true
}

/// Appends comma-separated integers to `out`, or `empty_fallback` (e.g. `"-1"`) when `ids` is empty.
pub fn write_sql_int_list(out: &mut String, ids: &[i64], empty_fallback: &str) {
    if ids.is_empty() {
        out.push_str(empty_fallback);
        return;
    }
    for (idx, &id) in ids.iter().enumerate() {
        if idx > 0 {
            out.push(',');
        }
        let _ = write!(out, "{id}");
    }
}

/// Returns a comma-separated SQL integer list string, or `empty_fallback` when `ids` is empty.
pub fn sql_int_list(ids: &[i64], empty_fallback: &str) -> String {
    if ids.is_empty() {
        return empty_fallback.to_string();
    }
    let mut out = String::with_capacity(ids.len() * 8);
    write_sql_int_list(&mut out, ids, empty_fallback);
    out
}

/// Quotes a SQL string literal (`'...'` with single quotes doubled as `''`),
/// matching `ActiveRecord::ConnectionAdapters::Quoting#quote`.
#[inline]
pub fn write_sql_quoted_string(out: &mut String, s: &str) {
    out.push('\'');
    for b in s.split('\'') {
        out.push_str(b);
        out.push_str("''");
    }
    // Remove the trailing extra `''` and close with a single `'`
    out.pop();
}

/// Appends a comma-separated list of quoted SQL literals (`'a','b'`).
pub fn write_sql_quoted_list<S: AsRef<str>>(out: &mut String, items: &[S]) {
    for (idx, item) in items.iter().enumerate() {
        if idx > 0 {
            out.push(',');
        }
        write_sql_quoted_string(out, item.as_ref());
    }
}

/// Builds a Postgres typed array literal (`ARRAY['a','b']::text[]`).
pub fn sql_string_array_literal<S: AsRef<str>>(items: &[S], pg_type: &str) -> String {
    let mut out = String::with_capacity(items.len() * 12 + pg_type.len() + 12);
    out.push_str("ARRAY[");
    write_sql_quoted_list(&mut out, items);
    out.push_str("]::");
    out.push_str(pg_type);
    out.push_str("[]");
    out
}

/// Appends a quoted `pgvector` literal (`'[0.1,0.2,...]'`) to `out`.
///
/// Returns `false` if any float falls outside the standard decimal formatting domain.
pub fn write_sql_vector_literal(out: &mut String, values: &[f64]) -> bool {
    out.push_str("'[");
    for (idx, &v) in values.iter().enumerate() {
        if idx > 0 {
            out.push(',');
        }
        if !write_ruby_float(out, v) {
            return false;
        }
    }
    out.push_str("]'");
    true
}

/// Formats a slice of `f64` values as a `pgvector` bracketed string `"[0.1,0.2,...]"`.
pub fn sql_vector_literal(values: &[f64]) -> Option<String> {
    let mut out = String::with_capacity(values.len() * 10 + 2);
    out.push('[');
    for (idx, &v) in values.iter().enumerate() {
        if idx > 0 {
            out.push(',');
        }
        if !write_ruby_float(&mut out, v) {
            return None;
        }
    }
    out.push(']');
    Some(out)
}

/// Collapses all consecutive whitespace runs into a single `' '` and trims leading/trailing
/// whitespace in a single $O(N)$ pass, matching Rails `String#squish`.
pub fn sql_squish(sql: &str) -> String {
    let mut out = String::with_capacity(sql.len());
    if sql.is_ascii() {
        let mut in_space = true;
        for &b in sql.as_bytes() {
            if b.is_ascii_whitespace() {
                if !in_space {
                    out.push(' ');
                    in_space = true;
                }
            } else {
                out.push(b as char);
                in_space = false;
            }
        }
    } else {
        let mut in_space = true;
        for ch in sql.chars() {
            if ch.is_whitespace() {
                if !in_space {
                    out.push(' ');
                    in_space = true;
                }
            } else {
                out.push(ch);
                in_space = false;
            }
        }
    }
    if out.ends_with(' ') {
        out.pop();
    }
    out
}

/// User AI disclosure preference for `FeedConfig#score_sql`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AiPreference {
    ShowAll,
    MinimizeAi,
    HideFullyAutonomous,
}

/// All 23 weight/rate attributes of a `FeedConfig` model used in `FeedConfig#score_sql`.
#[derive(Debug, Clone, Copy, Default)]
pub struct FeedScoreWeights {
    pub feed_success_weight: f64,
    pub comment_score_weight: f64,
    pub score_weight: f64,
    pub organization_follow_weight: f64,
    pub user_follow_weight: f64,
    pub follow_status_weight: f64,
    pub tag_follow_weight: f64,
    pub subforem_follow_weight: f64,
    pub label_match_weight: f64,
    pub recency_weight: f64,
    pub comment_recency_weight: f64,
    pub lookback_window_weight: f64,
    pub precomputed_selections_weight: f64,
    pub recent_article_suppression_rate: f64,
    pub published_today_weight: f64,
    pub general_past_day_bonus_weight: f64,
    pub recently_active_past_day_bonus_weight: f64,
    pub recent_subforem_weight: f64,
    pub semantic_similarity_weight: f64,
    pub ai_disclosure_matching_weight: f64,
    pub autonomous_ai_penalty_weight: f64,
    pub featured_weight: f64,
    pub favorited_weight: f64,
    pub status_weight: f64,
    pub clickbait_score_weight: f64,
    pub compellingness_score_weight: f64,
    pub language_match_weight: f64,
    pub randomness_weight: f64,
}

/// Pre-extracted user, activity, and request context for `build_feed_config_score_sql`.
#[derive(Debug, Clone)]
pub struct FeedScoreContext<'a> {
    pub recent_pageviews_count: usize,
    pub organization_follow_ids: &'a [i64],
    pub user_follow_ids: &'a [i64],
    pub tag_names: &'a [String],
    pub optimized_tags_query: bool,
    pub optimized_tags_limit: usize,
    pub is_root_subforem: bool,
    pub subforem_follow_ids: &'a [i64],
    pub label_names: &'a [String],
    pub lookback_window_utc_sec: i64,
    pub second_latest_pageview_utc_sec: i64,
    pub precomputed_selection_ids: &'a [i64],
    pub has_activity_store: bool,
    pub recent_article_ids: &'a [i64],
    pub published_since_24h_utc_sec: i64,
    pub recent_subforem_ids: &'a [i64],
    pub interest_embedding: &'a [f64],
    pub published_since_30d_utc_sec: i64,
    pub ai_preference: AiPreference,
    pub languages: &'a [String],
    pub random_seed: u32,
}

#[inline]
fn begin_term(out: &mut String, has_terms: &mut bool) {
    if *has_terms {
        out.push_str(" + ");
    } else {
        *has_terms = true;
    }
}

/// Compiles the complete `FeedConfig#score_sql` SQL expression in a single pass.
///
/// Returns `None` if any float falls outside the standard decimal range so the Ruby caller
/// can transparently fall back to `legacy_score_sql`.
pub fn build_feed_config_score_sql(
    w: &FeedScoreWeights,
    ctx: &FeedScoreContext<'_>,
) -> Option<String> {
    let mut out = String::with_capacity(4096);
    out.push('(');
    let mut has_terms = false;

    // 1. feed_success_weight
    if w.feed_success_weight > 0.0 {
        begin_term(&mut out, &mut has_terms);
        out.push_str("(articles.feed_success_score * ");
        if !write_ruby_float(&mut out, w.feed_success_weight) {
            return None;
        }
        out.push(')');
    }

    // 2. comment_score_weight
    if w.comment_score_weight > 0.0 {
        begin_term(&mut out, &mut has_terms);
        out.push_str("(articles.comment_score * ");
        if !write_ruby_float(&mut out, w.comment_score_weight) {
            return None;
        }
        out.push(')');
    }

    // 3. score_weight
    if w.score_weight > 0.0 {
        begin_term(&mut out, &mut has_terms);
        out.push_str("(articles.score * ");
        if !write_ruby_float(&mut out, w.score_weight) {
            return None;
        }
        out.push(')');
    }

    // 4. organization_follow_weight
    if w.organization_follow_weight > 0.0 {
        begin_term(&mut out, &mut has_terms);
        out.push_str("(CASE WHEN articles.organization_id IN (");
        write_sql_int_list(&mut out, ctx.organization_follow_ids, "-1");
        out.push_str(") THEN ");
        if !write_ruby_float(&mut out, w.organization_follow_weight) {
            return None;
        }
        out.push_str(" ELSE 0 END)");
    }

    // 5. user_follow_weight
    if w.user_follow_weight > 0.0 {
        begin_term(&mut out, &mut has_terms);
        out.push_str("(CASE WHEN articles.user_id IN (");
        write_sql_int_list(&mut out, ctx.user_follow_ids, "-1");
        out.push_str(") THEN ");
        if !write_ruby_float(&mut out, w.user_follow_weight) {
            return None;
        }
        out.push_str(" ELSE 0 END)");
    }

    // 6. follow_status_weight
    if w.follow_status_weight > 0.0 {
        begin_term(&mut out, &mut has_terms);
        out.push_str("(CASE WHEN articles.type_of = 1 AND articles.user_id IN (");
        write_sql_int_list(&mut out, ctx.user_follow_ids, "-1");
        out.push_str(") THEN ");
        if !write_ruby_float(&mut out, w.follow_status_weight) {
            return None;
        }
        out.push_str(" ELSE 0 END)");
    }

    // 7. tag_follow_weight
    if w.tag_follow_weight > 0.0 && !ctx.tag_names.is_empty() {
        begin_term(&mut out, &mut has_terms);
        if ctx.optimized_tags_query {
            let limit = ctx.optimized_tags_limit.min(ctx.tag_names.len());
            out.push_str("(CASE WHEN articles.tags_array && ARRAY[");
            write_sql_quoted_list(&mut out, &ctx.tag_names[..limit]);
            out.push_str("]::text[] THEN ");
            if !write_ruby_float(&mut out, w.tag_follow_weight) {
                return None;
            }
            out.push_str(" ELSE 0 END)");
        } else {
            let limit = 24.min(ctx.tag_names.len());
            out.push_str("(CASE WHEN ");
            for (idx, tag) in ctx.tag_names[..limit].iter().enumerate() {
                if idx > 0 {
                    out.push_str(" OR ");
                }
                out.push_str("articles.cached_tag_list ~ '[[:<:]]");
                out.push_str(tag);
                out.push_str("[[:>:]]'");
            }
            out.push_str(" THEN ");
            if !write_ruby_float(&mut out, w.tag_follow_weight) {
                return None;
            }
            out.push_str(" ELSE 0 END)");
        }
    }

    // 8. subforem_follow_weight
    if w.subforem_follow_weight > 0.0 && ctx.is_root_subforem {
        begin_term(&mut out, &mut has_terms);
        out.push_str("(CASE WHEN articles.subforem_id IN (");
        write_sql_int_list(&mut out, ctx.subforem_follow_ids, "-1");
        out.push_str(") THEN ");
        if !write_ruby_float(&mut out, w.subforem_follow_weight) {
            return None;
        }
        out.push_str(" ELSE 0 END)");
    }

    // 9. label_match_weight
    if w.label_match_weight > 0.0 && !ctx.label_names.is_empty() {
        begin_term(&mut out, &mut has_terms);
        out.push_str("(CASE WHEN articles.cached_label_list && ARRAY[");
        write_sql_quoted_list(&mut out, ctx.label_names);
        out.push_str("]::varchar[] THEN ");
        if !write_ruby_float(&mut out, w.label_match_weight) {
            return None;
        }
        out.push_str(" ELSE 0 END)");
    }

    // 10. recency_weight
    if w.recency_weight > 0.0 {
        begin_term(&mut out, &mut has_terms);
        out.push_str(
            "((1.0 / (1.0 + (EXTRACT(epoch FROM (NOW() - articles.published_at)) / 3600.0))) * ",
        );
        if !write_ruby_float(&mut out, w.recency_weight) {
            return None;
        }
        out.push(')');
    }

    // 11. comment_recency_weight
    if w.comment_recency_weight > 0.0 {
        begin_term(&mut out, &mut has_terms);
        out.push_str(
            "((1.0 / (1.0 + (EXTRACT(epoch FROM (NOW() - articles.last_comment_at)) / 3600.0))) * ",
        );
        if !write_ruby_float(&mut out, w.comment_recency_weight) {
            return None;
        }
        out.push(')');
    }

    // 12. lookback_window_weight
    if w.lookback_window_weight > 0.0 {
        begin_term(&mut out, &mut has_terms);
        out.push_str("(CASE WHEN articles.published_at BETWEEN '");
        write_utc_db_timestamp(&mut out, ctx.lookback_window_utc_sec);
        out.push_str("' AND '");
        write_utc_db_timestamp(&mut out, ctx.second_latest_pageview_utc_sec);
        out.push_str("' THEN ");
        if !write_ruby_float(&mut out, w.lookback_window_weight) {
            return None;
        }
        out.push_str(" ELSE 0 END)");
    }

    // 13. precomputed_selections_weight
    if w.precomputed_selections_weight > 0.0 && !ctx.precomputed_selection_ids.is_empty() {
        begin_term(&mut out, &mut has_terms);
        out.push_str("(CASE WHEN articles.id IN (");
        write_sql_int_list(&mut out, ctx.precomputed_selection_ids, "-1");
        out.push_str(") THEN ");
        if !write_ruby_float(&mut out, w.precomputed_selections_weight) {
            return None;
        }
        out.push_str(" ELSE 0 END)");
    }

    // 14. recent_article_suppression_rate
    if w.recent_article_suppression_rate > 0.0 && ctx.has_activity_store {
        begin_term(&mut out, &mut has_terms);
        out.push_str("(CASE WHEN articles.id IN (");
        write_sql_int_list(&mut out, ctx.recent_article_ids, "-1");
        out.push_str(") THEN -");
        if !write_ruby_float(&mut out, w.recent_article_suppression_rate) {
            return None;
        }
        out.push_str(" ELSE 0 END)");
    }

    // 15. published_today_weight
    if w.published_today_weight > 0.0 {
        begin_term(&mut out, &mut has_terms);
        out.push_str("(CASE WHEN articles.published_at >= '");
        write_utc_db_timestamp(&mut out, ctx.published_since_24h_utc_sec);
        out.push_str("' THEN ");
        if !write_ruby_float(&mut out, w.published_today_weight) {
            return None;
        }
        out.push_str(" ELSE 0 END)");
    }

    // 16. general_past_day_bonus_weight
    if w.general_past_day_bonus_weight > 0.0 {
        begin_term(&mut out, &mut has_terms);
        out.push_str("(CASE WHEN articles.published_at >= '");
        write_utc_db_timestamp(&mut out, ctx.published_since_24h_utc_sec);
        out.push_str("' THEN ");
        if !write_ruby_float(&mut out, w.general_past_day_bonus_weight) {
            return None;
        }
        out.push_str(" ELSE 0 END)");
    }

    // 17. recently_active_past_day_bonus_weight
    if w.recently_active_past_day_bonus_weight > 0.0 && ctx.recent_pageviews_count > 0 {
        let bonus_value =
            w.recently_active_past_day_bonus_weight * (ctx.recent_pageviews_count as f64);
        begin_term(&mut out, &mut has_terms);
        out.push_str("(CASE WHEN articles.published_at >= '");
        write_utc_db_timestamp(&mut out, ctx.published_since_24h_utc_sec);
        out.push_str("' THEN ");
        if !write_ruby_float(&mut out, bonus_value) {
            return None;
        }
        out.push_str(" ELSE 0 END)");
    }

    // 18. recent_subforem_weight
    if w.recent_subforem_weight > 0.0 && ctx.is_root_subforem && !ctx.recent_subforem_ids.is_empty()
    {
        begin_term(&mut out, &mut has_terms);
        out.push_str("( CASE WHEN articles.subforem_id = ANY(ARRAY[");
        write_sql_int_list(&mut out, ctx.recent_subforem_ids, "");
        out.push_str("]::bigint[]) THEN ");
        if !write_ruby_float(&mut out, w.recent_subforem_weight) {
            return None;
        }
        out.push_str(" * COALESCE( cardinality( array_positions(ARRAY[");
        write_sql_int_list(&mut out, ctx.recent_subforem_ids, "");
        out.push_str("]::bigint[], articles.subforem_id) ), 0 ) ELSE 0 END )");
    }

    // 19. semantic_similarity_weight
    if w.semantic_similarity_weight > 0.0 && !ctx.interest_embedding.is_empty() {
        begin_term(&mut out, &mut has_terms);
        out.push_str(
            "( CASE WHEN articles.semantic_embedding IS NOT NULL AND articles.published_at >= '",
        );
        write_utc_db_timestamp(&mut out, ctx.published_since_30d_utc_sec);
        out.push_str("' THEN (1 - (articles.semantic_embedding <=> ");
        if !write_sql_vector_literal(&mut out, ctx.interest_embedding) {
            return None;
        }
        out.push_str(")) * ");
        if !write_ruby_float(&mut out, w.semantic_similarity_weight) {
            return None;
        }
        out.push_str(" ELSE 0 END )");
    }

    // 20. ai_disclosure_matching_weight
    if w.ai_disclosure_matching_weight > 0.0 {
        match ctx.ai_preference {
            AiPreference::MinimizeAi => {
                begin_term(&mut out, &mut has_terms);
                out.push_str("(CASE WHEN articles.ai_disclosure_level = 3 THEN -");
                if !write_ruby_float(&mut out, w.ai_disclosure_matching_weight) {
                    return None;
                }
                out.push_str(" WHEN articles.ai_disclosure_level = 5 THEN -");
                if !write_ruby_float(&mut out, w.ai_disclosure_matching_weight * 2.0) {
                    return None;
                }
                out.push_str(" ELSE 0 END)");
            }
            AiPreference::HideFullyAutonomous => {
                begin_term(&mut out, &mut has_terms);
                out.push_str("(CASE WHEN articles.ai_disclosure_level = 3 THEN -");
                if !write_ruby_float(&mut out, w.ai_disclosure_matching_weight) {
                    return None;
                }
                out.push_str(" ELSE 0 END)");
            }
            AiPreference::ShowAll => {}
        }
    }

    // 21. autonomous_ai_penalty_weight
    if w.autonomous_ai_penalty_weight > 0.0 {
        begin_term(&mut out, &mut has_terms);
        out.push_str("(CASE WHEN articles.ai_disclosure_level = 5 THEN -");
        if !write_ruby_float(&mut out, w.autonomous_ai_penalty_weight) {
            return None;
        }
        out.push_str(" ELSE 0 END)");
    }

    // 22. featured_weight
    if w.featured_weight > 0.0 {
        begin_term(&mut out, &mut has_terms);
        out.push_str("(CASE WHEN articles.featured = TRUE THEN ");
        if !write_ruby_float(&mut out, w.featured_weight) {
            return None;
        }
        out.push_str(" ELSE 0 END)");
    }

    // 23. favorited_weight
    if w.favorited_weight > 0.0 {
        begin_term(&mut out, &mut has_terms);
        out.push_str("(CASE WHEN articles.favorited_by_user_id IS NOT NULL THEN ");
        if !write_ruby_float(&mut out, w.favorited_weight) {
            return None;
        }
        out.push_str(" ELSE 0 END)");
    }

    // 24. status_weight
    if w.status_weight > 0.0 {
        begin_term(&mut out, &mut has_terms);
        out.push_str("(CASE WHEN articles.type_of = 1 THEN ");
        if !write_ruby_float(&mut out, w.status_weight) {
            return None;
        }
        out.push_str(" ELSE 0 END)");
    }

    // 25. clickbait_score_weight
    if w.clickbait_score_weight > 0.0 {
        begin_term(&mut out, &mut has_terms);
        out.push_str("(- (articles.clickbait_score * ");
        if !write_ruby_float(&mut out, w.clickbait_score_weight) {
            return None;
        }
        out.push_str("))");
    }

    // 26. compellingness_score_weight
    if w.compellingness_score_weight > 0.0 {
        begin_term(&mut out, &mut has_terms);
        out.push_str("(articles.compellingness_score * ");
        if !write_ruby_float(&mut out, w.compellingness_score_weight) {
            return None;
        }
        out.push(')');
    }

    // 27. language_match_weight (requires score_weight > 0.0)
    if w.language_match_weight > 0.0 && w.score_weight > 0.0 {
        begin_term(&mut out, &mut has_terms);
        out.push_str("(CASE WHEN articles.language IN ('");
        if ctx.languages.is_empty() {
            out.push_str("en");
        } else {
            for (idx, lang) in ctx.languages.iter().enumerate() {
                if idx > 0 {
                    out.push_str("','");
                }
                out.push_str(lang);
            }
        }
        out.push_str("') THEN ");
        if !write_ruby_float(&mut out, w.language_match_weight) {
            return None;
        }
        out.push_str(" ELSE 0 END)");
    }

    // 28. randomness_weight
    if w.randomness_weight > 0.0 {
        begin_term(&mut out, &mut has_terms);
        let _ = write!(
            out,
            "((CASE WHEN articles.id IS NOT NULL THEN MOD((articles.id * 137 + {}), 1000) / 1000.0 ELSE 0 END) * ",
            ctx.random_seed
        );
        if !write_ruby_float(&mut out, w.randomness_weight) {
            return None;
        }
        out.push(')');
    }

    if !has_terms {
        out.push('0');
    }
    out.push(')');

    // Only run `sql_squish` if user-supplied tag/label/language strings could have introduced
    // multi-space or newline/tab whitespace.
    let needs_squish = out.as_bytes().windows(2).any(|w| {
        (w[0].is_ascii_whitespace() && w[0] != b' ')
            || (w[1].is_ascii_whitespace() && w[1] != b' ')
            || (w[0] == b' ' && w[1] == b' ')
    }) || !out.is_ascii();

    if needs_squish {
        Some(sql_squish(&out))
    } else {
        Some(out)
    }
}

/// Splits a `cached_tag_list` string on `", "` while stripping trailing empty segments.
pub fn split_cached_tag_list(cached_tag_list: &str) -> Vec<&str> {
    if cached_tag_list.is_empty() {
        return Vec::new();
    }
    let mut parts: Vec<&str> = cached_tag_list.split(", ").collect();
    while parts.last() == Some(&"") {
        parts.pop();
    }
    parts
}

/// Scores an article's `cached_tag_list` against a user's followed tags and their point values.
pub fn score_followed_tags<S: AsRef<str>>(
    cached_tag_list: &str,
    names: &[S],
    points: &[f64],
    tag_weight: f64,
    unfollowed_score: f64,
) -> Option<f64> {
    if names.len() != points.len() || !tag_weight.is_finite() || !unfollowed_score.is_finite() {
        return None;
    }
    if names.is_empty() {
        return Some(0.0);
    }
    let tags = split_cached_tag_list(cached_tag_list);
    let mut sum = 0.0_f64;
    for (name, &pts) in names.iter().zip(points.iter()) {
        if !pts.is_finite() {
            return None;
        }
        sum += if tags.contains(&name.as_ref()) {
            pts * tag_weight
        } else {
            unfollowed_score
        };
    }
    sum.is_finite().then_some(sum)
}

/// Computes the experience-level distance penalty when at least one rating is a `Float`.
#[inline]
pub fn score_experience_level(article_xp: f64, user_xp: f64, weight: f64) -> Option<f64> {
    if !article_xp.is_finite() || !user_xp.is_finite() || !weight.is_finite() {
        return None;
    }
    let score = -(((article_xp - user_xp).abs() / 2.0) * weight);
    score.is_finite().then_some(score)
}

/// Computes the experience-level distance penalty when both ratings are Ruby `Integer`s.
#[inline]
pub fn score_experience_level_int(article_xp: i64, user_xp: i64, weight: f64) -> Option<f64> {
    if !weight.is_finite() {
        return None;
    }
    let half = article_xp.checked_sub(user_xp)?.checked_abs()? / 2;
    let score = -((half as f64) * weight);
    score.is_finite().then_some(score)
}

/// Scores an article's AI disclosure level against a user's `feed_ai_preference`.
#[inline]
pub fn score_ai_disclosure(
    pref: Option<&str>,
    level: Option<&str>,
    some_penalty: f64,
    auto_penalty: f64,
) -> Option<f64> {
    if !some_penalty.is_finite() || !auto_penalty.is_finite() {
        return None;
    }
    Some(match (pref, level) {
        (Some("minimize_ai"), Some("some_ai"))
        | (Some("hide_fully_autonomous"), Some("some_ai")) => some_penalty,
        (Some("minimize_ai"), Some("fully_autonomous")) => auto_penalty,
        _ => 0.0,
    })
}

/// Pre-extracted user context and `[comment_w, xp_w, f_user, nf_user, nil_tag, f_tag_w, nf_tag, f_org, nf_org, some_ai, auto_ai]` weights.
#[derive(Debug, Clone)]
pub struct UserArticleScoreContext<'a, S: AsRef<str> = &'a str> {
    pub has_user: bool,
    pub following_user_ids: &'a [i64],
    pub following_org_ids: &'a [i64],
    pub followed_tag_names: &'a [S],
    pub followed_tag_points: &'a [f64],
    pub user_xp: (f64, bool, i64),
    pub ai_preference: Option<&'a str>,
    pub weights: [f64; 11],
}

/// Pre-extracted attributes of a single candidate article for feed scoring.
#[derive(Debug, Clone)]
pub struct ArticleScoreInput<'a> {
    pub user_id: Option<i64>,
    pub organization_id: Option<i64>,
    pub cached_tag_list: &'a str,
    pub xp: (f64, bool, i64),
    pub comments_count: i64,
    pub ai_disclosure_level: Option<&'a str>,
    pub base_article_points: f64,
}

fn score_shared<S: AsRef<str>>(
    ctx: &UserArticleScoreContext<'_, S>,
    a: &ArticleScoreInput<'_>,
) -> Option<[f64; 4]> {
    let w = &ctx.weights;
    if !w[2].is_finite()
        || !w[3].is_finite()
        || !w[4].is_finite()
        || !w[7].is_finite()
        || !w[8].is_finite()
    {
        return None;
    }
    let u = if a
        .user_id
        .is_some_and(|id| ctx.following_user_ids.contains(&id))
    {
        w[2]
    } else {
        w[3]
    };
    let o = if a
        .organization_id
        .is_some_and(|id| id != 0 && ctx.following_org_ids.contains(&id))
    {
        w[7]
    } else {
        w[8]
    };
    let t = if ctx.has_user {
        score_followed_tags(
            a.cached_tag_list,
            ctx.followed_tag_names,
            ctx.followed_tag_points,
            w[5],
            w[6],
        )?
    } else {
        w[4]
    };
    let ai = if ctx.has_user {
        score_ai_disclosure(ctx.ai_preference, a.ai_disclosure_level, w[9], w[10])?
    } else {
        0.0
    };
    Some([u, o, t, ai])
}

/// Computes the 6-component composite score for `LargeForemExperimental#score_single_article`.
pub fn score_article_for_user<S: AsRef<str>>(
    ctx: &UserArticleScoreContext<'_, S>,
    a: &ArticleScoreInput<'_>,
) -> Option<f64> {
    if !a.base_article_points.is_finite() || !ctx.weights[0].is_finite() {
        return None;
    }
    let [u, o, t, ai] = score_shared(ctx, a)?;
    let xp = if a.xp.1 && ctx.user_xp.1 {
        score_experience_level_int(a.xp.2, ctx.user_xp.2, ctx.weights[1])?
    } else {
        score_experience_level(a.xp.0, ctx.user_xp.0, ctx.weights[1])?
    };
    let c = (a.comments_count as f64) * ctx.weights[0];
    let total = a.base_article_points + u + o + t + xp + c + ai;
    (c.is_finite() && total.is_finite()).then_some(total)
}

fn cruby_sift_down(arr: &mut [(f64, usize)], mut root: usize, n: usize) {
    let tmp = arr[root];
    while 2 * root + 1 < n {
        let mut child = 2 * root + 1;
        if child + 1 < n && arr[child].0 < arr[child + 1].0 {
            child += 1;
        }
        if tmp.0 >= arr[child].0 {
            break;
        }
        arr[root] = arr[child];
        root = child;
    }
    arr[root] = tmp;
}

/// Matches CRuby 3.3 `rb_uniform_quicksort_intro_2` (`enum.c`) used by `Enumerable#sort_by`.
fn cruby_introsort(arr: &mut [(f64, usize)], mut depth: usize) {
    let mut hi = arr.len();
    while hi > 16 {
        if depth == 0 {
            for i in (0..(hi / 2)).rev() {
                cruby_sift_down(arr, i, hi);
            }
            for i in (1..hi).rev() {
                arr.swap(0, i);
                cruby_sift_down(arr, 0, i);
            }
            return;
        }
        depth -= 1;
        let (a, b, c) = (arr[0].0, arr[hi / 2].0, arr[hi - 1].0);
        let pivot = if a < b {
            if b < c {
                b
            } else if c < a {
                a
            } else {
                c
            }
        } else if c < b {
            b
        } else if a < c {
            a
        } else {
            c
        };
        let (mut left, mut right) = (0, hi - 1);
        loop {
            while arr[left].0 < pivot {
                left += 1;
            }
            while arr[right].0 > pivot {
                right -= 1;
            }
            if right < left {
                break;
            }
            arr.swap(left, right);
            left += 1;
            if right == 0 || right - 1 < left {
                right = right.wrapping_sub(1);
                break;
            }
            right -= 1;
        }
        let right_start = right.wrapping_add(1);
        if hi - right_start > 1 {
            cruby_introsort(&mut arr[right_start..hi], depth);
        }
        hi = left;
    }
    for i in 1..hi {
        let tmp = arr[i];
        let mut j = i;
        while j > 0 && arr[j - 1].0 > tmp.0 {
            arr[j] = arr[j - 1];
            j -= 1;
        }
        arr[j] = tmp;
    }
}

/// Computes the sorted index permutation for `Articles::Feeds::Basic#default_home_feed`.
pub fn rank_basic_feed_indices<S: AsRef<str>>(
    ctx: &UserArticleScoreContext<'_, S>,
    articles: &[ArticleScoreInput<'_>],
) -> Option<Vec<usize>> {
    let mut keyed: Vec<(f64, usize)> = Vec::with_capacity(articles.len());
    for (idx, a) in articles.iter().enumerate() {
        let [u, o, t, ai] = score_shared(ctx, a)?;
        let score = t + o + u + ai - (idx as f64);
        if !score.is_finite() {
            return None;
        }
        keyed.push((score, idx));
    }
    if keyed.len() > 1 && keyed.windows(2).any(|w| w[0].0 > w[1].0) {
        let depth = 2 * ((usize::BITS - 1 - keyed.len().leading_zeros()) as usize);
        cruby_introsort(&mut keyed, depth);
    }
    Some(keyed.into_iter().rev().map(|(_, idx)| idx).collect())
}

/// Filters `(article_id, time_tracked_in_seconds)` pageview pairs where `seconds > min_seconds_exclusive`.
pub fn filter_tracked_article_ids(entries: &[(i64, f64)], min_sec: f64) -> Option<Vec<i64>> {
    if !min_sec.is_finite() || entries.iter().any(|&(_, s)| !s.is_finite()) {
        return None;
    }
    Some(
        entries
            .iter()
            .filter_map(|&(id, s)| (s > min_sec).then_some(id))
            .collect(),
    )
}

/// Tag source for an article in `aggregate_recent_activity_metadata`.
#[derive(Debug, Clone)]
pub enum ArticleTagSource<'a> {
    CommaSeparated(&'a str),
    PreSplit(&'a [String]),
}

/// Aggregates `(recent_tags, recent_labels, recent_organizations, recent_users, recent_subforems)`.
#[allow(clippy::type_complexity)]
pub fn aggregate_recent_activity_metadata(
    tag_sources: &[ArticleTagSource<'_>],
    label_lists: &[Vec<String>],
    org_ids: &[Option<i64>],
    user_ids: &[Option<i64>],
    subforem_ids: &[Option<i64>],
    max_labels: usize,
) -> (Vec<String>, Vec<String>, Vec<i64>, Vec<i64>, Vec<i64>) {
    let mut tags: Vec<String> = Vec::new();
    for src in tag_sources {
        match src {
            ArticleTagSource::CommaSeparated(s) => {
                for t in split_cached_tag_list(s) {
                    if !tags.iter().any(|x| x == t) {
                        tags.push(t.to_owned());
                    }
                }
            }
            ArticleTagSource::PreSplit(list) => {
                for t in list.iter() {
                    if !tags.contains(t) {
                        tags.push(t.clone());
                    }
                }
            }
        }
    }
    let mut labels: Vec<String> = Vec::with_capacity(max_labels);
    if max_labels > 0 {
        'lbl: for list in label_lists {
            for l in list {
                if !labels.contains(l) {
                    labels.push(l.clone());
                    if labels.len() >= max_labels {
                        break 'lbl;
                    }
                }
            }
        }
    }
    let dedup_i64 = |items: &[Option<i64>]| -> Vec<i64> {
        let mut out = Vec::new();
        for &id in items.iter().flatten() {
            if !out.contains(&id) {
                out.push(id);
            }
        }
        out
    };
    (
        tags,
        labels,
        dedup_i64(org_ids),
        dedup_i64(user_ids),
        subforem_ids.iter().copied().flatten().collect(),
    )
}

/// Scores and orders subforem IDs for `UserDecorator#ordered_subforems`.
pub fn order_subforem_ids(recent: &[i64], followed: &[i64], discoverable: &[i64]) -> Vec<i64> {
    let mut scored: Vec<(i64, i64)> = Vec::with_capacity(recent.len() + followed.len());
    for (&id, d) in recent
        .iter()
        .map(|i| (i, 1_i64))
        .chain(followed.iter().map(|i| (i, 10_i64)))
    {
        if let Some(e) = scored.iter_mut().find(|(k, _)| *k == id) {
            e.1 = e.1.saturating_add(d);
        } else {
            scored.push((id, d));
        }
    }
    scored.sort_by_key(|a| std::cmp::Reverse(a.1));
    let mut out: Vec<i64> = scored.iter().map(|&(id, _)| id).collect();
    for &id in discoverable {
        if !scored.iter().any(|&(sid, _)| sid == id) {
            out.push(id);
        }
    }
    out
}

/// Parses a strict 10-byte ISO-8601 date `"YYYY-MM-DD"` into days since `1970-01-01`.
#[inline]
pub fn parse_iso_date_days(bytes: &[u8]) -> Option<i64> {
    if bytes.len() != 10 || bytes[4] != b'-' || bytes[7] != b'-' {
        return None;
    }
    let (y, m, d) = (
        parse_4_digits(bytes, 0)?,
        parse_2_digits(bytes, 5)?,
        parse_2_digits(bytes, 8)?,
    );
    ((1..=12).contains(&m) && d >= 1 && d <= days_in_month(y, m)).then(|| days_from_civil(y, m, d))
}

/// Formats days since `1970-01-01` as an ISO-8601 `"YYYY-MM-DD"` string.
#[inline]
pub fn format_iso_date_days(days: i64) -> String {
    let (y, m, d) = civil_from_days(days);
    format!("{y:04}-{m:02}-{d:02}")
}

/// Complete payload structure returned by `UserActivityHeatmapService#build_payload`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HeatmapPayload {
    pub start_date: String,
    pub end_date: String,
    pub days: Vec<(String, i64, i64, i64, i64)>,
    pub totals: [i64; 4],
    pub max: i64,
}

fn populate_heatmap_buckets(
    entries: &[(i64, i64)],
    start_days: i64,
    window_len: usize,
    buckets: &mut [i64],
) -> Option<i64> {
    let mut deduped: Vec<(i64, i64)> = Vec::with_capacity(entries.len());
    for &(day, count) in entries {
        if let Some(e) = deduped.iter_mut().find(|(d, _)| *d == day) {
            e.1 = count;
        } else {
            deduped.push((day, count));
        }
    }
    let mut sum = 0_i64;
    for &(day, count) in &deduped {
        sum = sum.checked_add(count)?;
        if day >= start_days && ((day - start_days) as usize) < window_len {
            buckets[(day - start_days) as usize] = count;
        }
    }
    Some(sum)
}

/// Builds the complete daily activity heatmap rows, totals, and maximum.
pub fn build_activity_heatmap(
    start_days: i64,
    end_days: i64,
    articles: &[(i64, i64)],
    comments: &[(i64, i64)],
    reactions: &[(i64, i64)],
) -> Option<HeatmapPayload> {
    let window_len = if end_days < start_days {
        0
    } else {
        let diff = end_days.checked_sub(start_days)?;
        if diff > 10_000 {
            return None;
        }
        (diff as usize) + 1
    };
    let (mut ab, mut cb, mut rb) = (
        vec![0_i64; window_len],
        vec![0_i64; window_len],
        vec![0_i64; window_len],
    );
    let ta = populate_heatmap_buckets(articles, start_days, window_len, &mut ab)?;
    let tc = populate_heatmap_buckets(comments, start_days, window_len, &mut cb)?;
    let tr = populate_heatmap_buckets(reactions, start_days, window_len, &mut rb)?;
    let tall = ta.checked_add(tc)?.checked_add(tr)?;
    let mut days = Vec::with_capacity(window_len);
    let mut max = 0_i64;
    for i in 0..window_len {
        let total = ab[i].checked_add(cb[i])?.checked_add(rb[i])?;
        if i == 0 || total > max {
            max = total;
        }
        days.push((
            format_iso_date_days(start_days + (i as i64)),
            ab[i],
            cb[i],
            rb[i],
            total,
        ));
    }
    Some(HeatmapPayload {
        start_date: format_iso_date_days(start_days),
        end_date: format_iso_date_days(end_days),
        days,
        totals: [ta, tc, tr, tall],
        max,
    })
}

#[inline]
const fn is_ascii_regex_space(b: u8) -> bool {
    matches!(b, b' ' | b'\t' | b'\n' | b'\r' | 0x0B | 0x0C)
}

#[inline]
const fn is_xml_space_or_delim(b: u8) -> bool {
    matches!(b, b'>' | b'/' | b' ' | b'\t' | b'\n' | b'\r')
}

fn skip_xml_tag_close(bytes: &[u8], mut i: usize) -> Option<usize> {
    let mut quote = 0_u8;
    while i < bytes.len() {
        let b = bytes[i];
        if quote != 0 {
            if b == quote {
                quote = 0;
            }
        } else if b == b'"' || b == b'\'' {
            quote = b;
        } else if b == b'>' {
            return Some(i);
        }
        i += 1;
    }
    None
}

fn match_xml_open_tag(bytes: &[u8], pos: usize, tag: &[u8]) -> Option<usize> {
    let start = pos + 1;
    let end = start.checked_add(tag.len())?;
    if end >= bytes.len() || !bytes[start..end].eq_ignore_ascii_case(tag) {
        return None;
    }
    if !is_xml_space_or_delim(bytes[end]) {
        return None;
    }
    skip_xml_tag_close(bytes, end)
}

fn match_xml_close_tag(bytes: &[u8], pos: usize, tag: &[u8]) -> Option<usize> {
    let start = pos + 2;
    let end = start.checked_add(tag.len())?;
    if end >= bytes.len() || bytes[pos + 1] != b'/' || !bytes[start..end].eq_ignore_ascii_case(tag)
    {
        return None;
    }
    let mut k = end;
    while k < bytes.len() && matches!(bytes[k], b' ' | b'\t' | b'\n' | b'\r') {
        k += 1;
    }
    (k < bytes.len() && bytes[k] == b'>').then_some(k)
}

fn find_subslice(haystack: &[u8], start: usize, needle: &[u8]) -> Option<usize> {
    haystack
        .get(start..)?
        .windows(needle.len())
        .position(|w| w == needle)
        .map(|off| start + off)
}

/// Truncates an RSS (`<item>...</item>`) or Atom (`<entry>...</entry>`) XML feed string
/// to at most `max_items` items, preserving all non-item XML structure (prolog, channel
/// metadata, and closing tags). Returns `Cow::Borrowed(xml)` with zero allocations when
/// the feed already contains `<= max_items` items or has unclosed tags.
pub fn truncate_feed_xml_items(xml: &str, max_items: usize) -> Cow<'_, str> {
    if max_items == 0 {
        return Cow::Borrowed(xml);
    }
    let bytes = xml.as_bytes();
    let mut tag_kind: Option<&'static [u8]> = None;
    let mut count = 0_usize;
    let mut excess_ranges: Vec<(usize, usize)> = Vec::new();
    let mut i = 0;

    while i < bytes.len() {
        if bytes[i] != b'<' {
            i += 1;
            continue;
        }
        if bytes[i..].starts_with(b"<!--") {
            let Some(end) = find_subslice(bytes, i + 4, b"-->") else {
                return Cow::Borrowed(xml);
            };
            i = end + 3;
            continue;
        }
        if bytes[i..].starts_with(b"<![CDATA[") {
            let Some(end) = find_subslice(bytes, i + 9, b"]]>") else {
                return Cow::Borrowed(xml);
            };
            i = end + 3;
            continue;
        }

        let matched = match tag_kind {
            Some(tk) => match_xml_open_tag(bytes, i, tk).map(|gt| (tk, gt)),
            None => match_xml_open_tag(bytes, i, b"item")
                .map(|gt| (&b"item"[..], gt))
                .or_else(|| match_xml_open_tag(bytes, i, b"entry").map(|gt| (&b"entry"[..], gt))),
        };
        let Some((tk, open_gt)) = matched else {
            i += 1;
            continue;
        };
        tag_kind = Some(tk);
        let item_start = i;

        let item_end = if bytes[open_gt - 1] == b'/' {
            open_gt + 1
        } else {
            let mut depth = 1_usize;
            let mut j = open_gt + 1;
            let mut close_end = None;
            while j < bytes.len() {
                if bytes[j] != b'<' {
                    j += 1;
                    continue;
                }
                if bytes[j..].starts_with(b"<!--") {
                    let Some(end) = find_subslice(bytes, j + 4, b"-->") else {
                        return Cow::Borrowed(xml);
                    };
                    j = end + 3;
                    continue;
                }
                if bytes[j..].starts_with(b"<![CDATA[") {
                    let Some(end) = find_subslice(bytes, j + 9, b"]]>") else {
                        return Cow::Borrowed(xml);
                    };
                    j = end + 3;
                    continue;
                }
                if let Some(cgt) = match_xml_close_tag(bytes, j, tk) {
                    depth -= 1;
                    if depth == 0 {
                        close_end = Some(cgt + 1);
                        break;
                    }
                    j = cgt + 1;
                    continue;
                }
                if let Some(ogt) = match_xml_open_tag(bytes, j, tk) {
                    if bytes[ogt - 1] != b'/' {
                        depth += 1;
                    }
                    j = ogt + 1;
                    continue;
                }
                j += 1;
            }
            let Some(ce) = close_end else {
                return Cow::Borrowed(xml);
            };
            ce
        };

        count += 1;
        if count > max_items {
            excess_ranges.push((item_start, item_end));
        }
        i = item_end;
    }

    if excess_ranges.is_empty() {
        return Cow::Borrowed(xml);
    }

    let removed_bytes: usize = excess_ranges.iter().map(|(s, e)| e - s).sum();
    let mut out = String::with_capacity(xml.len().saturating_sub(removed_bytes));
    let mut cursor = 0;
    for (start, end) in excess_ranges {
        out.push_str(&xml[cursor..start]);
        cursor = end;
    }
    out.push_str(&xml[cursor..]);
    Cow::Owned(out)
}

fn match_html_block_tag_after_lt(bytes: &[u8], after_lt: usize) -> bool {
    const TAGS: [&[u8]; 10] = [
        b"blockquote",
        b"section",
        b"figure",
        b"table",
        b"div",
        b"pre",
        b"ul",
        b"ol",
        b"li",
        b"p",
    ];
    let mut i = after_lt;
    while i < bytes.len() && is_ascii_regex_space(bytes[i]) {
        i += 1;
    }
    let rem = &bytes[i..];
    if rem.len() >= 3
        && (rem[0] == b'h' || rem[0] == b'H')
        && (b'1'..=b'6').contains(&rem[1])
        && (rem[2] == b'>' || is_ascii_regex_space(rem[2]))
    {
        return true;
    }
    for tag in TAGS {
        if rem.len() > tag.len()
            && rem[..tag.len()].eq_ignore_ascii_case(tag)
            && (rem[tag.len()] == b'>' || is_ascii_regex_space(rem[tag.len()]))
        {
            return true;
        }
    }
    false
}

/// Checks whether feed item `content` is predominantly HTML rather than Markdown/plain text,
/// matching `Feeds::AssembleArticleMarkdown#html_content?`:
/// counts `/<\s*(p|div|h[1-6]|ul|ol|li|blockquote|pre|table|section|figure)[\s>]/i` matches
/// vs. `/\n\s*\n/` paragraph breaks in a single zero-allocation pass.
pub fn feed_html_content(content: &str) -> bool {
    let bytes = content.as_bytes();
    let mut block_tag_count = 0_usize;
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'<' && match_html_block_tag_after_lt(bytes, i + 1) {
            block_tag_count += 1;
        }
        i += 1;
    }
    if block_tag_count == 0 {
        return false;
    }

    let mut paragraph_breaks = 0_usize;
    let mut j = 0;
    while j < bytes.len() {
        if is_ascii_regex_space(bytes[j]) {
            let mut newlines = 0_usize;
            while j < bytes.len() && is_ascii_regex_space(bytes[j]) {
                if bytes[j] == b'\n' {
                    newlines += 1;
                }
                j += 1;
            }
            if newlines >= 2 {
                paragraph_breaks += 1;
            }
        } else {
            j += 1;
        }
    }

    block_tag_count > paragraph_breaks
}

fn match_youtube_liquid_tag(text: &str) -> Option<usize> {
    let bytes = text.as_bytes();
    if bytes.len() < 26 || !bytes.starts_with(b"{%") || !is_ascii_regex_space(bytes[2]) {
        return None;
    }
    if !bytes[3..].starts_with(b"youtube") || !is_ascii_regex_space(bytes[10]) {
        return None;
    }
    let inner_start = 11;
    let mut char_ends: [usize; 19] = [0; 19];
    let mut count = 0_usize;
    for (off, ch) in text[inner_start..].char_indices() {
        if ch == '\n' {
            break;
        }
        count += 1;
        char_ends[count] = inner_start + off + ch.len_utf8();
        if count == 18 {
            break;
        }
    }
    if count < 11 {
        return None;
    }
    for k in (11..=count).rev() {
        let pos = char_ends[k];
        if pos + 3 <= bytes.len()
            && is_ascii_regex_space(bytes[pos])
            && bytes[pos + 1] == b'%'
            && bytes[pos + 2] == b'}'
        {
            return Some(pos + 3);
        }
    }
    None
}

/// Fuses the three post-`ReverseMarkdown` normalizations in
/// `Feeds::AssembleArticleMarkdown#assemble_body_markdown`:
/// 1. Strips `"```\n\n```"`
/// 2. Replaces `"&nbsp;"` and `"\u{00A0}"` with `" "`
/// 3. Unescapes `\_` to `_` inside `/{%\syoutube\s(.{11,18})\s%}/` tags.
pub fn postprocess_feed_markdown(content: &str) -> Cow<'_, str> {
    let has_empty_fence = content.contains("```\n\n```");
    let has_nbsp = content.contains("&nbsp;") || content.contains('\u{00A0}');
    let has_yt = content.contains("{%") && content.contains("\\_");
    if !has_empty_fence && !has_nbsp && !has_yt {
        return Cow::Borrowed(content);
    }

    let step1: Cow<'_, str> = if has_empty_fence {
        Cow::Owned(content.replace("```\n\n```", ""))
    } else {
        Cow::Borrowed(content)
    };

    let step2: Cow<'_, str> = if step1.contains("&nbsp;") || step1.contains('\u{00A0}') {
        let s = step1.as_ref();
        let bytes = s.as_bytes();
        let mut out = String::with_capacity(s.len());
        let mut last = 0;
        let mut i = 0;
        while i < bytes.len() {
            if bytes[i..].starts_with(b"&nbsp;") {
                out.push_str(&s[last..i]);
                out.push(' ');
                i += 6;
                last = i;
            } else if bytes[i..].starts_with(&[0xC2, 0xA0]) {
                out.push_str(&s[last..i]);
                out.push(' ');
                i += 2;
                last = i;
            } else {
                i += 1;
            }
        }
        out.push_str(&s[last..]);
        Cow::Owned(out)
    } else {
        step1
    };

    if !(step2.contains("{%") && step2.contains("\\_")) {
        return step2;
    }

    let s = step2.as_ref();
    let bytes = s.as_bytes();
    let mut out: Option<String> = None;
    let mut last = 0;
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'{' {
            if let Some(tag_len) = match_youtube_liquid_tag(&s[i..]) {
                let tag = &s[i..i + tag_len];
                if tag.contains("\\_") {
                    let buf = out.get_or_insert_with(|| String::with_capacity(s.len()));
                    buf.push_str(&s[last..i]);
                    buf.push_str(&tag.replace("\\_", "_"));
                    i += tag_len;
                    last = i;
                    continue;
                }
                i += tag_len;
                continue;
            }
        }
        i += 1;
    }

    match out {
        Some(mut buf) => {
            buf.push_str(&s[last..]);
            Cow::Owned(buf)
        }
        None => step2,
    }
}

fn is_clean_url_token(s: &str) -> bool {
    !s.is_empty() && s.bytes().all(|b| (0x21..0x7F).contains(&b))
}

fn validate_simple_base_origin(base_url: &str) -> bool {
    if !is_clean_url_token(base_url) {
        return false;
    }
    let Some(rest) = base_url
        .strip_prefix("https://")
        .or_else(|| base_url.strip_prefix("http://"))
    else {
        return false;
    };
    !rest.is_empty() && !rest.contains(['/', '?', '#'])
}

fn resolve_simple_feed_path(
    base_url: &str,
    feed_source_url: &str,
    path: &str,
) -> Option<Option<String>> {
    if path.starts_with("http://") || path.starts_with("https://") {
        return Some(None);
    }
    if !is_clean_url_token(path)
        || path.starts_with("//")
        || path.contains([':', '?', '#', '\\'])
        || path.split('/').any(|seg| seg == "." || seg == "..")
    {
        return None;
    }
    if path.starts_with('/') {
        if !validate_simple_base_origin(base_url) {
            return None;
        }
        let mut joined = String::with_capacity(base_url.len() + path.len());
        joined.push_str(base_url);
        joined.push_str(path);
        return Some(Some(joined));
    }

    if !is_clean_url_token(feed_source_url) || feed_source_url.contains(['?', '#', '\\']) {
        return None;
    }
    let rest = feed_source_url
        .strip_prefix("https://")
        .or_else(|| feed_source_url.strip_prefix("http://"))?;
    if rest.is_empty() || rest.starts_with('/') {
        return None;
    }
    let scheme_host_offset = feed_source_url.len() - rest.len();
    let dir_prefix = match rest.rfind('/') {
        Some(slash_idx) => &feed_source_url[..scheme_host_offset + slash_idx + 1],
        None => return None,
    };
    if dir_prefix[scheme_host_offset..]
        .split('/')
        .any(|seg| seg == "." || seg == "..")
    {
        return None;
    }
    let mut joined = String::with_capacity(dir_prefix.len() + path.len());
    joined.push_str(dir_prefix);
    joined.push_str(path);
    Some(Some(joined))
}

/// Resolves relative URLs in inline `<img ... src="...">` tags and Markdown `![alt](path)`
/// image syntax in a single native call, matching
/// `Feeds::AssembleArticleMarkdown#resolve_relative_image_urls`.
/// Returns `None` if a relative URL requires Ruby's `URI.join` (dot segments, queries, ...).
pub fn resolve_feed_markdown_images<'a>(
    content: &'a str,
    base_url: &str,
    feed_source_url: &str,
) -> Option<Cow<'a, str>> {
    let has_img = content.contains("<img");
    let has_md = content.contains("![");
    if !has_img && !has_md {
        return Some(Cow::Borrowed(content));
    }

    let stage1: Cow<'a, str> = if has_img {
        let bytes = content.as_bytes();
        let mut out: Option<String> = None;
        let mut last = 0;
        let mut i = 0;
        while i + 5 < bytes.len() {
            if bytes[i..].starts_with(b"<img") && is_ascii_regex_space(bytes[i + 4]) {
                let mut k = i + 5;
                let mut matched = None;
                while k < bytes.len() && bytes[k] != b'>' {
                    if bytes[k..].starts_with(b"src=\"") || bytes[k..].starts_with(b"src='") {
                        let path_start = k + 5;
                        let mut p = path_start;
                        while p < bytes.len() && bytes[p] != b'"' && bytes[p] != b'\'' {
                            p += 1;
                        }
                        if p > path_start && p < bytes.len() {
                            matched = Some((path_start, p));
                        }
                        break;
                    }
                    k += 1;
                }
                if let Some((path_start, path_end)) = matched {
                    let path = &content[path_start..path_end];
                    if let Some(resolved) =
                        resolve_simple_feed_path(base_url, feed_source_url, path)?
                    {
                        let buf =
                            out.get_or_insert_with(|| String::with_capacity(content.len() + 64));
                        buf.push_str(&content[last..path_start]);
                        buf.push_str(&resolved);
                        buf.push(bytes[path_end] as char);
                        i = path_end + 1;
                        last = i;
                        continue;
                    }
                    i = path_end + 1;
                    continue;
                }
            }
            i += 1;
        }
        match out {
            Some(mut buf) => {
                buf.push_str(&content[last..]);
                Cow::Owned(buf)
            }
            None => Cow::Borrowed(content),
        }
    } else {
        Cow::Borrowed(content)
    };

    if !stage1.contains("![") {
        return Some(stage1);
    }

    let s = stage1.as_ref();
    let bytes = s.as_bytes();
    let mut out: Option<String> = None;
    let mut last = 0;
    let mut i = 0;
    while i + 4 < bytes.len() {
        if bytes[i] == b'!' && bytes[i + 1] == b'[' {
            let mut close_br = i + 2;
            while close_br < bytes.len() && bytes[close_br] != b']' {
                close_br += 1;
            }
            if close_br + 2 < bytes.len() && bytes[close_br + 1] == b'(' {
                let path_start = close_br + 2;
                let mut close_paren = path_start;
                while close_paren < bytes.len() && bytes[close_paren] != b')' {
                    close_paren += 1;
                }
                if close_paren > path_start && close_paren < bytes.len() {
                    let path = &s[path_start..close_paren];
                    if let Some(resolved) =
                        resolve_simple_feed_path(base_url, feed_source_url, path)?
                    {
                        let buf = out.get_or_insert_with(|| String::with_capacity(s.len() + 64));
                        buf.push_str(&s[last..path_start]);
                        buf.push_str(&resolved);
                        buf.push(')');
                        i = close_paren + 1;
                        last = i;
                        continue;
                    }
                    i = close_paren + 1;
                    continue;
                }
            }
        }
        i += 1;
    }

    match out {
        Some(mut buf) => {
            buf.push_str(&s[last..]);
            Some(Cow::Owned(buf))
        }
        None => Some(stage1),
    }
}

/// Formats up to 4 RSS/Atom category tags by stripping spaces and non-alphanumeric
/// characters and truncating each to 20 characters, matching
/// `Feeds::AssembleArticleMarkdown#get_tags`.
/// Returns `None` if any of the first 4 tags contains non-ASCII bytes so Ruby's
/// `[[:alnum:]]` regex handles Unicode letters identically.
pub fn format_feed_tags<S: AsRef<str>>(categories: &[S]) -> Option<String> {
    let take = categories.len().min(4);
    if take == 0 {
        return Some(String::new());
    }
    for cat in &categories[..take] {
        if !cat.as_ref().is_ascii() {
            return None;
        }
    }
    let mut out = String::with_capacity(take * 21);
    for (idx, cat) in categories[..take].iter().enumerate() {
        if idx > 0 {
            out.push(',');
        }
        let mut count = 0_usize;
        for &b in cat.as_ref().as_bytes() {
            if b.is_ascii_alphanumeric() {
                out.push(b as char);
                count += 1;
                if count == 20 {
                    break;
                }
            }
        }
    }
    Some(out)
}

#[inline]
const fn is_email_word_char(b: u8) -> bool {
    b.is_ascii_alphanumeric() || b == b'_'
}

#[inline]
const fn is_email_local_char(b: u8) -> bool {
    is_email_word_char(b) || matches!(b, b'.' | b'+' | b'-')
}

#[inline]
const fn is_email_domain_char(b: u8) -> bool {
    is_email_word_char(b) || matches!(b, b'.' | b'-')
}

/// Extracts `(email, name)` from an RSS/Atom author string in a single pass, matching:
/// - `email = author_string[/[\w.+-]+@[\w.-]+\.\w+/]`
/// - `name = author_string.sub(/<[^>]+>/, "").strip`
///
/// Returns `None` if `author_string` contains non-ASCII bytes.
pub fn extract_feed_author(author_string: &str) -> Option<(Option<String>, String)> {
    if !author_string.is_ascii() {
        return None;
    }
    let bytes = author_string.as_bytes();
    let mut email: Option<String> = None;
    let mut i = 0;
    while i < bytes.len() {
        if is_email_local_char(bytes[i]) {
            let local_start = i;
            while i < bytes.len() && is_email_local_char(bytes[i]) {
                i += 1;
            }
            if i < bytes.len() && bytes[i] == b'@' {
                let dom_start = i + 1;
                let mut k = dom_start;
                while k < bytes.len() && is_email_domain_char(bytes[k]) {
                    k += 1;
                }
                let segment = &bytes[dom_start..k];
                if let Some(dot_rel) = segment.iter().rposition(|&b| b == b'.') {
                    if dot_rel > 0
                        && dot_rel + 1 < segment.len()
                        && segment[dot_rel + 1..]
                            .iter()
                            .all(|&b| is_email_word_char(b))
                    {
                        email =
                            Some(author_string[local_start..dom_start + k - dom_start].to_string());
                        break;
                    }
                }
            }
        } else {
            i += 1;
        }
    }

    let name_untrimmed: Cow<'_, str> = if let Some(lt) = bytes.iter().position(|&b| b == b'<') {
        if let Some(gt_rel) = bytes[lt + 1..].iter().position(|&b| b == b'>') {
            if gt_rel > 0 {
                let gt = lt + 1 + gt_rel;
                let mut s = String::with_capacity(author_string.len() - (gt - lt + 1));
                s.push_str(&author_string[..lt]);
                s.push_str(&author_string[gt + 1..]);
                Cow::Owned(s)
            } else {
                Cow::Borrowed(author_string)
            }
        } else {
            Cow::Borrowed(author_string)
        }
    } else {
        Cow::Borrowed(author_string)
    };

    let trimmed = name_untrimmed
        .trim_matches(|c: char| matches!(c as u32, 0x09..=0x0D | 0x20 | 0x00))
        .to_string();
    Some((email, trimmed))
}

#[inline]
const fn is_rb_path_char(b: u8) -> bool {
    is_email_word_char(b) || matches!(b, b'/' | b'.' | b'-')
}

/// Replaces Ruby file/line references matching `/\/[\w\/.-]+\.rb:\d+/` with `"[path]"`
/// and truncates to 500 characters (`...`), matching `Feeds::Import#sanitize_error`.
pub fn sanitize_feed_error(message: &str) -> String {
    let bytes = message.as_bytes();
    let mut scrubbed = String::with_capacity(message.len().min(512));
    let mut last = 0;
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'/' {
            let mut k = i + 1;
            while k < bytes.len() && is_rb_path_char(bytes[k]) {
                k += 1;
            }
            let path_slice = &bytes[i + 1..k];
            if let Some(rb_rel) = (0..path_slice.len().saturating_sub(2))
                .rev()
                .find(|&p| p > 0 && &path_slice[p..p + 3] == b".rb")
            {
                let after_rb = i + 1 + rb_rel + 3;
                if after_rb + 1 < bytes.len()
                    && bytes[after_rb] == b':'
                    && bytes[after_rb + 1].is_ascii_digit()
                {
                    let mut d = after_rb + 2;
                    while d < bytes.len() && bytes[d].is_ascii_digit() {
                        d += 1;
                    }
                    scrubbed.push_str(&message[last..i]);
                    scrubbed.push_str("[path]");
                    i = d;
                    last = i;
                    continue;
                }
            }
        }
        i += 1;
    }
    scrubbed.push_str(&message[last..]);

    if scrubbed.chars().count() <= 500 {
        return scrubbed;
    }
    let end_byte = scrubbed
        .char_indices()
        .nth(497)
        .map_or(scrubbed.len(), |(idx, _)| idx);
    scrubbed.truncate(end_byte);
    scrubbed.push_str("...");
    scrubbed
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn civil_date_round_trip() {
        assert_eq!(days_from_civil(1970, 1, 1), 0);
        assert_eq!(civil_from_days(0), (1970, 1, 1));

        assert_eq!(days_from_civil(2026, 10, 27), 20_753);
        assert_eq!(civil_from_days(20_753), (2026, 10, 27));

        // Leap day 2024-02-29
        let leap = days_from_civil(2024, 2, 29);
        assert_eq!(civil_from_days(leap), (2024, 2, 29));
        assert_eq!(civil_from_days(leap + 1), (2024, 3, 1));
    }

    #[test]
    fn parse_timestamp_formats() {
        let utc = parse_timestamp(b"2026-10-27T14:23:45Z").unwrap();
        assert_eq!(format_utc_db_timestamp(utc.utc_sec), "2026-10-27 14:23:45");
        assert_eq!(utc.subsec_nanos, 0);
        assert_eq!(utc.local_days, days_from_civil(2026, 10, 27));

        let frac = parse_timestamp(b"2026-10-27T14:23:45.125Z").unwrap();
        assert_eq!(frac.utc_sec, utc.utc_sec);
        assert_eq!(frac.subsec_nanos, 125_000_000);

        // With -04:00 offset: local time 2026-10-27 10:23:45-04:00 == 2026-10-27 14:23:45Z
        let offset = parse_timestamp(b"2026-10-27T10:23:45-04:00").unwrap();
        assert_eq!(offset.utc_sec, utc.utc_sec);
        assert_eq!(offset.local_days, days_from_civil(2026, 10, 27));

        // Late-night local time that crosses UTC midnight preserves local calendar day
        let late_local = parse_timestamp(b"2026-10-27T22:30:00-04:00").unwrap();
        assert_eq!(late_local.local_days, days_from_civil(2026, 10, 27));
        assert_eq!(
            format_utc_db_timestamp(late_local.utc_sec),
            "2026-10-28 02:30:00"
        );

        // SQL format
        let sql_fmt = parse_timestamp(b"2026-10-27 14:23:45 UTC").unwrap();
        assert_eq!(sql_fmt.utc_sec, utc.utc_sec);

        // Date-only format
        let date_only = parse_timestamp(b"2026-10-27").unwrap();
        assert_eq!(
            format_utc_db_timestamp(date_only.utc_sec),
            "2026-10-27 00:00:00"
        );

        // Invalid formats
        assert!(parse_timestamp(b"not-a-timestamp").is_none());
        assert!(parse_timestamp(b"2026-02-29T00:00:00Z").is_none()); // 2026 is not a leap year
        assert!(parse_timestamp(b"2026-13-01T00:00:00Z").is_none());
        assert!(parse_timestamp(b"2026-10-27T25:00:00Z").is_none());
    }

    #[test]
    fn activity_days_and_pageviews_window() {
        let d1 = parse_timestamp(b"2026-10-27T12:00:00Z").unwrap();
        let d1_dup = parse_timestamp(b"2026-10-27T18:00:00Z").unwrap();
        let d2 = parse_timestamp(b"2026-10-25T09:00:00Z").unwrap();
        let d3 = parse_timestamp(b"2026-10-22T15:00:00Z").unwrap();
        let old = parse_timestamp(b"2026-10-15T12:00:00Z").unwrap();
        let cutoff = parse_timestamp(b"2026-10-20T12:00:00Z").unwrap();

        let entries = [d1, d1_dup, d2, d3, old];
        assert_eq!(count_distinct_activity_days(&entries, cutoff.utc_sec, 0), 3);

        let cutoff_24h = parse_timestamp(b"2026-10-26T12:00:00Z").unwrap();
        assert_eq!(count_pageviews_since(&entries, cutoff_24h.utc_sec, 0), 2);
    }

    #[test]
    fn dynamic_shuffle_count_matches_custom_feed_spec() {
        let now = parse_timestamp(b"2026-10-27T12:00:00Z").unwrap();

        let half_hour_ago = ParsedTimestamp::from_epoch_and_offset(now.utc_sec - 1800, 0, 0);
        assert_eq!(
            calculate_dynamic_shuffle_count(half_hour_ago, now.utc_sec, 0, 1.0),
            20
        );

        let one_hour_ago = ParsedTimestamp::from_epoch_and_offset(now.utc_sec - 3600 - 1, 0, 0);
        assert_eq!(
            calculate_dynamic_shuffle_count(one_hour_ago, now.utc_sec, 0, 1.0),
            19
        );
        assert_eq!(
            calculate_dynamic_shuffle_count(one_hour_ago, now.utc_sec, 0, 0.5),
            10
        );
        assert_eq!(
            calculate_dynamic_shuffle_count(one_hour_ago, now.utc_sec, 0, 0.33),
            6
        );
        assert_eq!(
            calculate_dynamic_shuffle_count(one_hour_ago, now.utc_sec, 0, 2.0),
            20
        );

        let two_hours_ago = ParsedTimestamp::from_epoch_and_offset(now.utc_sec - 7200 - 1, 0, 0);
        assert_eq!(
            calculate_dynamic_shuffle_count(two_hours_ago, now.utc_sec, 0, 1.0),
            18
        );

        let fifteen_hours_ago =
            ParsedTimestamp::from_epoch_and_offset(now.utc_sec - 15 * 3600 - 1, 0, 0);
        assert_eq!(
            calculate_dynamic_shuffle_count(fifteen_hours_ago, now.utc_sec, 0, 1.0),
            5
        );
    }

    #[test]
    fn video_duration_formatting() {
        assert_eq!(format_video_duration(0).as_deref(), Some("00:00"));
        assert_eq!(format_video_duration(59).as_deref(), Some("00:59"));
        assert_eq!(format_video_duration(60).as_deref(), Some("01:00"));
        assert_eq!(format_video_duration(323).as_deref(), Some("05:23"));
        assert_eq!(format_video_duration(3600).as_deref(), Some("1:00:00"));
        assert_eq!(format_video_duration(3723).as_deref(), Some("1:02:03"));
        assert_eq!(format_video_duration(90_061).as_deref(), Some("1:01:01"));
        assert!(format_video_duration(-1).is_none());
    }

    #[test]
    fn weighted_shuffle_deterministic_with_supplied_randoms() {
        let randoms = [0.95, 0.05, 0.5, 0.1];
        let indices = weighted_shuffle_indices(4, 1.0, &randoms).unwrap();
        assert_eq!(indices.len(), 4);
        // index 1 with r=0.05 -> 1 + (0.2 - 2.0) = -0.8
        // index 0 with r=0.95 -> 0 + (3.8 - 2.0) = 1.8
        assert_eq!(indices[0], 1);
    }

    #[test]
    fn build_score_sql_zero_weights_returns_zero() {
        let weights = FeedScoreWeights::default();
        let ctx = FeedScoreContext {
            recent_pageviews_count: 0,
            organization_follow_ids: &[],
            user_follow_ids: &[],
            tag_names: &[],
            optimized_tags_query: false,
            optimized_tags_limit: 20,
            is_root_subforem: false,
            subforem_follow_ids: &[],
            label_names: &[],
            lookback_window_utc_sec: 0,
            second_latest_pageview_utc_sec: 0,
            precomputed_selection_ids: &[],
            has_activity_store: false,
            recent_article_ids: &[],
            published_since_24h_utc_sec: 0,
            recent_subforem_ids: &[],
            interest_embedding: &[],
            published_since_30d_utc_sec: 0,
            ai_preference: AiPreference::ShowAll,
            languages: &[],
            random_seed: 42,
        };
        assert_eq!(
            build_feed_config_score_sql(&weights, &ctx).as_deref(),
            Some("(0)")
        );
    }

    #[test]
    fn split_and_score_primitives_and_ranking() {
        assert_eq!(
            split_cached_tag_list("ruby, rails, "),
            vec!["ruby", "rails"]
        );
        let names = ["ruby".to_string(), "rust".to_string()];
        let points = [2.0, 3.0];
        assert_eq!(
            score_followed_tags("ruby, webdev, rust", &names, &points, 1.0, 0.0),
            Some(5.0)
        );
        assert_eq!(score_experience_level(8.0, 1.0, 1.0), Some(-3.5));
        assert_eq!(score_experience_level_int(8, 1, 1.0), Some(-3.0));
        assert_eq!(
            score_ai_disclosure(Some("minimize_ai"), Some("some_ai"), -10.0, -25.0),
            Some(-10.0)
        );
        let ctx = UserArticleScoreContext {
            has_user: true,
            following_user_ids: &[10, 20],
            following_org_ids: &[100],
            followed_tag_names: &names,
            followed_tag_points: &points,
            user_xp: (5.0, false, 5),
            ai_preference: Some("minimize_ai"),
            weights: [0.2, 1.0, 1.0, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0, -10.0, -25.0],
        };
        let a0 = ArticleScoreInput {
            user_id: Some(99),
            organization_id: None,
            cached_tag_list: "js",
            xp: (5.0, false, 5),
            comments_count: 5,
            ai_disclosure_level: Some("no_ai"),
            base_article_points: 0.0,
        };
        let a1 = ArticleScoreInput {
            user_id: Some(10),
            organization_id: Some(100),
            cached_tag_list: "ruby, rust",
            xp: (7.0, false, 7),
            comments_count: 10,
            ai_disclosure_level: Some("some_ai"),
            base_article_points: 0.0,
        };
        assert_eq!(score_article_for_user(&ctx, &a1), Some(-2.0));
        let a2 = ArticleScoreInput {
            ai_disclosure_level: Some("no_ai"),
            ..a1
        };
        assert_eq!(
            rank_basic_feed_indices(&ctx, &[a0, a2]).unwrap(),
            vec![1, 0]
        );
    }

    #[test]
    fn activity_metadata_subforems_and_heatmap() {
        assert_eq!(
            filter_tracked_article_ids(&[(1, 120.0), (2, 29.0), (3, 30.0)], 29.0).unwrap(),
            vec![1, 3]
        );
        let pre_split = ["tag2".to_string(), "tag3".to_string()];
        let tag_sources = [
            ArticleTagSource::CommaSeparated("tag1, tag2"),
            ArticleTagSource::PreSplit(&pre_split),
        ];
        let labels = [
            vec!["l1".to_string(), "l2".to_string()],
            vec![
                "l2".to_string(),
                "l3".to_string(),
                "l4".to_string(),
                "l5".to_string(),
                "l6".to_string(),
            ],
        ];
        let meta = aggregate_recent_activity_metadata(
            &tag_sources,
            &labels,
            &[Some(10), Some(10), None, Some(20)],
            &[Some(1), Some(2), Some(1)],
            &[Some(101), None, Some(101), Some(202)],
            5,
        );
        assert_eq!(meta.0, vec!["tag1", "tag2", "tag3"]);
        assert_eq!(meta.1, vec!["l1", "l2", "l3", "l4", "l5"]);
        assert_eq!((meta.2, meta.3), (vec![10, 20], vec![1, 2]));
        assert_eq!(meta.4, vec![101, 101, 202]);
        assert_eq!(
            order_subforem_ids(&[1, 1, 3], &[1, 2], &[1, 2, 3, 4, 5]),
            vec![1, 2, 3, 4, 5]
        );
        let (start, end) = (
            parse_iso_date_days(b"2026-10-25").unwrap(),
            parse_iso_date_days(b"2026-10-27").unwrap(),
        );
        let p = build_activity_heatmap(start, end, &[(start, 1)], &[(start + 1, 2)], &[(end, 3)])
            .unwrap();
        assert_eq!((p.days.len(), p.totals[3], p.max), (3, 6, 3));
    }

    #[test]
    fn truncate_feed_xml_items_rss_and_atom() {
        let rss = "<rss><channel><title>Blog</title><item><title>1</title></item><item><title>2</title></item><item><title>3</title></item></channel></rss>";
        assert_eq!(
            truncate_feed_xml_items(rss, 2).as_ref(),
            "<rss><channel><title>Blog</title><item><title>1</title></item><item><title>2</title></item></channel></rss>"
        );
        // Zero-copy when count <= max_items
        assert!(matches!(truncate_feed_xml_items(rss, 3), Cow::Borrowed(_)));
        assert!(matches!(truncate_feed_xml_items(rss, 10), Cow::Borrowed(_)));

        // Atom <entry> with attributes and CDATA containing </entry>
        let atom = "<feed><entry id=\"1\"><content><![CDATA[</entry><entry>]]></content></entry><entry id=\"2\"><title>B</title></entry></feed>";
        assert_eq!(
            truncate_feed_xml_items(atom, 1).as_ref(),
            "<feed><entry id=\"1\"><content><![CDATA[</entry><entry>]]></content></entry></feed>"
        );
    }

    #[test]
    fn feed_html_vs_markdown_detection() {
        assert!(feed_html_content(
            "<p>First paragraph</p><p>Second paragraph</p>"
        ));
        assert!(!feed_html_content(
            "# Heading\n\nParagraph 1 with <code>inline</code>\n\nParagraph 2"
        ));
        assert!(!feed_html_content("Plain text without any tags"));
        assert!(feed_html_content(
            "<div><h1>Title</h1>\n\n<p>Body</p></div>"
        ));
    }

    #[test]
    fn postprocess_feed_markdown_all_transforms() {
        let clean = "Hello world\n\n```ruby\nputs 1\n```";
        assert!(matches!(postprocess_feed_markdown(clean), Cow::Borrowed(_)));

        let dirty = "Before\n```\n\n```\nMiddle&nbsp;text\u{00A0}here\n{% youtube dQw4w9WgXcQ\\_test %}\nAfter";
        assert_eq!(
            postprocess_feed_markdown(dirty).as_ref(),
            "Before\n\nMiddle text here\n{% youtube dQw4w9WgXcQ_test %}\nAfter"
        );
    }

    #[test]
    fn resolve_feed_markdown_images_root_and_relative() {
        let base = "https://example.com";
        let source = "https://example.com/posts/2026/my-post";
        let md = "Text ![alt](/assets/a.png) and ![rel](images/b.jpg) and <img class=\"x\" src=\"/c.gif\"> and ![abs](https://cdn.example.com/d.png)";
        assert_eq!(
            resolve_feed_markdown_images(md, base, source)
                .unwrap()
                .as_ref(),
            "Text ![alt](https://example.com/assets/a.png) and ![rel](https://example.com/posts/2026/images/b.jpg) and <img class=\"x\" src=\"https://example.com/c.gif\"> and ![abs](https://cdn.example.com/d.png)"
        );
        // Dot-segments decline to Ruby's URI.join
        assert!(resolve_feed_markdown_images("![up](../img.png)", base, source).is_none());
    }

    #[test]
    fn format_feed_tags_and_extract_author_and_sanitize_error() {
        let cats = [
            "Ruby on Rails!",
            "web-dev",
            "verylongcategorynamethatexceedstwentycharacters",
            "fourth_tag",
            "fifth_ignored",
        ];
        assert_eq!(
            format_feed_tags(&cats).as_deref(),
            Some("RubyonRails,webdev,verylongcategoryname,fourthtag")
        );
        assert_eq!(format_feed_tags::<&str>(&[]).as_deref(), Some(""));
        assert!(format_feed_tags(&["café"]).is_none());

        assert_eq!(
            extract_feed_author("Jane Doe <jane.doe+rss@example.org>"),
            Some((
                Some("jane.doe+rss@example.org".to_string()),
                "Jane Doe".to_string()
            ))
        );
        assert_eq!(
            extract_feed_author("  John Smith  "),
            Some((None, "John Smith".to_string()))
        );

        let err = "Error in /app/services/feeds/import.rb:42:in `call' and /gems/rss-0.3.rb:12";
        assert_eq!(
            sanitize_feed_error(err),
            "Error in [path]:in `call' and [path]"
        );
        let long_err = "x".repeat(600);
        let sanitized_long = sanitize_feed_error(&long_err);
        assert_eq!(sanitized_long.len(), 500);
        assert!(sanitized_long.ends_with("..."));
    }
}
