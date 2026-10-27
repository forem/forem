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
}
