//! Literal transcript HTML substitutions after Rouge and before sanitization.
//!
//! These deliberately match the renderer's string/regexp substitutions, not HTML
//! parsing rules: entities stay encoded and markers inside code are styled too.

use std::borrow::Cow;

const CODE_OPEN: &str = "<pre><code>";
const CODE_CLOSE: &str = "</code></pre>";
const HIGHLIGHT_OPEN: &str = "<pre class=\"highlight\"><code>";
const REDACTED: &str = "[REDACTED]";
const STYLED_REDACTED: &str = "<span class=\"agent-session-redacted\">[REDACTED]</span>";

/// Matches the non-overlapping, lazy `<pre><code>(.*?)</code></pre>` Ruby regexp.
pub fn wrap_untagged_codeblocks(html: &str) -> Option<Cow<'_, str>> {
    rewrite(html, true, false)
}

/// Replaces literal markers everywhere, without decoding or interpreting markup.
pub fn style_redaction_markers(html: &str) -> Cow<'_, str> {
    // With code wrapping disabled there can be no unclosed-code deferral.
    rewrite(html, false, true).expect("marker replacement accepts every UTF-8 string")
}

/// Fuses untagged-code wrapping and optional marker styling into one byte scan
/// and one lazily allocated output buffer. No Ruby or DOM objects are involved.
///
/// An unclosed code opener defers to Ruby; no partial output escapes. Nested
/// openers belong to the first match, exactly as with the legacy lazy regexp.
pub fn postprocess_transcript_html(html: &str, redact: bool) -> Option<Cow<'_, str>> {
    rewrite(html, true, redact)
}

/// Finds `needle` in `haystack` by jumping between occurrences of `first_char` via
/// std's `memchr`-backed `char` pattern search (`TwoWaySearcher` disables `memchr`
/// when a multi-byte needle's critical factorization offset is non-zero).
#[inline]
fn find_delimiter(haystack: &str, needle: &[u8], first_char: char) -> Option<usize> {
    let bytes = haystack.as_bytes();
    let mut offset = 0;
    while offset + needle.len() <= bytes.len() {
        let pos = offset + haystack[offset..].find(first_char)?;
        if bytes[pos..].starts_with(needle) {
            return Some(pos);
        }
        offset = pos + 1;
    }
    None
}

/// Rewrites untagged `<pre><code>` blocks and `[REDACTED]` markers using `memchr`-accelerated
/// delimiter searches over disjoint slices, returning `Cow::Borrowed` when neither delimiter
/// is present.
fn rewrite(html: &str, wrap_code: bool, redact: bool) -> Option<Cow<'_, str>> {
    let mut next_open = if wrap_code {
        find_delimiter(html, CODE_OPEN.as_bytes(), '<')
    } else {
        None
    };
    let mut next_redact = if redact {
        find_delimiter(html, REDACTED.as_bytes(), '[')
    } else {
        None
    };
    if next_open.is_none() && next_redact.is_none() {
        return Some(Cow::Borrowed(html));
    }

    let mut output: Option<String> = None;
    let mut copied = 0;

    loop {
        if let Some(open_pos) = next_open.filter(|&o| next_redact.is_none_or(|r| o < r)) {
            let body_start = open_pos + CODE_OPEN.len();
            let close_pos = find_delimiter(&html[body_start..], CODE_CLOSE.as_bytes(), '<')
                .map(|rel| body_start + rel)?;

            let buffer = output.get_or_insert_with(|| String::with_capacity(html.len()));
            // All slice boundaries are ASCII delimiter boundaries, including when
            // the intervening content contains multibyte UTF-8 characters.
            buffer.push_str(&html[copied..open_pos]);
            buffer.push_str(HIGHLIGHT_OPEN);
            copied = body_start;

            while let Some(redact_pos) = next_redact.filter(|&pos| pos < close_pos) {
                buffer.push_str(&html[copied..redact_pos]);
                buffer.push_str(STYLED_REDACTED);
                copied = redact_pos + REDACTED.len();
                next_redact = find_delimiter(&html[copied..], REDACTED.as_bytes(), '[')
                    .map(|rel| copied + rel);
            }

            let after_close = close_pos + CODE_CLOSE.len();
            next_open = find_delimiter(&html[after_close..], CODE_OPEN.as_bytes(), '<')
                .map(|rel| after_close + rel);
        } else if let Some(redact_pos) = next_redact {
            let buffer = output.get_or_insert_with(|| String::with_capacity(html.len()));
            buffer.push_str(&html[copied..redact_pos]);
            buffer.push_str(STYLED_REDACTED);
            copied = redact_pos + REDACTED.len();
            next_redact =
                find_delimiter(&html[copied..], REDACTED.as_bytes(), '[').map(|rel| copied + rel);
        } else {
            break;
        }
    }

    Some(match output {
        Some(mut buffer) => {
            buffer.push_str(&html[copied..]);
            Cow::Owned(buffer)
        }
        None => Cow::Borrowed(html),
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn unchanged_input_is_borrowed() {
        for html in [
            "",
            "plain 日本語 🚀\r\n",
            "<pre class=\"highlight\"><code>x</code></pre>",
        ] {
            assert!(matches!(
                postprocess_transcript_html(html, true),
                Some(Cow::Borrowed(_))
            ));
        }
    }

    #[test]
    fn wraps_empty_multiline_and_nested_code_like_the_lazy_regexp() {
        for body in ["", "日本語 🚀\r\n&amp; &#64;", "<pre><code>inner", "\0"] {
            let html = format!("before<pre><code>{body}</code></pre>after");
            assert_eq!(
                wrap_untagged_codeblocks(&html).unwrap(),
                format!("before{HIGHLIGHT_OPEN}{body}</code></pre>after")
            );
        }
    }

    #[test]
    fn fused_output_matches_composition_without_reprocessing_inserted_markers() {
        let html =
            "[REDACTED]<pre><code>[REDACTED]\r\n🚀</code></pre><pre><code></code></pre>[REDACTED]";
        let wrapped = wrap_untagged_codeblocks(html).unwrap();
        assert_eq!(
            postprocess_transcript_html(html, true).unwrap(),
            style_redaction_markers(&wrapped)
        );
        assert_eq!(
            postprocess_transcript_html(html, false),
            wrap_untagged_codeblocks(html)
        );
        assert_eq!(
            style_redaction_markers("[redacted] &#91;REDACTED]"),
            "[redacted] &#91;REDACTED]"
        );
    }

    #[test]
    fn incomplete_blocks_defer_without_returning_partial_rewrites() {
        for html in [
            "<pre><code>",
            "[REDACTED]<pre><code>x",
            "<pre><code>ok</code></pre><pre><code>bad",
        ] {
            assert_eq!(postprocess_transcript_html(html, true), None);
            assert_eq!(wrap_untagged_codeblocks(html), None);
        }
        assert_eq!(
            style_redaction_markers("<pre><code>[REDACTED]"),
            format!("<pre><code>{STYLED_REDACTED}")
        );
    }

    #[test]
    fn only_exact_openers_and_closers_match() {
        for html in [
            "<PRE><code>x</code></PRE>",
            "<pre><code class=\"text\">x</code></pre>",
            "<pre> <code>x</code></pre>",
        ] {
            assert_eq!(postprocess_transcript_html(html, true).unwrap(), html);
        }
        assert_eq!(wrap_untagged_codeblocks("<pre><code>x</code> </pre>"), None);
    }
}
