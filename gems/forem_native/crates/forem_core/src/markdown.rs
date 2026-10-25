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

/// Equivalent of `MarkdownProcessor::Parser#escape_liquid_tags_in_codeblock`:
///
/// ```ruby
/// content.gsub(/([[:space:]]*(`{3,}|~{3,}))[\s\S]*?\2|`{2}.+?`{2}|`{1}.+?`{1}/m) do |codeblock|
///   codeblock.gsub!("{% endraw %}", "{----% endraw %----}")
///   codeblock.gsub!("{% raw %}", "{----% raw %----}")
///   if codeblock.match?(/[[:space:]]*`{3,}/)
///     "\n{% raw %}\n#{codeblock}\n{% endraw %}\n"
///   else
///     "{% raw %}#{codeblock}{% endraw %}"
///   end
/// end
/// ```
///
/// Onigmo's `[[:space:]]` on UTF-8 strings is the Unicode `White_Space` property, the same set
/// as `char::is_whitespace`. Every other delimiter is an ASCII byte, so slicing never splits a
/// multi-byte character, and the unanchored `match?` is simply "contains three backticks".
///
/// Returns `Cow::Borrowed` when there is no code (the common case for comments), so callers
/// can hand back a shared copy of the input instead of copying it.
pub fn escape_liquid_tags_in_codeblock(content: &str) -> Cow<'_, str> {
    let mut scanner = CodeScanner::new(content.as_bytes());
    let mut out: Option<String> = None;
    let mut copied = 0;
    let mut pos = 0;

    // Only whitespace, backticks, and tildes can start a match; skip other ASCII in bulk.
    while let Some(skip) = content.as_bytes()[pos..]
        .iter()
        .position(|&b| !b.is_ascii() || matches!(b, b'`' | b'~' | b'\t'..=b'\r' | b' '))
    {
        pos += skip;
        let Some(ch) = content[pos..].chars().next() else {
            break;
        };
        let found = if ch.is_whitespace() {
            // Fewer leading spaces would leave a space where the fence must start, so the
            // whole run is consumed, and the inline alternatives need a backtick at `pos`.
            let fence = pos + whitespace_len(&content[pos..]);
            match scanner.fenced_block_end(fence) {
                Some(end) => Some(end),
                None => {
                    pos = fence;
                    continue;
                }
            }
        } else if ch == '`' {
            scanner
                .fenced_block_end(pos)
                .or_else(|| scanner.inline_code_end(pos))
        } else if ch == '~' {
            scanner.fenced_block_end(pos)
        } else {
            None
        };

        let Some(end) = found else {
            pos += ch.len_utf8();
            continue;
        };
        let buf = out.get_or_insert_with(|| String::with_capacity(content.len() + 64));
        buf.push_str(&content[copied..pos]);
        push_raw_wrapped(&content[pos..end], buf);
        copied = end;
        pos = end;
    }

    match out {
        Some(mut buf) => {
            buf.push_str(&content[copied..]);
            Cow::Owned(buf)
        }
        None => Cow::Borrowed(content),
    }
}

fn whitespace_len(text: &str) -> usize {
    text.find(|c: char| !c.is_whitespace())
        .unwrap_or(text.len())
}

fn push_raw_wrapped(codeblock: &str, out: &mut String) {
    // Neither replacement can create or split an occurrence of the other tag.
    let escaped: Cow<'_, str> = if codeblock.contains("raw %}") {
        Cow::Owned(
            codeblock
                .replace("{% endraw %}", "{----% endraw %----}")
                .replace("{% raw %}", "{----% raw %----}"),
        )
    } else {
        Cow::Borrowed(codeblock)
    };
    if escaped.contains("```") {
        out.push_str("\n{% raw %}\n");
        out.push_str(&escaped);
        out.push_str("\n{% endraw %}\n");
    } else {
        out.push_str("{% raw %}");
        out.push_str(&escaped);
        out.push_str("{% endraw %}");
    }
}

/// Longest fence/backtick run length whose failed searches are remembered.
const MEMO_RUN_CAP: usize = 8;

/// Backtracking-equivalent matcher for the code alternatives of the escape regex.
///
/// A failed search for `k` consecutive fence bytes from `from` proves there is no such run
/// anywhere at or after `from` (nor any longer run), so those failures are remembered.
/// That keeps unclosed backticks linear instead of rescanning the rest of the document.
struct CodeScanner<'a> {
    bytes: &'a [u8],
    // `absent_from[fence][k - 1]`: no run of `k` fence bytes starts at or after this offset.
    absent_from: [[usize; MEMO_RUN_CAP]; 2],
}

impl<'a> CodeScanner<'a> {
    fn new(bytes: &'a [u8]) -> Self {
        Self {
            bytes,
            absent_from: [[usize::MAX; MEMO_RUN_CAP]; 2],
        }
    }

    /// `(`{3,}|~{3,})[\s\S]*?\2` at `start`: the greedy fence backtracks from the full run
    /// down to three bytes, and each length closes at the earliest identical run after it.
    fn fenced_block_end(&mut self, start: usize) -> Option<usize> {
        let fence = *self.bytes.get(start)?;
        if fence != b'`' && fence != b'~' {
            return None;
        }
        let run = self.bytes[start..]
            .iter()
            .take_while(|&&b| b == fence)
            .count();
        (3..=run).rev().find_map(|len| {
            self.find_run(fence, len, start + len)
                .map(|close| close + len)
        })
    }

    /// `` `{2}.+?`{2}|`{1}.+?`{1} `` at `start` (a backtick). `.+?` must consume at least
    /// one character, and a backtick is never part of a multi-byte one.
    fn inline_code_end(&mut self, start: usize) -> Option<usize> {
        if self.bytes.get(start + 1) == Some(&b'`') {
            if let Some(close) = self.find_run(b'`', 2, start + 3) {
                return Some(close + 2);
            }
        }
        self.find_run(b'`', 1, start + 2).map(|close| close + 1)
    }

    /// Offset of the first run of `len` consecutive `fence` bytes starting at or after `from`.
    fn find_run(&mut self, fence: u8, len: usize, from: usize) -> Option<usize> {
        let memo = &mut self.absent_from[usize::from(fence == b'~')];
        if memo[..len.min(MEMO_RUN_CAP)]
            .iter()
            .any(|&absent| from >= absent)
        {
            return None;
        }

        let mut count = 0;
        for (i, &b) in self.bytes.iter().enumerate().skip(from) {
            if b == fence {
                count += 1;
                if count == len {
                    return Some(i + 1 - len);
                }
            } else {
                count = 0;
            }
        }

        if len <= MEMO_RUN_CAP {
            memo[len - 1] = memo[len - 1].min(from);
        }
        None
    }
}

/// Placeholder `MarkdownProcessor::Parser#convert_escaped_pipes_outside_codeblocks` swaps
/// in for `\|` inside inline code spans.
const ESC_PIPE_PLACEHOLDER: &str = "\u{0}FOREM_ESC_PIPE\u{0}";

/// Equivalent of `MarkdownProcessor::Parser#convert_escaped_pipes_outside_codeblocks`:
///
/// ```ruby
/// content.each_line.map do |line|
///   # lines inside ``` / ~~~ fenced blocks (and the fence lines) are kept verbatim
///   line.gsub!(/(`+)([^`\n]*?(?:`(?!\1)[^`\n]*?)*)\1/) { |span| span.gsub('\|') { placeholder } }
///   line.gsub!(/(?<!\\)\\\|/, "&#124;")
///   line.gsub!(placeholder) { '\|' }
///   line
/// end.join
/// ```
///
/// `each_line` and Ruby's `^`/`$` only split on `\n`, and Ruby's `\s` is ASCII-only
/// (`[ \t\n\v\f\r]`), so every delimiter is a single ASCII byte and slicing never splits a
/// multi-byte UTF-8 character.
///
/// Returns `Cow::Borrowed` when no line changes, so callers can hand back a shared copy.
pub fn convert_escaped_pipes_outside_codeblocks(content: &str) -> Cow<'_, str> {
    if !content.contains("\\|") {
        return Cow::Borrowed(content);
    }

    let mut out: Option<String> = None;
    let mut offset = 0;
    let mut fence: Option<(u8, usize)> = None;

    for line in content.split_inclusive('\n') {
        let start = offset;
        offset += line.len();

        let converted = if let Some((fence_char, min_len)) = fence {
            if is_closing_fence(line.as_bytes(), fence_char, min_len) {
                fence = None;
            }
            None
        } else if let Some(opening) = opening_fence(line.as_bytes()) {
            fence = Some(opening);
            None
        } else if line.contains("\\|") || line.contains(ESC_PIPE_PLACEHOLDER) {
            // Lines without `\|` can still carry a literal placeholder, which Ruby's last
            // `gsub!` turns into `\|`.
            Some(convert_escaped_pipes_in_line(line)).filter(|converted| converted != line)
        } else {
            None
        };

        match (converted, out.as_mut()) {
            (Some(converted), Some(s)) => s.push_str(&converted),
            (Some(converted), None) => {
                let mut s = String::with_capacity(content.len() + 64);
                s.push_str(&content[..start]);
                s.push_str(&converted);
                out = Some(s);
            }
            (None, Some(s)) => s.push_str(line),
            (None, None) => {}
        }
    }

    match out {
        Some(s) => Cow::Owned(s),
        None => Cow::Borrowed(content),
    }
}

#[inline]
const fn is_ruby_space(byte: u8) -> bool {
    matches!(byte, b' ' | b'\t' | b'\n' | 0x0b | 0x0c | b'\r')
}

#[inline]
fn run_len(bytes: &[u8], from: usize, byte: u8) -> usize {
    bytes[from..].iter().take_while(|&&b| b == byte).count()
}

/// `line[/^\s*((`{3,}|~{3,}))/i, 1]` as `(fence_char, marker_len)`.
fn opening_fence(line: &[u8]) -> Option<(u8, usize)> {
    let i = line.iter().take_while(|&&b| is_ruby_space(b)).count();
    let fence_char = *line.get(i).filter(|&&b| b == b'`' || b == b'~')?;
    let len = run_len(line, i, fence_char);
    (len >= 3).then_some((fence_char, len))
}

/// `line.match?(/^\s*#{fence_char}{#{min_len},}\s*$/)`.
fn is_closing_fence(line: &[u8], fence_char: u8, min_len: usize) -> bool {
    let i = line.iter().take_while(|&&b| is_ruby_space(b)).count();
    let len = run_len(line, i, fence_char);
    len >= min_len && line[i + len..].iter().all(|&b| is_ruby_space(b))
}

fn convert_escaped_pipes_in_line(line: &str) -> String {
    let bytes = line.as_bytes();

    // Pass 1: protect `\|` inside inline code spans with the placeholder.
    let mut protected = String::with_capacity(line.len() + 32);
    if bytes.contains(&b'`') {
        // `tick_runs[i]` = number of consecutive backticks starting at `i`.
        let mut tick_runs = vec![0usize; bytes.len() + 1];
        for i in (0..bytes.len()).rev() {
            if bytes[i] == b'`' {
                tick_runs[i] = tick_runs[i + 1] + 1;
            }
        }

        let mut copied = 0;
        let mut search = 0;
        while let Some(start) = find_byte(bytes, search, b'`') {
            match code_span_end(bytes, &tick_runs, start) {
                Some(end) => {
                    protected.push_str(&line[copied..start]);
                    protected.push_str(&line[start..end].replace("\\|", ESC_PIPE_PLACEHOLDER));
                    copied = end;
                    search = end;
                }
                None => search = start + 1,
            }
        }
        protected.push_str(&line[copied..]);
    } else {
        protected.push_str(line);
    }

    // Pass 2: `gsub!(/(?<!\\)\\\|/, "&#124;")`.
    let protected_bytes = protected.as_bytes();
    let mut entities = String::with_capacity(protected.len() + 16);
    let mut copied = 0;
    let mut i = 0;
    while i + 1 < protected_bytes.len() {
        if protected_bytes[i] == b'\\'
            && protected_bytes[i + 1] == b'|'
            && (i == 0 || protected_bytes[i - 1] != b'\\')
        {
            entities.push_str(&protected[copied..i]);
            entities.push_str("&#124;");
            i += 2;
            copied = i;
        } else {
            i += 1;
        }
    }
    entities.push_str(&protected[copied..]);

    // Pass 3: `gsub!(placeholder) { '\|' }`.
    if entities.contains(ESC_PIPE_PLACEHOLDER) {
        entities.replace(ESC_PIPE_PLACEHOLDER, "\\|")
    } else {
        entities
    }
}

/// End of the Onigmo match of `/(`+)([^`\n]*?(?:`(?!\1)[^`\n]*?)*)\1/` anchored at `start`.
///
/// The backreference group backtracks from the full backtick run down to a single one; for
/// each length the body walks forward, stopping at the first backtick followed by a full
/// closing run, and otherwise falls back to the right-most backtick that starts one.
fn code_span_end(bytes: &[u8], tick_runs: &[usize], start: usize) -> Option<usize> {
    let run = tick_runs[start];
    (1..=run).rev().find_map(|ticks| {
        let mut fallback = None;
        let mut i = start + ticks;
        while i < bytes.len() && bytes[i] != b'\n' {
            if bytes[i] == b'`' {
                if tick_runs[i + 1] >= ticks {
                    return Some(i + ticks);
                }
                if tick_runs[i] >= ticks {
                    fallback = Some(i + ticks);
                }
            }
            i += 1;
        }
        fallback
    })
}

/// Mirrors `MarkdownProcessor::Parser#convert_code_tags_to_triple_backticks`:
///
/// ```ruby
/// return content unless /^<code>$/.match?(content)
/// return content if content.include?("<code>") && content.include?("<pre>")
///
/// content.gsub(%r{^</?code>$}, "\n```\n")
/// ```
///
/// Ruby's `^`/`$` only split on `\n` (a `\r` stays part of the line), so both regexes match
/// whole `\n`-delimited lines and their matches can never overlap.
///
/// Returns `Cow::Borrowed` when nothing changes, so callers can hand back the input itself.
pub fn convert_code_tags_to_triple_backticks(content: &str) -> Cow<'_, str> {
    if !has_code_tag_line(content) || content.contains("<pre>") {
        return Cow::Borrowed(content);
    }

    let mut out = String::with_capacity(content.len() + 64);
    for (i, line) in content.split('\n').enumerate() {
        if i > 0 {
            out.push('\n');
        }
        if line == "<code>" || line == "</code>" {
            out.push_str("\n```\n");
        } else {
            out.push_str(line);
        }
    }
    Cow::Owned(out)
}

/// `/^<code>$/.match?(content)`. The `contains` prefilter (SIMD-accelerated in std, unlike
/// `match_indices`) rejects bodies without any `<code>` tag cheaply; the line walk then skips
/// inline `<code>` spans without re-searching for each one.
fn has_code_tag_line(content: &str) -> bool {
    content.contains("<code>") && content.split('\n').any(|line| line == "<code>")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn code_tags_without_a_bare_code_line_are_borrowed() {
        for input in [
            "",
            "</code>",
            "<code></code>",
            "a<code>\n</code>",
            "x\n<code>\r\n</code>\n",
            "<code>\r</code>",
            "inline <code>x</code> only",
        ] {
            assert!(matches!(
                convert_code_tags_to_triple_backticks(input),
                Cow::Borrowed(_)
            ));
        }
    }

    #[test]
    fn code_tags_next_to_a_pre_tag_are_borrowed() {
        for input in [
            "<code>\n<pre>",
            "<pre>\n<code>\n code \n</code>\n</pre>",
            "<code>\nhi\n</code>\n</code>x\n<pre>z",
        ] {
            assert!(matches!(
                convert_code_tags_to_triple_backticks(input),
                Cow::Borrowed(_)
            ));
        }
    }

    #[test]
    fn bare_code_tag_lines_become_triple_backticks() {
        let cases = [
            ("<code>", "\n```\n"),
            ("<code>\n</code>", "\n```\n\n\n```\n"),
            ("\n<code>\n\n</code>\n", "\n\n```\n\n\n\n```\n\n"),
            ("\n</code>\n<code>\n", "\n\n```\n\n\n```\n\n"),
            ("é\n<code>\n日本\n</code>", "é\n\n```\n\n日本\n\n```\n"),
            (
                "<code>\n</CODE>\n<code >\n<//code>\n</code>",
                "\n```\n\n</CODE>\n<code >\n<//code>\n\n```\n",
            ),
            (
                "<code>\r\n<code>\n</code>\r\n",
                "<code>\r\n\n```\n\n</code>\r\n",
            ),
        ];
        for (input, expected) in cases {
            assert_eq!(convert_code_tags_to_triple_backticks(input), expected);
        }
    }

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

    fn escape(input: &str) -> String {
        escape_liquid_tags_in_codeblock(input).into_owned()
    }

    #[test]
    fn borrows_input_without_code() {
        for input in [
            "",
            "plain text",
            "a ` b",
            "~~ x ~~",
            "{% raw %} outside",
            "日本 🚀\r\n",
        ] {
            assert!(
                matches!(escape_liquid_tags_in_codeblock(input), Cow::Borrowed(s) if s == input),
                "{input:?}"
            );
        }
    }

    #[test]
    fn wraps_fenced_blocks_with_their_leading_whitespace() {
        assert_eq!(
            escape("a\n```js\n{{ x }}\n```\nb"),
            "a\n{% raw %}\n\n```js\n{{ x }}\n```\n{% endraw %}\n\nb"
        );
        assert_eq!(escape("~~~\nx\n~~~"), "{% raw %}~~~\nx\n~~~{% endraw %}");
        assert_eq!(
            escape("\u{a0}\u{3000}```x```"),
            "\n{% raw %}\n\u{a0}\u{3000}```x```\n{% endraw %}\n"
        );
        // U+200B is not White_Space, so it stays outside the match.
        assert_eq!(
            escape("\u{200b}```x```"),
            "\u{200b}\n{% raw %}\n```x```\n{% endraw %}\n"
        );
    }

    #[test]
    fn mirrors_fence_backtracking() {
        let cases = [
            ("````", "\n{% raw %}\n```\n{% endraw %}\n`"),
            ("`````", "\n{% raw %}\n`````\n{% endraw %}\n"),
            ("``````", "\n{% raw %}\n``````\n{% endraw %}\n"),
            ("````a```", "\n{% raw %}\n````a```\n{% endraw %}\n"),
            ("~~~~a~~~", "{% raw %}~~~~a~~~{% endraw %}"),
            ("~~~a", "~~~a"),
            ("  ```a", "  \n{% raw %}\n```\n{% endraw %}\na"),
            (
                "`a```b`",
                "{% raw %}`a`{% endraw %}{% raw %}``b`{% endraw %}",
            ),
            ("``a`", "{% raw %}``a`{% endraw %}"),
            ("``", "``"),
            ("```", "\n{% raw %}\n```\n{% endraw %}\n"),
            ("`\n`", "{% raw %}`\n`{% endraw %}"),
            ("`é`", "{% raw %}`é`{% endraw %}"),
        ];
        for (input, expected) in cases {
            assert_eq!(escape(input), expected, "{input:?}");
        }
    }

    #[test]
    fn neutralizes_raw_tags_inside_code_only() {
        assert_eq!(
            escape("{% raw %}`{% raw %}x{% endraw %}`"),
            "{% raw %}{% raw %}`{----% raw %----}x{----% endraw %----}`{% endraw %}"
        );
    }

    #[test]
    fn stays_linear_on_long_whitespace_runs_and_unclosed_fences() {
        let spaces = " ".repeat(200_000);
        assert_eq!(
            escape(&format!("{spaces}```x")),
            format!("{spaces}\n{{% raw %}}\n```\n{{% endraw %}}\nx")
        );
        let tail = " \u{3000}~~ x\t".repeat(50_000);
        assert_eq!(
            escape(&format!("~~~~{tail}")),
            format!("~~~~{tail}"),
            "an unclosed tilde fence never matches"
        );
    }

    fn pipes(input: &str) -> String {
        convert_escaped_pipes_outside_codeblocks(input).into_owned()
    }

    #[test]
    fn borrows_input_without_convertible_pipes() {
        for input in [
            "",
            "a | b",
            "```\na\\|b\n```",
            "`a\\|b`",
            "leave \\\\|alone",
        ] {
            assert!(matches!(
                convert_escaped_pipes_outside_codeblocks(input),
                Cow::Borrowed(s) if s == input
            ));
        }
        assert!(matches!(
            convert_escaped_pipes_outside_codeblocks("a\\|b"),
            Cow::Owned(_)
        ));
    }

    #[test]
    fn mirrors_ruby_escaped_pipe_conversion() {
        // Expectations generated from the legacy Ruby implementation.
        for (input, expected) in [
            ("a\\|b", "a&#124;b"),
            ("| a\\|b | c\\|d |\n", "| a&#124;b | c&#124;d |\n"),
            ("leave \\\\|alone", "leave \\\\|alone"),
            ("`a\\|b` c\\|d", "`a\\|b` c&#124;d"),
            ("`` a\\|b `` x\\|y", "`` a\\|b `` x&#124;y"),
            ("``a`\\|", "``a`&#124;"),
            ("`a``b\\|`", "`a``b\\|`"),
            ("``a`b\\|``", "``a`b\\|``"),
            ("```\na\\|b\n```\nc\\|d", "```\na\\|b\n```\nc&#124;d"),
            ("~~~\na\\|b\n~~~~\nc\\|d", "~~~\na\\|b\n~~~~\nc&#124;d"),
            (
                "````\n```\na\\|b\n````\n\\|",
                "````\n```\na\\|b\n````\n&#124;",
            ),
            (
                "  ```js\n\\|\n  ```  \r\n\\|",
                "  ```js\n\\|\n  ```  \r\n&#124;",
            ),
            ("~~~\n\\|\n```\n\\|", "~~~\n\\|\n```\n\\|"),
            ("\\|\r\n`\\|`\r\n", "&#124;\r\n`\\|`\r\n"),
            ("é\\|🚀 `日本\\|`", "é&#124;🚀 `日本\\|`"),
            ("\u{0}FOREM_ESC_PIPE\u{0} \\|", "\\| &#124;"),
            ("\\|\\|\\\\|", "&#124;&#124;\\\\|"),
            ("`\\|\n\\|`", "`&#124;\n&#124;`"),
        ] {
            assert_eq!(pipes(input), expected, "{input:?}");
        }
    }
}
