use std::borrow::Cow;

const FRONT_MATTER_FENCE: &str = "---";

/// Quotes `<section>: value` lines inside the front matter, matching
/// `MarkdownProcessor::Fixer::Base.add_quotes_to_section`:
///
/// ```ruby
/// markdown.sub(/-{3}.*?-{3}/m) do |front_matter|
///   front_matter.gsub(/#{section}: ?(?<content>.*?)(\r\n|\n)/m) do |target|
///     captured_text = Regexp.last_match("content")
///     match = captured_text.scan(/(^".*"$|^'.*'$)/)
///     if match.empty?
///       parsed_text = captured_text.gsub(/(?<!\\)"/, "\\\"")
///       "#{section}: \"#{parsed_text}\"\n"
///     else
///       target
///     end
///   end
/// end
/// ```
///
/// ### Behavioral Equivalence Notes
/// - The front matter is the first `---` plus everything up to the next `---` that starts
///   at least three bytes later (the lazy `/m` match never needs to backtrack its start).
/// - `#{section}` is matched literally anywhere inside it (so `subtitle:` matches `title`),
///   and the lazy `/m` content stops at the first `\n`, dropping a `\r` right before it.
/// - The captured content never holds a `\n`, so `^`/`$` only anchor at its ends: it is
///   "already quoted" when it is at least two bytes long and starts and ends with the
///   same `"` or `'`.
///
/// Returns `None` when `section` is not a plain `[A-Za-z0-9_]+` word (Ruby would interpolate
/// it as a regex) and `Cow::Borrowed` when nothing needs quoting.
pub fn add_quotes_to_section<'a>(markdown: &'a str, section: &str) -> Option<Cow<'a, str>> {
    if section.is_empty()
        || !section
            .bytes()
            .all(|byte| byte.is_ascii_alphanumeric() || byte == b'_')
    {
        return None;
    }

    let bytes = markdown.as_bytes();
    let Some(open) = find(markdown, FRONT_MATTER_FENCE, 0) else {
        return Some(Cow::Borrowed(markdown));
    };
    let Some(close) = find(
        markdown,
        FRONT_MATTER_FENCE,
        open + FRONT_MATTER_FENCE.len(),
    ) else {
        return Some(Cow::Borrowed(markdown));
    };
    let front_matter = &markdown[..close + FRONT_MATTER_FENCE.len()];

    let mut out: Option<String> = None;
    // Everything before `copied` is already in `out`.
    let mut copied = 0;
    let mut search_from = open;

    while let Some(start) = find(front_matter, section, search_from) {
        let colon = start + section.len();
        if bytes.get(colon) != Some(&b':') {
            search_from = start + 1;
            continue;
        }
        let mut content_start = colon + 1;
        if bytes.get(content_start) == Some(&b' ') {
            content_start += 1;
        }
        let Some(newline) = find(front_matter, "\n", content_start) else {
            break;
        };
        let content_end = if newline > content_start && bytes[newline - 1] == b'\r' {
            newline - 1
        } else {
            newline
        };
        search_from = newline + 1;

        let content = &markdown[content_start..content_end];
        if is_wrapped_in_quotes(content.as_bytes()) {
            continue;
        }

        let out = out.get_or_insert_with(|| String::with_capacity(markdown.len() + 16));
        out.push_str(&markdown[copied..start]);
        out.push_str(section);
        out.push_str(": \"");
        push_escaped_double_quotes(content, out);
        out.push_str("\"\n");
        copied = newline + 1;
    }

    Some(match out {
        Some(mut out) => {
            out.push_str(&markdown[copied..]);
            Cow::Owned(out)
        }
        None => Cow::Borrowed(markdown),
    })
}

fn is_wrapped_in_quotes(content: &[u8]) -> bool {
    match (content.first(), content.last()) {
        (Some(&first), Some(&last)) => {
            content.len() >= 2 && (first == b'"' || first == b'\'') && first == last
        }
        _ => false,
    }
}

/// `captured_text.gsub(/(?<!\\)"/, "\\\"")`: escapes every `"` not preceded by a backslash.
fn push_escaped_double_quotes(content: &str, out: &mut String) {
    let mut prev = None;
    for ch in content.chars() {
        if ch == '"' && prev != Some('\\') {
            out.push('\\');
        }
        out.push(ch);
        prev = Some(ch);
    }
}

/// `str::find` uses std's vectorized substring search; every `from` here sits right after
/// an ASCII byte, so it is always a char boundary.
fn find(haystack: &str, needle: &str, from: usize) -> Option<usize> {
    haystack.get(from..)?.find(needle).map(|index| index + from)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn quote(markdown: &str, section: &str) -> String {
        add_quotes_to_section(markdown, section)
            .expect("plain section")
            .into_owned()
    }

    #[test]
    fn quotes_unquoted_title() {
        assert_eq!(
            quote("---\ntitle: Hello\n---\nbody", "title"),
            "---\ntitle: \"Hello\"\n---\nbody"
        );
    }

    #[test]
    fn escapes_unescaped_double_quotes_only() {
        assert_eq!(
            quote("---\ntitle: a \"b\" \\\"c\\\"\n---", "title"),
            "---\ntitle: \"a \\\"b\\\" \\\"c\\\"\"\n---"
        );
        assert_eq!(
            quote("---\ntitle: \"Hello\n---", "title"),
            "---\ntitle: \"\\\"Hello\"\n---"
        );
    }

    #[test]
    fn keeps_already_quoted_values_and_their_line_endings() {
        let input = "---\ntitle: \"Hi\"\r\ndescription: 'x'\n---";
        assert!(matches!(
            add_quotes_to_section(input, "title"),
            Some(Cow::Borrowed(_))
        ));
        assert_eq!(quote(input, "description"), input);
    }

    #[test]
    fn single_quote_character_is_not_wrapped() {
        assert_eq!(
            quote("---\ntitle: \"\n---", "title"),
            "---\ntitle: \"\\\"\"\n---"
        );
        assert_eq!(
            quote("---\ntitle: '\n---", "title"),
            "---\ntitle: \"'\"\n---"
        );
        assert_eq!(
            quote("---\ntitle: \"x'\n---", "title"),
            "---\ntitle: \"\\\"x'\"\n---"
        );
    }

    #[test]
    fn normalizes_crlf_and_handles_missing_space_and_empty_values() {
        assert_eq!(
            quote("---\r\ntitle:Hi\r\n---", "title"),
            "---\r\ntitle: \"Hi\"\n---"
        );
        assert_eq!(quote("---\ntitle:\n---", "title"), "---\ntitle: \"\"\n---");
        assert_eq!(quote("---\ntitle: \n---", "title"), "---\ntitle: \"\"\n---");
        assert_eq!(
            quote("---\ntitle:  two\n---", "title"),
            "---\ntitle: \" two\"\n---"
        );
    }

    #[test]
    fn keeps_lone_carriage_returns_in_content() {
        assert_eq!(
            quote("---\ntitle: a\rb\r\r\n---", "title"),
            "---\ntitle: \"a\rb\r\"\n---"
        );
    }

    #[test]
    fn matches_every_literal_occurrence_inside_front_matter_only() {
        assert_eq!(
            quote("---\nsubtitle: a\ntitle: b\n---\ntitle: c\n", "title"),
            "---\nsubtitle: \"a\"\ntitle: \"b\"\n---\ntitle: c\n"
        );
        assert_eq!(
            quote("---\ntitletitle: x\n---", "title"),
            "---\ntitletitle: \"x\"\n---"
        );
        assert_eq!(quote("---\ntitle x\n---", "title"), "---\ntitle x\n---");
    }

    #[test]
    fn needs_a_newline_inside_front_matter() {
        assert_eq!(quote("---title: x---\n", "title"), "---title: x---\n");
        assert_eq!(
            quote("---\ntitle: x ---\ntitle: y\n", "title"),
            "---\ntitle: x ---\ntitle: y\n"
        );
    }

    #[test]
    fn front_matter_is_first_dash_run_to_next() {
        assert_eq!(
            quote("intro ----\ntitle: x\n---", "title"),
            "intro ----\ntitle: \"x\"\n---"
        );
        assert_eq!(quote("-----title: x\n", "title"), "-----title: x\n");
        assert_eq!(
            quote("------\ntitle: x\n---", "title"),
            "------\ntitle: x\n---"
        );
        assert_eq!(quote("no front matter", "title"), "no front matter");
        assert_eq!(quote("", "title"), "");
    }

    #[test]
    fn handles_multibyte_content() {
        assert_eq!(
            quote("---\ntitle: 日本語 \"🎉\"\n---", "title"),
            "---\ntitle: \"日本語 \\\"🎉\\\"\"\n---"
        );
    }

    #[test]
    fn rejects_non_word_sections() {
        assert!(add_quotes_to_section("---\ntitle: x\n---", "").is_none());
        assert!(add_quotes_to_section("---\ntitle: x\n---", "ti.le").is_none());
    }
}
