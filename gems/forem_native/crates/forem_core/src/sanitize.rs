//! HTML5 full sanitization matching `ActionView::Base.full_sanitizer.sanitize`
//! (`Rails::HTML5::FullSanitizer`: `Loofah.html5_fragment` + `Rails::HTML::TextOnlyScrubber` +
//! `fragment.to_html(encoding: "UTF-8")`).
//!
//! `TextOnlyScrubber` removes every non-text node bottom-up while hoisting its children in
//! document order, and `to_html(encoding: "UTF-8")` serializes the remaining text nodes with
//! `&`, `<`, `>`, and U+00A0 (`&nbsp;`) escaped.

/// Windows-1252 replacements for numeric character references in `0x80..=0x9F`
/// (WHATWG HTML5 §13.2.5.80 Numeric character reference end state).
const C1_REPLACEMENTS: [char; 32] = [
    '\u{20AC}', '\u{0081}', '\u{201A}', '\u{0192}', '\u{201E}', '\u{2026}', '\u{2020}', '\u{2021}',
    '\u{02C6}', '\u{2030}', '\u{0160}', '\u{2039}', '\u{0152}', '\u{008D}', '\u{017D}', '\u{008F}',
    '\u{0090}', '\u{2018}', '\u{2019}', '\u{201C}', '\u{201D}', '\u{2022}', '\u{2013}', '\u{2014}',
    '\u{02DC}', '\u{2122}', '\u{0161}', '\u{203A}', '\u{0153}', '\u{009D}', '\u{017E}', '\u{0178}',
];

/// The 106 WHATWG HTML5 legacy character reference names that may match without a trailing `;`.
const LEGACY_ENTITY_NAMES: [&str; 106] = [
    "AElig", "AMP", "Aacute", "Acirc", "Agrave", "Aring", "Atilde", "Auml", "COPY", "Ccedil",
    "ETH", "Eacute", "Ecirc", "Egrave", "Euml", "GT", "Iacute", "Icirc", "Igrave", "Iuml", "LT",
    "Ntilde", "Oacute", "Ocirc", "Ograve", "Oslash", "Otilde", "Ouml", "QUOT", "REG", "THORN",
    "Uacute", "Ucirc", "Ugrave", "Uuml", "Yacute", "aacute", "acirc", "acute", "aelig", "agrave",
    "amp", "aring", "atilde", "auml", "brvbar", "ccedil", "cedil", "cent", "copy", "curren", "deg",
    "divide", "eacute", "ecirc", "egrave", "eth", "euml", "frac12", "frac14", "frac34", "gt",
    "iacute", "icirc", "iexcl", "igrave", "iquest", "iuml", "laquo", "lt", "macr", "micro",
    "middot", "nbsp", "not", "ntilde", "oacute", "ocirc", "ograve", "ordf", "ordm", "oslash",
    "otilde", "ouml", "para", "plusmn", "pound", "quot", "raquo", "reg", "sect", "shy", "sup1",
    "sup2", "sup3", "szlig", "thorn", "times", "uacute", "ucirc", "ugrave", "uml", "uuml",
    "yacute", "yen", "yuml",
];

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum SectionKind {
    Thead,
    Tbody,
    Tfoot,
}

impl SectionKind {
    fn from_tag(name: &[u8]) -> Option<Self> {
        if name.eq_ignore_ascii_case(b"thead") {
            Some(Self::Thead)
        } else if name.eq_ignore_ascii_case(b"tbody") {
            Some(Self::Tbody)
        } else if name.eq_ignore_ascii_case(b"tfoot") {
            Some(Self::Tfoot)
        } else {
            None
        }
    }
}

/// Tracks the exact HTML5 table insertion state so any malformed table markup that could
/// implicitly close a cell/row/section or trigger HTML5 foster-parenting is declined (`None`).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum TableState {
    NotInTable,
    InTable,
    InCaption,
    InColgroup,
    InSection(SectionKind),
    InRow(Option<SectionKind>),
    InTd(Option<SectionKind>),
    InTh(Option<SectionKind>),
}

impl TableState {
    fn is_outside_cell(self) -> bool {
        matches!(
            self,
            Self::InTable | Self::InColgroup | Self::InSection(_) | Self::InRow(_)
        )
    }
}

/// Strips all HTML tags, comments, and doctypes while decoding HTML character references and
/// re-serializing text nodes (`&` -> `&amp;`, `<` -> `&lt;`, `>` -> `&gt;`, U+00A0 -> `&nbsp;`,
/// `\r\n`/`\r` -> `\n`), matching `ActionView::Base.full_sanitizer.sanitize`.
///
/// Returns `None` when the input requires the full HTML5 tree builder or entity table (such as
/// NUL bytes, leading BOM, foster-parented or malformed `<table>` markup, foreign-content breakout
/// inside `<svg>`, unclosed or malformed tags/comments, or uncommon named character references)
/// so the caller can fall back to `ActionView::Base.full_sanitizer.sanitize`.
pub fn full_sanitize(html: &str) -> Option<String> {
    if html.is_empty() {
        return Some(String::new());
    }
    let bytes = html.as_bytes();
    if bytes.contains(&0) || html.starts_with('\u{FEFF}') {
        return None;
    }
    if !bytes
        .iter()
        .any(|&b| matches!(b, b'<' | b'>' | b'&' | b'\r' | 0xC2))
    {
        return Some(html.to_owned());
    }

    let mut out = String::with_capacity(html.len());
    let mut table_state = TableState::NotInTable;
    let mut svg_depth = 0usize;
    let mut i = 0;

    while i < bytes.len() {
        let b = bytes[i];
        if b == b'<' {
            let Some(&next) = bytes.get(i + 1) else {
                if table_state.is_outside_cell() {
                    return None;
                }
                out.push_str("&lt;");
                i += 1;
                continue;
            };

            if next == b'!' {
                i = skip_markup_declaration(bytes, i)?;
                continue;
            }
            if next == b'?' {
                return None;
            }
            if next == b'/' {
                let (name, tag_end) = parse_end_tag(bytes, i)?;
                update_end_tag_state(name, &mut table_state, &mut svg_depth)?;
                i = tag_end;
                continue;
            }
            if next.is_ascii_alphabetic() {
                let (name, tag_end, self_closing) = parse_start_tag(bytes, i)?;
                if is_declined_tag(name) {
                    return None;
                }

                if svg_depth > 0 {
                    if name.eq_ignore_ascii_case(b"svg") {
                        if !self_closing {
                            svg_depth += 1;
                        }
                        i = tag_end;
                        continue;
                    }
                    if name.eq_ignore_ascii_case(b"title") {
                        if self_closing {
                            return None;
                        }
                        let (content_end, close_end) = find_closing_tag(bytes, tag_end, name)?;
                        if bytes[tag_end..content_end].contains(&b'<') {
                            return None;
                        }
                        push_rcdata(&mut out, &html[tag_end..content_end])?;
                        i = close_end;
                        continue;
                    }
                    if !is_svg_child_tag(name) {
                        return None;
                    }
                    i = tag_end;
                    continue;
                }

                if is_any_table_tag(name) {
                    update_start_tag_table_state(name, self_closing, &mut table_state)?;
                    i = tag_end;
                    continue;
                }
                if table_state.is_outside_cell() {
                    return None;
                }

                if name.eq_ignore_ascii_case(b"svg") {
                    if !self_closing {
                        svg_depth += 1;
                    }
                    i = tag_end;
                    continue;
                }
                if name.eq_ignore_ascii_case(b"pre") {
                    i = skip_leading_newline(bytes, tag_end)?;
                    continue;
                }
                if is_rawtext_or_script_tag(name) {
                    if self_closing {
                        return None;
                    }
                    let (content_end, close_end) = find_closing_tag(bytes, tag_end, name)?;
                    let inner = &html[tag_end..content_end];
                    if name.eq_ignore_ascii_case(b"script") && has_script_escape_sequence(inner) {
                        return None;
                    }
                    push_rawtext(&mut out, inner);
                    i = close_end;
                    continue;
                }
                if is_rcdata_tag(name) {
                    if self_closing {
                        return None;
                    }
                    let is_textarea = name.eq_ignore_ascii_case(b"textarea");
                    let (content_end, close_end) = find_closing_tag(bytes, tag_end, name)?;
                    let inner_start = if is_textarea {
                        skip_leading_newline(&bytes[..content_end], tag_end)?
                    } else {
                        if bytes[tag_end..content_end].contains(&b'<') {
                            return None;
                        }
                        tag_end
                    };
                    push_rcdata(&mut out, &html[inner_start..content_end])?;
                    i = close_end;
                    continue;
                }
                i = tag_end;
                continue;
            }

            // `<` followed by a non-tag character (e.g. `a < b` or `x < 10`) is literal text.
            if table_state.is_outside_cell() {
                return None;
            }
            out.push_str("&lt;");
            i += 1;
            continue;
        }

        if table_state.is_outside_cell() && !is_html_space(b) {
            return None;
        }

        match b {
            b'>' => {
                out.push_str("&gt;");
                i += 1;
            }
            b'\r' => {
                out.push('\n');
                i += if bytes.get(i + 1) == Some(&b'\n') {
                    2
                } else {
                    1
                };
            }
            b'&' => {
                let consumed = push_entity_or_amp(&mut out, &html[i..])?;
                i += consumed;
            }
            0xC2 if bytes.get(i + 1) == Some(&0xA0) => {
                out.push_str("&nbsp;");
                i += 2;
            }
            _ => {
                let start = i;
                i += 1;
                if table_state.is_outside_cell() {
                    while i < bytes.len() && is_html_space(bytes[i]) && bytes[i] != b'\r' {
                        i += 1;
                    }
                } else {
                    while i < bytes.len() && !matches!(bytes[i], b'<' | b'>' | b'&' | b'\r' | 0xC2)
                    {
                        i += 1;
                    }
                }
                out.push_str(&html[start..i]);
            }
        }
    }

    if table_state != TableState::NotInTable || svg_depth != 0 {
        return None;
    }

    Some(out)
}

fn is_html_space(byte: u8) -> bool {
    matches!(byte, b' ' | b'\t' | b'\n' | b'\r' | 0x0C)
}

fn is_tag_name_byte(byte: u8) -> bool {
    byte.is_ascii_alphanumeric() || byte == b'-' || byte == b':'
}

fn is_declined_tag(name: &[u8]) -> bool {
    [
        &b"xmp"[..],
        b"noembed",
        b"noframes",
        b"plaintext",
        b"listing",
        b"select",
        b"math",
        b"template",
        b"noscript",
        b"frameset",
        b"applet",
        b"marquee",
        b"object",
    ]
    .iter()
    .any(|tag| name.eq_ignore_ascii_case(tag))
}

/// Pure SVG drawing/container elements that never trigger HTML5 foreign-content breakout.
fn is_svg_child_tag(name: &[u8]) -> bool {
    [
        &b"path"[..],
        b"g",
        b"circle",
        b"rect",
        b"line",
        b"polyline",
        b"polygon",
        b"ellipse",
        b"text",
        b"tspan",
        b"defs",
        b"clippath",
        b"lineargradient",
        b"radialgradient",
        b"stop",
        b"use",
        b"symbol",
        b"mask",
        b"pattern",
        b"filter",
    ]
    .iter()
    .any(|tag| name.eq_ignore_ascii_case(tag))
}

fn is_any_table_tag(name: &[u8]) -> bool {
    [
        &b"table"[..],
        b"thead",
        b"tbody",
        b"tfoot",
        b"tr",
        b"td",
        b"th",
        b"caption",
        b"colgroup",
        b"col",
    ]
    .iter()
    .any(|tag| name.eq_ignore_ascii_case(tag))
}

fn is_rawtext_or_script_tag(name: &[u8]) -> bool {
    name.eq_ignore_ascii_case(b"style")
        || name.eq_ignore_ascii_case(b"script")
        || name.eq_ignore_ascii_case(b"iframe")
}

fn is_rcdata_tag(name: &[u8]) -> bool {
    name.eq_ignore_ascii_case(b"textarea") || name.eq_ignore_ascii_case(b"title")
}

fn update_start_tag_table_state(
    name: &[u8],
    self_closing: bool,
    table_state: &mut TableState,
) -> Option<()> {
    if name.eq_ignore_ascii_case(b"col") {
        if *table_state == TableState::InColgroup {
            return Some(());
        }
        return None;
    }
    if self_closing {
        return None;
    }
    if name.eq_ignore_ascii_case(b"table") {
        if *table_state == TableState::NotInTable {
            *table_state = TableState::InTable;
            return Some(());
        }
        return None;
    }
    if name.eq_ignore_ascii_case(b"caption") {
        if *table_state == TableState::InTable {
            *table_state = TableState::InCaption;
            return Some(());
        }
        return None;
    }
    if name.eq_ignore_ascii_case(b"colgroup") {
        if *table_state == TableState::InTable {
            *table_state = TableState::InColgroup;
            return Some(());
        }
        return None;
    }
    if let Some(sec) = SectionKind::from_tag(name) {
        if *table_state == TableState::InTable {
            *table_state = TableState::InSection(sec);
            return Some(());
        }
        return None;
    }
    if name.eq_ignore_ascii_case(b"tr") {
        *table_state = match *table_state {
            TableState::InTable => TableState::InRow(None),
            TableState::InSection(sec) => TableState::InRow(Some(sec)),
            _ => return None,
        };
        return Some(());
    }
    if name.eq_ignore_ascii_case(b"td") {
        if let TableState::InRow(sec) = *table_state {
            *table_state = TableState::InTd(sec);
            return Some(());
        }
        return None;
    }
    if name.eq_ignore_ascii_case(b"th") {
        if let TableState::InRow(sec) = *table_state {
            *table_state = TableState::InTh(sec);
            return Some(());
        }
        return None;
    }
    None
}

fn update_end_tag_state(
    name: &[u8],
    table_state: &mut TableState,
    svg_depth: &mut usize,
) -> Option<()> {
    if is_declined_tag(name) {
        return None;
    }
    if *svg_depth > 0 {
        if name.eq_ignore_ascii_case(b"svg") {
            *svg_depth -= 1;
            return Some(());
        }
        if is_svg_child_tag(name) {
            return Some(());
        }
        return None;
    }
    if name.eq_ignore_ascii_case(b"svg") {
        return None;
    }
    if is_any_table_tag(name) {
        if name.eq_ignore_ascii_case(b"table") {
            if *table_state == TableState::InTable {
                *table_state = TableState::NotInTable;
                return Some(());
            }
            return None;
        }
        if name.eq_ignore_ascii_case(b"caption") {
            if *table_state == TableState::InCaption {
                *table_state = TableState::InTable;
                return Some(());
            }
            return None;
        }
        if name.eq_ignore_ascii_case(b"colgroup") {
            if *table_state == TableState::InColgroup {
                *table_state = TableState::InTable;
                return Some(());
            }
            return None;
        }
        if let Some(sec) = SectionKind::from_tag(name) {
            if *table_state == TableState::InSection(sec) {
                *table_state = TableState::InTable;
                return Some(());
            }
            return None;
        }
        if name.eq_ignore_ascii_case(b"tr") {
            *table_state = match *table_state {
                TableState::InRow(Some(sec)) => TableState::InSection(sec),
                TableState::InRow(None) => TableState::InTable,
                _ => return None,
            };
            return Some(());
        }
        if name.eq_ignore_ascii_case(b"td") {
            if let TableState::InTd(sec) = *table_state {
                *table_state = TableState::InRow(sec);
                return Some(());
            }
            return None;
        }
        if name.eq_ignore_ascii_case(b"th") {
            if let TableState::InTh(sec) = *table_state {
                *table_state = TableState::InRow(sec);
                return Some(());
            }
            return None;
        }
        return None;
    }
    if table_state.is_outside_cell() {
        return None;
    }
    Some(())
}

/// Skips `<!-- ... -->` or `<!DOCTYPE ...>` starting at `start` (`bytes[start..]` starts with `<!`).
fn skip_markup_declaration(bytes: &[u8], start: usize) -> Option<usize> {
    let rest = &bytes[start..];
    if let Some(after_open) = rest.strip_prefix(b"<!--") {
        if after_open.starts_with(b">") || after_open.starts_with(b"->") {
            return None;
        }
        let end = find_subslice(after_open, b"-->")?;
        if find_subslice(&after_open[..end], b"--!>").is_some() {
            return None;
        }
        return Some(start + 4 + end + 3);
    }
    if rest.len() > 9 && rest[2..9].eq_ignore_ascii_case(b"doctype") && is_html_space(rest[9]) {
        let mut i = start + 10;
        while i < bytes.len() {
            match bytes[i] {
                b'>' => return Some(i + 1),
                b'<' | b'"' | b'\'' => return None,
                _ => i += 1,
            }
        }
    }
    None
}

/// Parses `</name>` starting at `start` (`bytes[start..]` starts with `</`).
fn parse_end_tag(bytes: &[u8], start: usize) -> Option<(&[u8], usize)> {
    let name_start = start + 2;
    if !bytes.get(name_start)?.is_ascii_alphabetic() {
        return None;
    }
    let mut i = name_start + 1;
    while i < bytes.len() && is_tag_name_byte(bytes[i]) {
        i += 1;
    }
    let name = &bytes[name_start..i];
    while i < bytes.len() && is_html_space(bytes[i]) {
        i += 1;
    }
    if bytes.get(i) != Some(&b'>') {
        return None;
    }
    Some((name, i + 1))
}

/// Parses `<name ...>` or `<name .../>` starting at `start` (`bytes[start]` is `<`).
fn parse_start_tag(bytes: &[u8], start: usize) -> Option<(&[u8], usize, bool)> {
    let name_start = start + 1;
    let mut i = name_start + 1;
    while i < bytes.len() && is_tag_name_byte(bytes[i]) {
        i += 1;
    }
    let name = &bytes[name_start..i];

    loop {
        if i >= bytes.len() {
            return None;
        }
        if bytes[i] == b'>' {
            return Some((name, i + 1, false));
        }
        if bytes[i..].starts_with(b"/>") {
            return Some((name, i + 2, true));
        }
        if !is_html_space(bytes[i]) {
            return None;
        }
        while i < bytes.len() && is_html_space(bytes[i]) {
            i += 1;
        }
        if i >= bytes.len() {
            return None;
        }
        if bytes[i] == b'>' {
            return Some((name, i + 1, false));
        }
        if bytes[i..].starts_with(b"/>") {
            return Some((name, i + 2, true));
        }

        // Attribute name
        let attr_start = i;
        while i < bytes.len()
            && !is_html_space(bytes[i])
            && !matches!(bytes[i], b'=' | b'>' | b'/' | b'"' | b'\'' | b'<')
        {
            i += 1;
        }
        if i == attr_start {
            return None;
        }

        while i < bytes.len() && is_html_space(bytes[i]) {
            i += 1;
        }
        if bytes.get(i) != Some(&b'=') {
            continue;
        }
        i += 1;
        while i < bytes.len() && is_html_space(bytes[i]) {
            i += 1;
        }
        let quote = *bytes.get(i)?;
        if quote == b'"' || quote == b'\'' {
            i += 1;
            let close = bytes[i..].iter().position(|&b| b == quote)?;
            i += close + 1;
        } else {
            // Unquoted attribute value (WHATWG HTML5 §13.2.5.38): `/` and `=` are normal value characters.
            let val_start = i;
            while i < bytes.len()
                && !is_html_space(bytes[i])
                && !matches!(bytes[i], b'>' | b'"' | b'\'' | b'<' | b'`')
            {
                i += 1;
            }
            if i == val_start {
                return None;
            }
        }
    }
}

/// HTML5 strips a single leading newline immediately after `<pre>` and `<textarea>` start tags.
fn skip_leading_newline(bytes: &[u8], pos: usize) -> Option<usize> {
    if bytes.get(pos..pos + 2) == Some(b"&#") {
        return None;
    }
    if bytes.get(pos..pos + 2) == Some(b"\r\n") {
        Some(pos + 2)
    } else if bytes.get(pos).is_some_and(|&b| b == b'\n' || b == b'\r') {
        Some(pos + 1)
    } else {
        Some(pos)
    }
}

/// Finds the matching `</expected_name>` closing tag in RAWTEXT/RCDATA/Script data mode.
fn find_closing_tag(bytes: &[u8], start: usize, expected_name: &[u8]) -> Option<(usize, usize)> {
    let mut i = start;
    let name_len = expected_name.len();
    while let Some(offset) = find_subslice(&bytes[i..], b"</") {
        let tag_start = i + offset;
        let name_start = tag_start + 2;
        if let Some(candidate) = bytes.get(name_start..name_start + name_len) {
            if candidate.eq_ignore_ascii_case(expected_name) {
                let after_name = name_start + name_len;
                let &delim = bytes.get(after_name)?;
                if delim == b'>' {
                    return Some((tag_start, after_name + 1));
                }
                if is_html_space(delim) {
                    let mut j = after_name + 1;
                    while j < bytes.len() && is_html_space(bytes[j]) {
                        j += 1;
                    }
                    if bytes.get(j) == Some(&b'>') {
                        return Some((tag_start, j + 1));
                    }
                    return None;
                }
                if delim == b'/' {
                    return None;
                }
            }
        }
        i = tag_start + 2;
    }
    None
}

fn has_script_escape_sequence(inner: &str) -> bool {
    let bytes = inner.as_bytes();
    if find_subslice(bytes, b"<!--").is_some() {
        return true;
    }
    let mut i = 0;
    while let Some(offset) = bytes[i..].iter().position(|&b| b == b'<') {
        let pos = i + offset;
        if bytes
            .get(pos + 1..pos + 7)
            .is_some_and(|s| s.eq_ignore_ascii_case(b"script"))
        {
            return true;
        }
        i = pos + 1;
    }
    false
}

/// Serializes RAWTEXT / Script data content as a text node (no entity decoding, only escaping).
fn push_rawtext(out: &mut String, text: &str) {
    let bytes = text.as_bytes();
    let mut i = 0;
    while i < bytes.len() {
        match bytes[i] {
            b'&' => {
                out.push_str("&amp;");
                i += 1;
            }
            b'<' => {
                out.push_str("&lt;");
                i += 1;
            }
            b'>' => {
                out.push_str("&gt;");
                i += 1;
            }
            b'\r' => {
                out.push('\n');
                i += if bytes.get(i + 1) == Some(&b'\n') {
                    2
                } else {
                    1
                };
            }
            0xC2 if bytes.get(i + 1) == Some(&0xA0) => {
                out.push_str("&nbsp;");
                i += 2;
            }
            _ => {
                let start = i;
                i += 1;
                while i < bytes.len() && !matches!(bytes[i], b'&' | b'<' | b'>' | b'\r' | 0xC2) {
                    i += 1;
                }
                out.push_str(&text[start..i]);
            }
        }
    }
}

/// Serializes RCDATA content as a text node (decodes entities, escapes `<`, `>`, `&`, U+00A0).
fn push_rcdata(out: &mut String, text: &str) -> Option<()> {
    let bytes = text.as_bytes();
    let mut i = 0;
    while i < bytes.len() {
        match bytes[i] {
            b'&' => {
                let consumed = push_entity_or_amp(out, &text[i..])?;
                i += consumed;
            }
            b'<' => {
                out.push_str("&lt;");
                i += 1;
            }
            b'>' => {
                out.push_str("&gt;");
                i += 1;
            }
            b'\r' => {
                out.push('\n');
                i += if bytes.get(i + 1) == Some(&b'\n') {
                    2
                } else {
                    1
                };
            }
            0xC2 if bytes.get(i + 1) == Some(&0xA0) => {
                out.push_str("&nbsp;");
                i += 2;
            }
            _ => {
                let start = i;
                i += 1;
                while i < bytes.len() && !matches!(bytes[i], b'&' | b'<' | b'>' | b'\r' | 0xC2) {
                    i += 1;
                }
                out.push_str(&text[start..i]);
            }
        }
    }
    Some(())
}

/// Decodes a character reference starting at `rest` (`rest.starts_with('&')`) or emits `&amp;`.
/// Returns the number of bytes consumed from `rest`.
fn push_entity_or_amp(out: &mut String, rest: &str) -> Option<usize> {
    let bytes = rest.as_bytes();
    let Some(&second) = bytes.get(1) else {
        out.push_str("&amp;");
        return Some(1);
    };

    if second == b'#' {
        return push_numeric_entity(out, bytes);
    }

    if second.is_ascii_alphabetic() {
        let mut end = 2;
        while end < bytes.len() && bytes[end].is_ascii_alphanumeric() {
            end += 1;
        }
        let name = &rest[1..end];
        if bytes.get(end) == Some(&b';') {
            let replacement = named_entity(name)?;
            out.push_str(replacement);
            return Some(end + 1);
        }
        if starts_with_legacy_entity(name) {
            return None;
        }
        out.push_str("&amp;");
        return Some(1);
    }

    out.push_str("&amp;");
    Some(1)
}

fn push_numeric_entity(out: &mut String, bytes: &[u8]) -> Option<usize> {
    let (radix, digits_start) = match bytes.get(2) {
        Some(b'x' | b'X') => (16u32, 3usize),
        _ => (10u32, 2usize),
    };
    let mut end = digits_start;
    let mut code = 0u32;
    while end < bytes.len() {
        let digit = match (radix, bytes[end]) {
            (_, b'0'..=b'9') => u32::from(bytes[end] - b'0'),
            (16, b'a'..=b'f') => u32::from(bytes[end] - b'a' + 10),
            (16, b'A'..=b'F') => u32::from(bytes[end] - b'A' + 10),
            _ => break,
        };
        code = code.saturating_mul(radix).saturating_add(digit);
        end += 1;
    }
    if end == digits_start {
        // `&#` or `&#x` not followed by digits is literal text (`&amp;#...`).
        out.push_str("&amp;");
        return Some(1);
    }
    if bytes.get(end) != Some(&b';') {
        // Semicolon-less numeric character reference: let Nokogiri/Gumbo handle it.
        return None;
    }

    let decoded = if code == 0 || code > 0x10FFFF || (0xD800..=0xDFFF).contains(&code) {
        '\u{FFFD}'
    } else if (0x80..=0x9F).contains(&code) {
        C1_REPLACEMENTS[(code - 0x80) as usize]
    } else {
        char::from_u32(code)?
    };

    match decoded {
        '&' => out.push_str("&amp;"),
        '<' => out.push_str("&lt;"),
        '>' => out.push_str("&gt;"),
        '\u{00A0}' => out.push_str("&nbsp;"),
        c => out.push(c),
    }
    Some(end + 1)
}

fn starts_with_legacy_entity(name: &str) -> bool {
    LEGACY_ENTITY_NAMES
        .iter()
        .any(|legacy| name.starts_with(legacy))
}

#[allow(clippy::too_many_lines)]
fn named_entity(name: &str) -> Option<&'static str> {
    Some(match name {
        "amp" | "AMP" => "&amp;",
        "lt" | "LT" => "&lt;",
        "gt" | "GT" => "&gt;",
        "quot" | "QUOT" => "\"",
        "apos" => "'",
        "nbsp" => "&nbsp;",
        "iexcl" => "¡",
        "cent" => "¢",
        "pound" => "£",
        "curren" => "¤",
        "yen" => "¥",
        "brvbar" => "¦",
        "sect" => "§",
        "uml" => "¨",
        "copy" | "COPY" => "©",
        "ordf" => "ª",
        "laquo" => "«",
        "not" => "¬",
        "shy" => "\u{00AD}",
        "reg" | "REG" => "®",
        "macr" => "¯",
        "deg" => "°",
        "plusmn" => "±",
        "sup2" => "²",
        "sup3" => "³",
        "acute" => "´",
        "micro" => "µ",
        "para" => "¶",
        "middot" => "·",
        "cedil" => "¸",
        "sup1" => "¹",
        "ordm" => "º",
        "raquo" => "»",
        "frac14" => "¼",
        "frac12" => "½",
        "frac34" => "¾",
        "iquest" => "¿",
        "Agrave" => "À",
        "Aacute" => "Á",
        "Acirc" => "Â",
        "Atilde" => "Ã",
        "Auml" => "Ä",
        "Aring" => "Å",
        "AElig" => "Æ",
        "Ccedil" => "Ç",
        "Egrave" => "È",
        "Eacute" => "É",
        "Ecirc" => "Ê",
        "Euml" => "Ë",
        "Igrave" => "Ì",
        "Iacute" => "Í",
        "Icirc" => "Î",
        "Iuml" => "Ï",
        "ETH" => "Ð",
        "Ntilde" => "Ñ",
        "Ograve" => "Ò",
        "Oacute" => "Ó",
        "Ocirc" => "Ô",
        "Otilde" => "Õ",
        "Ouml" => "Ö",
        "times" => "×",
        "Oslash" => "Ø",
        "Ugrave" => "Ù",
        "Uacute" => "Ú",
        "Ucirc" => "Û",
        "Uuml" => "Ü",
        "Yacute" => "Ý",
        "THORN" => "Þ",
        "szlig" => "ß",
        "agrave" => "à",
        "aacute" => "á",
        "acirc" => "â",
        "atilde" => "ã",
        "auml" => "ä",
        "aring" => "å",
        "aelig" => "æ",
        "ccedil" => "ç",
        "egrave" => "è",
        "eacute" => "é",
        "ecirc" => "ê",
        "euml" => "ë",
        "igrave" => "ì",
        "iacute" => "í",
        "icirc" => "î",
        "iuml" => "ï",
        "eth" => "ð",
        "ntilde" => "ñ",
        "ograve" => "ò",
        "oacute" => "ó",
        "ocirc" => "ô",
        "otilde" => "õ",
        "ouml" => "ö",
        "divide" => "÷",
        "oslash" => "ø",
        "ugrave" => "ù",
        "uacute" => "ú",
        "ucirc" => "û",
        "uuml" => "ü",
        "yacute" => "ý",
        "thorn" => "þ",
        "yuml" => "ÿ",
        "fnof" => "ƒ",
        "ndash" => "–",
        "mdash" => "—",
        "lsquo" => "‘",
        "rsquo" => "’",
        "sbquo" => "‚",
        "ldquo" => "“",
        "rdquo" => "”",
        "bdquo" => "„",
        "dagger" => "†",
        "Dagger" => "‡",
        "bull" => "•",
        "hellip" => "…",
        "permil" => "‰",
        "prime" => "′",
        "Prime" => "″",
        "lsaquo" => "‹",
        "rsaquo" => "›",
        "oline" => "‾",
        "frasl" => "⁄",
        "euro" => "€",
        "trade" => "™",
        "larr" => "←",
        "uarr" => "↑",
        "rarr" => "→",
        "darr" => "↓",
        "harr" => "↔",
        "minus" => "−",
        "lowast" => "∗",
        "radic" => "√",
        "infin" => "∞",
        "asymp" => "≈",
        "ne" => "≠",
        "equiv" => "≡",
        "le" => "≤",
        "ge" => "≥",
        "ensp" => "\u{2002}",
        "emsp" => "\u{2003}",
        "thinsp" => "\u{2009}",
        "zwnj" => "\u{200C}",
        "zwj" => "\u{200D}",
        "lrm" => "\u{200E}",
        "rlm" => "\u{200F}",
        _ => return None,
    })
}

fn find_subslice(haystack: &[u8], needle: &[u8]) -> Option<usize> {
    haystack
        .windows(needle.len())
        .position(|window| window == needle)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn handles_empty_and_plain_text() {
        assert_eq!(full_sanitize("").as_deref(), Some(""));
        assert_eq!(full_sanitize("hello world").as_deref(), Some("hello world"));
        assert_eq!(
            full_sanitize("日本語と絵文字 🚀").as_deref(),
            Some("日本語と絵文字 🚀")
        );
    }

    #[test]
    fn strips_tags_comments_and_doctypes() {
        assert_eq!(
            full_sanitize("<p>Hello <b>world</b>!</p>").as_deref(),
            Some("Hello world!")
        );
        assert_eq!(
            full_sanitize("<div class=\"a\" data-x=\"1 > 2\" data-y='3 > 4'>text</div>").as_deref(),
            Some("text")
        );
        assert_eq!(
            full_sanitize("<a href=https://dev.to/path/>unquoted slash</a>").as_deref(),
            Some("unquoted slash")
        );
        assert_eq!(
            full_sanitize("<!DOCTYPE html><!-- comment --><p>doc</p>").as_deref(),
            Some("doc")
        );
    }

    #[test]
    fn decodes_entities_and_escapes_output() {
        assert_eq!(
            full_sanitize("Tom & Jerry &amp; &lt; &gt; &quot; &#39; &#x27; &apos; &nbsp; &#160;")
                .as_deref(),
            Some("Tom &amp; Jerry &amp; &lt; &gt; \" ' ' ' &nbsp; &nbsp;")
        );
        assert_eq!(
            full_sanitize("&#x25B8; &middot; &copy; &mdash; &ndash; &hellip; &rarr;").as_deref(),
            Some("▸ · © — – … →")
        );
        assert_eq!(
            full_sanitize("a < b && c > d\u{00A0}e\r\nf\rg").as_deref(),
            Some("a &lt; b &amp;&amp; c &gt; d&nbsp;e\nf\ng")
        );
        assert_eq!(
            full_sanitize("https://dev.to?a=1&b=2&utm_source=x").as_deref(),
            Some("https://dev.to?a=1&amp;b=2&amp;utm_source=x")
        );
    }

    #[test]
    fn handles_pre_svg_table_style_script_iframe_and_rcdata() {
        assert_eq!(
            full_sanitize("<pre>\nline 1\nline 2</pre>").as_deref(),
            Some("line 1\nline 2")
        );
        assert_eq!(
            full_sanitize("<pre><code>\nline 1</code></pre>").as_deref(),
            Some("\nline 1")
        );
        assert_eq!(
            full_sanitize("<svg viewBox=\"0 0 24 24\"><title>Enter fullscreen mode</title><path d=\"M0 0\"/></svg>").as_deref(),
            Some("Enter fullscreen mode")
        );
        assert_eq!(
            full_sanitize("<table>\n<caption>Cap</caption>\n<colgroup><col></colgroup>\n<thead>\n<tr><th>H1</th></tr>\n</thead>\n<tbody>\n<tr><td>C1</td></tr>\n</tbody>\n<tfoot>\n<tr><td>F1</td></tr>\n</tfoot>\n</table>").as_deref(),
            Some("\nCap\n\n\nH1\n\n\nC1\n\n\nF1\n\n")
        );
        assert_eq!(
            full_sanitize("<style>.a > .b { content: \"<x>\"; }</style>").as_deref(),
            Some(".a &gt; .b { content: \"&lt;x&gt;\"; }")
        );
        assert_eq!(
            full_sanitize("<script>const a = 1 < 2 && 3 > 1;</script>").as_deref(),
            Some("const a = 1 &lt; 2 &amp;&amp; 3 &gt; 1;")
        );
        assert_eq!(
            full_sanitize(
                "<iframe src=\"https://youtube.com/embed/1\">fallback <b>text</b></iframe>"
            )
            .as_deref(),
            Some("fallback &lt;b&gt;text&lt;/b&gt;")
        );
        assert_eq!(
            full_sanitize("<textarea>\n<b>raw</b> &amp; text</textarea>").as_deref(),
            Some("&lt;b&gt;raw&lt;/b&gt; &amp; text")
        );
    }

    #[test]
    fn declines_ambiguous_html5_and_malformed_table_edge_cases() {
        for input in [
            "null\0byte",
            "\u{FEFF}bom",
            "<table><tr><td>1</td></tr>stray<td>2</td></table>",
            "<table><b>stray</b><tr><td>1</td></tr></table>",
            "<table><tr><td>A</tr> stray</td></table>",
            "<table><tr><td>A<tr> stray</td></table>",
            "<table><tr><td>A</tbody> stray</td></table>",
            "<table><tr><td>A</th> stray</td></table>",
            "<table><thead><tr><td>A</tr></tbody> stray</thead></table>",
            "<table><caption>A<tr><td>B</td></tr>stray</caption></table>",
            "<table><colgroup>stray</colgroup><tr><td>A</td></tr></table>",
            "<table><tr><td><svg>A</td></tr>stray</svg></table>",
            "<table><tr><td><object>A</td>stray</tr></table>",
            "<table><tr><td><marquee>A</td>stray</tr></table>",
            "<table><tr><td><applet>A</td>stray</tr></table>",
            "<table><tr><td><table><tr><td>nested</td></tr></table></td></tr></table>",
            "</td>",
            "</tr>",
            "</table>",
            "<svg><p><style>a > b</style></svg>",
            "<div><svg></div><title><b>raw</b></title></svg>",
            "<title><b>raw</b></title>",
            "<!-- unclosed",
            "<!-->abrupt",
            "<!-- --!>bang",
            "<?xml version=\"1.0\"?>",
            "<div attr=\"unclosed>",
            "&unknownentity;",
            "&copy=1",
            "&#123",
            "<xmp>raw</xmp>",
            "<plaintext>raw",
            "<script><!-- escaped --></script>",
        ] {
            assert_eq!(full_sanitize(input), None, "{input:?}");
        }
    }
}
