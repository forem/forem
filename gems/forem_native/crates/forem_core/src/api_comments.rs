//! Single-pass arena tree builder and streaming JSON serializer for the
//! Forem Comments API (`Api::CommentsController#index` and `#show`).
//!
//! Replaces Ancestry nested-Hash arrangement, recursive `prune` Hash cloning,
//! recursive `edge_cache_keys` Array allocations, and 4-level recursive
//! Jbuilder partial rendering with a single-pass Rust pipeline:
//!
//! - **Tier 1 composable primitives**:
//!   - [`encode_base26_id`] / [`write_base26_id`]: zero-allocation base-26 `id_code`
//!     formatter matching Ruby's `Integer#to_s(26)`.
//!   - [`format_utc_iso8601`] / [`write_utc_iso8601`]: stack-allocated UTC
//!     `YYYY-MM-DDTHH:MM:SSZ` formatter matching Ruby's `Time#utc.iso8601`.
//!   - [`parse_ancestry_parent_id`]: zero-allocation ancestry parent ID extractor.
//! - **Tier 2 single-pass pipeline kernel**:
//!   - [`serialize_api_comments_json`]: builds an arena-indexed comment tree,
//!     applies `max_depth` pruning and optional root-level pagination, collects
//!     included comment IDs for Fastly `Surrogate-Key` headers, and streams the
//!     complete JSON payload into a single pre-sized buffer using
//!     [`crate::json::write_json_string`].

use std::collections::HashMap;
use std::fmt::Write;

use crate::json::write_json_string;

const BASE26_DIGITS: &[u8; 26] = b"0123456789abcdefghijklmnop";

const AI_DISCLOSURE_KEYS: [&str; 4] = ["not_disclosed", "no_ai", "some_ai", "fully_autonomous"];

/// Flat representation of a comment row fetched from PostgreSQL.
#[derive(Debug, Clone, Copy)]
pub struct ApiCommentRow<'a> {
    pub id: i64,
    pub ancestry: Option<&'a str>,
    pub processed_html: Option<&'a str>,
    /// Index into the deduplicated `users` slice, or `-1` when deleted/hidden.
    pub user_idx: i64,
    pub deleted: bool,
    pub hidden: bool,
    /// UTC epoch seconds (`Time#tv_sec`), or `None` when `created_at` is `nil`.
    pub created_at_sec: Option<i64>,
    /// `0` = `not_disclosed`, `1` = `no_ai`, `2` = `some_ai`, `3` = `fully_autonomous`.
    pub ai_disclosure_idx: u8,
}

/// Deduplicated user payload for `api/v0/shared/_user.json.jbuilder`.
#[derive(Debug, Clone, Copy)]
pub struct ApiCommentUser<'a> {
    pub id: i64,
    pub name: Option<&'a str>,
    pub username: Option<&'a str>,
    pub twitter_username: Option<&'a str>,
    pub github_username: Option<&'a str>,
    pub website_url: Option<&'a str>,
    pub profile_image: Option<&'a str>,
    pub profile_image_90: Option<&'a str>,
}

/// Pre-resolved localized strings passed from Ruby.
#[derive(Debug, Clone, Copy)]
pub struct ApiCommentLabels<'a> {
    pub deleted_body_html: &'a str,
    pub hidden_body_html: &'a str,
    pub ai_disclosure_labels: [&'a str; 4],
}

/// Tree pruning, pagination, and JSON escaping options.
#[derive(Debug, Clone, Copy)]
pub struct ApiCommentsOptions {
    pub max_depth: usize,
    /// `false` for `#index` (JSON array of root threads), `true` for `#show` (single root object).
    pub single_root: bool,
    pub root_offset: usize,
    pub root_limit: Option<usize>,
    pub escape_html_entities: bool,
}

/// Writes `id` formatted in base 26 (matching Ruby's `id.to_s(26)`) directly into `out`
/// using a 16-byte stack buffer with zero heap allocations.
pub fn write_base26_id(out: &mut String, id: i64) {
    if id == 0 {
        out.push('0');
        return;
    }

    let negative = id < 0;
    let mut n = id.unsigned_abs();
    let mut buf = [0u8; 16];
    let mut pos = buf.len();

    while n > 0 {
        pos -= 1;
        buf[pos] = BASE26_DIGITS[(n % 26) as usize];
        n /= 26;
    }

    if negative {
        pos -= 1;
        buf[pos] = b'-';
    }

    // SAFETY: `buf[pos..]` contains only ASCII digits, lowercase letters, and optional '-'.
    let s = unsafe { std::str::from_utf8_unchecked(&buf[pos..]) };
    out.push_str(s);
}

/// Formats `id` in base 26, matching Ruby's `id.to_s(26)` (e.g. `1000` -> `"1cc"`).
pub fn encode_base26_id(id: i64) -> String {
    let mut out = String::with_capacity(14);
    write_base26_id(&mut out, id);
    out
}

/// Converts days since Unix epoch (`1970-01-01`) to proleptic Gregorian `(year, month, day)`.
///
/// Uses Howard Hinnant's `civil_from_days` algorithm.
#[inline]
pub(crate) fn civil_from_days(days_since_epoch: i64) -> (i64, u32, u32) {
    let z = days_since_epoch + 719_468;
    let era = z.div_euclid(146_097);
    let doe = (z - era * 146_097) as u64; // [0, 146096]
    let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365; // [0, 399]
    let y = (yoe as i64) + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100); // [0, 365]
    let mp = (5 * doy + 2) / 153; // [0, 11]
    let d = (doy - (153 * mp + 2) / 5 + 1) as u32; // [1, 31]
    let m = (if mp < 10 { mp + 3 } else { mp - 9 }) as u32; // [1, 12]
    let year = y + i64::from(m <= 2);
    (year, m, d)
}

/// Writes `epoch_secs` as UTC ISO-8601 (`YYYY-MM-DDTHH:MM:SSZ`) into `out` using a
/// 20-byte stack buffer, matching Ruby's `Time.at(epoch_secs).utc.iso8601`.
///
/// Returns `false` if the resulting year is outside `0000..=9999` (deferring to Ruby).
pub fn write_utc_iso8601(out: &mut String, epoch_secs: i64) -> bool {
    let days = epoch_secs.div_euclid(86_400);
    let secs_of_day = epoch_secs.rem_euclid(86_400) as u32;

    let (year, month, day) = civil_from_days(days);
    if !(0..=9999).contains(&year) {
        return false;
    }

    let y = year as u32;
    let hour = secs_of_day / 3600;
    let minute = (secs_of_day % 3600) / 60;
    let second = secs_of_day % 60;

    let buf: [u8; 20] = [
        b'0' + (y / 1000) as u8,
        b'0' + ((y / 100) % 10) as u8,
        b'0' + ((y / 10) % 10) as u8,
        b'0' + (y % 10) as u8,
        b'-',
        b'0' + (month / 10) as u8,
        b'0' + (month % 10) as u8,
        b'-',
        b'0' + (day / 10) as u8,
        b'0' + (day % 10) as u8,
        b'T',
        b'0' + (hour / 10) as u8,
        b'0' + (hour % 10) as u8,
        b':',
        b'0' + (minute / 10) as u8,
        b'0' + (minute % 10) as u8,
        b':',
        b'0' + (second / 10) as u8,
        b'0' + (second % 10) as u8,
        b'Z',
    ];

    // SAFETY: `buf` is strictly ASCII.
    let s = unsafe { std::str::from_utf8_unchecked(&buf) };
    out.push_str(s);
    true
}

/// Formats `epoch_secs` as UTC ISO-8601 (`YYYY-MM-DDTHH:MM:SSZ`), returning `None`
/// for years outside `0000..=9999`.
pub fn format_utc_iso8601(epoch_secs: i64) -> Option<String> {
    let mut out = String::with_capacity(20);
    if write_utc_iso8601(&mut out, epoch_secs) {
        Some(out)
    } else {
        None
    }
}

/// Extracts the immediate parent ID from an `ancestry` path string (e.g. `"12/34/56"` -> `Some(Some(56))`).
///
/// - `None` or `Some("")` -> `Some(None)` (root comment).
/// - Valid `/`-separated sequence of positive integer IDs -> `Some(Some(parent_id))`.
/// - Malformed ancestry (leading/trailing `/`, empty segment, non-digit, `0`, overflow) -> `None`.
pub fn parse_ancestry_parent_id(ancestry: Option<&str>) -> Option<Option<i64>> {
    let raw = match ancestry {
        None | Some("") => return Some(None),
        Some(s) => s,
    };

    let mut segment_val: i64 = 0;
    let mut segment_len: usize = 0;

    for &b in raw.as_bytes() {
        if b == b'/' {
            if segment_len == 0 || segment_val <= 0 {
                return None;
            }
            segment_val = 0;
            segment_len = 0;
        } else if b.is_ascii_digit() {
            segment_val = segment_val
                .checked_mul(10)?
                .checked_add(i64::from(b - b'0'))?;
            segment_len += 1;
        } else {
            return None;
        }
    }

    if segment_len == 0 || segment_val <= 0 {
        return None;
    }

    Some(Some(segment_val))
}

#[inline]
fn write_opt_json_string(out: &mut String, value: Option<&str>, escape_html: bool) {
    match value {
        Some(s) => write_json_string(out, s, escape_html),
        None => out.push_str("null"),
    }
}

struct WriteContext<'a> {
    rows: &'a [ApiCommentRow<'a>],
    users: &'a [ApiCommentUser<'a>],
    children: &'a [Vec<usize>],
    labels: &'a ApiCommentLabels<'a>,
    max_depth: usize,
    escape_html: bool,
}

enum WriteFrame {
    Enter {
        idx: usize,
        depth: usize,
        needs_comma: bool,
    },
    Close,
}

fn write_comment_node(
    ctx: &WriteContext<'_>,
    root_idx: usize,
    out: &mut String,
    included_ids: &mut Vec<i64>,
) -> bool {
    let mut stack = Vec::with_capacity(64);
    stack.push(WriteFrame::Enter {
        idx: root_idx,
        depth: 0,
        needs_comma: false,
    });

    while let Some(frame) = stack.pop() {
        match frame {
            WriteFrame::Close => {
                out.push_str("]}");
            }
            WriteFrame::Enter {
                idx,
                depth,
                needs_comma,
            } => {
                let row = &ctx.rows[idx];
                let ai_idx = row.ai_disclosure_idx as usize;
                if ai_idx >= AI_DISCLOSURE_KEYS.len() {
                    return false;
                }

                if needs_comma {
                    out.push(',');
                }

                included_ids.push(row.id);

                out.push_str("{\"type_of\":\"comment\",\"id_code\":\"");
                write_base26_id(out, row.id);
                out.push_str("\",\"created_at\":");
                match row.created_at_sec {
                    Some(sec) => {
                        out.push('"');
                        if !write_utc_iso8601(out, sec) {
                            return false;
                        }
                        out.push('"');
                    }
                    None => out.push_str("null"),
                }

                out.push_str(",\"ai_disclosure_level\":");
                write_json_string(out, AI_DISCLOSURE_KEYS[ai_idx], ctx.escape_html);
                out.push_str(",\"ai_disclosure_label\":");
                write_json_string(
                    out,
                    ctx.labels.ai_disclosure_labels[ai_idx],
                    ctx.escape_html,
                );

                if row.deleted {
                    out.push_str(",\"body_html\":");
                    write_json_string(out, ctx.labels.deleted_body_html, ctx.escape_html);
                    out.push_str(",\"user\":{}");
                } else if row.hidden {
                    out.push_str(",\"body_html\":");
                    write_json_string(out, ctx.labels.hidden_body_html, ctx.escape_html);
                    out.push_str(",\"user\":{}");
                } else {
                    let user = match usize::try_from(row.user_idx)
                        .ok()
                        .and_then(|u_idx| ctx.users.get(u_idx))
                    {
                        Some(u) => u,
                        None => return false,
                    };

                    out.push_str(",\"body_html\":");
                    write_opt_json_string(out, row.processed_html, ctx.escape_html);

                    out.push_str(",\"user\":{\"name\":");
                    write_opt_json_string(out, user.name, ctx.escape_html);
                    out.push_str(",\"username\":");
                    write_opt_json_string(out, user.username, ctx.escape_html);
                    out.push_str(",\"twitter_username\":");
                    write_opt_json_string(out, user.twitter_username, ctx.escape_html);
                    out.push_str(",\"github_username\":");
                    write_opt_json_string(out, user.github_username, ctx.escape_html);
                    out.push_str(",\"user_id\":");
                    let _ = write!(out, "{}", user.id);
                    out.push_str(",\"website_url\":");
                    write_opt_json_string(out, user.website_url, ctx.escape_html);
                    out.push_str(",\"profile_image\":");
                    write_opt_json_string(out, user.profile_image, ctx.escape_html);
                    out.push_str(",\"profile_image_90\":");
                    write_opt_json_string(out, user.profile_image_90, ctx.escape_html);
                    out.push('}');
                }

                out.push_str(",\"children\":[");
                stack.push(WriteFrame::Close);

                let next_depth = depth + 1;
                if next_depth < ctx.max_depth {
                    for (child_pos, &child_idx) in ctx.children[idx].iter().enumerate().rev() {
                        stack.push(WriteFrame::Enter {
                            idx: child_idx,
                            depth: next_depth,
                            needs_comma: child_pos > 0,
                        });
                    }
                }
            }
        }
    }

    true
}

/// Builds the nested comment tree from flat rows, applies `max_depth` pruning and optional
/// root-level pagination, and streams the exact Jbuilder-equivalent JSON payload plus the
/// list of included comment IDs (for Fastly `Surrogate-Key` headers) in a single pass.
///
/// Graph-integrity checks (ancestry path syntax, duplicate comment IDs, cycles, and
/// `single_root` root-count validation) run across all supplied rows before pagination.
/// Per-node payload validation (active `user_idx` lookup, `ai_disclosure_idx` range, and
/// UTC timestamp year `0000..=9999`) applies to emitted nodes only (matching Jbuilder,
/// which only evaluates those fields when rendering a node).
///
/// Returns `None` if any checked input falls outside the strict fast-path domain,
/// signaling the caller to fall back to Ruby/Jbuilder.
pub fn serialize_api_comments_json(
    rows: &[ApiCommentRow<'_>],
    users: &[ApiCommentUser<'_>],
    labels: &ApiCommentLabels<'_>,
    options: &ApiCommentsOptions,
) -> Option<(String, Vec<i64>)> {
    if rows.is_empty() {
        return if options.single_root {
            None
        } else {
            Some(("[]".to_string(), Vec::new()))
        };
    }

    let mut id_to_idx: HashMap<i64, usize> = HashMap::with_capacity(rows.len());
    for (idx, row) in rows.iter().enumerate() {
        if id_to_idx.insert(row.id, idx).is_some() {
            return None;
        }
    }

    let mut children: Vec<Vec<usize>> = vec![Vec::new(); rows.len()];
    let mut roots: Vec<usize> = Vec::new();

    for (idx, row) in rows.iter().enumerate() {
        let parent_id = parse_ancestry_parent_id(row.ancestry)?;
        match parent_id.and_then(|pid| id_to_idx.get(&pid).copied()) {
            Some(parent_idx) => {
                if parent_idx == idx {
                    return None;
                }
                children[parent_idx].push(idx);
            }
            None => roots.push(idx),
        }
    }

    // Verify every row is reachable from a root so disconnected cyclic components
    // (e.g. two rows naming each other as parent alongside a valid root) defer to Ruby.
    let mut visited_count: usize = 0;
    let mut reach_stack: Vec<usize> = roots.clone();
    while let Some(node_idx) = reach_stack.pop() {
        visited_count += 1;
        if visited_count > rows.len() {
            return None;
        }
        reach_stack.extend_from_slice(&children[node_idx]);
    }
    if visited_count != rows.len() {
        return None;
    }

    if options.max_depth == 0 {
        return if options.single_root {
            None
        } else {
            Some(("[]".to_string(), Vec::new()))
        };
    }

    let (selected_roots, is_full_tree): (&[usize], bool) = if options.single_root {
        if roots.len() != 1 {
            return None;
        }
        (&roots[..1], true)
    } else {
        let start = options.root_offset.min(roots.len());
        let end = match options.root_limit {
            Some(limit) => start.saturating_add(limit).min(roots.len()),
            None => roots.len(),
        };
        if start >= end {
            return Some(("[]".to_string(), Vec::new()));
        }
        (&roots[start..end], start == 0 && end == roots.len())
    };

    let (selected_count, html_bytes) = if is_full_tree {
        let bytes: usize = rows
            .iter()
            .map(|r| r.processed_html.map_or(0, str::len))
            .sum();
        (rows.len(), bytes)
    } else {
        let mut count: usize = 0;
        let mut bytes: usize = 0;
        let mut est_stack: Vec<(usize, usize)> = selected_roots.iter().map(|&r| (r, 0)).collect();
        while let Some((node_idx, depth)) = est_stack.pop() {
            count += 1;
            bytes = bytes.saturating_add(rows[node_idx].processed_html.map_or(0, str::len));
            let next_depth = depth + 1;
            if next_depth < options.max_depth {
                for &child_idx in &children[node_idx] {
                    est_stack.push((child_idx, next_depth));
                }
            }
        }
        (count, bytes)
    };

    let estimated_capacity = html_bytes.saturating_add(selected_count.saturating_mul(320));
    let mut out = String::with_capacity(estimated_capacity.max(64));
    let mut included_ids = Vec::with_capacity(selected_count);

    let ctx = WriteContext {
        rows,
        users,
        children: &children,
        labels,
        max_depth: options.max_depth,
        escape_html: options.escape_html_entities,
    };

    if options.single_root {
        if !write_comment_node(&ctx, selected_roots[0], &mut out, &mut included_ids) {
            return None;
        }
    } else {
        out.push('[');
        for (pos, &root_idx) in selected_roots.iter().enumerate() {
            if pos > 0 {
                out.push(',');
            }
            if !write_comment_node(&ctx, root_idx, &mut out, &mut included_ids) {
                return None;
            }
        }
        out.push(']');
    }

    Some((out, included_ids))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_labels() -> ApiCommentLabels<'static> {
        ApiCommentLabels {
            deleted_body_html: "<p>[deleted]</p>",
            hidden_body_html: "<p>[hidden by post author]</p>",
            ai_disclosure_labels: ["Not disclosed", "No AI", "Some AI", "Fully autonomous"],
        }
    }

    fn sample_user() -> ApiCommentUser<'static> {
        ApiCommentUser {
            id: 42,
            name: Some("Ada Lovelace"),
            username: Some("ada"),
            twitter_username: Some("ada_dev"),
            github_username: None,
            website_url: Some("https://ada.example.com"),
            profile_image: Some("https://img.example.com/640.png"),
            profile_image_90: Some("https://img.example.com/90.png"),
        }
    }

    #[test]
    fn encodes_base26_ids_matching_ruby() {
        assert_eq!(encode_base26_id(0), "0");
        assert_eq!(encode_base26_id(1), "1");
        assert_eq!(encode_base26_id(25), "p");
        assert_eq!(encode_base26_id(26), "10");
        assert_eq!(encode_base26_id(1000), "1cc");
        assert_eq!(encode_base26_id(123_456_789), "aa44a1");
        assert_eq!(encode_base26_id(-1000), "-1cc");
        assert_eq!(encode_base26_id(i64::MIN), "-3igoecjbmca688");
    }

    #[test]
    fn formats_utc_iso8601_across_calendar_boundaries() {
        assert_eq!(
            format_utc_iso8601(0).as_deref(),
            Some("1970-01-01T00:00:00Z")
        );
        assert_eq!(
            format_utc_iso8601(-1).as_deref(),
            Some("1969-12-31T23:59:59Z")
        );
        assert_eq!(
            format_utc_iso8601(951_782_400).as_deref(),
            Some("2000-02-29T00:00:00Z")
        );
        assert_eq!(
            format_utc_iso8601(1_709_251_199).as_deref(),
            Some("2024-02-29T23:59:59Z")
        );
        assert_eq!(
            format_utc_iso8601(1_709_251_200).as_deref(),
            Some("2024-03-01T00:00:00Z")
        );
        // 1900 is not a leap year
        assert_eq!(
            format_utc_iso8601(-2_203_977_600).as_deref(),
            Some("1900-02-28T00:00:00Z")
        );
        assert_eq!(
            format_utc_iso8601(-2_203_891_200).as_deref(),
            Some("1900-03-01T00:00:00Z")
        );
        // Year 9999 upper bound
        assert_eq!(
            format_utc_iso8601(253_402_300_799).as_deref(),
            Some("9999-12-31T23:59:59Z")
        );
        // Year 10000 defers to Ruby
        assert_eq!(format_utc_iso8601(253_402_300_800), None);
        // Year -1 defers to Ruby
        assert_eq!(format_utc_iso8601(-62_167_219_201), None);
    }

    #[test]
    fn parses_ancestry_parent_id_strictly() {
        assert_eq!(parse_ancestry_parent_id(None), Some(None));
        assert_eq!(parse_ancestry_parent_id(Some("")), Some(None));
        assert_eq!(parse_ancestry_parent_id(Some("42")), Some(Some(42)));
        assert_eq!(parse_ancestry_parent_id(Some("1/2/3/456")), Some(Some(456)));
        assert_eq!(parse_ancestry_parent_id(Some("/42")), None);
        assert_eq!(parse_ancestry_parent_id(Some("42/")), None);
        assert_eq!(parse_ancestry_parent_id(Some("1//2")), None);
        assert_eq!(parse_ancestry_parent_id(Some("abc")), None);
        assert_eq!(parse_ancestry_parent_id(Some("0")), None);
        assert_eq!(parse_ancestry_parent_id(Some("-1")), None);
        assert_eq!(parse_ancestry_parent_id(Some("0/42")), None);
        assert_eq!(parse_ancestry_parent_id(Some("12/0/42")), None);
        assert_eq!(
            parse_ancestry_parent_id(Some("9223372036854775808/42")),
            None
        );
        assert_eq!(
            parse_ancestry_parent_id(Some("9223372036854775807/42")),
            Some(Some(42))
        );
    }

    #[test]
    fn serializes_nested_tree_with_deleted_hidden_and_pruning() {
        let users = [sample_user()];
        let labels = sample_labels();
        let rows = [
            ApiCommentRow {
                id: 1000,
                ancestry: None,
                processed_html: Some("<p>Root &amp; co</p>"),
                user_idx: 0,
                deleted: false,
                hidden: false,
                created_at_sec: Some(1_700_000_000),
                ai_disclosure_idx: 2,
            },
            ApiCommentRow {
                id: 1001,
                ancestry: Some("1000"),
                processed_html: Some("<p>Secret</p>"),
                user_idx: -1,
                deleted: true,
                hidden: true,
                created_at_sec: Some(1_700_000_060),
                ai_disclosure_idx: 0,
            },
            ApiCommentRow {
                id: 1002,
                ancestry: Some("1000/1001"),
                processed_html: Some("<p>Grandchild</p>"),
                user_idx: 0,
                deleted: false,
                hidden: false,
                created_at_sec: None,
                ai_disclosure_idx: 1,
            },
        ];

        let opts = ApiCommentsOptions {
            max_depth: 2,
            single_root: false,
            root_offset: 0,
            root_limit: None,
            escape_html_entities: true,
        };

        let (json, included) =
            serialize_api_comments_json(&rows, &users, &labels, &opts).expect("should serialize");
        assert_eq!(included, vec![1000, 1001]);
        assert!(json.contains("\"id_code\":\"1cc\""));
        assert!(json.contains("\"ai_disclosure_level\":\"some_ai\""));
        assert!(json.contains("\"body_html\":\"\\u003cp\\u003e[deleted]\\u003c/p\\u003e\""));
        assert!(json.contains("\"user\":{}"));
        assert!(!json.contains("Grandchild"));
    }

    #[test]
    fn supports_show_mode_for_nested_subtree_root_and_pagination() {
        let users = [sample_user()];
        let labels = sample_labels();
        let rows = [
            ApiCommentRow {
                id: 50,
                ancestry: Some("10/20"),
                processed_html: Some("<p>Subtree root</p>"),
                user_idx: 0,
                deleted: false,
                hidden: false,
                created_at_sec: Some(1_700_000_000),
                ai_disclosure_idx: 3,
            },
            ApiCommentRow {
                id: 51,
                ancestry: Some("10/20/50"),
                processed_html: Some("<p>Subtree child</p>"),
                user_idx: -1,
                deleted: false,
                hidden: true,
                created_at_sec: Some(1_700_000_010),
                ai_disclosure_idx: 0,
            },
        ];

        let show_opts = ApiCommentsOptions {
            max_depth: 50,
            single_root: true,
            root_offset: 0,
            root_limit: None,
            escape_html_entities: false,
        };

        let (json, included) =
            serialize_api_comments_json(&rows, &users, &labels, &show_opts).expect("show");
        assert!(json.starts_with('{') && json.ends_with('}'));
        assert_eq!(included, vec![50, 51]);
        assert!(json.contains("<p>[hidden by post author]</p>"));
        assert!(json.contains("\"ai_disclosure_level\":\"fully_autonomous\""));

        let page_opts = ApiCommentsOptions {
            max_depth: 50,
            single_root: false,
            root_offset: 1,
            root_limit: Some(10),
            escape_html_entities: false,
        };
        let (paged_json, paged_ids) =
            serialize_api_comments_json(&rows, &users, &labels, &page_opts).expect("paged");
        assert_eq!(paged_json, "[]");
        assert!(paged_ids.is_empty());
    }

    #[test]
    fn defers_to_ruby_on_out_of_domain_inputs() {
        let users = [sample_user()];
        let labels = sample_labels();
        let opts = ApiCommentsOptions {
            max_depth: 50,
            single_root: false,
            root_offset: 0,
            root_limit: None,
            escape_html_entities: true,
        };

        // Missing user index for active comment
        let bad_user = [ApiCommentRow {
            id: 1,
            ancestry: None,
            processed_html: Some("hi"),
            user_idx: 5,
            deleted: false,
            hidden: false,
            created_at_sec: Some(0),
            ai_disclosure_idx: 0,
        }];
        assert!(serialize_api_comments_json(&bad_user, &users, &labels, &opts).is_none());

        // Malformed ancestry
        let bad_ancestry = [ApiCommentRow {
            id: 1,
            ancestry: Some("bad/path"),
            processed_html: Some("hi"),
            user_idx: 0,
            deleted: false,
            hidden: false,
            created_at_sec: Some(0),
            ai_disclosure_idx: 0,
        }];
        assert!(serialize_api_comments_json(&bad_ancestry, &users, &labels, &opts).is_none());

        // Empty in single_root mode
        let show_opts = ApiCommentsOptions {
            single_root: true,
            ..opts
        };
        assert!(serialize_api_comments_json(&[], &users, &labels, &show_opts).is_none());

        // Multiple disconnected roots in single_root mode defer to Ruby so legacy_show
        // preserves edge_cache_keys for all arranged trees
        let multi_roots = [
            ApiCommentRow {
                id: 1,
                ancestry: None,
                processed_html: Some("a"),
                user_idx: 0,
                deleted: false,
                hidden: false,
                created_at_sec: Some(0),
                ai_disclosure_idx: 0,
            },
            ApiCommentRow {
                id: 2,
                ancestry: None,
                processed_html: Some("b"),
                user_idx: 0,
                deleted: false,
                hidden: false,
                created_at_sec: Some(0),
                ai_disclosure_idx: 0,
            },
        ];
        assert!(serialize_api_comments_json(&multi_roots, &users, &labels, &show_opts).is_none());

        // Disconnected 2-node cycle alongside a valid root must return None in both modes
        let cyclic_rows = [
            ApiCommentRow {
                id: 1,
                ancestry: None,
                processed_html: Some("root"),
                user_idx: 0,
                deleted: false,
                hidden: false,
                created_at_sec: Some(0),
                ai_disclosure_idx: 0,
            },
            ApiCommentRow {
                id: 2,
                ancestry: Some("3"),
                processed_html: Some("cycle a"),
                user_idx: 0,
                deleted: false,
                hidden: false,
                created_at_sec: Some(0),
                ai_disclosure_idx: 0,
            },
            ApiCommentRow {
                id: 3,
                ancestry: Some("2"),
                processed_html: Some("cycle b"),
                user_idx: 0,
                deleted: false,
                hidden: false,
                created_at_sec: Some(0),
                ai_disclosure_idx: 0,
            },
        ];
        assert!(serialize_api_comments_json(&cyclic_rows, &users, &labels, &opts).is_none());
        assert!(serialize_api_comments_json(&cyclic_rows, &users, &labels, &show_opts).is_none());

        // Duplicate IDs must still be rejected even when max_depth == 0
        let zero_depth_opts = ApiCommentsOptions {
            max_depth: 0,
            ..opts
        };
        let dup_rows = [
            ApiCommentRow {
                id: 1,
                ancestry: None,
                processed_html: Some("a"),
                user_idx: 0,
                deleted: false,
                hidden: false,
                created_at_sec: Some(0),
                ai_disclosure_idx: 0,
            },
            ApiCommentRow {
                id: 1,
                ancestry: None,
                processed_html: Some("b"),
                user_idx: 0,
                deleted: false,
                hidden: false,
                created_at_sec: Some(0),
                ai_disclosure_idx: 0,
            },
        ];
        assert!(
            serialize_api_comments_json(&dup_rows, &users, &labels, &zero_depth_opts).is_none()
        );
    }

    #[test]
    fn serializes_very_deep_reply_chain_iteratively_without_stack_overflow() {
        let users = [sample_user()];
        let labels = sample_labels();
        let depth = 5_000usize;
        let ancestries: Vec<String> = (1..depth).map(|i| i.to_string()).collect();
        let mut rows = Vec::with_capacity(depth);
        rows.push(ApiCommentRow {
            id: 1,
            ancestry: None,
            processed_html: Some("<p>0</p>"),
            user_idx: 0,
            deleted: false,
            hidden: false,
            created_at_sec: Some(0),
            ai_disclosure_idx: 0,
        });
        for i in 1..depth {
            rows.push(ApiCommentRow {
                id: (i + 1) as i64,
                ancestry: Some(&ancestries[i - 1]),
                processed_html: Some("<p>x</p>"),
                user_idx: 0,
                deleted: false,
                hidden: false,
                created_at_sec: Some(0),
                ai_disclosure_idx: 0,
            });
        }
        let opts = ApiCommentsOptions {
            max_depth: 10_000,
            single_root: true,
            root_offset: 0,
            root_limit: None,
            escape_html_entities: false,
        };
        let (json, included) =
            serialize_api_comments_json(&rows, &users, &labels, &opts).expect("deep chain");
        assert_eq!(included.len(), depth);
        assert!(json.starts_with("{\"type_of\":\"comment\""));
        assert!(json.ends_with("]}"));
    }
}
