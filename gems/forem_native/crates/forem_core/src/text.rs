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
}
