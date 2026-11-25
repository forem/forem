//! Single-pass streaming XML 1.0 sitemap serializers and ISO date primitives for
//! Forem (`SitemapsController#show` / `app/views/sitemaps/{index,posts,users,tags}.xml.erb`).
//!
//! Replaces per-row ActionView ERB rendering (`app_url` -> `URL.url` -> `join_url` FFI
//! round-trips, `Time#strftime("%F")` allocations, `ERB::Util.html_escape` allocations,
//! and custom-domain org `.map { |slug, t| ["/#{slug}", t] }` intermediate arrays) with:
//!
//! - **Tier 1 composable primitives**:
//!   - [`write_iso_date`] / [`format_iso_date`]: stack-allocated 10-byte `YYYY-MM-DD`
//!     formatter matching Ruby's `Time#strftime("%F")` for any UTC offset.
//!   - [`write_erb_html_escaped`]: single-pass HTML/XML escaper matching
//!     `ERB::Util.html_escape` (`&`, `<`, `>`, `"`, `'`).
//! - **Tier 2 single-pass streaming kernels**:
//!   - [`serialize_sitemap_index_xml`]: streams `app/views/sitemaps/index.xml.erb`
//!     into a single pre-sized UTF-8 `String` buffer.
//!   - [`serialize_sitemap_urlset_xml`] / [`serialize_sitemap_urlset_xml_indexed`]:
//!     streams `app/views/sitemaps/{posts,users,tags}.xml.erb` into a single pre-sized
//!     UTF-8 `String` buffer with optional `path_prefix` (`""`, `"/"`, `"/t/"`).

use std::fmt::Write as _;

use crate::api_comments::civil_from_days;
use crate::url::join_url;

const XML_DECL: &str = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
const SITEMAPINDEX_OPEN: &str =
    "<sitemapindex xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n";
const SITEMAPINDEX_CLOSE: &str = "</sitemapindex>\n";
const URLSET_OPEN: &str = "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n";
const URLSET_CLOSE: &str = "</urlset>\n";

/// Maximum sitemap index page count handled on the native fast path to guard against
/// accidental runaway allocations on malformed counts.
const MAX_INDEX_LAST_PAGE: i64 = 100_000;

/// Writes a `YYYY-MM-DD` calendar date for `(unix_secs, utc_offset_secs)` into `out`,
/// matching Ruby's `Time#strftime("%F")`.
///
/// Returns `None` if adding `utc_offset_secs` overflows or the local year falls outside
/// `0..=9999`.
pub fn write_iso_date(out: &mut String, unix_secs: i64, utc_offset_secs: i32) -> Option<()> {
    let local_secs = unix_secs.checked_add(i64::from(utc_offset_secs))?;
    let days = local_secs.div_euclid(86_400);
    let (year, month, day) = civil_from_days(days);
    if !(0..=9999).contains(&year) {
        return None;
    }

    let y = year as u32;
    let m = month;
    let d = day;
    let buf = [
        b'0' + ((y / 1000) % 10) as u8,
        b'0' + ((y / 100) % 10) as u8,
        b'0' + ((y / 10) % 10) as u8,
        b'0' + (y % 10) as u8,
        b'-',
        b'0' + (m / 10) as u8,
        b'0' + (m % 10) as u8,
        b'-',
        b'0' + (d / 10) as u8,
        b'0' + (d % 10) as u8,
    ];
    let formatted = std::str::from_utf8(&buf).ok()?;
    out.push_str(formatted);
    Some(())
}

/// Formats `(unix_secs, utc_offset_secs)` as `YYYY-MM-DD`, matching `Time#strftime("%F")`.
pub fn format_iso_date(unix_secs: i64, utc_offset_secs: i32) -> Option<String> {
    let mut out = String::with_capacity(10);
    write_iso_date(&mut out, unix_secs, utc_offset_secs)?;
    Some(out)
}

/// Appends `input` to `out` with `ERB::Util.html_escape` semantics
/// (`&` -> `&amp;`, `<` -> `&lt;`, `>` -> `&gt;`, `"` -> `&quot;`, `'` -> `&#39;`).
pub fn write_erb_html_escaped(out: &mut String, input: &str) {
    let bytes = input.as_bytes();
    let mut last = 0;
    for (idx, &b) in bytes.iter().enumerate() {
        let replacement = match b {
            b'&' => "&amp;",
            b'<' => "&lt;",
            b'>' => "&gt;",
            b'"' => "&quot;",
            b'\'' => "&#39;",
            _ => continue,
        };
        if last < idx {
            out.push_str(&input[last..idx]);
        }
        out.push_str(replacement);
        last = idx + 1;
    }
    if last < input.len() {
        out.push_str(&input[last..]);
    }
}

/// Returns `true` when `path` is a non-empty relative/root-relative path containing only
/// unreserved ASCII characters (`A-Z`, `a-z`, `0-9`, `-`, `_`, `~`, `.`, `/`) with no
/// protocol-relative `//` prefix and no dot segments (`.` or `..`), so it requires neither
/// percent-encoding nor HTML entity escaping.
#[inline]
fn is_simple_unreserved_path(path: &str) -> bool {
    let bytes = path.as_bytes();
    if bytes.is_empty() || path.starts_with("//") {
        return false;
    }
    if !bytes
        .iter()
        .all(|&b| b.is_ascii_alphanumeric() || matches!(b, b'/' | b'-' | b'_' | b'.' | b'~'))
    {
        return false;
    }
    !path.split('/').any(|seg| seg == "." || seg == "..")
}

/// Writes `ERB::Util.html_escape(join_url(base_url, path)?)` into `out`, using the
/// pre-normalized `base_origin` (without trailing `/`) to avoid per-row allocations on the
/// 99.99% simple-path fast path.
#[inline]
fn write_sitemap_loc(
    out: &mut String,
    base_url: &str,
    base_origin: &str,
    path: &str,
) -> Option<()> {
    if is_simple_unreserved_path(path) {
        out.push_str(base_origin);
        if !path.starts_with('/') {
            out.push('/');
        }
        out.push_str(path);
        return Some(());
    }
    let loc = join_url(base_url, path)?;
    write_erb_html_escaped(out, &loc);
    Some(())
}

/// Normalizes a root-origin `base_url` (e.g. `"https://dev.to"` or `"https://DEV.TO:443/"`)
/// into `"https://dev.to"` (without trailing `/`), returning `None` if `base_url` contains a
/// subpath, query string, or fragment so relative path joins cannot diverge from `Addressable::URI`.
fn normalize_root_base_origin(base_url: &str) -> Option<String> {
    let normalized = join_url(base_url, "")?;
    if normalized != join_url(base_url, "/")? {
        return None;
    }
    normalized.strip_suffix('/').map(str::to_owned)
}

/// Streams `app/views/sitemaps/index.xml.erb` into a single pre-allocated UTF-8 `String`.
///
/// Returns `None` if `articles_count < 0`, `page_limit <= 0`, the resulting page count
/// exceeds [`MAX_INDEX_LAST_PAGE`], or `base_url` falls outside [`join_url`]'s fast-path
/// domain.
pub fn serialize_sitemap_index_xml(
    base_url: &str,
    articles_count: i64,
    page_limit: i64,
    include_users_and_tags: bool,
) -> Option<String> {
    if articles_count < 0 || page_limit <= 0 {
        return None;
    }

    let base_origin_owned = normalize_root_base_origin(base_url)?;
    let base_origin = base_origin_owned.as_str();

    let multi_page = articles_count > page_limit;
    let last_page = if multi_page {
        let lp = articles_count / page_limit;
        if lp > MAX_INDEX_LAST_PAGE {
            return None;
        }
        lp as usize
    } else {
        0
    };

    let entry_count =
        if multi_page { last_page + 1 } else { 1 } + if include_users_and_tags { 2 } else { 0 };
    let capacity = XML_DECL.len()
        + SITEMAPINDEX_OPEN.len()
        + SITEMAPINDEX_CLOSE.len()
        + entry_count * (base_origin.len() + 76);
    let mut out = String::with_capacity(capacity);

    out.push_str(XML_DECL);
    out.push_str(SITEMAPINDEX_OPEN);

    if multi_page {
        for n in 0..=last_page {
            out.push_str("      <sitemap>\n          <loc>");
            out.push_str(base_origin);
            let _ = write!(&mut out, "/sitemap-posts-{n}.xml");
            out.push_str("</loc>\n      </sitemap>\n");
        }
    } else {
        out.push_str("      <sitemap>\n        <loc>");
        out.push_str(base_origin);
        out.push_str("/sitemap-posts.xml</loc>\n    </sitemap>\n");
    }

    if include_users_and_tags {
        out.push_str("  <sitemap>\n      <loc>");
        out.push_str(base_origin);
        out.push_str("/sitemap-users.xml</loc>\n  </sitemap>\n");

        out.push_str("  <sitemap>\n      <loc>");
        out.push_str(base_origin);
        out.push_str("/sitemap-tags.xml</loc>\n  </sitemap>\n");
    }

    out.push_str(SITEMAPINDEX_CLOSE);
    Some(out)
}

/// Streams `app/views/sitemaps/{posts,users,tags}.xml.erb` from an indexed path arena
/// into a single pre-allocated UTF-8 `String`.
///
/// Each entry in `entries` is `(path_start, path_end, unix_secs, utc_offset_secs)` where
/// `&path_arena[path_start..path_end]` is the row's raw path/slug/username/tag name.
/// When `path_prefix` is non-empty (e.g. `"/"` for custom-domain org slugs or `"/t/"` for
/// tags), it is prepended in a single reused scratch buffer before calling [`join_url`].
///
/// Returns `None` if any row's URL falls outside [`join_url`]'s strict fast-path domain or
/// any timestamp falls outside `0000..=9999`.
pub fn serialize_sitemap_urlset_xml_indexed(
    base_url: &str,
    path_prefix: &str,
    path_arena: &str,
    entries: &[(usize, usize, i64, i32)],
) -> Option<String> {
    let base_origin_owned = normalize_root_base_origin(base_url)?;
    let base_origin = base_origin_owned.as_str();

    let per_row_overhead = 86 + base_origin.len() + path_prefix.len();
    let capacity = XML_DECL.len()
        + URLSET_OPEN.len()
        + URLSET_CLOSE.len()
        + entries.len().saturating_mul(per_row_overhead)
        + path_arena.len();
    let mut out = String::with_capacity(capacity);

    out.push_str(XML_DECL);
    out.push_str(URLSET_OPEN);

    let mut path_buf = if path_prefix.is_empty() {
        String::new()
    } else {
        String::with_capacity(path_prefix.len() + 64)
    };

    for &(start, end, unix_secs, utc_offset_secs) in entries {
        let raw_path = path_arena.get(start..end)?;
        out.push_str("    <url>\n        <loc>");
        if path_prefix.is_empty() {
            write_sitemap_loc(&mut out, base_url, base_origin, raw_path)?;
        } else {
            path_buf.clear();
            path_buf.push_str(path_prefix);
            path_buf.push_str(raw_path);
            write_sitemap_loc(&mut out, base_url, base_origin, &path_buf)?;
        }
        out.push_str("</loc>\n        <lastmod>");
        write_iso_date(&mut out, unix_secs, utc_offset_secs)?;
        out.push_str("</lastmod>\n    </url>\n");
    }

    out.push_str(URLSET_CLOSE);
    Some(out)
}

/// Convenience wrapper over [`serialize_sitemap_urlset_xml_indexed`] for `&[(&str, i64, i32)]`.
pub fn serialize_sitemap_urlset_xml(
    base_url: &str,
    path_prefix: &str,
    rows: &[(&str, i64, i32)],
) -> Option<String> {
    let total_path_len: usize = rows.iter().map(|(p, _, _)| p.len()).sum();
    let mut arena = String::with_capacity(total_path_len);
    let mut entries = Vec::with_capacity(rows.len());
    for &(path, secs, offset) in rows {
        let start = arena.len();
        arena.push_str(path);
        entries.push((start, arena.len(), secs, offset));
    }
    serialize_sitemap_urlset_xml_indexed(base_url, path_prefix, &arena, &entries)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn formats_iso_dates_across_offsets_and_leap_years() {
        // 1970-01-01 00:00:00 UTC
        assert_eq!(format_iso_date(0, 0).as_deref(), Some("1970-01-01"));
        // 1970-01-01 00:00:00 UTC in UTC-5 -> 1969-12-31
        assert_eq!(format_iso_date(0, -18_000).as_deref(), Some("1969-12-31"));
        // 2020-02-29 23:30:00 UTC (leap day)
        assert_eq!(
            format_iso_date(1_583_019_000, 0).as_deref(),
            Some("2020-02-29")
        );
        // Same instant in UTC+2 -> 2020-03-01
        assert_eq!(
            format_iso_date(1_583_019_000, 7_200).as_deref(),
            Some("2020-03-01")
        );
        // Pre-epoch date: 1969-12-31 23:59:59 UTC
        assert_eq!(format_iso_date(-1, 0).as_deref(), Some("1969-12-31"));
        // Year > 9999 returns None
        assert_eq!(format_iso_date(253_402_300_800, 0), None);
    }

    #[test]
    fn escapes_erb_html_entities() {
        let mut out = String::new();
        write_erb_html_escaped(&mut out, "https://dev.to/a?b=1&c='2'\"<3>");
        assert_eq!(out, "https://dev.to/a?b=1&amp;c=&#39;2&#39;&quot;&lt;3&gt;");
    }

    #[test]
    fn serializes_single_page_sitemap_index() {
        let xml = serialize_sitemap_index_xml("https://dev.to", 5, 750, true).unwrap();
        let expected = concat!(
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n",
            "<sitemapindex xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n",
            "      <sitemap>\n",
            "        <loc>https://dev.to/sitemap-posts.xml</loc>\n",
            "    </sitemap>\n",
            "  <sitemap>\n",
            "      <loc>https://dev.to/sitemap-users.xml</loc>\n",
            "  </sitemap>\n",
            "  <sitemap>\n",
            "      <loc>https://dev.to/sitemap-tags.xml</loc>\n",
            "  </sitemap>\n",
            "</sitemapindex>\n",
        );
        assert_eq!(xml, expected);
    }

    #[test]
    fn serializes_multi_page_org_sitemap_index() {
        let xml = serialize_sitemap_index_xml("http://blog.mlh.com", 2, 1, false).unwrap();
        let expected = concat!(
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n",
            "<sitemapindex xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n",
            "      <sitemap>\n",
            "          <loc>http://blog.mlh.com/sitemap-posts-0.xml</loc>\n",
            "      </sitemap>\n",
            "      <sitemap>\n",
            "          <loc>http://blog.mlh.com/sitemap-posts-1.xml</loc>\n",
            "      </sitemap>\n",
            "      <sitemap>\n",
            "          <loc>http://blog.mlh.com/sitemap-posts-2.xml</loc>\n",
            "      </sitemap>\n",
            "</sitemapindex>\n",
        );
        assert_eq!(xml, expected);
    }

    #[test]
    fn rejects_invalid_sitemap_index_params() {
        assert_eq!(
            serialize_sitemap_index_xml("https://dev.to", -1, 10, true),
            None
        );
        assert_eq!(
            serialize_sitemap_index_xml("https://dev.to", 10, 0, true),
            None
        );
        assert_eq!(
            serialize_sitemap_index_xml("ftp://dev.to", 10, 10, true),
            None
        );
    }

    #[test]
    fn serializes_urlset_with_and_without_prefix() {
        let rows = [
            ("/ben/hello-world", 1_583_540_850, 0),
            ("/alice/rust-101", 1_700_000_000, 0),
        ];
        let xml = serialize_sitemap_urlset_xml("https://dev.to", "", &rows).unwrap();
        let expected = concat!(
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n",
            "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n",
            "    <url>\n",
            "        <loc>https://dev.to/ben/hello-world</loc>\n",
            "        <lastmod>2020-03-07</lastmod>\n",
            "    </url>\n",
            "    <url>\n",
            "        <loc>https://dev.to/alice/rust-101</loc>\n",
            "        <lastmod>2023-11-14</lastmod>\n",
            "    </url>\n",
            "</urlset>\n",
        );
        assert_eq!(xml, expected);

        let tag_rows = [("ruby", 1_700_000_000, 0)];
        let tag_xml = serialize_sitemap_urlset_xml("https://dev.to", "/t/", &tag_rows).unwrap();
        assert!(tag_xml.contains("<loc>https://dev.to/t/ruby</loc>"));

        let user_rows = [("ben", 1_700_000_000, 0)];
        let user_xml = serialize_sitemap_urlset_xml("https://dev.to", "", &user_rows).unwrap();
        assert!(user_xml.contains("<loc>https://dev.to/ben</loc>"));
    }

    #[test]
    fn urlset_returns_none_for_out_of_domain_paths() {
        let rows = [("café", 1_700_000_000, 0)];
        assert_eq!(
            serialize_sitemap_urlset_xml("https://dev.to", "/t/", &rows),
            None
        );

        let dot_rows = [("/a/../b", 1_700_000_000, 0)];
        assert_eq!(
            serialize_sitemap_urlset_xml("https://dev.to", "", &dot_rows),
            None
        );

        let ok_rows = [("ben", 1_700_000_000, 0)];
        assert_eq!(
            serialize_sitemap_urlset_xml("https://dev.to/sub/", "", &ok_rows),
            None
        );
        assert_eq!(
            serialize_sitemap_index_xml("https://dev.to/sub/", 10, 750, true),
            None
        );
        assert_eq!(
            serialize_sitemap_index_xml("https://dev.to?x=1", 10, 750, true),
            None
        );
    }
}
