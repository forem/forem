/// Opening tag of a quickie (status post) title paragraph.
const PARAGRAPH_OPEN: &str = "<p class=\"quickie-paragraph\">";
const PARAGRAPH_CLOSE: &str = "</p>";
const PARAGRAPH_BREAK: &str = "</p><p class=\"quickie-paragraph\">";
const EMPTY_PARAGRAPH: &str = "<p class=\"quickie-paragraph\"></p>";
const READ_MORE: &str = "<span class=\"quickie-read-more\">...read more</span>";
const URL_SPAN_OPEN: &str = "<span style=\"text-decoration: underline;\">";
const URL_SPAN_CLOSE: &str = "</span>";
const FEED_LINES: usize = 6;
const URL_DISPLAY_CHARS: usize = 25;
const URL_TRUNCATED_CHARS: usize = 22;

/// Renders a status post title as HTML, matching `Article#legacy_title_finalized` (and, with
/// `truncate_for_feed`, `Article#legacy_truncate_title_for_feed`): its sequence of `gsub!`
/// passes for paragraphs and `<br>`s, then underlined URLs shortened to 25 characters.
///
/// ### Behavioral Equivalence Notes
/// - Ruby's `\s` is ASCII-only (` \t\n\v\f\r`); NBSP and other Unicode spaces are kept.
/// - `/\n\s*\n/` is greedy, so it runs from a newline to the *last* newline of the
///   whitespace run that follows it.
/// - Every `gsub!` is a separate left-to-right pass, so text produced by one pass (or typed
///   by the author) is only matched by the passes after it, exactly like Ruby.
/// - `split("\n")` drops trailing empty lines before the first six lines are taken.
/// - URL lengths count characters, not bytes; every delimiter is ASCII, so URLs always
///   end on a UTF-8 boundary.
pub fn quickie_title_html(title: &str, truncate_for_feed: bool) -> String {
    let source = if truncate_for_feed {
        feed_lines(title)
    } else {
        title.to_owned()
    };

    let mut html = replace_paragraph_breaks(&source).replace('\n', "<br>");
    if html.contains("<br>") || html.contains("</p><p") {
        let wrapped = format!("{PARAGRAPH_OPEN}{html}{PARAGRAPH_CLOSE}");
        let without_empty = wrapped.replace(EMPTY_PARAGRAPH, "");
        let without_blank = remove_blank_paragraphs(&without_empty);
        let left_trimmed = trim_paragraph_starts(&without_blank);
        html = trim_paragraph_ends(&left_trimmed);
    }
    if truncate_for_feed {
        html.push_str(READ_MORE);
    }
    underline_urls(&html)
}

/// Ruby's `\s`: space, `\t`, `\n`, `\v`, `\f`, and `\r`.
fn is_space(byte: u8) -> bool {
    matches!(byte, b' ' | b'\t' | b'\n' | 0x0b | 0x0c | b'\r')
}

/// `title.split("\n").first(6).join("\n")`.
fn feed_lines(title: &str) -> String {
    let mut lines: Vec<&str> = title.split('\n').collect();
    while lines.last().is_some_and(|line| line.is_empty()) {
        lines.pop();
    }
    lines.truncate(FEED_LINES);
    lines.join("\n")
}

/// `gsub(/\n\s*\n/, PARAGRAPH_BREAK)`.
fn replace_paragraph_breaks(text: &str) -> String {
    let bytes = text.as_bytes();
    let mut out = String::with_capacity(text.len());
    let mut copied = 0;
    let mut i = 0;
    while let Some(offset) = bytes[i..].iter().position(|&b| b == b'\n') {
        let start = i + offset;
        let mut last_newline = None;
        let mut j = start + 1;
        while j < bytes.len() && is_space(bytes[j]) {
            if bytes[j] == b'\n' {
                last_newline = Some(j);
            }
            j += 1;
        }
        match last_newline {
            Some(end) => {
                out.push_str(&text[copied..start]);
                out.push_str(PARAGRAPH_BREAK);
                copied = end + 1;
                i = end + 1;
            }
            // The run after this newline has no other newline, so no match can start
            // inside it either.
            None => i = j,
        }
    }
    out.push_str(&text[copied..]);
    out
}

/// `gsub(%r{<p class="quickie-paragraph">\s*</p>}, "")`.
fn remove_blank_paragraphs(text: &str) -> String {
    let mut out = String::with_capacity(text.len());
    let mut copied = 0;
    let mut search = 0;
    while let Some(offset) = text[search..].find(PARAGRAPH_OPEN) {
        let start = search + offset;
        let after_open = start + PARAGRAPH_OPEN.len();
        let close = after_open + count_spaces(&text.as_bytes()[after_open..]);
        if text[close..].starts_with(PARAGRAPH_CLOSE) {
            out.push_str(&text[copied..start]);
            copied = close + PARAGRAPH_CLOSE.len();
            search = copied;
        } else {
            // The opening tag has a single `<`, so occurrences never overlap.
            search = after_open;
        }
    }
    out.push_str(&text[copied..]);
    out
}

/// `gsub(/<p class="quickie-paragraph">\s+/, PARAGRAPH_OPEN)`.
fn trim_paragraph_starts(text: &str) -> String {
    let mut out = String::with_capacity(text.len());
    let mut copied = 0;
    let mut search = 0;
    while let Some(offset) = text[search..].find(PARAGRAPH_OPEN) {
        let after_open = search + offset + PARAGRAPH_OPEN.len();
        let spaces = count_spaces(&text.as_bytes()[after_open..]);
        if spaces > 0 {
            out.push_str(&text[copied..after_open]);
            copied = after_open + spaces;
        }
        search = after_open + spaces;
    }
    out.push_str(&text[copied..]);
    out
}

/// `gsub(%r{\s+</p>}, "</p>")`: a whitespace run is dropped only when `</p>` follows it.
fn trim_paragraph_ends(text: &str) -> String {
    let bytes = text.as_bytes();
    let mut out = String::with_capacity(text.len());
    let mut copied = 0;
    let mut search = 0;
    while let Some(offset) = text[search..].find(PARAGRAPH_CLOSE) {
        let close = search + offset;
        let mut run_start = close;
        // `copied` is never inside a run: it sits right after a `</p>`.
        while run_start > copied && is_space(bytes[run_start - 1]) {
            run_start -= 1;
        }
        if run_start < close {
            out.push_str(&text[copied..run_start]);
            copied = close;
        }
        search = close + PARAGRAPH_CLOSE.len();
    }
    out.push_str(&text[copied..]);
    out
}

fn count_spaces(bytes: &[u8]) -> usize {
    bytes.iter().take_while(|&&b| is_space(b)).count()
}

/// `[^\s<>"{}|\\^`\[\]]`, for one byte of a valid UTF-8 string.
fn is_url_byte(byte: u8) -> bool {
    !is_space(byte)
        && !matches!(
            byte,
            b'<' | b'>' | b'"' | b'{' | b'}' | b'|' | b'\\' | b'^' | b'`' | b'[' | b']'
        )
}

/// Byte length of the `https?://` scheme at the start of `bytes`, if there is one.
fn url_scheme_len(bytes: &[u8]) -> Option<usize> {
    if bytes.starts_with(b"https://") {
        Some(8)
    } else if bytes.starts_with(b"http://") {
        Some(7)
    } else {
        None
    }
}

/// `gsub(%r{https?://[^\s<>"{}|\\^`\[\]]+}) { ... }`.
fn underline_urls(text: &str) -> String {
    if !text.contains("http") {
        return text.to_owned();
    }
    let bytes = text.as_bytes();
    let mut out = String::with_capacity(text.len() + 64);
    let mut copied = 0;
    let mut search = 0;
    while let Some(offset) = text[search..].find("http") {
        let start = search + offset;
        let Some(scheme_len) = url_scheme_len(&bytes[start..]) else {
            search = start + 1;
            continue;
        };
        let rest = start + scheme_len;
        let end = rest
            + bytes[rest..]
                .iter()
                .take_while(|&&b| is_url_byte(b))
                .count();
        if end == rest {
            search = start + 1;
            continue;
        }
        out.push_str(&text[copied..start]);
        push_display_url(&mut out, &text[rest..end]);
        copied = end;
        search = end;
    }
    out.push_str(&text[copied..]);
    out
}

fn push_display_url(out: &mut String, without_scheme: &str) {
    let without_www = without_scheme
        .strip_prefix("www.")
        .unwrap_or(without_scheme);
    let clean = without_www.strip_suffix('/').unwrap_or(without_www);
    out.push_str(URL_SPAN_OPEN);
    if clean.chars().count() > URL_DISPLAY_CHARS {
        let cut = clean
            .char_indices()
            .nth(URL_TRUNCATED_CHARS)
            .map_or(clean.len(), |(index, _)| index);
        out.push_str(&clean[..cut]);
        out.push_str("...");
    } else {
        out.push_str(clean);
    }
    out.push_str(URL_SPAN_CLOSE);
}

#[cfg(test)]
mod tests {
    use super::*;

    // Expectations are the outputs of the legacy Ruby methods.
    #[test]
    fn matches_the_legacy_ruby_output() {
        let cases = [
            ("", false, ""),
            ("日本語 🎉 title", false, "日本語 🎉 title"),
            ("a\nb", false, "<p class=\"quickie-paragraph\">a<br>b</p>"),
            ("a\n \t\n \n b", false, "<p class=\"quickie-paragraph\">a</p><p class=\"quickie-paragraph\">b</p>"),
            ("a\r\n\r\nb", false, "<p class=\"quickie-paragraph\">a</p><p class=\"quickie-paragraph\">b</p>"),
            ("a\r\nb", false, "<p class=\"quickie-paragraph\">a\r<br>b</p>"),
            ("\n\nhi\n\n", false, "<p class=\"quickie-paragraph\">hi</p>"),
            ("  \n  ", false, "<p class=\"quickie-paragraph\"><br></p>"),
            ("a\n\u{a0}\nb", false, "<p class=\"quickie-paragraph\">a<br>\u{a0}<br>b</p>"),
            ("x </p>", false, "x </p>"),
            ("x </p><p y", false, "<p class=\"quickie-paragraph\">x</p><p y</p>"),
            ("see https://www.example.com/ now", false, "see <span style=\"text-decoration: underline;\">example.com</span> now"),
            ("http://abcdefghijklmnopqrstuvwxyz.com", false, "<span style=\"text-decoration: underline;\">abcdefghijklmnopqrstuv...</span>"),
            ("https://例え.テスト/日本語のパスはとても長いのでここで切り詰められます", false, "<span style=\"text-decoration: underline;\">例え.テスト/日本語のパスはとても長いのでこ...</span>"),
            ("http:// x", false, "http:// x"),
            ("hhttps://a", false, "h<span style=\"text-decoration: underline;\">a</span>"),
            ("http:///", false, "<span style=\"text-decoration: underline;\"></span>"),
            ("https://a.dev\nnext", false, "<p class=\"quickie-paragraph\"><span style=\"text-decoration: underline;\">a.dev</span><br>next</p>"),
            ("1\n2\n3\n4\n5\n6\n7\n8\n9", true, "<p class=\"quickie-paragraph\">1<br>2<br>3<br>4<br>5<br>6</p><span class=\"quickie-read-more\">...read more</span>"),
            ("a\n\n\n\n\n\n\n\n\n", true, "a<span class=\"quickie-read-more\">...read more</span>"),
        ];
        for (title, truncate_for_feed, expected) in cases {
            assert_eq!(
                quickie_title_html(title, truncate_for_feed),
                expected,
                "{title:?}"
            );
        }
    }
}
