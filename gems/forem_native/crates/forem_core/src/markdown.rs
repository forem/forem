use std::borrow::Cow;

/// Words read per minute constant matching `MarkdownProcessor::Parser::WORDS_READ_PER_MINUTE`.
pub const WORDS_READ_PER_MINUTE: usize = 275;

#[inline]
const fn is_ascii_word_byte(byte: u8) -> bool {
    byte.is_ascii_alphanumeric() || byte == b'_'
}

/// Counts tokens produced by Ruby's `content.split(/\W+/).count` in a single zero-allocation pass.
///
/// ### Behavioral Equivalence Notes
/// In Ruby, `/\W+/` (without the `/u` flag) defines word characters strictly as ASCII `[a-zA-Z0-9_]`.
/// Furthermore, `String#split(pattern)` with default `limit = 0`:
/// - Returns `[]` (`0` tokens) when the string is empty or contains only non-word bytes.
/// - Strips all trailing empty fields when the string ends with `/\W+/`.
/// - Preserves a single leading `""` token when the string starts with a non-word byte (`/\W+/`)
///   and contains at least one ASCII word run after it.
#[inline]
pub fn split_word_count_bytes(bytes: &[u8]) -> usize {
    let mut word_runs = 0usize;
    let mut in_word = false;

    for &byte in bytes {
        if is_ascii_word_byte(byte) {
            if !in_word {
                word_runs += 1;
                in_word = true;
            }
        } else {
            in_word = false;
        }
    }

    if word_runs == 0 {
        return 0;
    }

    let starts_with_non_word = !is_ascii_word_byte(bytes[0]);
    word_runs + usize::from(starts_with_non_word)
}

/// Convenience wrapper around [`split_word_count_bytes`] for UTF-8 `&str` slices.
#[inline]
pub fn split_word_count(text: &str) -> usize {
    split_word_count_bytes(text.as_bytes())
}

/// Calculates estimated reading time in minutes, matching
/// `(content.split(/\W+/).count / 275.0).ceil` in `MarkdownProcessor::Parser#calculate_reading_time`.
#[inline]
pub fn calculate_reading_time_bytes(bytes: &[u8]) -> usize {
    let word_count = split_word_count_bytes(bytes);
    word_count.div_ceil(WORDS_READ_PER_MINUTE)
}

/// Convenience wrapper around [`calculate_reading_time_bytes`] for UTF-8 `&str` slices.
#[inline]
pub fn calculate_reading_time(text: &str) -> usize {
    calculate_reading_time_bytes(text.as_bytes())
}

/// Equivalent of `MarkdownProcessor::Parser#convert_deeply_nested_links_to_html`:
///
/// ```ruby
/// content.gsub(/^(?: {16,}|\t{4,})[-*+ \d.]* .*$/) do |line|
///   line.gsub(/\[([^\]]*)\]\(([^)]*)\)/) { "<a href=\"#{$2}\">#{$1}</a>" }
/// end
/// ```
///
/// Ruby's `^`/`$` only split on `\n` (a trailing `\r` stays part of the line) and `\d` is
/// ASCII-only, so every delimiter is a single ASCII byte and slicing never splits a
/// multi-byte UTF-8 character.
///
/// Returns `Cow::Borrowed` when no line is deeply nested (the common case), so callers can
/// hand back a shared copy of the input instead of copying it.
pub fn convert_deeply_nested_links_to_html(content: &str) -> Cow<'_, str> {
    let mut out: Option<String> = None;
    let mut line_start = 0;
    for line in content.split_inclusive('\n') {
        let body = line.strip_suffix('\n').unwrap_or(line);
        if is_deeply_nested_line(body.as_bytes()) {
            let buf = out.get_or_insert_with(|| {
                let mut buf = String::with_capacity(content.len() + 64);
                buf.push_str(&content[..line_start]);
                buf
            });
            push_links_as_html(body, buf);
            buf.push_str(&line[body.len()..]);
        } else if let Some(buf) = out.as_mut() {
            buf.push_str(line);
        }
        line_start += line.len();
    }
    out.map_or(Cow::Borrowed(content), Cow::Owned)
}

/// Matches `^(?: {16,}|\t{4,})[-*+ \d.]* .*$` against a single line (without `\n`).
///
/// Extra leading spaces past the 16th can backtrack into `[-*+ \d.]*` (and serve as the
/// required space), so the regex matches iff the run of `[-*+ \d.]` characters after the
/// minimal indent contains a space. Tabs are outside that class, so the tab branch has to
/// consume every leading tab.
fn is_deeply_nested_line(line: &[u8]) -> bool {
    let leading = |byte: u8| line.iter().take_while(|&&b| b == byte).count();
    let indent = if leading(b' ') >= 16 {
        16
    } else {
        match leading(b'\t') {
            tabs if tabs >= 4 => tabs,
            _ => return false,
        }
    };

    line[indent..]
        .iter()
        .take_while(|&&b| matches!(b, b'-' | b'*' | b'+' | b' ' | b'.' | b'0'..=b'9'))
        .any(|&b| b == b' ')
}

/// Rewrites `[text](url)` as `<a href="url">text</a>` with the leftmost-first semantics of
/// `/\[([^\]]*)\]\(([^)]*)\)/`: the text runs to the first `]` (and may contain `[`), which
/// must be followed by `(`, and the url runs to the first `)` after it.
fn push_links_as_html(line: &str, out: &mut String) {
    let bytes = line.as_bytes();
    let mut copied = 0;
    let mut pos = 0;

    while let Some(offset) = bytes[pos..].iter().position(|&b| b == b'[') {
        let open = pos + offset;
        // Every `[` before this `]` shares it as the end of its text.
        let Some(close) = find_byte(bytes, open + 1, b']') else {
            break;
        };
        if bytes.get(close + 1) != Some(&b'(') {
            pos = close + 1;
            continue;
        }
        // No later `[` can find a `)` either.
        let Some(paren) = find_byte(bytes, close + 2, b')') else {
            break;
        };

        out.push_str(&line[copied..open]);
        out.push_str("<a href=\"");
        out.push_str(&line[close + 2..paren]);
        out.push_str("\">");
        out.push_str(&line[open + 1..close]);
        out.push_str("</a>");
        copied = paren + 1;
        pos = copied;
    }
    out.push_str(&line[copied..]);
}

#[inline]
fn find_byte(bytes: &[u8], from: usize, needle: u8) -> Option<usize> {
    bytes
        .get(from..)?
        .iter()
        .position(|&b| b == needle)
        .map(|i| from + i)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_and_non_word_only_strings_return_zero() {
        assert_eq!(split_word_count(""), 0);
        assert_eq!(calculate_reading_time(""), 0);

        assert_eq!(split_word_count("   \n\t\r  "), 0);
        assert_eq!(calculate_reading_time("   \n\t\r  "), 0);

        assert_eq!(split_word_count("... --- !!! ???"), 0);
        assert_eq!(calculate_reading_time("... --- !!! ???"), 0);

        assert_eq!(split_word_count("🚀 🌟 🎉"), 0);
        assert_eq!(calculate_reading_time("🚀 🌟 🎉"), 0);
    }

    #[test]
    fn basic_word_counting_and_reading_time() {
        assert_eq!(split_word_count("hello"), 1);
        assert_eq!(calculate_reading_time("hello"), 1);

        assert_eq!(split_word_count("hello world"), 2);
        assert_eq!(calculate_reading_time("hello world"), 1);

        assert_eq!(split_word_count("foo_bar_123 baz"), 2);
        assert_eq!(calculate_reading_time("foo_bar_123 baz"), 1);
    }

    #[test]
    fn preserves_ruby_split_leading_delimiter_semantics() {
        // In Ruby: "  hello world  ".split(/\W+/) => ["", "hello", "world"] (count = 3)
        assert_eq!(split_word_count("  hello world  "), 3);
        assert_eq!(split_word_count("...hello...world..."), 3);
        assert_eq!(split_word_count("\n\thello\n"), 2);
        assert_eq!(split_word_count("🚀 hello 🌟"), 2);
        assert_eq!(split_word_count("café résumé"), 3);
    }

    #[test]
    fn reading_time_boundaries_match_ceil_division() {
        let words_275 = (0..275).map(|_| "word").collect::<Vec<_>>().join(" ");
        assert_eq!(split_word_count(&words_275), 275);
        assert_eq!(calculate_reading_time(&words_275), 1);

        let words_276 = (0..276).map(|_| "word").collect::<Vec<_>>().join(" ");
        assert_eq!(split_word_count(&words_276), 276);
        assert_eq!(calculate_reading_time(&words_276), 2);

        // Leading non-word char pushes 275 words to 276 tokens in Ruby's `split(/\W+/)`
        let leading_space_275 = format!(" {words_275}");
        assert_eq!(split_word_count(&leading_space_275), 276);
        assert_eq!(calculate_reading_time(&leading_space_275), 2);

        let words_550 = (0..550).map(|_| "word").collect::<Vec<_>>().join(" ");
        assert_eq!(calculate_reading_time(&words_550), 2);

        let words_551 = (0..551).map(|_| "word").collect::<Vec<_>>().join(" ");
        assert_eq!(calculate_reading_time(&words_551), 3);
    }

    fn nested(input: &str) -> String {
        convert_deeply_nested_links_to_html(input).into_owned()
    }

    #[test]
    fn borrows_input_when_no_line_is_deeply_nested() {
        let input = "# Title\n\n- [a](b)\n    - [c](d)\n```\ncode\n```\n";
        assert!(matches!(
            convert_deeply_nested_links_to_html(input),
            Cow::Borrowed(s) if s == input
        ));
        let deep = format!("intro\n{}- [a](b)\noutro", " ".repeat(16));
        assert!(matches!(
            convert_deeply_nested_links_to_html(&deep),
            Cow::Owned(_)
        ));
    }

    #[test]
    fn leaves_shallow_and_non_list_lines_untouched() {
        for input in [
            "",
            "\n",
            "[a](b)",
            "- [a](b)",
            &format!("{}- [a](b)", " ".repeat(15)),
            &format!("{}x [a](b)", " ".repeat(16)),
            &format!("{}-[a](b)", " ".repeat(16)),
            "\t\t\t- [a](b)",
            "\t\t\t\tx [a](b)",
            &format!("x{}- [a](b)", " ".repeat(16)),
        ] {
            assert_eq!(nested(input), input, "{input:?}");
        }
    }

    #[test]
    fn converts_links_on_deeply_nested_lines() {
        let indent = " ".repeat(16);
        assert_eq!(
            nested(&format!("{indent}- [DEV](https://dev.to) and [x](y)")),
            format!("{indent}- <a href=\"https://dev.to\">DEV</a> and <a href=\"y\">x</a>")
        );
        assert_eq!(
            nested(&format!("{indent} [a](b)")),
            format!("{indent} <a href=\"b\">a</a>")
        );
        assert_eq!(
            nested(&format!("{indent}1.2 [a](b)")),
            format!("{indent}1.2 <a href=\"b\">a</a>")
        );
        assert_eq!(
            nested("\t\t\t\t\t- [a](b)"),
            "\t\t\t\t\t- <a href=\"b\">a</a>"
        );
        assert_eq!(
            nested("\t\t\t\t \t[a](b)"),
            "\t\t\t\t \t<a href=\"b\">a</a>"
        );
    }

    #[test]
    fn mirrors_leftmost_regex_link_semantics() {
        let indent = " ".repeat(17);
        let cases = [
            ("[a [b](c)", "<a href=\"c\">a [b</a>"),
            ("[a] [b](c)", "[a] <a href=\"c\">b</a>"),
            ("[](  )", "<a href=\"  \"></a>"),
            ("[a](b(c))", "<a href=\"b(c\">a</a>)"),
            ("[a](b", "[a](b"),
            ("[a]](b)", "[a]](b)"),
            ("[[a]](b)", "[[a]](b)"),
            ("[a](b) [c]", "<a href=\"b\">a</a> [c]"),
            ("[日本](🚀) é", "<a href=\"🚀\">日本</a> é"),
        ];
        for (body, expected) in cases {
            assert_eq!(
                nested(&format!("{indent}{body}")),
                format!("{indent}{expected}"),
                "{body:?}"
            );
        }
    }

    #[test]
    fn treats_only_lf_as_a_line_break() {
        let indent = " ".repeat(16);
        assert_eq!(
            nested(&format!("{indent}- [a](b)\r\n[c](d)\n{indent}- [e](f)\n")),
            format!("{indent}- <a href=\"b\">a</a>\r\n[c](d)\n{indent}- <a href=\"f\">e</a>\n")
        );
        // Links never span lines.
        assert_eq!(
            nested(&format!("{indent}- [a\n](b)")),
            format!("{indent}- [a\n](b)")
        );
    }
}
