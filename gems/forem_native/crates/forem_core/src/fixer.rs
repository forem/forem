use std::borrow::Cow;

const FRONT_MATTER_FENCE: &str = "---";
const TAGS_LINE: &str = "\ntags:";
const PUBLISHED_KEY: &str = "published: ";
const CODEBLOCK_MARKER: &str = "```";

/// Replaces CRLF line endings with LF, matching `String#gsub("\\r\\n", "\\n")`.
///
/// Returns `Cow::Borrowed` when the input contains no CRLF pair.
pub fn convert_new_lines(markdown: &str) -> Cow<'_, str> {
    if !markdown.as_bytes().windows(2).any(|pair| pair == b"\r\n") {
        return Cow::Borrowed(markdown);
    }

    Cow::Owned(markdown.replace("\r\n", "\n"))
}

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

/// Joins `#tag` lists on `tags:` lines, matching `MarkdownProcessor::Fixer::Base.split_tags`:
///
/// ```ruby
/// markdown.gsub(/\ntags:.*\n/) do |tags|
///   tags.split(" #").join(",").delete("#").gsub(":,", ": ")
/// end
/// ```
///
/// ### Behavioral Equivalence Notes
/// - A match is `\ntags:` plus the rest of its line *including* the closing `\n`, so a
///   `tags:` on the very first line or on an unterminated last line is left alone, and a
///   `tags:` line right after another one is skipped (its leading `\n` was consumed).
/// - The match always ends in `\n`, so `split(" #")` never drops trailing empty fields and
///   `split(" #").join(",")` is exactly a left-to-right `" #"` -> `","` replacement.
/// - The three steps run in Ruby's order over the whole match (including the `\ntags:`
///   prefix), so `tags: #a` becomes `tags: a` via `tags:,a`.
///
/// Returns `Cow::Borrowed` when there is no `tags:` line to rewrite.
pub fn split_tags(markdown: &str) -> Cow<'_, str> {
    let mut out: Option<String> = None;
    // Everything before `copied` is already in `out`.
    let mut copied = 0;
    let mut search_from = 0;

    while let Some(start) = find(markdown, TAGS_LINE, search_from) {
        let Some(newline) = find(markdown, "\n", start + TAGS_LINE.len()) else {
            break;
        };
        let end = newline + 1;
        search_from = end;
        let segment = &markdown[start..end];
        if !segment.contains('#') && !segment.contains(":,") {
            continue;
        }

        let out = out.get_or_insert_with(|| String::with_capacity(markdown.len()));
        out.push_str(&markdown[copied..start]);
        let joined = segment.replace(" #", ",").replace('#', "");
        out.push_str(&joined.replace(":,", ": "));
        copied = end;
    }

    match out {
        Some(mut out) => {
            out.push_str(&markdown[copied..]);
            Cow::Owned(out)
        }
        None => Cow::Borrowed(markdown),
    }
}

/// Lowercases `published:` keys inside every front matter block, matching
/// `MarkdownProcessor::Fixer::Base.lowercase_published`:
///
/// ```ruby
/// markdown.gsub(/-{3}.*?-{3}/m) do |front_matter|
///   front_matter.gsub(/^published: /i, "published: ")
/// end
/// ```
///
/// ### Behavioral Equivalence Notes
/// - Each block is a `---` plus everything up to the next `---` that starts at least three
///   bytes later; the next block search resumes right after it. Once no closing `---` is
///   left, no later start can find one either.
/// - The inner `gsub` only sees the block, so `^` anchors right after a `\n` inside it
///   (its first byte is `-`) and the key has to end before the closing `---` ends.
/// - Onigmo's `/i` folds ASCII letters plus `ſ` (U+017F LONG S) for `s`; no other code
///   point or sequence folds onto `published` (checked against every code point).
///
/// Returns `Cow::Borrowed` when every key inside front matter is already lowercase.
pub fn lowercase_published(markdown: &str) -> Cow<'_, str> {
    let bytes = markdown.as_bytes();
    let mut out: Option<String> = None;
    // Everything before `copied` is already in `out`.
    let mut copied = 0;
    let mut search_from = 0;

    while let Some(open) = find(markdown, FRONT_MATTER_FENCE, search_from) {
        let Some(close) = find(
            markdown,
            FRONT_MATTER_FENCE,
            open + FRONT_MATTER_FENCE.len(),
        ) else {
            break;
        };
        let end = close + FRONT_MATTER_FENCE.len();
        let front_matter = &markdown[..end];

        let mut line_from = open;
        while let Some(newline) = find(front_matter, "\n", line_from) {
            let start = newline + 1;
            line_from = start;
            let Some(len) = published_key_len(&bytes[start..end]) else {
                continue;
            };
            if &bytes[start..start + len] == PUBLISHED_KEY.as_bytes() {
                continue;
            }

            let out = out.get_or_insert_with(|| String::with_capacity(markdown.len()));
            out.push_str(&markdown[copied..start]);
            out.push_str(PUBLISHED_KEY);
            copied = start + len;
        }

        search_from = end;
    }

    match out {
        Some(mut out) => {
            out.push_str(&markdown[copied..]);
            Cow::Owned(out)
        }
        None => Cow::Borrowed(markdown),
    }
}

/// Byte length of a `/published: /i` match at the start of `bytes`, if there is one.
fn published_key_len(bytes: &[u8]) -> Option<usize> {
    let (head, rest) = (bytes.get(..5)?, &bytes[5..]);
    if !head.eq_ignore_ascii_case(b"publi") {
        return None;
    }
    let s_len = match rest {
        [b's' | b'S', ..] => 1,
        // `ſ` (U+017F) case-folds to `s`.
        [0xC5, 0xBF, ..] => 2,
        _ => return None,
    };
    let tail = rest.get(s_len..s_len + 5)?;
    if tail[..3].eq_ignore_ascii_case(b"hed") && &tail[3..] == b": " {
        Some(5 + s_len + 5)
    } else {
        None
    }
}

/// Escapes `@_username_` underscores outside fenced code blocks, matching
/// `MarkdownProcessor::Fixer::Base.underscores_in_usernames`:
///
/// ```ruby
/// return markdown unless markdown.match?(/(?<!`)@_\w+_/)
///
/// traverser = MarkdownProcessor::Traverser.new(markdown)
/// traverser.each do |line|
///   next if traverser.in_codeblock?
///
///   line.scan(/(?<!`)@_\w+_/).each do |to_escape|
///     line.sub!(to_escape, to_escape.gsub("_", "\\_"))
///   end
/// end.join
/// ```
///
/// ### Behavioral Equivalence Notes
/// - `Traverser` flips its state on every line holding a ```` ``` ```` and skips only the
///   lines in between, so the fence lines themselves are still escaped.
/// - Ruby's `\w` is ASCII-only here, and the greedy `\w+_` ends at the last `_` of the
///   word run that has at least one word byte before it.
/// - `sub!` replaces the first literal occurrence in the (already updated) line, which can be
///   an earlier `` `@_name_ `` the scan itself skipped; that is replayed as-is.
/// - Without a match `Traverser` yields the lines unchanged, so the early return is only a
///   shortcut.
///
/// Returns `Cow::Borrowed` when no username gets escaped (the binding then returns the input).
pub fn underscores_in_usernames(markdown: &str) -> Cow<'_, str> {
    if next_username(markdown, 0).is_none() {
        return Cow::Borrowed(markdown);
    }

    let mut out: Option<String> = None;
    // Everything before `copied` is already in `out`.
    let mut copied = 0;
    let mut offset = 0;
    let mut in_codeblock = false;

    for line in markdown.split_inclusive('\n') {
        let start = offset;
        offset += line.len();
        if line.contains(CODEBLOCK_MARKER) {
            in_codeblock = !in_codeblock;
        } else if in_codeblock {
            continue;
        }

        let Some(escaped) = escape_usernames_in_line(line) else {
            continue;
        };
        let out = out.get_or_insert_with(|| String::with_capacity(markdown.len() + 16));
        out.push_str(&markdown[copied..start]);
        out.push_str(&escaped);
        copied = offset;
    }

    match out {
        Some(mut out) => {
            out.push_str(&markdown[copied..]);
            Cow::Owned(out)
        }
        None => Cow::Borrowed(markdown),
    }
}

/// `escape_underscored_username_in_line!`, or `None` when the line has no username.
fn escape_usernames_in_line(line: &str) -> Option<String> {
    let mut matches = Vec::new();
    let mut from = 0;
    while let Some((start, end)) = next_username(line, from) {
        matches.push(&line[start..end]);
        from = end;
    }
    if matches.is_empty() {
        return None;
    }

    let mut escaped_line = line.to_owned();
    for to_escape in matches {
        if let Some(at) = escaped_line.find(to_escape) {
            escaped_line.replace_range(at..at + to_escape.len(), &to_escape.replace('_', "\\_"));
        }
    }
    Some(escaped_line)
}

/// Byte range of the next `/(?<!`)@_\w+_/` match starting at or after `from`.
fn next_username(text: &str, mut from: usize) -> Option<(usize, usize)> {
    let bytes = text.as_bytes();
    while let Some(at) = find(text, "@_", from) {
        from = at + 1;
        if at > 0 && bytes[at - 1] == b'`' {
            continue;
        }
        let run_start = at + 2;
        let run_len = bytes[run_start..]
            .iter()
            .take_while(|&&byte| byte.is_ascii_alphanumeric() || byte == b'_')
            .count();
        // `\w+` needs one word byte before the closing `_`.
        if let Some(last) = bytes[run_start..run_start + run_len]
            .iter()
            .skip(1)
            .rposition(|&byte| byte == b'_')
        {
            return Some((at, run_start + 1 + last + 1));
        }
    }
    None
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

#[inline]
fn chain_cow<'a>(input: Cow<'a, str>, f: impl FnOnce(&str) -> Cow<'_, str>) -> Cow<'a, str> {
    match f(&input) {
        Cow::Borrowed(_) => input,
        Cow::Owned(s) => Cow::Owned(s),
    }
}

/// Runs the complete `MarkdownProcessor::Fixer::FixAll` pipeline in a single Rust pass
/// without intermediate Ruby `String` allocations or repeated FFI crossings:
/// 1. `add_quotes_to_section("title")`
/// 2. `add_quotes_to_section("description")`
/// 3. `lowercase_published`
/// 4. `convert_new_lines`
/// 5. `split_tags`
/// 6. `underscores_in_usernames`
///
/// Returns `Cow::Borrowed` when none of the six passes alter `markdown`.
pub fn fix_all(markdown: &str) -> Cow<'_, str> {
    let step = add_quotes_to_section(markdown, "title").unwrap_or(Cow::Borrowed(markdown));
    let step = chain_cow(step, |s| {
        add_quotes_to_section(s, "description").unwrap_or(Cow::Borrowed(s))
    });
    let step = chain_cow(step, lowercase_published);
    let step = chain_cow(step, convert_new_lines);
    let step = chain_cow(step, split_tags);
    chain_cow(step, underscores_in_usernames)
}

/// Runs the `MarkdownProcessor::Fixer::FixForPreview` pipeline in a single Rust pass:
/// 1. `add_quotes_to_section("title")`
/// 2. `add_quotes_to_section("description")`
/// 3. `underscores_in_usernames`
///
/// Returns `Cow::Borrowed` when none of the three passes alter `markdown`.
pub fn fix_for_preview(markdown: &str) -> Cow<'_, str> {
    let step = add_quotes_to_section(markdown, "title").unwrap_or(Cow::Borrowed(markdown));
    let step = chain_cow(step, |s| {
        add_quotes_to_section(s, "description").unwrap_or(Cow::Borrowed(s))
    });
    chain_cow(step, underscores_in_usernames)
}

/// Runs the `MarkdownProcessor::Fixer::FixForComment` pipeline (`underscores_in_usernames`).
#[inline]
pub fn fix_for_comment(markdown: &str) -> Cow<'_, str> {
    underscores_in_usernames(markdown)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn converts_crlf_pairs_and_preserves_other_bytes() {
        assert_eq!(convert_new_lines(""), "");
        assert!(matches!(convert_new_lines("LF\nonly\r"), Cow::Borrowed(_)));
        assert_eq!(convert_new_lines("a\r\nb\r\nc"), "a\nb\nc");
        assert_eq!(convert_new_lines("🚀\r\n日本\rX\n"), "🚀\n日本\rX\n");
        assert_eq!(convert_new_lines("\r\r\n"), "\r\n");
    }

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

    #[test]
    fn split_tags_joins_hash_tags() {
        assert_eq!(
            split_tags("---\ntags: #a #b #c\n---"),
            "---\ntags: a,b,c\n---"
        );
        assert_eq!(split_tags("---\ntags: a, b\n---"), "---\ntags: a, b\n---");
        assert_eq!(split_tags("---\ntags:#a#b\n"), "---\ntags:ab\n");
        assert_eq!(split_tags("x\ntags: # #a ##b\n"), "x\ntags: ,a,b\n");
        assert_eq!(split_tags("x\ntags::# a\n"), "x\ntags:: a\n");
    }

    #[test]
    fn split_tags_needs_leading_and_trailing_newlines() {
        assert!(matches!(split_tags("tags: #a #b\n"), Cow::Borrowed(_)));
        assert!(matches!(split_tags("x\ntags: #a #b"), Cow::Borrowed(_)));
        assert!(matches!(split_tags(""), Cow::Borrowed(_)));
        assert_eq!(
            split_tags("\ntags: #a\ntags: #b\n\ntags: #c\n"),
            "\ntags: a\ntags: #b\n\ntags: c\n"
        );
    }

    #[test]
    fn split_tags_keeps_carriage_returns_and_multibyte() {
        assert_eq!(
            split_tags("x\r\ntags: #日本 #🚀\r\nbody #x\n"),
            "x\r\ntags: 日本,🚀\r\nbody #x\n"
        );
        assert_eq!(split_tags("\nTags: #a\n"), "\nTags: #a\n");
    }

    #[test]
    fn lowercase_published_rewrites_keys_inside_front_matter_only() {
        assert_eq!(
            lowercase_published("---\nPublished: true\nPUBLISHED: false\n---\nPublished: x\n"),
            "---\npublished: true\npublished: false\n---\nPublished: x\n"
        );
        assert_eq!(
            lowercase_published("---\na: 1\n---\n\n---\nPuBlIsHeD: y\n---"),
            "---\na: 1\n---\n\n---\npublished: y\n---"
        );
        assert_eq!(
            lowercase_published("---\nPublished: ---"),
            "---\npublished: ---"
        );
    }

    #[test]
    fn lowercase_published_needs_line_start_and_exact_key() {
        for input in [
            "---Published: x\n---",
            "--- Published: x\n---",
            "---\n Published: x\n---",
            "---\nPublished:x\n---",
            "---\nPublished : x\n---",
            "---\npublished: x\n---",
            "---\nPubli---shed: x\n",
            "---\nPublished:---",
            "---\r\nx\rPublished: x\n---",
            "-----\nPublished: x",
            "",
        ] {
            assert!(
                matches!(lowercase_published(input), Cow::Borrowed(_)),
                "{input:?}"
            );
        }
        assert_eq!(
            lowercase_published("---\r\nPublished: x\r\n---"),
            "---\r\npublished: x\r\n---"
        );
    }

    #[test]
    fn lowercase_published_folds_long_s_and_keeps_multibyte() {
        assert_eq!(
            lowercase_published("---\nPubliſhed: 日本\nPUBLIſHED: 🎉\n---"),
            "---\npublished: 日本\npublished: 🎉\n---"
        );
        assert!(matches!(
            lowercase_published("---\nPubliſshed: x\nPublishéd: y\n---"),
            Cow::Borrowed(_)
        ));
    }

    #[test]
    fn underscores_in_usernames_escapes_greedy_word_runs() {
        for (input, expected) in [
            ("@_xy_", "@\\_xy\\_"),
            ("@_x_y_", "@\\_x\\_y\\_"),
            ("@___", "@\\_\\_\\_"),
            ("@_a_b", "@\\_a\\_b"),
            ("a@_b_c@_d_", "a@\\_b\\_c@\\_d\\_"),
            ("@_a_@_b_", "@\\_a\\_@\\_b\\_"),
            ("@@_a_", "@@\\_a\\_"),
            ("@_a_\r\n@_b_", "@\\_a\\_\r\n@\\_b\\_"),
        ] {
            assert_eq!(underscores_in_usernames(input), expected, "{input:?}");
        }
        for input in [
            "",
            "@__",
            "@_a",
            "_make this cursive_",
            "@_é_ @_aé_x_",
            "`@_a_`",
        ] {
            assert!(
                matches!(underscores_in_usernames(input), Cow::Borrowed(_)),
                "{input:?}"
            );
        }
    }

    #[test]
    fn underscores_in_usernames_skips_codeblocks_but_not_fence_lines() {
        assert_eq!(
            underscores_in_usernames("@_dev_\n```ruby\n@_in_code_\n```\n@_out_\n"),
            "@\\_dev\\_\n```ruby\n@_in_code_\n```\n@\\_out\\_\n"
        );
        assert_eq!(
            underscores_in_usernames("``` @_fence_\n@_in_\n```\n"),
            "``` @\\_fence\\_\n@_in_\n```\n"
        );
        assert!(matches!(
            underscores_in_usernames("```@_fence_\n@_in_\n```\n"),
            Cow::Borrowed(_)
        ));
    }

    #[test]
    fn underscores_in_usernames_replays_first_occurrence_sub() {
        assert_eq!(underscores_in_usernames("`@_a_ @_a_"), "`@\\_a\\_ @_a_");
        assert_eq!(
            underscores_in_usernames("x`@_a_b_ @_a_"),
            "x`@\\_a\\_b_ @_a_"
        );
    }

    #[test]
    fn fix_all_fuses_all_six_fixer_passes() {
        let input = "---\r\ntitle: Hello \"World\"\r\ndescription: A post\r\nPublished: true\r\ntags: #ruby #rust\r\n---\r\nHi @_dev_user_!\r\n";
        let expected = "---\ntitle: \"Hello \\\"World\\\"\"\ndescription: \"A post\"\npublished: true\ntags: ruby,rust\n---\nHi @\\_dev\\_user\\_!\n";
        assert_eq!(fix_all(input), expected);

        let clean = "---\ntitle: \"Already Quoted\"\ndescription: \"Clean\"\npublished: false\ntags: ruby,rust\n---\nHello world\n";
        assert!(matches!(fix_all(clean), Cow::Borrowed(_)));
    }

    #[test]
    fn fix_for_preview_and_comment_run_subset_pipelines() {
        let input = "---\ntitle: Preview\ndescription: Sub\nPublished: true\ntags: #ruby #rust\n---\nHi @_dev_!\r\n";
        let expected_preview = "---\ntitle: \"Preview\"\ndescription: \"Sub\"\nPublished: true\ntags: #ruby #rust\n---\nHi @\\_dev\\_!\r\n";
        assert_eq!(fix_for_preview(input), expected_preview);

        let clean = "---\ntitle: \"Preview\"\ndescription: \"Sub\"\n---\nPlain body\n";
        assert!(matches!(fix_for_preview(clean), Cow::Borrowed(_)));

        assert_eq!(fix_for_comment("Hello @_a_b_!"), "Hello @\\_a\\_b\\_!");
        assert!(matches!(fix_for_comment("Plain comment"), Cow::Borrowed(_)));
    }
}
