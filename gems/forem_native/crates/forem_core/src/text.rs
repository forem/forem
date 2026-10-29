//! Plain-text predicates used outside the Markdown pipeline.

use std::borrow::Cow;

/// Whether `content` with every whitespace character replaced by a space includes `title`
/// without its `…` characters, matching
/// `content.gsub(/[[:space:]]/, " ").include?(title.delete("…"))` in
/// `Feeds::CheckItemMediumReply#content_is_not_the_title?`.
///
/// Onigmo's Unicode `[[:space:]]` is exactly the `White_Space` property, i.e. `char::is_whitespace`.
pub fn content_includes_title(content: &str, title: &str) -> bool {
    let title = if title.contains('…') {
        Cow::Owned(title.replace('…', ""))
    } else {
        Cow::Borrowed(title)
    };
    // After the `gsub` the only whitespace left in the content is ` `, so a title holding any
    // other whitespace can never match.
    if title.contains(|c: char| c != ' ' && c.is_whitespace()) {
        return false;
    }
    if !content.contains(|c: char| c != ' ' && c.is_whitespace()) {
        return content.contains(&*title);
    }

    let normalized: String = content
        .chars()
        .map(|c| if c.is_whitespace() { ' ' } else { c })
        .collect();
    normalized.contains(&*title)
}

/// Generates a GitHub-style heading anchor slug from `heading_html`, matching
/// `AgentSessionRenderers::HeadingAnchors.slugify`:
/// 1. Strips `<[^>]*>` HTML tags (`heading_html.gsub(/<[^>]*>/, "")`).
/// 2. Unescapes basic (`&apos;`, `&amp;`, `&quot;`, `&gt;`, `&lt;`) and numeric
///    (`&#[0-9]+;`, `&#[xX][0-9A-Fa-f]+;` with code point `< 0x10FFFF`) HTML entities
///    (`CGI.unescapeHTML`).
/// 3. Strips leading and trailing Ruby ASCII whitespace (`\0`, `\t`, `\n`, `\v`, `\f`, `\r`, `' '`).
/// 4. Lowercases characters, drops characters matching `SLUG_DISALLOWED` (`/[^\p{L}\p{M}\p{N}\p{Pc}\- ]/`),
///    and converts spaces (`' '`) to hyphens (`'-'`).
///
/// Returns `None` when a numeric entity encodes a UTF-16 surrogate (`0xD800..=0xDFFF`) or when the
/// stripped text contains a code point outside the verified Unicode domain so the Ruby caller can
/// fall back to `legacy_slugify`.
pub fn slugify_heading_anchor(heading_html: &str) -> Option<String> {
    let without_tags = strip_angle_bracket_tags(heading_html);
    let unescaped = unescape_cgi_html(&without_tags)?;
    let trimmed = trim_ruby_strip(&unescaped);

    let mut slug = String::with_capacity(trimmed.len());
    for ch in trimmed.chars() {
        if !is_supported_slug_char(ch) {
            return None;
        }
        for lower in ch.to_lowercase() {
            if is_slug_allowed(lower) {
                slug.push(if lower == ' ' { '-' } else { lower });
            }
        }
    }
    Some(slug)
}

fn strip_angle_bracket_tags(html: &str) -> Cow<'_, str> {
    let bytes = html.as_bytes();
    let Some(first_lt) = bytes.iter().position(|&b| b == b'<') else {
        return Cow::Borrowed(html);
    };
    let Some(first_gt_rel) = bytes[first_lt + 1..].iter().position(|&b| b == b'>') else {
        return Cow::Borrowed(html);
    };

    let mut out = String::with_capacity(html.len());
    out.push_str(&html[..first_lt]);
    let mut copied = first_lt + 1 + first_gt_rel + 1;
    let mut i = copied;

    while let Some(lt_rel) = bytes[i..].iter().position(|&b| b == b'<') {
        let lt = i + lt_rel;
        let Some(gt_rel) = bytes[lt + 1..].iter().position(|&b| b == b'>') else {
            break;
        };
        out.push_str(&html[copied..lt]);
        copied = lt + 1 + gt_rel + 1;
        i = copied;
    }
    out.push_str(&html[copied..]);
    Cow::Owned(out)
}

fn unescape_cgi_html(text: &str) -> Option<Cow<'_, str>> {
    if !text.contains('&') {
        return Some(Cow::Borrowed(text));
    }

    let bytes = text.as_bytes();
    let mut out = String::with_capacity(text.len());
    let mut copied = 0;
    let mut i = 0;

    while let Some(amp_rel) = bytes[i..].iter().position(|&b| b == b'&') {
        let amp = i + amp_rel;
        let rest = &bytes[amp + 1..];
        let matched = if rest.starts_with(b"apos;") {
            Some(("'", 6))
        } else if rest.starts_with(b"amp;") {
            Some(("&", 5))
        } else if rest.starts_with(b"quot;") {
            Some(("\"", 6))
        } else if rest.starts_with(b"gt;") {
            Some((">", 4))
        } else if rest.starts_with(b"lt;") {
            Some(("<", 4))
        } else {
            None
        };

        if let Some((replacement, consumed)) = matched {
            out.push_str(&text[copied..amp]);
            out.push_str(replacement);
            copied = amp + consumed;
            i = copied;
            continue;
        }

        if rest.first() == Some(&b'#') {
            if let Some((codepoint, consumed)) = parse_numeric_entity(&rest[1..]) {
                if codepoint < 0x10ffff {
                    let ch = char::from_u32(codepoint)?;
                    out.push_str(&text[copied..amp]);
                    out.push(ch);
                    copied = amp + 2 + consumed;
                    i = copied;
                    continue;
                }
            }
        }

        i = amp + 1;
    }

    if copied == 0 {
        return Some(Cow::Borrowed(text));
    }
    out.push_str(&text[copied..]);
    Some(Cow::Owned(out))
}

fn parse_numeric_entity(after_hash: &[u8]) -> Option<(u32, usize)> {
    if matches!(after_hash.first(), Some(b'x' | b'X')) {
        let digits = after_hash[1..]
            .iter()
            .take_while(|&&b| b.is_ascii_hexdigit())
            .count();
        if digits == 0 || after_hash.get(1 + digits) != Some(&b';') {
            return None;
        }
        let mut value = 0u32;
        for &b in &after_hash[1..1 + digits] {
            let d = match b {
                b'0'..=b'9' => u32::from(b - b'0'),
                b'a'..=b'f' => u32::from(b - b'a' + 10),
                b'A'..=b'F' => u32::from(b - b'A' + 10),
                _ => unreachable!(),
            };
            value = value.saturating_mul(16).saturating_add(d);
        }
        Some((value, 1 + digits + 1))
    } else {
        let digits = after_hash
            .iter()
            .take_while(|&&b| b.is_ascii_digit())
            .count();
        if digits == 0 || after_hash.get(digits) != Some(&b';') {
            return None;
        }
        let mut value = 0u32;
        for &b in &after_hash[..digits] {
            value = value.saturating_mul(10).saturating_add(u32::from(b - b'0'));
        }
        Some((value, digits + 1))
    }
}

fn trim_ruby_strip(text: &str) -> &str {
    let bytes = text.as_bytes();
    let is_strip = |b: u8| matches!(b, 0 | b'\t'..=b'\r' | b' ');
    let start = bytes.iter().take_while(|&&b| is_strip(b)).count();
    let end = bytes.len()
        - bytes[start..]
            .iter()
            .rev()
            .take_while(|&&b| is_strip(b))
            .count();
    &text[start..end]
}

fn is_supported_slug_char(c: char) -> bool {
    let u = c as u32;
    u < 0x0483
        || (0x2000..=0x203E).contains(&u)
        || (0x3040..=0x3098).contains(&u)
        || (0x30A0..=0x30FA).contains(&u)
        || (0x4E00..=0x9FFF).contains(&u)
        || (0xAC00..=0xD7A3).contains(&u)
        || (0x1F300..=0x1FAFF).contains(&u)
}

fn is_slug_allowed(c: char) -> bool {
    c.is_alphanumeric() || matches!(c, '-' | ' ' | '_' | '\u{0300}'..='\u{036F}')
}

/// Rewrites `href="#([^"]+)"` intra-document fragment links in `html` using `ids_by_slug`,
/// matching `AgentSessionRenderers::HeadingAnchors#link_fragments`:
/// 1. Unescapes HTML entities via `CGI.unescapeHTML` (`unescape_cgi_html`).
/// 2. Percent-decodes URI components via `Addressable::URI.unencode_component`.
/// 3. Looks up `ids_by_slug[fragment] || ids_by_slug[fragment.downcase]`.
/// 4. When found, rewrites the attribute to `href="##{ERB::Util.html_escape(id)}"`.
///
/// Returns `Some(Cow::Borrowed(html))` when no fragment link is rewritten, `Some(Cow::Owned(_))`
/// when one or more fragment links are rewritten, or `None` if an entity or percent-decoded
/// sequence falls outside the verified UTF-8 / Unicode lowercase domain so the caller can fall
/// back to `legacy_link_fragments`.
pub fn link_heading_anchor_fragments<'a, K: AsRef<str>, V: AsRef<str>>(
    html: &'a str,
    ids_by_slug: &[(K, V)],
) -> Option<Cow<'a, str>> {
    const PREFIX: &[u8] = b"href=\"#";

    if ids_by_slug.is_empty() || html.len() < PREFIX.len() + 2 {
        return Some(Cow::Borrowed(html));
    }

    let bytes = html.as_bytes();
    let mut out: Option<String> = None;
    let mut last_copied = 0usize;
    let mut i = 0usize;

    while i + PREFIX.len() + 2 <= bytes.len() {
        let Some(rel) = find_subslice(&bytes[i..], PREFIX) else {
            break;
        };
        let match_start = i + rel;
        let frag_start = match_start + PREFIX.len();
        let Some(quote_rel) = bytes[frag_start..].iter().position(|&b| b == b'"') else {
            break;
        };
        let frag_end = frag_start + quote_rel;
        if frag_end == frag_start {
            // `href="#"` has an empty capture group so `/href="#([^"]+)"/` does not match here.
            i = frag_end + 1;
            continue;
        }

        let raw_frag = &html[frag_start..frag_end];
        let unescaped = unescape_cgi_html(raw_frag)?;
        let decoded = unencode_uri_component(&unescaped)?;

        let matched_id = lookup_slug_id(ids_by_slug, &decoded)?;
        if let Some(id) = matched_id {
            let buf = out.get_or_insert_with(|| String::with_capacity(html.len() + 32));
            buf.push_str(&html[last_copied..frag_start]);
            push_erb_html_escaped(buf, id);
            buf.push('"');
            last_copied = frag_end + 1;
        }

        i = frag_end + 1;
    }

    match out {
        None => Some(Cow::Borrowed(html)),
        Some(mut s) => {
            s.push_str(&html[last_copied..]);
            Some(Cow::Owned(s))
        }
    }
}

#[inline]
fn find_subslice(haystack: &[u8], needle: &[u8]) -> Option<usize> {
    if needle.is_empty() {
        return Some(0);
    }
    let first = needle[0];
    let mut pos = 0;
    while pos + needle.len() <= haystack.len() {
        let rel = haystack[pos..].iter().position(|&b| b == first)?;
        let idx = pos + rel;
        if idx + needle.len() > haystack.len() {
            return None;
        }
        if &haystack[idx..idx + needle.len()] == needle {
            return Some(idx);
        }
        pos = idx + 1;
    }
    None
}

fn unencode_uri_component(input: &str) -> Option<Cow<'_, str>> {
    if !input.contains('%') {
        return Some(Cow::Borrowed(input));
    }

    let bytes = input.as_bytes();
    let mut out: Option<Vec<u8>> = None;
    let mut last_copied = 0usize;
    let mut i = 0usize;

    while i < bytes.len() {
        if bytes[i] == b'%' {
            if let (Some(&h1), Some(&h2)) = (bytes.get(i + 1), bytes.get(i + 2)) {
                if let (Some(d1), Some(d2)) = (hex_nibble(h1), hex_nibble(h2)) {
                    let buf = out.get_or_insert_with(|| Vec::with_capacity(bytes.len()));
                    buf.extend_from_slice(&bytes[last_copied..i]);
                    buf.push((d1 << 4) | d2);
                    i += 3;
                    last_copied = i;
                    continue;
                }
            }
        }
        i += 1;
    }

    match out {
        None => Some(Cow::Borrowed(input)),
        Some(mut vec) => {
            vec.extend_from_slice(&bytes[last_copied..]);
            String::from_utf8(vec).ok().map(Cow::Owned)
        }
    }
}

#[inline]
fn hex_nibble(b: u8) -> Option<u8> {
    match b {
        b'0'..=b'9' => Some(b - b'0'),
        b'a'..=b'f' => Some(b - b'a' + 10),
        b'A'..=b'F' => Some(b - b'A' + 10),
        _ => None,
    }
}

fn lookup_slug_id<'a, K: AsRef<str>, V: AsRef<str>>(
    ids_by_slug: &'a [(K, V)],
    fragment: &str,
) -> Option<Option<&'a str>> {
    for (k, v) in ids_by_slug {
        if k.as_ref() == fragment {
            return Some(Some(v.as_ref()));
        }
    }

    let mut lower = String::with_capacity(fragment.len());
    for ch in fragment.chars() {
        if !is_supported_slug_char(ch) {
            return None;
        }
        for lc in ch.to_lowercase() {
            lower.push(lc);
        }
    }

    for (k, v) in ids_by_slug {
        if k.as_ref() == lower {
            return Some(Some(v.as_ref()));
        }
    }

    Some(None)
}

#[inline]
fn push_erb_html_escaped(out: &mut String, s: &str) {
    for ch in s.chars() {
        match ch {
            '&' => out.push_str("&amp;"),
            '<' => out.push_str("&lt;"),
            '>' => out.push_str("&gt;"),
            '"' => out.push_str("&quot;"),
            '\'' => out.push_str("&#39;"),
            _ => out.push(ch),
        }
    }
}

/// Normalizes a URL for display, matching `ApplicationHelper#beautified_url`:
/// `url.sub(%r{\A((https?|ftp):/)?/}, "").sub(/\?.*/, "").chomp("/")`.
///
/// 1. Strips a single leading `"https://"`, `"http://"`, `"ftp://"`, or `"/"` prefix.
/// 2. Strips from the first `'?'` up to the end of the line (all characters except `'\n'`,
///    matching Ruby's `.` without `/m`).
/// 3. Strips a single trailing `'/'` (`String#chomp("/")`).
pub fn beautified_url(url: &str) -> Cow<'_, str> {
    let after_prefix = url
        .strip_prefix("https://")
        .or_else(|| url.strip_prefix("http://"))
        .or_else(|| url.strip_prefix("ftp://"))
        .or_else(|| url.strip_prefix('/'))
        .unwrap_or(url);

    if let Some(q_idx) = after_prefix.find('?') {
        let after_q = &after_prefix[q_idx + 1..];
        if let Some(nl_rel) = after_q.find('\n') {
            let tail = &after_q[nl_rel..];
            let tail = tail.strip_suffix('/').unwrap_or(tail);
            let mut out = String::with_capacity(q_idx + tail.len());
            out.push_str(&after_prefix[..q_idx]);
            out.push_str(tail);
            return Cow::Owned(out);
        }
        let before_q = &after_prefix[..q_idx];
        return Cow::Borrowed(before_q.strip_suffix('/').unwrap_or(before_q));
    }

    Cow::Borrowed(after_prefix.strip_suffix('/').unwrap_or(after_prefix))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn finds_the_title_in_plain_content() {
        assert!(content_includes_title("<p>Hello world</p>", "Hello world"));
        assert!(!content_includes_title("<p>Hello world</p>", "Goodbye"));
    }

    #[test]
    fn empty_title_is_always_included() {
        assert!(content_includes_title("", ""));
        assert!(content_includes_title("anything", ""));
        assert!(content_includes_title("anything", "……"));
        assert!(!content_includes_title("", "a"));
    }

    #[test]
    fn deletes_ellipses_from_the_title() {
        assert!(content_includes_title("I think this is right", "I think…"));
        assert!(content_includes_title("abc", "a…b…c"));
        assert!(!content_includes_title("I think…", "I think… really"));
        assert!(content_includes_title("I think…", "I think"));
    }

    #[test]
    fn replaces_content_whitespace_with_spaces() {
        assert!(content_includes_title("Hello\nworld", "Hello world"));
        assert!(content_includes_title("Hello\u{a0}world", "Hello world"));
        assert!(content_includes_title(
            "Hello\u{3000}\r\nworld",
            "Hello   world"
        ));
        assert!(!content_includes_title("Hello\r\nworld", "Hello world"));
        assert!(content_includes_title("a\u{2028}b\u{85}c", "a b c"));
    }

    #[test]
    fn titles_with_other_whitespace_never_match() {
        assert!(!content_includes_title("Hello\nworld", "Hello\nworld"));
        assert!(!content_includes_title(
            "Hello\u{a0}world",
            "Hello\u{a0}world"
        ));
        assert!(!content_includes_title("tab\there", "\t"));
    }

    #[test]
    fn treats_non_whitespace_lookalikes_literally() {
        // U+200B ZERO WIDTH SPACE and U+180E MONGOLIAN VOWEL SEPARATOR are not `[[:space:]]`.
        assert!(!content_includes_title("a\u{200b}b", "a b"));
        assert!(content_includes_title("a\u{200b}b", "a\u{200b}b"));
        assert!(!content_includes_title("a\u{180e}b", "a b"));
    }

    #[test]
    fn whitespace_set_matches_onigmo_posix_space() {
        // Every code point Onigmo's `/[[:space:]]/` matches in UTF-8 (brute-forced in Ruby 3.3).
        let onigmo: Vec<u32> = vec![
            0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x20, 0x85, 0xa0, 0x1680, 0x2000, 0x2001, 0x2002, 0x2003,
            0x2004, 0x2005, 0x2006, 0x2007, 0x2008, 0x2009, 0x200a, 0x2028, 0x2029, 0x202f, 0x205f,
            0x3000,
        ];
        let rust: Vec<u32> = (0..=0x10ffff)
            .filter_map(char::from_u32)
            .filter(|c| c.is_whitespace())
            .map(u32::from)
            .collect();
        assert_eq!(rust, onigmo);
    }

    #[test]
    fn handles_multibyte_content() {
        assert!(content_includes_title(
            "日本語\nのタイトル 🎉",
            "日本語 のタイトル 🎉"
        ));
        assert!(!content_includes_title("日本語のタイトル", "タイトル🎉"));
    }

    #[test]
    fn slugifies_headings_like_github() {
        assert_eq!(
            slugify_heading_anchor("Getting Started").as_deref(),
            Some("getting-started")
        );
        assert_eq!(
            slugify_heading_anchor("FAQ &amp; Troubleshooting").as_deref(),
            Some("faq--troubleshooting")
        );
        assert_eq!(
            slugify_heading_anchor("What&#39;s New in v2.0?").as_deref(),
            Some("whats-new-in-v20")
        );
        assert_eq!(
            slugify_heading_anchor("Astro vs WordPress: the practical comparison").as_deref(),
            Some("astro-vs-wordpress-the-practical-comparison")
        );
        assert_eq!(
            slugify_heading_anchor("Work through a small-business example_now").as_deref(),
            Some("work-through-a-small-business-example_now")
        );
        assert_eq!(
            slugify_heading_anchor("Call <code>run()</code> <em>now</em>").as_deref(),
            Some("call-run-now")
        );
        assert_eq!(
            slugify_heading_anchor("Überblick über Café").as_deref(),
            Some("überblick-über-café")
        );
    }

    #[test]
    fn slugifies_entities_tags_whitespace_and_unicode() {
        assert_eq!(slugify_heading_anchor("").as_deref(), Some(""));
        assert_eq!(slugify_heading_anchor("!!! ???").as_deref(), Some("-"));
        assert_eq!(
            slugify_heading_anchor("\0\t\n\r  Hello\t\nWorld  \0").as_deref(),
            Some("helloworld")
        );
        assert_eq!(slugify_heading_anchor(". a ").as_deref(), Some("-a"));
        assert_eq!(
            slugify_heading_anchor("&<i></i>amp; &apos; &quot; &lt;b&gt; &#x41; &#X42; &#0067;")
                .as_deref(),
            Some("---b-a-b-c")
        );
        assert_eq!(
            slugify_heading_anchor("unclosed <tag and <a\nb>kept <trailing").as_deref(),
            Some("unclosed-kept-trailing")
        );
        assert_eq!(
            slugify_heading_anchor("İstanbul \u{039f}\u{03a3} 日本語 한글 🎉").as_deref(),
            Some("i\u{307}stanbul-\u{03bf}\u{03c3}-日本語-한글-")
        );
    }

    #[test]
    fn declines_surrogate_entities_and_unsupported_codepoints() {
        assert_eq!(slugify_heading_anchor("&#xD800;"), None);
        assert_eq!(slugify_heading_anchor("&#55296;"), None);
        assert_eq!(
            slugify_heading_anchor("&#x10FFFF;").as_deref(),
            Some("x10ffff")
        );
        assert_eq!(slugify_heading_anchor("circled Ⓐ"), None);
    }

    #[test]
    fn beautifies_urls_matching_application_helper() {
        assert_eq!(beautified_url("https://github.com"), "github.com");
        assert_eq!(beautified_url("http://github.com/"), "github.com");
        assert_eq!(
            beautified_url("ftp://files.example.com/pub/"),
            "files.example.com/pub"
        );
        assert_eq!(beautified_url("https://github.com?a=3"), "github.com");
        assert_eq!(beautified_url("https://github.com/?a=3&b=4"), "github.com");
        assert_eq!(
            beautified_url("https://github.com/rails"),
            "github.com/rails"
        );
        assert_eq!(
            beautified_url("https://github.com/rails/rails/?tab=readme"),
            "github.com/rails/rails"
        );
    }

    #[test]
    fn beautifies_urls_across_prefixes_newlines_and_unicode() {
        assert_eq!(beautified_url(""), "");
        assert_eq!(beautified_url("/"), "");
        assert_eq!(beautified_url("//github.com/"), "/github.com");
        assert_eq!(beautified_url("/github.com//"), "github.com/");
        assert_eq!(beautified_url("https:/github.com/"), "https:/github.com");
        assert_eq!(beautified_url("HTTPS://github.com/"), "HTTPS://github.com");
        assert_eq!(
            beautified_url("https://github.com?a=1\nb=2/"),
            "github.com\nb=2"
        );
        assert_eq!(beautified_url("https://github.com/?a=1\n"), "github.com/\n");
        assert_eq!(
            beautified_url("https://github.com?a=1\r\nb=2/"),
            "github.com\nb=2"
        );
        assert_eq!(
            beautified_url("https://例え.テスト/パス/?q=🎉/"),
            "例え.テスト/パス"
        );
    }

    #[test]
    fn links_heading_anchor_fragments_matching_ruby() {
        let ids = vec![
            (
                "getting-started".to_string(),
                "agent-session-7-3-getting-started".to_string(),
            ),
            (
                "faq--troubleshooting".to_string(),
                "agent-session-7-3-faq--troubleshooting".to_string(),
            ),
            (
                "überblick".to_string(),
                "agent-session-7-3-überblick".to_string(),
            ),
        ];

        let html = "<a href=\"#getting-started\">Go</a> <a href=\"#faq--troubleshooting\">FAQ</a>";
        assert_eq!(
            link_heading_anchor_fragments(html, &ids).as_deref(),
            Some(
                "<a href=\"#agent-session-7-3-getting-started\">Go</a> \
                 <a href=\"#agent-session-7-3-faq--troubleshooting\">FAQ</a>"
            )
        );

        assert_eq!(
            link_heading_anchor_fragments("<a href=\"#%C3%BCberblick\">x</a>", &ids).as_deref(),
            Some("<a href=\"#agent-session-7-3-überblick\">x</a>")
        );
        assert_eq!(
            link_heading_anchor_fragments("<a href=\"#Getting-Started\">x</a>", &ids).as_deref(),
            Some("<a href=\"#agent-session-7-3-getting-started\">x</a>")
        );

        let unchanged =
            "<a href=\"#missing\">x</a> <a href=\"https://example.com/#getting-started\">y</a>";
        let res = link_heading_anchor_fragments(unchanged, &ids).unwrap();
        assert!(matches!(res, Cow::Borrowed(_)));
        assert_eq!(res, unchanged);
    }
}
