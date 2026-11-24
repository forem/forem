//! Single-pass streaming JSON serializers for `ReactionsController#index`
//! (`GET /reactions?article_id=...` and `GET /reactions?commentable_id=...&commentable_type=...`).
//!
//! Replaces `Reaction` ActiveRecord model hydration, intermediate `{ id:, count: }` Ruby Hash
//! allocation, `ActiveModel::Serialization#as_json`, `TimeWithZone#as_json`, and
//! `ActiveSupport::JSON.encode` with:
//!
//! - **Tier 1 composable primitives**:
//!   - [`write_json_float`] / [`format_json_float`]: zero-allocation finite decimal float
//!     formatter matching Ruby's `Float#to_s` / `ActiveSupport::JSON.encode` for values in
//!     `[1e-4, 1e15)` and `±0.0`.
//!   - [`write_reaction_object`]: streams a single reaction JSON object in the exact caller-supplied
//!     `column_names` order (migration-proof parity with `Reaction#attributes`).
//! - **Tier 2 single-pass pipeline kernels**:
//!   - [`serialize_article_reactions_json`]: partitions `readinglist` reactions after public
//!     reactions in place and streams `{"current_user":...,"reactions":[...],"article_reaction_counts":[...]}`
//!     into a single pre-sized buffer.
//!   - [`serialize_comment_reactions_json`][] streams
//!     `{"current_user":...,"reactions":[...],"public_reaction_counts":[{"id":...,"count":...},...]}`
//!     directly from plucked `(id, public_reactions_count)` pairs into a single pre-sized buffer.

use std::fmt::Write;

use crate::api_articles::write_utc_iso8601_millis;
use crate::json::write_json_string;

/// Typed attribute value for a single column of a `Reaction` row.
#[derive(Debug, Clone, PartialEq)]
pub enum ReactionFieldValue<'a> {
    Null,
    Int(i64),
    Float(f64),
    Str(&'a str),
    /// UTC timestamp formatted as `"YYYY-MM-DDTHH:MM:SS.mmmZ"`.
    UtcMillis {
        secs: i64,
        millis: u32,
    },
    Bool(bool),
}

/// Entry in `article_reaction_counts` (`{ category: "like", count: 1 }`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ArticleReactionCount<'a> {
    pub category: &'a str,
    pub count: i64,
}

/// Entry in `public_reaction_counts` (`{ id: 123, count: 4 }`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct CommentReactionCount {
    pub id: i64,
    pub count: i64,
}

/// Writes a finite `f64` matching Ruby's `Float#to_s` / `ActiveSupport::JSON.encode`
/// for `±0.0`, exact integer floats in `(-1e15, 1e15)`, and exact dyadic 1/16ths in
/// `(-1e9, 1e9)` (e.g. `0.5`, `1.25`, `-2.75`, `0.0625`).
///
/// Restricting the fast path to exact binary floats avoids any IEEE-754 ULP tie-breaking
/// divergence between Ruby's `dtoa` and Rust's float formatter; all other floats
/// (scientific notation, non-dyadic decimals, `NaN`, `±Infinity`) return `false` to
/// defer cleanly to Ruby.
#[inline]
pub fn write_json_float(out: &mut String, value: f64) -> bool {
    if !value.is_finite() {
        return false;
    }
    if value == 0.0 {
        out.push_str(if value.is_sign_negative() {
            "-0.0"
        } else {
            "0.0"
        });
        return true;
    }
    let abs = value.abs();
    if abs < 1e15 && value.fract() == 0.0 {
        let _ = write!(out, "{value:.1}");
        return true;
    }
    if abs < 1e9 && (value * 16.0).fract() == 0.0 {
        let _ = write!(out, "{value}");
        return true;
    }
    false
}

/// Convenience wrapper around [`write_json_float`] returning an owned `Option<String>`.
pub fn format_json_float(value: f64) -> Option<String> {
    let mut out = String::with_capacity(24);
    write_json_float(&mut out, value).then_some(out)
}

/// Streams a single reaction JSON object (`{"col0":val0,...}`) in the exact order of
/// `column_names`, using ActiveSupport HTML-safe JSON string escaping (`<`, `>`, `&`,
/// U+2028, U+2029).
///
/// Returns `false` if `column_names.len() != values.len()` or any value is outside
/// the fast-path domain (e.g. out-of-range timestamp or scientific-notation float).
pub fn write_reaction_object(
    out: &mut String,
    column_names: &[&str],
    values: &[ReactionFieldValue<'_>],
) -> bool {
    if column_names.len() != values.len() {
        return false;
    }

    out.push('{');
    for (idx, (&col, val)) in column_names.iter().zip(values.iter()).enumerate() {
        if idx > 0 {
            out.push(',');
        }
        write_json_string(out, col, true);
        out.push(':');
        match val {
            ReactionFieldValue::Null => out.push_str("null"),
            ReactionFieldValue::Int(n) => {
                let _ = write!(out, "{n}");
            }
            ReactionFieldValue::Float(f) => {
                if !write_json_float(out, *f) {
                    return false;
                }
            }
            ReactionFieldValue::Str(s) => write_json_string(out, s, true),
            ReactionFieldValue::UtcMillis { secs, millis } => {
                out.push('"');
                if !write_utc_iso8601_millis(out, *secs, *millis) {
                    return false;
                }
                out.push('"');
            }
            ReactionFieldValue::Bool(b) => out.push_str(if *b { "true" } else { "false" }),
        }
    }
    out.push('}');
    true
}

#[inline]
fn write_envelope_prefix(out: &mut String, user_id: Option<i64>) {
    out.push_str("{\"current_user\":{\"id\":");
    match user_id {
        Some(id) => {
            let _ = write!(out, "{id}");
        }
        None => out.push_str("null"),
    }
    out.push_str("},\"reactions\":[");
}

#[inline]
fn is_readinglist_row(row: &[ReactionFieldValue<'_>], category_col_idx: Option<usize>) -> bool {
    matches!(
        category_col_idx.and_then(|idx| row.get(idx)),
        Some(ReactionFieldValue::Str("readinglist"))
    )
}

/// Streams the complete `GET /reactions?article_id=...` JSON response in a single pass:
///
/// `{"current_user":{"id":...},"reactions":[...],"article_reaction_counts":[...]}`
///
/// Public reactions are emitted before any `"readinglist"` reaction while preserving relative
/// order within each partition (matching `Reaction.where(...).partition { |r| r.category == "readinglist" }`).
pub fn serialize_article_reactions_json(
    user_id: Option<i64>,
    column_names: &[&str],
    category_col_idx: Option<usize>,
    reaction_values: &[ReactionFieldValue<'_>],
    article_counts: &[ArticleReactionCount<'_>],
) -> Option<String> {
    let width = column_names.len();
    let row_count = match reaction_values.len().checked_div(width) {
        Some(count) if count * width == reaction_values.len() => count,
        None if reaction_values.is_empty() => 0,
        _ => return None,
    };
    let mut out = String::with_capacity(96 + row_count * 224 + article_counts.len() * 36);
    write_envelope_prefix(&mut out, user_id);

    let mut emitted_any = false;
    let mut has_readinglist = false;
    for row_idx in 0..row_count {
        let row = &reaction_values[row_idx * width..(row_idx + 1) * width];
        if is_readinglist_row(row, category_col_idx) {
            has_readinglist = true;
            continue;
        }
        if emitted_any {
            out.push(',');
        }
        if !write_reaction_object(&mut out, column_names, row) {
            return None;
        }
        emitted_any = true;
    }

    if has_readinglist {
        for row_idx in 0..row_count {
            let row = &reaction_values[row_idx * width..(row_idx + 1) * width];
            if !is_readinglist_row(row, category_col_idx) {
                continue;
            }
            if emitted_any {
                out.push(',');
            }
            if !write_reaction_object(&mut out, column_names, row) {
                return None;
            }
            emitted_any = true;
        }
    }

    out.push_str("],\"article_reaction_counts\":[");
    for (idx, entry) in article_counts.iter().enumerate() {
        if idx > 0 {
            out.push(',');
        }
        out.push_str("{\"category\":");
        write_json_string(&mut out, entry.category, true);
        out.push_str(",\"count\":");
        let _ = write!(out, "{}", entry.count);
        out.push('}');
    }
    out.push_str("]}");

    Some(out)
}

/// Streams the complete `GET /reactions?commentable_id=...&commentable_type=...` JSON response
/// in a single pass:
///
/// `{"current_user":{"id":...},"reactions":[...],"public_reaction_counts":[{"id":...,"count":...},...]}`
pub fn serialize_comment_reactions_json(
    user_id: Option<i64>,
    column_names: &[&str],
    reaction_values: &[ReactionFieldValue<'_>],
    comment_counts: &[CommentReactionCount],
) -> Option<String> {
    let width = column_names.len();
    let row_count = match reaction_values.len().checked_div(width) {
        Some(count) if count * width == reaction_values.len() => count,
        None if reaction_values.is_empty() => 0,
        _ => return None,
    };
    let mut out = String::with_capacity(96 + row_count * 224 + comment_counts.len() * 28);
    write_envelope_prefix(&mut out, user_id);

    for row_idx in 0..row_count {
        if row_idx > 0 {
            out.push(',');
        }
        let row = &reaction_values[row_idx * width..(row_idx + 1) * width];
        if !write_reaction_object(&mut out, column_names, row) {
            return None;
        }
    }

    out.push_str("],\"public_reaction_counts\":[");
    for (idx, entry) in comment_counts.iter().enumerate() {
        if idx > 0 {
            out.push(',');
        }
        let _ = write!(out, "{{\"id\":{},\"count\":{}}}", entry.id, entry.count);
    }
    out.push_str("]}");

    Some(out)
}

#[cfg(test)]
mod tests {
    use super::*;

    const SAMPLE_COLUMNS: [&str; 9] = [
        "id",
        "category",
        "reactable_id",
        "reactable_type",
        "user_id",
        "created_at",
        "updated_at",
        "points",
        "status",
    ];

    #[test]
    fn formats_json_floats_matching_ruby() {
        assert_eq!(format_json_float(0.0).as_deref(), Some("0.0"));
        assert_eq!(format_json_float(-0.0).as_deref(), Some("-0.0"));
        assert_eq!(format_json_float(1.0).as_deref(), Some("1.0"));
        assert_eq!(format_json_float(-1.0).as_deref(), Some("-1.0"));
        assert_eq!(format_json_float(0.5).as_deref(), Some("0.5"));
        assert_eq!(format_json_float(1.25).as_deref(), Some("1.25"));
        assert_eq!(format_json_float(-0.0625).as_deref(), Some("-0.0625"));
        assert_eq!(
            format_json_float(1e14).as_deref(),
            Some("100000000000000.0")
        );
        // Out-of-domain floats (non-dyadic, scientific notation, non-finite) defer to Ruby.
        assert_eq!(format_json_float(0.3), None);
        assert_eq!(format_json_float(1e-5), None);
        assert_eq!(format_json_float(1e15), None);
        assert_eq!(format_json_float(f64::NAN), None);
        assert_eq!(format_json_float(f64::INFINITY), None);
        assert_eq!(format_json_float(f64::NEG_INFINITY), None);
    }

    #[test]
    fn serializes_article_reactions_with_readinglist_partitioned_last() {
        let rows = [
            // Row 0: readinglist (should be emitted AFTER public reactions)
            ReactionFieldValue::Int(10),
            ReactionFieldValue::Str("readinglist"),
            ReactionFieldValue::Int(42),
            ReactionFieldValue::Str("Article"),
            ReactionFieldValue::Int(7),
            ReactionFieldValue::UtcMillis {
                secs: 1_700_000_000,
                millis: 123,
            },
            ReactionFieldValue::UtcMillis {
                secs: 1_700_000_001,
                millis: 45,
            },
            ReactionFieldValue::Float(1.0),
            ReactionFieldValue::Str("valid"),
            // Row 1: like (public, emitted first)
            ReactionFieldValue::Int(11),
            ReactionFieldValue::Str("like"),
            ReactionFieldValue::Int(42),
            ReactionFieldValue::Str("Article"),
            ReactionFieldValue::Int(7),
            ReactionFieldValue::UtcMillis {
                secs: 1_700_000_002,
                millis: 0,
            },
            ReactionFieldValue::UtcMillis {
                secs: 1_700_000_002,
                millis: 999,
            },
            ReactionFieldValue::Float(2.5),
            ReactionFieldValue::Str("confirmed"),
        ];
        let counts = [
            ArticleReactionCount {
                category: "like",
                count: 5,
            },
            ArticleReactionCount {
                category: "readinglist",
                count: 1,
            },
        ];

        let json =
            serialize_article_reactions_json(Some(7), &SAMPLE_COLUMNS, Some(1), &rows, &counts)
                .expect("valid article reactions JSON");

        assert_eq!(
            json,
            concat!(
                r#"{"current_user":{"id":7},"reactions":["#,
                r#"{"id":11,"category":"like","reactable_id":42,"reactable_type":"Article","user_id":7,"created_at":"2023-11-14T22:13:22.000Z","updated_at":"2023-11-14T22:13:22.999Z","points":2.5,"status":"confirmed"},"#,
                r#"{"id":10,"category":"readinglist","reactable_id":42,"reactable_type":"Article","user_id":7,"created_at":"2023-11-14T22:13:20.123Z","updated_at":"2023-11-14T22:13:21.045Z","points":1.0,"status":"valid"}"#,
                r#"],"article_reaction_counts":[{"category":"like","count":5},{"category":"readinglist","count":1}]}"#
            )
        );
    }

    #[test]
    fn serializes_signed_out_comment_reactions() {
        let counts = [
            CommentReactionCount { id: 101, count: 3 },
            CommentReactionCount { id: 102, count: 0 },
        ];
        let json = serialize_comment_reactions_json(None, &SAMPLE_COLUMNS, &[], &counts)
            .expect("valid comment reactions JSON");

        assert_eq!(
            json,
            r#"{"current_user":{"id":null},"reactions":[],"public_reaction_counts":[{"id":101,"count":3},{"id":102,"count":0}]}"#
        );
    }

    #[test]
    fn escapes_html_entities_and_unicode_separators() {
        let cols = ["category", "status"];
        let rows = [
            ReactionFieldValue::Str("<script>&"),
            ReactionFieldValue::Str("ok\u{2028}\u{2029}"),
        ];
        let counts = [ArticleReactionCount {
            category: "a&b<c>",
            count: 2,
        }];
        let json = serialize_article_reactions_json(Some(1), &cols, Some(0), &rows, &counts)
            .expect("escaped JSON");
        assert_eq!(
            json,
            r#"{"current_user":{"id":1},"reactions":[{"category":"\u003cscript\u003e\u0026","status":"ok\u2028\u2029"}],"article_reaction_counts":[{"category":"a\u0026b\u003cc\u003e","count":2}]}"#
        );
    }

    #[test]
    fn defers_on_out_of_domain_timestamp_or_float() {
        let cols = ["points"];
        let bad_float = [ReactionFieldValue::Float(1e-7)];
        assert_eq!(
            serialize_comment_reactions_json(None, &cols, &bad_float, &[]),
            None
        );

        let ts_cols = ["created_at"];
        let bad_ts = [ReactionFieldValue::UtcMillis {
            secs: 1_700_000_000,
            millis: 1_000,
        }];
        assert_eq!(
            serialize_comment_reactions_json(None, &ts_cols, &bad_ts, &[]),
            None
        );
    }
}
