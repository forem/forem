//! Pure-Rust kernels for the Markdown preprocessing and `Redcarpet::Render::HTMLRouge` pipeline.
//!
//! Covers:
//! - Tier 1: [`normalize_overly_nested_lists`] — zero-allocation line-by-line list indentation
//!   normalizer (matching `MarkdownProcessor::Parser#normalize_overly_nested_lists`).
//! - Tier 1: [`slugify_header`] & Tier 2: [`render_header`] — fused heading sanitization, RGI emoji
//!   stripping, slugification, and HTML `<hN>` anchor rendering.
//! - Tier 1: [`extract_img_attrs`] — zero-Nokogiri HTML `<img>` attribute extractor for linked
//!   images in `HTMLRouge#link`.
//! - Tier 1/2: [`render_image`] & [`render_link`] — strict fast-path URI safety validation,
//!   single-pass attribute/URI escaping, and `<img .../>` / `<a ...>` assembly.

use std::borrow::Cow;

use crate::emoji::strip_rgi_emoji;
use crate::sanitize::full_sanitize;

/// Maximum leading spaces preserved on a Markdown list item before Redcarpet drops text.
pub const MAX_LIST_INDENT_SPACES: usize = 16;

/// Maximum leading characters preserved on a tab-indented Markdown list item.
const MAX_TAB_LIST_INDENT: usize = 4;

/// Result of rendering a link in `Redcarpet::Render::HTMLRouge#link`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum RenderLinkResult {
    /// Rendered `<a>...</a>` HTML string.
    Html(String),
    /// `content` already contains a nested `<a\s.+/a>` link; caller must return `nil`.
    NestedLink,
}

#[inline]
fn is_ruby_ascii_space(b: u8) -> bool {
    matches!(b, b' ' | b'\t' | b'\n' | b'\r' | 0x0b | 0x0c)
}

#[inline]
fn is_html_space(b: u8) -> bool {
    matches!(b, b' ' | b'\t' | b'\n' | b'\r' | 0x0c)
}

/// Checks `/^\s*((`{3,}|~{3,}))/i` on a single line (exact match to
/// `MarkdownProcessor::Parser#fenced_code_block_opening_marker`).
fn fenced_code_block_opening_marker(line: &str) -> Option<(u8, usize)> {
    let bytes = line.as_bytes();
    let mut i = 0;
    while i < bytes.len() && is_ruby_ascii_space(bytes[i]) {
        i += 1;
    }
    let ch = *bytes.get(i)?;
    if ch != b'`' && ch != b'~' {
        return None;
    }
    let start = i;
    while i < bytes.len() && bytes[i] == ch {
        i += 1;
    }
    let len = i - start;
    (len >= 3).then_some((ch, len))
}

/// Checks `/^\s*#{fence_char}{#{min_len},}\s*$/` on a single line (exact match to
/// `MarkdownProcessor::Parser#fenced_code_block_closing_marker?`).
fn fenced_code_block_closing_marker(line: &str, fence_char: u8, min_len: usize) -> bool {
    let bytes = line.as_bytes();
    let mut i = 0;
    while i < bytes.len() && is_ruby_ascii_space(bytes[i]) {
        i += 1;
    }
    let start = i;
    while i < bytes.len() && bytes[i] == fence_char {
        i += 1;
    }
    if i - start < min_len {
        return false;
    }
    while i < bytes.len() && is_ruby_ascii_space(bytes[i]) {
        i += 1;
    }
    i == bytes.len()
}

/// Matches `/^([ \t]+)([-*+]|\d+\.)[ \t]+(.*)$/` on `line_no_nl` (which contains no `'\n'`).
/// Returns `(indent_end, marker_end, sep_end)` if matched.
fn match_indented_list_line(line_no_nl: &str) -> Option<(usize, usize, usize)> {
    let bytes = line_no_nl.as_bytes();
    let mut i = 0;
    while i < bytes.len() && (bytes[i] == b' ' || bytes[i] == b'\t') {
        i += 1;
    }
    if i == 0 {
        return None;
    }
    let indent_end = i;

    // Marker: `-`, `*`, `+`, or `\d+\.`
    let marker_end = match *bytes.get(i)? {
        b'-' | b'*' | b'+' => i + 1,
        b'0'..=b'9' => {
            let mut j = i + 1;
            while j < bytes.len() && bytes[j].is_ascii_digit() {
                j += 1;
            }
            if bytes.get(j) != Some(&b'.') {
                return None;
            }
            j + 1
        }
        _ => return None,
    };

    // Separator: `[ \t]+`
    let mut sep_end = marker_end;
    while sep_end < bytes.len() && (bytes[sep_end] == b' ' || bytes[sep_end] == b'\t') {
        sep_end += 1;
    }
    if sep_end == marker_end {
        return None;
    }

    Some((indent_end, marker_end, sep_end))
}

/// Tier 1: Caps excessive leading indentation on Markdown list items outside fenced code blocks
/// so Redcarpet does not drop deeply nested list item text.
///
/// Matches `MarkdownProcessor::Parser#normalize_overly_nested_lists` bit-for-bit, returning
/// `Cow::Borrowed(content)` with zero allocations when no line requires modification.
pub fn normalize_overly_nested_lists(content: &str) -> Cow<'_, str> {
    if content.is_empty() {
        return Cow::Borrowed(content);
    }

    let bytes = content.as_bytes();
    let mut current_fence: Option<(u8, usize)> = None;
    let mut out: Option<String> = None;
    let mut line_start = 0usize;

    while line_start < bytes.len() {
        let nl_pos = bytes[line_start..]
            .iter()
            .position(|&b| b == b'\n')
            .map(|rel| line_start + rel);
        let line_end = nl_pos.map_or(bytes.len(), |pos| pos + 1);
        let line = &content[line_start..line_end];

        if let Some((fence_char, min_len)) = current_fence {
            if fenced_code_block_closing_marker(line, fence_char, min_len) {
                current_fence = None;
            }
            if let Some(buf) = out.as_mut() {
                buf.push_str(line);
            }
            line_start = line_end;
            continue;
        }

        if let Some(opening) = fenced_code_block_opening_marker(line) {
            current_fence = Some(opening);
            if let Some(buf) = out.as_mut() {
                buf.push_str(line);
            }
            line_start = line_end;
            continue;
        }

        let (line_no_nl, has_nl) = if nl_pos.is_some() {
            (&line[..line.len() - 1], true)
        } else {
            (line, false)
        };

        if let Some((indent_end, marker_end, sep_end)) = match_indented_list_line(line_no_nl) {
            let indent = &line_no_nl[..indent_end];
            let has_tab = indent.as_bytes().contains(&b'\t');
            let cap = if has_tab {
                MAX_TAB_LIST_INDENT
            } else {
                MAX_LIST_INDENT_SPACES
            };
            let normalized_indent = &indent[..indent.len().min(cap)];
            let sep = &line_no_nl[marker_end..sep_end];
            let unchanged = normalized_indent.len() == indent.len() && sep == " ";

            if !unchanged {
                let buf = out.get_or_insert_with(|| {
                    let mut s = String::with_capacity(content.len());
                    s.push_str(&content[..line_start]);
                    s
                });
                buf.push_str(normalized_indent);
                buf.push_str(&line_no_nl[indent_end..marker_end]);
                buf.push(' ');
                buf.push_str(&line_no_nl[sep_end..]);
                if has_nl {
                    buf.push('\n');
                }
                line_start = line_end;
                continue;
            }
        }

        if let Some(buf) = out.as_mut() {
            buf.push_str(line);
        }
        line_start = line_end;
    }

    match out {
        Some(s) => Cow::Owned(s),
        None => Cow::Borrowed(content),
    }
}

/// Tier 1: Computes the heading anchor slug matching `Redcarpet::Render::HTMLRouge#slugify`.
///
/// Fuses `full_sanitize`, ASCII downcasing, `strip_rgi_emoji`, `strip`, punctuation stripping,
/// and whitespace-to-hyphen collapsing into a single pass. Returns `None` when `full_sanitize`
/// defers to Ruby or when non-ASCII characters (or NUL bytes) remain after RGI emoji stripping.
pub fn slugify_header(title: &str) -> Option<String> {
    let needs_sanitize = title
        .as_bytes()
        .iter()
        .any(|&b| matches!(b, b'<' | b'>' | b'&' | b'\r' | 0))
        || title.starts_with('\u{FEFF}');

    let sanitized: Cow<'_, str> = if needs_sanitize {
        Cow::Owned(full_sanitize(title)?)
    } else {
        Cow::Borrowed(title)
    };

    let without_emoji: Cow<'_, str> = if sanitized.is_ascii() {
        sanitized
    } else {
        let stripped = strip_rgi_emoji(sanitized.as_ref());
        if !stripped.is_ascii() {
            return None;
        }
        Cow::Owned(stripped.into_owned())
    };

    let bytes = without_emoji.as_bytes();
    if bytes.contains(&0) {
        return None;
    }

    // Match Ruby's `String#strip` (on ASCII without NUL).
    let mut start = 0;
    while start < bytes.len() && is_ruby_ascii_space(bytes[start]) {
        start += 1;
    }
    let mut end = bytes.len();
    while end > start && is_ruby_ascii_space(bytes[end - 1]) {
        end -= 1;
    }

    let trimmed = &bytes[start..end];
    let mut out = String::with_capacity(trimmed.len());
    let mut in_ws = false;

    for &b in trimmed {
        if b.is_ascii_punctuation() {
            continue;
        }
        if is_ruby_ascii_space(b) {
            in_ws = true;
            continue;
        }
        if in_ws {
            out.push('-');
            in_ws = false;
        }
        out.push(b.to_ascii_lowercase() as char);
    }
    if in_ws {
        out.push('-');
    }

    Some(out)
}

/// Tier 2: Renders a complete `<hN>` heading block with anchor link matching
/// `Redcarpet::Render::HTMLRouge#header(title, header_number)` in a single pass.
pub fn render_header(title: &str, header_number: i64) -> Option<String> {
    let slug = slugify_header(title)?;
    let mut out = String::with_capacity(title.len() + slug.len() * 2 + 64);
    use std::fmt::Write;
    let _ = writeln!(out, "<h{header_number}>");
    out.push_str("  <a name=\"");
    out.push_str(&slug);
    out.push_str("\" href=\"#");
    out.push_str(&slug);
    out.push_str("\" class=\"anchor\">\n  </a>\n  ");
    out.push_str(title);
    let _ = writeln!(out, "\n</h{header_number}>");
    Some(out)
}

/// Tier 1: Extracts `(src, alt, title)` attributes from the first `<img ...>` tag in `content`
/// without invoking `Nokogiri::HTML`.
///
/// Returns `None` if `content` has another `<` before `<img`, malformed/unclosed syntax,
/// unquoted attribute values, HTML entities (`&`) in attribute values, or duplicate `src`/`alt`/`title`
/// attributes so the caller transparently defers to `Nokogiri::HTML`.
pub fn extract_img_attrs(content: &str) -> Option<(Option<&str>, Option<&str>, Option<&str>)> {
    let bytes = content.as_bytes();
    let lt_pos = bytes.iter().position(|&b| b == b'<')?;
    let after_lt = &bytes[lt_pos..];
    if after_lt.len() < 5 || &after_lt[..4] != b"<img" {
        return None;
    }
    let next = after_lt[4];
    if !is_html_space(next) && next != b'/' && next != b'>' {
        return None;
    }

    let mut i = lt_pos + 4;
    let mut src: Option<&str> = None;
    let mut alt: Option<&str> = None;
    let mut title: Option<&str> = None;

    while i < bytes.len() {
        while i < bytes.len() && is_html_space(bytes[i]) {
            i += 1;
        }
        if i >= bytes.len() {
            return None;
        }
        if bytes[i] == b'>' {
            return Some((src, alt, title));
        }
        if bytes[i] == b'/' {
            if bytes.get(i + 1) == Some(&b'>') {
                return Some((src, alt, title));
            }
            return None;
        }

        // Parse attribute name.
        let name_start = i;
        while i < bytes.len()
            && (bytes[i].is_ascii_alphanumeric()
                || bytes[i] == b'-'
                || bytes[i] == b'_'
                || bytes[i] == b':')
        {
            i += 1;
        }
        if i == name_start {
            return None;
        }
        let name = &content[name_start..i];

        while i < bytes.len() && is_html_space(bytes[i]) {
            i += 1;
        }
        if i >= bytes.len() {
            return None;
        }

        // Boolean attribute (no `=`).
        if bytes[i] != b'=' {
            if name.eq_ignore_ascii_case("src")
                || name.eq_ignore_ascii_case("alt")
                || name.eq_ignore_ascii_case("title")
            {
                return None;
            }
            continue;
        }
        i += 1; // skip '='

        while i < bytes.len() && is_html_space(bytes[i]) {
            i += 1;
        }
        let quote = *bytes.get(i)?;
        if quote != b'"' && quote != b'\'' {
            return None;
        }
        i += 1;
        let val_start = i;
        while i < bytes.len() && bytes[i] != quote {
            if bytes[i] == b'&' || bytes[i] == 0 {
                return None;
            }
            i += 1;
        }
        if i >= bytes.len() {
            return None;
        }
        let val = &content[val_start..i];
        i += 1; // skip closing quote

        if name.eq_ignore_ascii_case("src") {
            if src.is_some() {
                return None;
            }
            src = Some(val);
        } else if name.eq_ignore_ascii_case("alt") {
            if alt.is_some() {
                return None;
            }
            alt = Some(val);
        } else if name.eq_ignore_ascii_case("title") {
            if title.is_some() {
                return None;
            }
            title = Some(val);
        }
    }

    None
}

/// Strict fast-path URI safety classification matching `HTMLRouge#allowed_uri?`.
///
/// Returns `Some(true)` for definitely allowed URIs, `Some(false)` for definitely disallowed
/// URIs, and `None` whenever entity unescaping, control-character stripping, `data:` media-type
/// inspection (when `allow_data` is true), or uncommon schemes require `Loofah::HTML5::Scrub`.
fn classify_uri_safety(uri: Option<&str>, allow_data: bool) -> Option<bool> {
    let Some(uri) = uri else {
        return Some(true);
    };

    let bytes = uri.as_bytes();
    let mut start = 0;
    while start < bytes.len() && is_ruby_ascii_space(bytes[start]) {
        start += 1;
    }
    let trimmed = &bytes[start..];
    if trimmed.is_empty() {
        return Some(true);
    }

    for (idx, &b) in trimmed.iter().enumerate() {
        if b < 0x20 || b == 0x7f || b >= 0x80 || b == b'&' {
            return None;
        }
        if matches!(b, b'/' | b'?' | b'#') {
            return Some(true);
        }
        if b == b':' {
            let scheme = &trimmed[..idx];
            if scheme.is_empty() {
                return None;
            }
            if scheme.eq_ignore_ascii_case(b"http")
                || scheme.eq_ignore_ascii_case(b"https")
                || scheme.eq_ignore_ascii_case(b"mailto")
                || scheme.eq_ignore_ascii_case(b"tel")
                || scheme.eq_ignore_ascii_case(b"ftp")
            {
                return Some(true);
            }
            if scheme.eq_ignore_ascii_case(b"javascript")
                || scheme.eq_ignore_ascii_case(b"vbscript")
            {
                return Some(false);
            }
            if scheme.eq_ignore_ascii_case(b"data") {
                return if allow_data { None } else { Some(false) };
            }
            return None;
        }
    }

    // No `:`, no `&`, no control chars, pure ASCII relative URI (e.g. `github.com`).
    Some(true)
}

/// Appends `uri` with `"`, `<`, `>` escaped like `HTMLRouge#escape_uri_attribute`.
fn push_escaped_uri_attr(out: &mut String, uri: &str) {
    let bytes = uri.as_bytes();
    let mut last = 0;
    for (i, &b) in bytes.iter().enumerate() {
        let repl = match b {
            b'"' => "&quot;",
            b'<' => "&lt;",
            b'>' => "&gt;",
            _ => continue,
        };
        if i > last {
            out.push_str(&uri[last..i]);
        }
        out.push_str(repl);
        last = i + 1;
    }
    if last < bytes.len() {
        out.push_str(&uri[last..]);
    }
}

/// Appends `value` with HTML special chars escaped like `ERB::Util.html_escape`.
/// Caller must ensure `value` contains no `'&'` (so `CGI.unescapeHTML` is a no-op).
fn push_escaped_html_attr(out: &mut String, value: &str) {
    let bytes = value.as_bytes();
    let mut last = 0;
    for (i, &b) in bytes.iter().enumerate() {
        let repl = match b {
            b'"' => "&quot;",
            b'\'' => "&#39;",
            b'<' => "&lt;",
            b'>' => "&gt;",
            _ => continue,
        };
        if i > last {
            out.push_str(&value[last..i]);
        }
        out.push_str(repl);
        last = i + 1;
    }
    if last < bytes.len() {
        out.push_str(&value[last..]);
    }
}

/// Checks Ruby's `%r{<a\s.+/a>}` (non-multiline: `.` does not match `\n`).
fn contains_nested_anchor(content: &str) -> bool {
    let bytes = content.as_bytes();
    let mut pos = 0;
    while pos + 6 < bytes.len() {
        let Some(rel) = content[pos..].find("<a") else {
            return false;
        };
        let idx = pos + rel;
        if let Some(&ws) = bytes.get(idx + 2) {
            if is_ruby_ascii_space(ws) {
                let after_ws = idx + 3;
                let line_end = bytes[after_ws..]
                    .iter()
                    .position(|&b| b == b'\n')
                    .map_or(bytes.len(), |r| after_ws + r);
                let mut chars = content[after_ws..line_end].chars();
                if chars.next().is_some() && chars.as_str().contains("/a>") {
                    return true;
                }
            }
        }
        pos = idx + 2;
    }
    false
}

/// Checks Ruby's `/\Ahttps?:\/\/\S+/`.
fn is_http_or_https_url(link: &str) -> bool {
    let rest = if let Some(r) = link.strip_prefix("https://") {
        r
    } else if let Some(r) = link.strip_prefix("http://") {
        r
    } else {
        return false;
    };
    rest.as_bytes()
        .first()
        .is_some_and(|&b| !is_ruby_ascii_space(b))
}

/// Checks Ruby's `/\A\w+:/` (ASCII word chars `[0-9A-Za-z_]+:`).
fn has_word_protocol(link: &str) -> bool {
    let bytes = link.as_bytes();
    let mut i = 0;
    while i < bytes.len() && (bytes[i].is_ascii_alphanumeric() || bytes[i] == b'_') {
        i += 1;
    }
    i > 0 && bytes.get(i) == Some(&b':')
}

/// Tier 1/2: Renders an `<img .../>` tag matching `Redcarpet::Render::HTMLRouge#image`.
///
/// Validates `link` via the strict URI fast-path, emits `resolved_url` (or `link` if `None`)
/// into `src`, and escapes `title` and `alt_text` into a single pre-allocated buffer.
/// Returns `None` if `link` requires `Loofah::HTML5::Scrub.allowed_uri?` or if `title`/`alt_text`
/// contains `&` requiring `CGI.unescapeHTML`.
pub fn render_image(
    link: Option<&str>,
    resolved_url: Option<&str>,
    title: Option<&str>,
    alt_text: Option<&str>,
) -> Option<String> {
    let allowed = classify_uri_safety(link, true)?;
    if !allowed {
        return Some(String::new());
    }
    if title.is_some_and(|t| t.as_bytes().contains(&b'&'))
        || alt_text.is_some_and(|a| a.as_bytes().contains(&b'&'))
    {
        return None;
    }

    let url = resolved_url.unwrap_or("");
    let cap =
        16 + url.len() + title.map_or(0, |t| t.len() + 9) + alt_text.map_or(0, |a| a.len() + 7);
    let mut out = String::with_capacity(cap);
    out.push_str("<img src=\"");
    push_escaped_uri_attr(&mut out, url);
    out.push('"');
    if let Some(t) = title {
        out.push_str(" title=\"");
        push_escaped_html_attr(&mut out, t);
        out.push('"');
    }
    if let Some(a) = alt_text {
        out.push_str(" alt=\"");
        push_escaped_html_attr(&mut out, a);
        out.push('"');
    }
    out.push_str("/>");
    Some(out)
}

/// Tier 2: Renders an `<a>...</a>` tag matching `Redcarpet::Render::HTMLRouge#link`.
///
/// When `raw_href` is `true`, matches the linked-image branch (no nested-`<a>` check,
/// no `link_attrs_html`, no protocol prefixing). Otherwise matches the standard link branch.
/// Returns `None` when `link` falls outside the strict URI safety fast-path.
pub fn render_link(
    link: Option<&str>,
    content: Option<&str>,
    link_attrs_html: &str,
    app_protocol: &str,
    app_domain: &str,
    raw_href: bool,
) -> Option<RenderLinkResult> {
    let body = content.unwrap_or("");

    if !raw_href && contains_nested_anchor(body) {
        return Some(RenderLinkResult::NestedLink);
    }

    let allowed = classify_uri_safety(link, false)?;
    if !allowed {
        let mut out = String::with_capacity(body.len() + 7);
        out.push_str("<a>");
        out.push_str(body);
        out.push_str("</a>");
        return Some(RenderLinkResult::Html(out));
    }

    let raw_link = link.unwrap_or("");
    let cap = raw_link.len()
        + body.len()
        + link_attrs_html.len()
        + app_protocol.len()
        + app_domain.len()
        + 24;
    let mut out = String::with_capacity(cap);
    out.push_str("<a href=\"");

    if raw_href {
        push_escaped_uri_attr(&mut out, raw_link);
        out.push_str("\">");
        out.push_str(body);
        out.push_str("</a>");
        return Some(RenderLinkResult::Html(out));
    }

    if link.is_none() || is_http_or_https_url(raw_link) || has_word_protocol(raw_link) {
        push_escaped_uri_attr(&mut out, raw_link);
    } else if raw_link.contains('.') {
        out.push_str("//");
        push_escaped_uri_attr(&mut out, raw_link);
    } else if raw_link.starts_with('#') {
        push_escaped_uri_attr(&mut out, raw_link);
    } else {
        out.push_str(app_protocol);
        out.push_str(app_domain);
        push_escaped_uri_attr(&mut out, raw_link);
    }

    out.push('"');
    out.push_str(link_attrs_html);
    out.push('>');
    out.push_str(body);
    out.push_str("</a>");
    Some(RenderLinkResult::Html(out))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn normalize_overly_nested_lists_borrows_unchanged() {
        let md = "# Heading\n\n- item 1\n  - item 2\n    - item 3\n";
        let res = normalize_overly_nested_lists(md);
        assert!(matches!(res, Cow::Borrowed(_)));
        assert_eq!(res, md);
    }

    #[test]
    fn normalize_overly_nested_lists_clamps_spaces_and_tabs_outside_fences() {
        let deep_spaces = format!("{}- deep\n", " ".repeat(20));
        let expected_spaces = format!("{}- deep\n", " ".repeat(16));
        assert_eq!(normalize_overly_nested_lists(&deep_spaces), expected_spaces);

        let deep_tabs = "\t\t\t\t\t\t1.  tabbed\r\n";
        assert_eq!(
            normalize_overly_nested_lists(deep_tabs),
            "\t\t\t\t1. tabbed\r\n"
        );

        let fenced = format!(
            "```\n{}- keep\n```\n{}- clamp\n",
            " ".repeat(24),
            " ".repeat(24)
        );
        let expected_fenced = format!(
            "```\n{}- keep\n```\n{}- clamp\n",
            " ".repeat(24),
            " ".repeat(16)
        );
        assert_eq!(normalize_overly_nested_lists(&fenced), expected_fenced);
    }

    #[test]
    fn slugify_and_render_header_matches_ruby() {
        assert_eq!(slugify_header("Hello, World!"), Some("hello-world".into()));
        assert_eq!(
            slugify_header("🚀 Launch Day: <em>v2.0</em>!"),
            Some("launch-day-v20".into())
        );
        assert_eq!(slugify_header("! hello !"), Some("-hello-".into()));
        assert_eq!(slugify_header("a - b"), Some("a-b".into()));
        assert_eq!(slugify_header("日本語見出し"), None);

        assert_eq!(
            render_header("Hello World", 2),
            Some(
                "<h2>\n  <a name=\"hello-world\" href=\"#hello-world\" class=\"anchor\">\n  </a>\n  Hello World\n</h2>\n"
                    .into()
            )
        );
    }

    #[test]
    fn extract_img_attrs_handles_valid_and_defers_malformed() {
        assert_eq!(
            extract_img_attrs(r#"<img src="https://example.com/a.png" alt="hi" title="t"/>"#),
            Some((Some("https://example.com/a.png"), Some("hi"), Some("t")))
        );
        assert_eq!(
            extract_img_attrs("<img src='https://example.com/a.png' />"),
            Some((Some("https://example.com/a.png"), None, None))
        );
        // Malformed unclosed quote/tag defers to Nokogiri
        assert_eq!(
            extract_img_attrs("<img src='https://example.com/a.png"),
            None
        );
        // Entity inside attribute defers to Nokogiri
        assert_eq!(
            extract_img_attrs(r#"<img src="https://example.com/a.png" alt="a &amp; b"/>"#),
            None
        );
    }

    #[test]
    fn render_image_and_link_cases() {
        assert_eq!(
            render_image(
                Some("https://example.com/a.png"),
                Some("https://cdn.example.com/a.png"),
                Some("my \"title\""),
                Some("alt <x>"),
            ),
            Some(
                r#"<img src="https://cdn.example.com/a.png" title="my &quot;title&quot;" alt="alt &lt;x&gt;"/>"#
                    .into()
            )
        );
        assert_eq!(
            render_image(
                Some("javascript:alert(1)"),
                Some("javascript:alert(1)"),
                None,
                Some("x")
            ),
            Some(String::new())
        );
        assert_eq!(
            render_image(
                Some("data:image/png;base64,abc"),
                Some("data:image/png;base64,abc"),
                None,
                None
            ),
            None
        );

        assert_eq!(
            render_link(
                Some("https://github.com"),
                Some("github"),
                " rel=\"nofollow\"",
                "https://",
                "dev.to",
                false
            ),
            Some(RenderLinkResult::Html(
                r#"<a href="https://github.com" rel="nofollow">github</a>"#.into()
            ))
        );
        assert_eq!(
            render_link(
                Some("github.com"),
                Some("github"),
                "",
                "https://",
                "dev.to",
                false
            ),
            Some(RenderLinkResult::Html(
                r#"<a href="//github.com">github</a>"#.into()
            ))
        );
        assert_eq!(
            render_link(Some("#v1.2"), Some("v1.2"), "", "https://", "dev.to", false),
            Some(RenderLinkResult::Html(
                r#"<a href="//#v1.2">v1.2</a>"#.into()
            ))
        );
        assert_eq!(
            render_link(
                Some("/t/career"),
                Some("career"),
                "",
                "https://",
                "dev.to",
                false
            ),
            Some(RenderLinkResult::Html(
                r#"<a href="https://dev.to/t/career">career</a>"#.into()
            ))
        );
        assert_eq!(
            render_link(
                Some("javascript:alert(1)"),
                Some("click"),
                "",
                "https://",
                "dev.to",
                false
            ),
            Some(RenderLinkResult::Html("<a>click</a>".into()))
        );
        assert_eq!(
            render_link(
                Some("javascript&#58;alert(1)"),
                Some("click"),
                "",
                "https://",
                "dev.to",
                false
            ),
            None
        );
        assert_eq!(
            render_link(
                Some("https://example.com"),
                Some("<a href=\"x\">nested</a>"),
                "",
                "https://",
                "dev.to",
                false
            ),
            Some(RenderLinkResult::NestedLink)
        );
        // Non-ASCII character immediately after `<a ` must not panic on UTF-8 boundary
        assert_eq!(
            render_link(
                Some("https://example.com"),
                Some("<a é='x'>nested</a>"),
                "",
                "https://",
                "dev.to",
                false
            ),
            Some(RenderLinkResult::NestedLink)
        );
        assert_eq!(
            render_link(
                Some("https://example.com"),
                Some("<a é/a>"),
                "",
                "https://",
                "dev.to",
                false
            ),
            Some(RenderLinkResult::NestedLink)
        );
        assert_eq!(
            render_link(
                Some("https://example.com"),
                Some("<a /a>"),
                "",
                "https://",
                "dev.to",
                false
            ),
            Some(RenderLinkResult::Html(
                r#"<a href="https://example.com"><a /a></a>"#.into()
            ))
        );
    }
}
