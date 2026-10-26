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
}
