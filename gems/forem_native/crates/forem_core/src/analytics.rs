//! Single-pass streaming analytics activity aggregators and JSON serializers for Forem
//! (`AnalyticsService` and `Api::AnalyticsController`).
//!
//! Replaces ActiveRecord `ArticleActivity` hydration, Ruby JSONB deserialization of
//! `daily_page_views` / `daily_reactions` / `daily_comments` / `daily_referrers`,
//! multi-pass intermediate Ruby `Hash` / `Array` / `Set` allocations, and
//! `ActiveSupport::JSON` serialization with:
//!
//! - **Tier 1 composable primitives**:
//!   - [`analytics_aggregate_totals`]: single-pass scan of raw JSONB strings computing
//!     comments, reactions (including `unique_reactors`), and page view totals with
//!     optional `start_iso..=end_iso` date filtering.
//!   - [`analytics_aggregate_referrers`]: single-pass scan of raw `daily_referrers`
//!     JSONB strings computing top-N referrer domains ordered by `-count`.
//!   - [`analytics_aggregate_grouped_by_day`]: O(1) bucket-indexed daily/weekly
//!     aggregation across all in-scope `ArticleActivity` rows.
//! - **Tier 2 single-pass fused streaming JSON kernels**:
//!   - [`analytics_grouped_by_day_json`]: streams `grouped_by_day` directly into a
//!     single pre-sized JSON `String` buffer without intermediate Ruby hashes.
//!   - [`analytics_dashboard_json`]: scans each row's raw JSONB columns **once** to
//!     compute `historical` (date-ranged buckets), `totals` (all-time), and `referrers`
//!     (date-ranged top-N) simultaneously, streaming the complete `/api/analytics/dashboard`
//!     JSON payload into one buffer.

use std::borrow::Cow;
use std::collections::{HashMap, HashSet};
use std::fmt::Write as _;

use crate::api_comments::civil_from_days;
use crate::json::write_json_string;

/// Upper bound on generated buckets to prevent runaway allocations on malformed date ranges.
const MAX_BUCKETS: usize = 20_000;
/// Maximum nesting depth when skipping unknown JSON fields.
const MAX_SKIP_DEPTH: usize = 32;

/// Aggregated page-view counters for a bucket or totals window.
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct PageViewTotals {
    pub total: i64,
    pub average_read_time_in_seconds: i64,
    pub total_read_time_in_seconds: i64,
}

/// Aggregated reaction counters for a bucket or totals window.
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct ReactionTotals {
    pub total: i64,
    pub like: i64,
    pub readinglist: i64,
    pub unicorn: i64,
    pub exploding_head: i64,
    pub raised_hands: i64,
    pub fire: i64,
    pub unique_reactors: i64,
}

/// Aggregated analytics totals across comments, reactions, and page views.
#[derive(Debug, Default, Clone, Copy, PartialEq, Eq)]
pub struct AnalyticsTotalsResult {
    pub comments_total: i64,
    pub reactions: ReactionTotals,
    pub page_views: PageViewTotals,
}

/// Single daily or weekly bucket result.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AnalyticsBucketResult {
    pub iso: String,
    pub comments_total: i64,
    pub follows_total: i64,
    pub reactions: ReactionTotals,
    pub page_views: PageViewTotals,
}

#[derive(Debug, Default)]
struct PageViewAcc {
    total: i64,
    sum_read_seconds: i64,
    logged_in_count: i64,
}

impl PageViewAcc {
    #[inline]
    fn add(&mut self, total: i64, sum_read_seconds: i64, logged_in_count: i64) -> Option<()> {
        self.total = self.total.checked_add(total)?;
        self.sum_read_seconds = self.sum_read_seconds.checked_add(sum_read_seconds)?;
        self.logged_in_count = self.logged_in_count.checked_add(logged_in_count)?;
        Some(())
    }

    #[inline]
    fn finish(&self) -> Option<PageViewTotals> {
        let avg = if self.logged_in_count > 0 {
            let ratio = (self.sum_read_seconds as f64) / (self.logged_in_count as f64);
            if !ratio.is_finite() {
                return None;
            }
            let rounded = ratio.round();
            // `i64::MAX as f64` rounds up to `2^63` (`9223372036854775808.0`), so reject
            // `>= i64::MAX as f64` to avoid saturating `2^63` down to `i64::MAX` (Ruby returns Bignum).
            if rounded < (i64::MIN as f64) || rounded >= (i64::MAX as f64) {
                return None;
            }
            rounded as i64
        } else {
            0
        };
        let total_read = self.total.checked_mul(avg)?;
        Some(PageViewTotals {
            total: self.total,
            average_read_time_in_seconds: avg,
            total_read_time_in_seconds: total_read,
        })
    }
}

#[derive(Debug, Default)]
struct ReactionAcc {
    total: i64,
    like: i64,
    readinglist: i64,
    unicorn: i64,
    exploding_head: i64,
    raised_hands: i64,
    fire: i64,
    reactor_ids: HashSet<i64>,
}

impl ReactionAcc {
    #[inline]
    fn add_counts(&mut self, counts: &ReactionCounts) -> Option<()> {
        self.total = self.total.checked_add(counts.total)?;
        self.like = self.like.checked_add(counts.like)?;
        self.readinglist = self.readinglist.checked_add(counts.readinglist)?;
        self.unicorn = self.unicorn.checked_add(counts.unicorn)?;
        self.exploding_head = self.exploding_head.checked_add(counts.exploding_head)?;
        self.raised_hands = self.raised_hands.checked_add(counts.raised_hands)?;
        self.fire = self.fire.checked_add(counts.fire)?;
        Some(())
    }

    #[inline]
    fn finish(&self) -> ReactionTotals {
        ReactionTotals {
            total: self.total,
            like: self.like,
            readinglist: self.readinglist,
            unicorn: self.unicorn,
            exploding_head: self.exploding_head,
            raised_hands: self.raised_hands,
            fire: self.fire,
            unique_reactors: self.reactor_ids.len() as i64,
        }
    }
}

#[derive(Debug, Default, Clone, Copy)]
struct ReactionCounts {
    total: i64,
    like: i64,
    readinglist: i64,
    unicorn: i64,
    exploding_head: i64,
    raised_hands: i64,
    fire: i64,
}

#[derive(Debug)]
struct BucketAcc {
    iso: [u8; 10],
    comments_total: i64,
    follows_total: i64,
    reactions: ReactionAcc,
    page_views: PageViewAcc,
}

/// Howard Hinnant's civil-to-days algorithm (inverse of `civil_from_days`).
/// Returns days since 1970-01-01.
#[inline]
pub fn days_from_civil(year: i64, month: u32, day: u32) -> i64 {
    let y = year - i64::from(month <= 2);
    let era = y.div_euclid(400);
    let yoe = (y - era * 400) as u64;
    let m = u64::from(month);
    let d = u64::from(day);
    let doy = (153 * (if m > 2 { m - 3 } else { m + 9 }) + 2) / 5 + d - 1;
    let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    era * 146_097 + (doe as i64) - 719_468
}

#[inline]
fn is_leap_year(year: i64) -> bool {
    (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
}

#[inline]
fn days_in_month(year: i64, month: u32) -> u32 {
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

/// Parses an exact 10-byte `YYYY-MM-DD` date string into days since 1970-01-01.
#[inline]
pub fn parse_iso_date(s: &str) -> Option<i64> {
    let b = s.as_bytes();
    if b.len() != 10 || b[4] != b'-' || b[7] != b'-' {
        return None;
    }
    let y = parse_4_digits(b[0], b[1], b[2], b[3])? as i64;
    let m = parse_2_digits(b[5], b[6])?;
    let d = parse_2_digits(b[8], b[9])?;
    if !(1..=12).contains(&m) || d < 1 || d > days_in_month(y, m) {
        return None;
    }
    Some(days_from_civil(y, m, d))
}

#[inline]
fn parse_2_digits(a: u8, b: u8) -> Option<u32> {
    if a.is_ascii_digit() && b.is_ascii_digit() {
        Some(u32::from(a - b'0') * 10 + u32::from(b - b'0'))
    } else {
        None
    }
}

#[inline]
fn parse_4_digits(a: u8, b: u8, c: u8, d: u8) -> Option<u32> {
    if a.is_ascii_digit() && b.is_ascii_digit() && c.is_ascii_digit() && d.is_ascii_digit() {
        Some(
            u32::from(a - b'0') * 1000
                + u32::from(b - b'0') * 100
                + u32::from(c - b'0') * 10
                + u32::from(d - b'0'),
        )
    } else {
        None
    }
}

/// Formats days since 1970-01-01 into a stack-allocated `YYYY-MM-DD` byte array.
#[inline]
fn format_days_iso(days: i64) -> Option<[u8; 10]> {
    let (year, month, day) = civil_from_days(days);
    if !(0..=9999).contains(&year) {
        return None;
    }
    let y = year as u32;
    Some([
        b'0' + ((y / 1000) % 10) as u8,
        b'0' + ((y / 100) % 10) as u8,
        b'0' + ((y / 10) % 10) as u8,
        b'0' + (y % 10) as u8,
        b'-',
        b'0' + (month / 10) as u8,
        b'0' + (month % 10) as u8,
        b'-',
        b'0' + (day / 10) as u8,
        b'0' + (day % 10) as u8,
    ])
}

/// Zero-AST streaming cursor over UTF-8 JSON bytes.
struct JsonCursor<'a> {
    src: &'a str,
    bytes: &'a [u8],
    pos: usize,
}

impl<'a> JsonCursor<'a> {
    #[inline]
    fn new(src: &'a str) -> Self {
        Self {
            src,
            bytes: src.as_bytes(),
            pos: 0,
        }
    }

    #[inline]
    fn skip_ws(&mut self) {
        while self.pos < self.bytes.len() {
            match self.bytes[self.pos] {
                b' ' | b'\t' | b'\n' | b'\r' => self.pos += 1,
                _ => break,
            }
        }
    }

    #[inline]
    fn peek(&self) -> Option<u8> {
        self.bytes.get(self.pos).copied()
    }

    #[inline]
    fn eat(&mut self, expected: u8) -> bool {
        self.skip_ws();
        if self.peek() == Some(expected) {
            self.pos += 1;
            true
        } else {
            false
        }
    }

    #[inline]
    fn is_eof(&mut self) -> bool {
        self.skip_ws();
        self.pos == self.bytes.len()
    }

    /// Reads a JSON string. Borrows directly from `self.src` when no backslash escapes occur.
    fn read_string(&mut self) -> Option<Cow<'a, str>> {
        self.skip_ws();
        if self.peek()? != b'"' {
            return None;
        }
        self.pos += 1;
        let start = self.pos;
        while self.pos < self.bytes.len() {
            let b = self.bytes[self.pos];
            if b == b'"' {
                let s = &self.src[start..self.pos];
                self.pos += 1;
                return Some(Cow::Borrowed(s));
            }
            if b == b'\\' {
                return self.read_escaped_string(start);
            }
            if b < 0x20 {
                return None;
            }
            self.pos += 1;
        }
        None
    }

    fn read_escaped_string(&mut self, start: usize) -> Option<Cow<'a, str>> {
        let mut out = String::with_capacity(self.pos - start + 16);
        out.push_str(&self.src[start..self.pos]);
        while self.pos < self.bytes.len() {
            let b = self.bytes[self.pos];
            if b == b'"' {
                self.pos += 1;
                return Some(Cow::Owned(out));
            }
            if b == b'\\' {
                self.pos += 1;
                let esc = *self.bytes.get(self.pos)?;
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
                        let code = self.read_hex4()?;
                        if (0xD800..=0xDBFF).contains(&code) {
                            if self.bytes.get(self.pos) != Some(&b'\\')
                                || self.bytes.get(self.pos + 1) != Some(&b'u')
                            {
                                return None;
                            }
                            self.pos += 2;
                            let low = self.read_hex4()?;
                            if !(0xDC00..=0xDFFF).contains(&low) {
                                return None;
                            }
                            let cp = 0x10000
                                + (((u32::from(code) - 0xD800) << 10) | (u32::from(low) - 0xDC00));
                            out.push(char::from_u32(cp)?);
                        } else if (0xDC00..=0xDFFF).contains(&code) {
                            return None;
                        } else {
                            out.push(char::from_u32(u32::from(code))?);
                        }
                    }
                    _ => return None,
                }
            } else if b < 0x20 {
                return None;
            } else {
                let ch_start = self.pos;
                self.pos += 1;
                while self.pos < self.bytes.len()
                    && self.bytes[self.pos] != b'"'
                    && self.bytes[self.pos] != b'\\'
                    && self.bytes[self.pos] >= 0x20
                {
                    self.pos += 1;
                }
                out.push_str(&self.src[ch_start..self.pos]);
            }
        }
        None
    }

    fn read_hex4(&mut self) -> Option<u16> {
        if self.pos + 4 > self.bytes.len() {
            return None;
        }
        let mut val = 0u16;
        for i in 0..4 {
            let d = match self.bytes[self.pos + i] {
                b'0'..=b'9' => u16::from(self.bytes[self.pos + i] - b'0'),
                b'a'..=b'f' => u16::from(self.bytes[self.pos + i] - b'a') + 10,
                b'A'..=b'F' => u16::from(self.bytes[self.pos + i] - b'A') + 10,
                _ => return None,
            };
            val = (val << 4) | d;
        }
        self.pos += 4;
        Some(val)
    }

    /// Reads an integer or `null` (returning `0`). Rejects floats/strings/booleans so
    /// out-of-domain inputs defer cleanly to Ruby.
    fn read_i64_or_null(&mut self) -> Option<i64> {
        self.skip_ws();
        let b = self.peek()?;
        if b == b'n' {
            if self.bytes.get(self.pos..self.pos + 4) == Some(b"null") {
                self.pos += 4;
                return Some(0);
            }
            return None;
        }
        self.read_i64()
    }

    fn read_i64(&mut self) -> Option<i64> {
        self.skip_ws();
        let start = self.pos;
        if self.peek() == Some(b'-') {
            self.pos += 1;
        }
        let digits_start = self.pos;
        while self.pos < self.bytes.len() && self.bytes[self.pos].is_ascii_digit() {
            self.pos += 1;
        }
        if self.pos == digits_start {
            return None;
        }
        // Reject leading zeros (except single "0" / "-0") and floats/exponents.
        if self.pos - digits_start > 1 && self.bytes[digits_start] == b'0' {
            return None;
        }
        if matches!(self.peek(), Some(b'.' | b'e' | b'E')) {
            return None;
        }
        self.src[start..self.pos].parse::<i64>().ok()
    }

    /// Reads `null` or `[int, ...]` and appends parsed `i64`s into `out`.
    fn read_i64_array_into_vec(&mut self, out: &mut Vec<i64>) -> Option<()> {
        self.skip_ws();
        if self.peek() == Some(b'n') {
            if self.bytes.get(self.pos..self.pos + 4) == Some(b"null") {
                self.pos += 4;
                return Some(());
            }
            return None;
        }
        if !self.eat(b'[') {
            return None;
        }
        self.skip_ws();
        if self.peek() == Some(b']') {
            self.pos += 1;
            return Some(());
        }
        loop {
            let v = self.read_i64()?;
            out.push(v);
            self.skip_ws();
            match self.peek()? {
                b',' => self.pos += 1,
                b']' => {
                    self.pos += 1;
                    return Some(());
                }
                _ => return None,
            }
        }
    }

    fn skip_value(&mut self, depth: usize) -> Option<()> {
        if depth > MAX_SKIP_DEPTH {
            return None;
        }
        self.skip_ws();
        match self.peek()? {
            b'"' => {
                let _ = self.read_string()?;
                Some(())
            }
            b'{' => {
                self.pos += 1;
                self.skip_ws();
                if self.peek() == Some(b'}') {
                    self.pos += 1;
                    return Some(());
                }
                loop {
                    let _ = self.read_string()?;
                    if !self.eat(b':') {
                        return None;
                    }
                    self.skip_value(depth + 1)?;
                    self.skip_ws();
                    match self.peek()? {
                        b',' => self.pos += 1,
                        b'}' => {
                            self.pos += 1;
                            return Some(());
                        }
                        _ => return None,
                    }
                }
            }
            b'[' => {
                self.pos += 1;
                self.skip_ws();
                if self.peek() == Some(b']') {
                    self.pos += 1;
                    return Some(());
                }
                loop {
                    self.skip_value(depth + 1)?;
                    self.skip_ws();
                    match self.peek()? {
                        b',' => self.pos += 1,
                        b']' => {
                            self.pos += 1;
                            return Some(());
                        }
                        _ => return None,
                    }
                }
            }
            b't' => {
                if self.bytes.get(self.pos..self.pos + 4) == Some(b"true") {
                    self.pos += 4;
                    Some(())
                } else {
                    None
                }
            }
            b'f' => {
                if self.bytes.get(self.pos..self.pos + 5) == Some(b"false") {
                    self.pos += 5;
                    Some(())
                } else {
                    None
                }
            }
            b'n' => {
                if self.bytes.get(self.pos..self.pos + 4) == Some(b"null") {
                    self.pos += 4;
                    Some(())
                } else {
                    None
                }
            }
            b'-' | b'0'..=b'9' => {
                if self.peek() == Some(b'-') {
                    self.pos += 1;
                }
                let start = self.pos;
                while self.pos < self.bytes.len() && self.bytes[self.pos].is_ascii_digit() {
                    self.pos += 1;
                }
                if self.pos == start {
                    return None;
                }
                if self.pos - start > 1 && self.bytes[start] == b'0' {
                    return None;
                }
                if self.peek() == Some(b'.') {
                    self.pos += 1;
                    let fstart = self.pos;
                    while self.pos < self.bytes.len() && self.bytes[self.pos].is_ascii_digit() {
                        self.pos += 1;
                    }
                    if self.pos == fstart {
                        return None;
                    }
                }
                if matches!(self.peek(), Some(b'e' | b'E')) {
                    self.pos += 1;
                    if matches!(self.peek(), Some(b'+' | b'-')) {
                        self.pos += 1;
                    }
                    let estart = self.pos;
                    while self.pos < self.bytes.len() && self.bytes[self.pos].is_ascii_digit() {
                        self.pos += 1;
                    }
                    if self.pos == estart {
                        return None;
                    }
                }
                Some(())
            }
            _ => None,
        }
    }
}

#[inline]
fn iso_in_range(iso: &str, start_iso: Option<&str>, end_iso: Option<&str>) -> bool {
    match (start_iso, end_iso) {
        (Some(s), Some(e)) => iso >= s && iso <= e,
        _ => true,
    }
}

/// Parses a single `daily_page_views` day object:
/// `{"total": N, "sum_read_seconds": N, "logged_in_count": N}`.
fn parse_page_view_day(cur: &mut JsonCursor<'_>) -> Option<(i64, i64, i64)> {
    if !cur.eat(b'{') {
        return None;
    }
    let mut total = 0i64;
    let mut sum_read = 0i64;
    let mut logged_in = 0i64;

    cur.skip_ws();
    if cur.peek() == Some(b'}') {
        cur.pos += 1;
        return Some((0, 0, 0));
    }
    loop {
        let key = cur.read_string()?;
        if !cur.eat(b':') {
            return None;
        }
        match key.as_ref() {
            "total" => total = cur.read_i64_or_null()?,
            "sum_read_seconds" => sum_read = cur.read_i64_or_null()?,
            "logged_in_count" => logged_in = cur.read_i64_or_null()?,
            _ => cur.skip_value(0)?,
        }
        cur.skip_ws();
        match cur.peek()? {
            b',' => cur.pos += 1,
            b'}' => {
                cur.pos += 1;
                return Some((total, sum_read, logged_in));
            }
            _ => return None,
        }
    }
}

/// Parses a single `daily_reactions` day object:
/// `{"total": N, "like": N, ..., "reactor_ids": [1, 2]}`.
fn parse_reaction_day(
    cur: &mut JsonCursor<'_>,
    reactor_buf: &mut Vec<i64>,
) -> Option<ReactionCounts> {
    if !cur.eat(b'{') {
        return None;
    }
    let mut counts = ReactionCounts::default();
    reactor_buf.clear();

    cur.skip_ws();
    if cur.peek() == Some(b'}') {
        cur.pos += 1;
        return Some(counts);
    }
    loop {
        let key = cur.read_string()?;
        if !cur.eat(b':') {
            return None;
        }
        match key.as_ref() {
            "total" => counts.total = cur.read_i64_or_null()?,
            "like" => counts.like = cur.read_i64_or_null()?,
            "readinglist" => counts.readinglist = cur.read_i64_or_null()?,
            "unicorn" => counts.unicorn = cur.read_i64_or_null()?,
            "exploding_head" => counts.exploding_head = cur.read_i64_or_null()?,
            "raised_hands" => counts.raised_hands = cur.read_i64_or_null()?,
            "fire" => counts.fire = cur.read_i64_or_null()?,
            "reactor_ids" => {
                reactor_buf.clear();
                cur.read_i64_array_into_vec(reactor_buf)?;
            }
            _ => cur.skip_value(0)?,
        }
        cur.skip_ws();
        match cur.peek()? {
            b',' => cur.pos += 1,
            b'}' => {
                cur.pos += 1;
                return Some(counts);
            }
            _ => return None,
        }
    }
}

/// Iterates top-level `{ "key": <value>, ... }` entries of a JSON object.
fn for_each_object_entry<'a, F>(src: &'a str, mut f: F) -> Option<()>
where
    F: FnMut(&str, &mut JsonCursor<'a>) -> Option<()>,
{
    let mut cur = JsonCursor::new(src);
    if !cur.eat(b'{') {
        return None;
    }
    cur.skip_ws();
    if cur.peek() == Some(b'}') {
        cur.pos += 1;
        return if cur.is_eof() { Some(()) } else { None };
    }
    loop {
        let key = cur.read_string()?;
        if !cur.eat(b':') {
            return None;
        }
        f(key.as_ref(), &mut cur)?;
        cur.skip_ws();
        match cur.peek()? {
            b',' => cur.pos += 1,
            b'}' => {
                cur.pos += 1;
                return if cur.is_eof() { Some(()) } else { None };
            }
            _ => return None,
        }
    }
}

/// Bucket layout for O(1) day-to-bucket mapping.
struct BucketPlan {
    start_day: i64,
    end_day: i64,
    weekly_bucketing: bool,
    weekly_start_day: i64,
    cutoff_day: i64,
    num_weekly: usize,
    daily_start: i64,
    buckets: Vec<BucketAcc>,
}

impl BucketPlan {
    fn build(
        start_iso: &str,
        end_iso: &str,
        weekly_bucketing: bool,
        weekly_start_iso: Option<&str>,
        cutoff_iso: Option<&str>,
        follows_by_iso: &HashMap<&str, i64>,
    ) -> Option<Self> {
        let start_day = parse_iso_date(start_iso)?;
        let end_day = parse_iso_date(end_iso)?;
        let mut buckets = Vec::new();
        let (weekly_start_day, cutoff_day, num_weekly, daily_start) = if weekly_bucketing {
            let ws = parse_iso_date(weekly_start_iso?)?;
            let cd = parse_iso_date(cutoff_iso?)?;
            if ws > start_day {
                return None;
            }
            let mut week = ws;
            while week < cd {
                if buckets.len() >= MAX_BUCKETS {
                    return None;
                }
                let iso = format_days_iso(week)?;
                let iso_str = std::str::from_utf8(&iso).ok()?;
                let follows_total = follows_by_iso.get(iso_str).copied().unwrap_or(0);
                buckets.push(BucketAcc {
                    iso,
                    comments_total: 0,
                    follows_total,
                    reactions: ReactionAcc::default(),
                    page_views: PageViewAcc::default(),
                });
                week = week.checked_add(7)?;
            }
            let num_weekly = buckets.len();
            let ds = cd.max(start_day);
            let mut day = ds;
            while day <= end_day {
                if buckets.len() >= MAX_BUCKETS {
                    return None;
                }
                let iso = format_days_iso(day)?;
                let iso_str = std::str::from_utf8(&iso).ok()?;
                let follows_total = follows_by_iso.get(iso_str).copied().unwrap_or(0);
                buckets.push(BucketAcc {
                    iso,
                    comments_total: 0,
                    follows_total,
                    reactions: ReactionAcc::default(),
                    page_views: PageViewAcc::default(),
                });
                day = day.checked_add(1)?;
            }
            (ws, cd, num_weekly, ds)
        } else {
            let mut day = start_day;
            while day <= end_day {
                if buckets.len() >= MAX_BUCKETS {
                    return None;
                }
                let iso = format_days_iso(day)?;
                let iso_str = std::str::from_utf8(&iso).ok()?;
                let follows_total = follows_by_iso.get(iso_str).copied().unwrap_or(0);
                buckets.push(BucketAcc {
                    iso,
                    comments_total: 0,
                    follows_total,
                    reactions: ReactionAcc::default(),
                    page_views: PageViewAcc::default(),
                });
                day = day.checked_add(1)?;
            }
            (start_day, start_day, 0, start_day)
        };

        Some(Self {
            start_day,
            end_day,
            weekly_bucketing,
            weekly_start_day,
            cutoff_day,
            num_weekly,
            daily_start,
            buckets,
        })
    }

    #[inline]
    fn bucket_index_for_iso(&self, iso: &str) -> Option<usize> {
        let day = parse_iso_date(iso)?;
        if day < self.start_day || day > self.end_day {
            return None;
        }
        if self.weekly_bucketing {
            if day < self.cutoff_day {
                let idx = ((day - self.weekly_start_day) / 7) as usize;
                (idx < self.num_weekly).then_some(idx)
            } else {
                let idx = self.num_weekly + (day - self.daily_start) as usize;
                (idx < self.buckets.len()).then_some(idx)
            }
        } else {
            let idx = (day - self.start_day) as usize;
            (idx < self.buckets.len()).then_some(idx)
        }
    }
}

/// Tier 1 primitive: aggregates comments, reactions, and page view totals across raw JSONB strings.
pub fn analytics_aggregate_totals(
    pv_jsons: &[&str],
    rx_jsons: &[&str],
    cm_jsons: &[&str],
    start_iso: Option<&str>,
    end_iso: Option<&str>,
) -> Option<AnalyticsTotalsResult> {
    let mut pv_acc = PageViewAcc::default();
    let mut rx_acc = ReactionAcc::default();
    let mut comments_total = 0i64;
    let mut reactor_buf = Vec::with_capacity(32);

    for src in pv_jsons {
        for_each_object_entry(src, |iso, cur| {
            if iso_in_range(iso, start_iso, end_iso) {
                let (t, s, l) = parse_page_view_day(cur)?;
                pv_acc.add(t, s, l)
            } else {
                cur.skip_value(0)
            }
        })?;
    }

    for src in rx_jsons {
        for_each_object_entry(src, |iso, cur| {
            if iso_in_range(iso, start_iso, end_iso) {
                let counts = parse_reaction_day(cur, &mut reactor_buf)?;
                rx_acc.add_counts(&counts)?;
                rx_acc.reactor_ids.extend(reactor_buf.iter().copied());
                Some(())
            } else {
                cur.skip_value(0)
            }
        })?;
    }

    for src in cm_jsons {
        for_each_object_entry(src, |iso, cur| {
            if iso_in_range(iso, start_iso, end_iso) {
                let n = cur.read_i64_or_null()?;
                comments_total = comments_total.checked_add(n)?;
                Some(())
            } else {
                cur.skip_value(0)
            }
        })?;
    }

    Some(AnalyticsTotalsResult {
        comments_total,
        reactions: rx_acc.finish(),
        page_views: pv_acc.finish()?,
    })
}

/// Tier 1 primitive: aggregates top-N referrer domains across raw `daily_referrers` JSONB strings.
pub fn analytics_aggregate_referrers(
    ref_jsons: &[&str],
    start_iso: Option<&str>,
    end_iso: Option<&str>,
    top: usize,
) -> Option<Vec<(String, i64)>> {
    let mut counts: HashMap<String, (i64, usize)> = HashMap::new();
    let mut next_order = 0usize;

    for src in ref_jsons {
        for_each_object_entry(src, |iso, cur| {
            if !iso_in_range(iso, start_iso, end_iso) {
                return cur.skip_value(0);
            }
            if !cur.eat(b'{') {
                return None;
            }
            cur.skip_ws();
            if cur.peek() == Some(b'}') {
                cur.pos += 1;
                return Some(());
            }
            loop {
                let domain = cur.read_string()?;
                if !cur.eat(b':') {
                    return None;
                }
                let n = cur.read_i64_or_null()?;
                if let Some(entry) = counts.get_mut(domain.as_ref()) {
                    entry.0 = entry.0.checked_add(n)?;
                } else {
                    counts.insert(domain.into_owned(), (n, next_order));
                    next_order += 1;
                }
                cur.skip_ws();
                match cur.peek()? {
                    b',' => cur.pos += 1,
                    b'}' => {
                        cur.pos += 1;
                        return Some(());
                    }
                    _ => return None,
                }
            }
        })?;
    }

    let mut ranked: Vec<(String, i64, usize)> = counts
        .into_iter()
        .map(|(domain, (count, order))| (domain, count, order))
        .collect();
    ranked.sort_by(|a, b| b.1.cmp(&a.1).then_with(|| a.2.cmp(&b.2)));
    ranked.truncate(top);
    Some(ranked.into_iter().map(|(d, c, _)| (d, c)).collect())
}

fn populate_buckets(
    plan: &mut BucketPlan,
    pv_jsons: &[&str],
    rx_jsons: &[&str],
    cm_jsons: &[&str],
    mut all_time: Option<(&mut PageViewAcc, &mut ReactionAcc, &mut i64)>,
) -> Option<()> {
    let mut reactor_buf = Vec::with_capacity(32);

    for src in pv_jsons {
        for_each_object_entry(src, |iso, cur| {
            let bucket_idx = plan.bucket_index_for_iso(iso);
            if bucket_idx.is_none() && all_time.is_none() {
                return cur.skip_value(0);
            }
            let (t, s, l) = parse_page_view_day(cur)?;
            if let Some(idx) = bucket_idx {
                plan.buckets[idx].page_views.add(t, s, l)?;
            }
            if let Some((ref mut all_pv, _, _)) = all_time {
                all_pv.add(t, s, l)?;
            }
            Some(())
        })?;
    }

    for src in rx_jsons {
        for_each_object_entry(src, |iso, cur| {
            let bucket_idx = plan.bucket_index_for_iso(iso);
            if bucket_idx.is_none() && all_time.is_none() {
                return cur.skip_value(0);
            }
            let counts = parse_reaction_day(cur, &mut reactor_buf)?;
            if let Some(idx) = bucket_idx {
                plan.buckets[idx].reactions.add_counts(&counts)?;
                plan.buckets[idx]
                    .reactions
                    .reactor_ids
                    .extend(reactor_buf.iter().copied());
            }
            if let Some((_, ref mut all_rx, _)) = all_time {
                all_rx.add_counts(&counts)?;
                all_rx.reactor_ids.extend(reactor_buf.iter().copied());
            }
            Some(())
        })?;
    }

    for src in cm_jsons {
        for_each_object_entry(src, |iso, cur| {
            let bucket_idx = plan.bucket_index_for_iso(iso);
            if bucket_idx.is_none() && all_time.is_none() {
                return cur.skip_value(0);
            }
            let n = cur.read_i64_or_null()?;
            if let Some(idx) = bucket_idx {
                plan.buckets[idx].comments_total =
                    plan.buckets[idx].comments_total.checked_add(n)?;
            }
            if let Some((_, _, ref mut all_cm)) = all_time {
                **all_cm = (**all_cm).checked_add(n)?;
            }
            Some(())
        })?;
    }

    Some(())
}

/// Tier 1 primitive: computes bucketed daily/weekly stats across raw JSONB strings.
#[allow(clippy::too_many_arguments)]
pub fn analytics_aggregate_grouped_by_day(
    pv_jsons: &[&str],
    rx_jsons: &[&str],
    cm_jsons: &[&str],
    follows_by_iso: &HashMap<&str, i64>,
    start_iso: &str,
    end_iso: &str,
    weekly_bucketing: bool,
    weekly_start_iso: Option<&str>,
    cutoff_iso: Option<&str>,
) -> Option<Vec<AnalyticsBucketResult>> {
    let mut plan = BucketPlan::build(
        start_iso,
        end_iso,
        weekly_bucketing,
        weekly_start_iso,
        cutoff_iso,
        follows_by_iso,
    )?;
    populate_buckets(&mut plan, pv_jsons, rx_jsons, cm_jsons, None)?;

    let mut out = Vec::with_capacity(plan.buckets.len());
    for b in &plan.buckets {
        let iso = std::str::from_utf8(&b.iso).ok()?.to_owned();
        out.push(AnalyticsBucketResult {
            iso,
            comments_total: b.comments_total,
            follows_total: b.follows_total,
            reactions: b.reactions.finish(),
            page_views: b.page_views.finish()?,
        });
    }
    Some(out)
}

#[inline]
fn write_stats_object(
    out: &mut String,
    comments_total: i64,
    follows_total: i64,
    rx: &ReactionTotals,
    pv: &PageViewTotals,
) {
    let _ = write!(
        out,
        "{{\"comments\":{{\"total\":{}}},\"follows\":{{\"total\":{}}},\"reactions\":{{\"total\":{},\"like\":{},\"readinglist\":{},\"unicorn\":{},\"exploding_head\":{},\"raised_hands\":{},\"fire\":{},\"unique_reactors\":{}}},\"page_views\":{{\"total\":{},\"average_read_time_in_seconds\":{},\"total_read_time_in_seconds\":{}}}}}",
        comments_total,
        follows_total,
        rx.total,
        rx.like,
        rx.readinglist,
        rx.unicorn,
        rx.exploding_head,
        rx.raised_hands,
        rx.fire,
        rx.unique_reactors,
        pv.total,
        pv.average_read_time_in_seconds,
        pv.total_read_time_in_seconds,
    );
}

fn write_buckets_json(out: &mut String, buckets: &[BucketAcc]) -> Option<()> {
    out.push('{');
    for (idx, b) in buckets.iter().enumerate() {
        if idx > 0 {
            out.push(',');
        }
        let iso = std::str::from_utf8(&b.iso).ok()?;
        out.push('"');
        out.push_str(iso);
        out.push_str("\":");
        let rx = b.reactions.finish();
        let pv = b.page_views.finish()?;
        write_stats_object(out, b.comments_total, b.follows_total, &rx, &pv);
    }
    out.push('}');
    Some(())
}

/// Tier 2 kernel: streams `grouped_by_day` directly into a pre-sized UTF-8 JSON `String`.
#[allow(clippy::too_many_arguments)]
pub fn analytics_grouped_by_day_json(
    pv_jsons: &[&str],
    rx_jsons: &[&str],
    cm_jsons: &[&str],
    follows_by_iso: &HashMap<&str, i64>,
    start_iso: &str,
    end_iso: &str,
    weekly_bucketing: bool,
    weekly_start_iso: Option<&str>,
    cutoff_iso: Option<&str>,
) -> Option<String> {
    let mut plan = BucketPlan::build(
        start_iso,
        end_iso,
        weekly_bucketing,
        weekly_start_iso,
        cutoff_iso,
        follows_by_iso,
    )?;
    populate_buckets(&mut plan, pv_jsons, rx_jsons, cm_jsons, None)?;

    let mut out = String::with_capacity(plan.buckets.len() * 260 + 16);
    write_buckets_json(&mut out, &plan.buckets)?;
    Some(out)
}

/// Tier 2 fused kernel: scans raw JSONB columns **once** to compute `historical`, all-time
/// `totals`, and `referrers` simultaneously, streaming the complete `/api/analytics/dashboard`
/// JSON response into a single pre-sized buffer.
#[allow(clippy::too_many_arguments)]
pub fn analytics_dashboard_json(
    pv_jsons: &[&str],
    rx_jsons: &[&str],
    cm_jsons: &[&str],
    ref_jsons: &[&str],
    follows_by_iso: &HashMap<&str, i64>,
    follows_total: i64,
    start_iso: &str,
    end_iso: &str,
    weekly_bucketing: bool,
    weekly_start_iso: Option<&str>,
    cutoff_iso: Option<&str>,
    top_referrers: usize,
    top_contributors_json: &str,
    follower_engagement_json: &str,
    start_date_floor_iso: &str,
) -> Option<String> {
    if top_contributors_json.is_empty() || follower_engagement_json.is_empty() {
        return None;
    }

    let mut plan = BucketPlan::build(
        start_iso,
        end_iso,
        weekly_bucketing,
        weekly_start_iso,
        cutoff_iso,
        follows_by_iso,
    )?;

    let mut all_pv = PageViewAcc::default();
    let mut all_rx = ReactionAcc::default();
    let mut all_cm = 0i64;

    populate_buckets(
        &mut plan,
        pv_jsons,
        rx_jsons,
        cm_jsons,
        Some((&mut all_pv, &mut all_rx, &mut all_cm)),
    )?;

    let referrers =
        analytics_aggregate_referrers(ref_jsons, Some(start_iso), Some(end_iso), top_referrers)?;
    let totals_rx = all_rx.finish();
    let totals_pv = all_pv.finish()?;

    let est_cap = plan.buckets.len() * 260
        + referrers.len() * 48
        + top_contributors_json.len()
        + follower_engagement_json.len()
        + 512;
    let mut out = String::with_capacity(est_cap);

    out.push_str("{\"historical\":");
    write_buckets_json(&mut out, &plan.buckets)?;
    out.push_str(",\"totals\":");
    write_stats_object(&mut out, all_cm, follows_total, &totals_rx, &totals_pv);
    out.push_str(",\"referrers\":{\"domains\":[");
    for (idx, (domain, count)) in referrers.iter().enumerate() {
        if idx > 0 {
            out.push(',');
        }
        out.push_str("{\"domain\":");
        write_json_string(&mut out, domain, true);
        let _ = write!(out, ",\"count\":{}}}", count);
    }
    out.push_str("]},\"top_contributors\":");
    out.push_str(top_contributors_json);
    out.push_str(",\"follower_engagement\":");
    out.push_str(follower_engagement_json);
    out.push_str(",\"start_date_floor\":");
    write_json_string(&mut out, start_date_floor_iso, true);
    out.push('}');

    Some(out)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_and_formats_iso_dates() {
        let d = parse_iso_date("2020-02-29").unwrap();
        assert_eq!(&format_days_iso(d).unwrap(), b"2020-02-29");
        assert!(parse_iso_date("2019-02-29").is_none());
        assert!(parse_iso_date("2020-13-01").is_none());
        assert!(parse_iso_date("not-a-date").is_none());
    }

    #[test]
    fn aggregates_totals_with_date_range_and_unique_reactors() {
        let pv = [
            r#"{"2024-01-01":{"total":10,"sum_read_seconds":155,"logged_in_count":3},"2024-01-05":{"total":99,"sum_read_seconds":999,"logged_in_count":1}}"#,
            r#"{"2024-01-01":{"total":5,"sum_read_seconds":45,"logged_in_count":1}}"#,
        ];
        let rx = [
            r#"{"2024-01-01":{"total":3,"like":2,"unicorn":1,"reactor_ids":[1,2]},"2024-01-05":{"total":1,"fire":1,"reactor_ids":[9]}}"#,
            r#"{"2024-01-01":{"total":2,"like":1,"fire":1,"reactor_ids":[2,3]}}"#,
        ];
        let cm = [r#"{"2024-01-01":4,"2024-01-05":10}"#, r#"{"2024-01-01":2}"#];

        let res = analytics_aggregate_totals(&pv, &rx, &cm, Some("2024-01-01"), Some("2024-01-02"))
            .unwrap();
        assert_eq!(res.comments_total, 6);
        assert_eq!(res.reactions.total, 5);
        assert_eq!(res.reactions.like, 3);
        assert_eq!(res.reactions.unicorn, 1);
        assert_eq!(res.reactions.fire, 1);
        assert_eq!(res.reactions.unique_reactors, 3);
        // sum_read = 200, logged_in = 4 -> avg = 50, total_read = 15 * 50 = 750
        assert_eq!(res.page_views.total, 15);
        assert_eq!(res.page_views.average_read_time_in_seconds, 50);
        assert_eq!(res.page_views.total_read_time_in_seconds, 750);
    }

    #[test]
    fn aggregates_referrers_with_escapes_and_top_limit() {
        let refs = [
            r#"{"2024-01-01":{"google.com":10,"dev.to":5,"a\"b.com":3},"2024-01-05":{"bing.com":100}}"#,
            r#"{"2024-01-01":{"dev.to":8,"t.co":2}}"#,
        ];
        let top2 = analytics_aggregate_referrers(&refs, Some("2024-01-01"), Some("2024-01-02"), 2)
            .unwrap();
        assert_eq!(
            top2,
            vec![("dev.to".to_string(), 13), ("google.com".to_string(), 10)]
        );

        let all = analytics_aggregate_referrers(&refs, None, None, 10).unwrap();
        assert_eq!(all[0], ("bing.com".to_string(), 100));
        assert!(all.iter().any(|(d, c)| d == "a\"b.com" && *c == 3));
    }

    #[test]
    fn aggregates_weekly_and_daily_buckets_in_one_pass() {
        let pv = [
            r#"{"2019-04-03":{"total":4,"sum_read_seconds":60,"logged_in_count":2},"2020-03-31":{"total":7,"sum_read_seconds":140,"logged_in_count":2}}"#,
        ];
        let rx = [
            r#"{"2019-04-03":{"total":1,"like":1,"reactor_ids":[10]},"2019-04-04":{"total":1,"unicorn":1,"reactor_ids":[10,11]}}"#,
        ];
        let cm = [r#"{"2019-04-03":2,"2019-04-05":3}"#];
        let mut follows = HashMap::new();
        follows.insert("2019-04-01", 5);

        let buckets = analytics_aggregate_grouped_by_day(
            &pv,
            &rx,
            &cm,
            &follows,
            "2019-04-03",
            "2020-04-01",
            true,
            Some("2019-04-01"),
            Some("2019-10-04"),
        )
        .unwrap();

        assert_eq!(buckets[0].iso, "2019-04-01");
        assert_eq!(buckets[0].follows_total, 5);
        assert_eq!(buckets[0].comments_total, 5);
        assert_eq!(buckets[0].reactions.total, 2);
        assert_eq!(buckets[0].reactions.unique_reactors, 2);
        assert_eq!(buckets[0].page_views.total, 4);
        assert_eq!(buckets[0].page_views.average_read_time_in_seconds, 30);

        let mar31 = buckets.iter().find(|b| b.iso == "2020-03-31").unwrap();
        assert_eq!(mar31.page_views.total, 7);
        assert_eq!(mar31.page_views.average_read_time_in_seconds, 70);
    }

    #[test]
    fn streams_dashboard_json_with_html_escaping() {
        let pv = [r#"{"2024-01-01":{"total":2,"sum_read_seconds":30,"logged_in_count":1}}"#];
        let rx = [r#"{"2024-01-01":{"total":1,"like":1,"reactor_ids":[7]}}"#];
        let cm = [r#"{"2024-01-01":1}"#];
        let rf = [r#"{"2024-01-01":{"a<b&c.com":4}}"#];
        let follows = HashMap::new();

        let json = analytics_dashboard_json(
            &pv,
            &rx,
            &cm,
            &rf,
            &follows,
            3,
            "2024-01-01",
            "2024-01-01",
            false,
            None,
            None,
            20,
            "[]",
            r#"{"total_followers":3,"engaged_followers":1,"ratio":33.3}"#,
            "2024-01-01",
        )
        .unwrap();

        assert!(json.contains(r#""domain":"a\u003cb\u0026c.com","count":4"#));
        assert!(json.contains(r#""start_date_floor":"2024-01-01""#));
        assert!(json.contains(r#""follows":{"total":3}"#));
    }

    #[test]
    fn defers_to_ruby_on_out_of_domain_json_types() {
        // Float counter or non-integer reactor_id -> None
        assert!(analytics_aggregate_totals(
            &[r#"{"2024-01-01":{"total":1.5}}"#],
            &[],
            &[],
            None,
            None
        )
        .is_none());
        assert!(analytics_aggregate_totals(
            &[],
            &[r#"{"2024-01-01":{"reactor_ids":["not_an_int"]}}"#],
            &[],
            None,
            None
        )
        .is_none());
        assert!(analytics_aggregate_totals(
            &[],
            &[r#"{"2024-01-01":{"reactor_ids":42}}"#],
            &[],
            None,
            None
        )
        .is_none());
        // i64::MAX / 1 rounds in f64 to 2^63 (Ruby Bignum), so defer to Ruby instead of saturating.
        assert!(analytics_aggregate_totals(
            &[r#"{"2024-01-01":{"total":1,"sum_read_seconds":9223372036854775807,"logged_in_count":1}}"#],
            &[],
            &[],
            None,
            None
        )
        .is_none());
        // Empty pre-encoded JSON fragment defers cleanly.
        assert!(analytics_dashboard_json(
            &[],
            &[],
            &[],
            &[],
            &HashMap::new(),
            0,
            "2024-01-01",
            "2024-01-01",
            false,
            None,
            None,
            20,
            "",
            "{}",
            "2024-01-01",
        )
        .is_none());
    }
}
