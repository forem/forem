//! Final, non-database-driven adjustments to stored `processed_html`
//! (`Article`, `Comment`, and `Billboard#processed_html_final` via the
//! `ProcessedHtmlFinalizable` concern), currently the Cloudflare Images domain migration that
//! rewrites every `PRIOR_CLOUDFLARE_IMAGES_DOMAIN` occurrence to `CLOUDFLARE_IMAGES_DOMAIN`.
//!
//! * Tier 1 — [`gsub_literal`]: Ruby `String#gsub(String, String)` semantics (non-overlapping,
//!   left-to-right literal replacement) that reports [`LiteralGsub::Unchanged`] without
//!   allocating when nothing matches, so the binding can hand back the caller's original string.
//! * Tier 1 — [`push_replaced_literal`]: the same replacement streamed into an existing buffer,
//!   used by the single-pass comment tree and story card renderers.
//! * [`push_processed_html_final`]: the shared `processed_html_final` step for those renderers.

/// Outcome of [`gsub_literal`] inside its fast-path domain.
#[derive(Debug, PartialEq, Eq)]
pub enum LiteralGsub {
    /// No occurrence of the needle; the haystack can be returned untouched.
    Unchanged,
    /// Every occurrence replaced.
    Replaced(String),
}

/// `haystack.gsub(needle, replacement)` for a literal `needle`.
///
/// Returns `None` (defer to Ruby) when `needle` is empty (Ruby inserts the replacement between
/// every character) or `replacement` contains a backslash (Ruby interprets `\0`, `\&`, `\k<..>`,
/// `\\`, ... in String replacements even for String patterns).
///
/// Matching on bytes is equivalent to Ruby's character-aware search because both strings are
/// valid UTF-8, which is self-synchronizing: a valid needle can only match at char boundaries.
pub fn gsub_literal(haystack: &str, needle: &str, replacement: &str) -> Option<LiteralGsub> {
    if needle.is_empty() || replacement.as_bytes().contains(&b'\\') {
        return None;
    }
    // `str::contains` has a SIMD prefilter for short needles that `str::find` lacks, so the common
    // no-match case (most documents no longer reference the prior domain) skips the Two-Way search.
    if !haystack.contains(needle) {
        return Some(LiteralGsub::Unchanged);
    }
    let first = haystack.find(needle)?;
    let mut out = String::with_capacity(estimated_capacity(haystack, needle, replacement));
    out.push_str(&haystack[..first]);
    out.push_str(replacement);
    push_replaced_literal(
        &mut out,
        &haystack[first + needle.len()..],
        needle,
        replacement,
    );
    Some(LiteralGsub::Replaced(out))
}

/// Appends `haystack` to `out` with every non-overlapping `needle` replaced by `replacement`
/// (a plain copy when `needle` is empty).
pub fn push_replaced_literal(out: &mut String, haystack: &str, needle: &str, replacement: &str) {
    if needle.is_empty() {
        out.push_str(haystack);
        return;
    }
    let mut rest = haystack;
    while let Some(pos) = rest.find(needle) {
        out.push_str(&rest[..pos]);
        out.push_str(replacement);
        rest = &rest[pos + needle.len()..];
    }
    out.push_str(rest);
}

/// Appends `processed_html` with the Cloudflare Images domain rewrite applied when both domains
/// are configured (non-empty), otherwise verbatim.
pub fn push_processed_html_final(
    out: &mut String,
    processed_html: &str,
    prior_domain: Option<&str>,
    current_domain: Option<&str>,
) {
    match (prior_domain, current_domain) {
        (Some(prior), Some(current)) if !prior.is_empty() && !current.is_empty() => {
            push_replaced_literal(out, processed_html, prior, current);
        }
        _ => out.push_str(processed_html),
    }
}

#[inline]
fn estimated_capacity(haystack: &str, needle: &str, replacement: &str) -> usize {
    // Domain swaps are usually same-length or shorter; leave headroom for a handful of longer
    // replacements without a pre-count pass.
    let growth = replacement.len().saturating_sub(needle.len());
    haystack.len() + growth.saturating_mul(16)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn replaced(h: &str, n: &str, r: &str) -> String {
        match gsub_literal(h, n, r) {
            Some(LiteralGsub::Replaced(s)) => s,
            other => panic!("expected replacement, got {other:?}"),
        }
    }

    #[test]
    fn unchanged_when_no_match() {
        assert_eq!(
            gsub_literal("<p>hi</p>", "media2.dev.to", "media.dev.to"),
            Some(LiteralGsub::Unchanged)
        );
        assert_eq!(gsub_literal("", "a", "b"), Some(LiteralGsub::Unchanged));
    }

    #[test]
    fn replaces_every_occurrence() {
        let html = "<img src='https://old.example/a.png'> <img src='https://old.example/b.png'>";
        assert_eq!(
            replaced(html, "old.example", "new.example.com"),
            "<img src='https://new.example.com/a.png'> <img src='https://new.example.com/b.png'>"
        );
    }

    #[test]
    fn non_overlapping_left_to_right_like_ruby() {
        assert_eq!(replaced("aaaa", "aa", "b"), "bb");
        assert_eq!(replaced("aaa", "aa", "b"), "ba");
        assert_eq!(replaced("abab", "ab", "ab"), "abab");
        assert_eq!(replaced("xx", "x", ""), "");
    }

    #[test]
    fn match_at_edges() {
        assert_eq!(replaced("old", "old", "new"), "new");
        assert_eq!(replaced("old-x-old", "old", "n"), "n-x-n");
    }

    #[test]
    fn multibyte_boundaries() {
        assert_eq!(
            replaced("héllo 🎉 old 日本 old", "old", "nëw"),
            "héllo 🎉 nëw 日本 nëw"
        );
        assert_eq!(replaced("🎉🎉", "🎉", "x"), "xx");
        // A needle sharing a UTF-8 continuation byte prefix must not match mid-char.
        assert_eq!(
            gsub_literal("é", "\u{a9}", "x"),
            Some(LiteralGsub::Unchanged)
        );
    }

    #[test]
    fn defers_out_of_domain() {
        assert_eq!(gsub_literal("abc", "", "x"), None);
        assert_eq!(gsub_literal("abc", "b", "\\0"), None);
        assert_eq!(gsub_literal("abc", "b", "a\\\\b"), None);
        // Backslashes in the pattern or haystack are literal for String patterns.
        assert_eq!(replaced("a\\b", "\\", "/"), "a/b");
    }

    #[test]
    fn push_helpers() {
        let mut out = String::from(">");
        push_replaced_literal(&mut out, "a.b.a", "a", "zz");
        assert_eq!(out, ">zz.b.zz");

        let mut out = String::new();
        push_replaced_literal(&mut out, "abc", "", "zz");
        assert_eq!(out, "abc");

        let mut out = String::new();
        push_processed_html_final(&mut out, "old/old", Some("old"), Some("new"));
        assert_eq!(out, "new/new");

        for (prior, current) in [
            (None, Some("new")),
            (Some("old"), None),
            (Some(""), Some("new")),
            (Some("old"), Some("")),
        ] {
            let mut out = String::new();
            push_processed_html_final(&mut out, "old", prior, current);
            assert_eq!(out, "old");
        }
    }
}
