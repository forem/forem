//! Emoji shortcode expansion and `<code>`-aware HTML emoji replacement matching
//! `Html::Parser#parse_emojis` and `Html::Parser#escape_colon_emojis_in_codeblock`.

use std::borrow::Cow;

use crate::emoji_data::{EMOJI_BLOB, EMOJI_ENTRIES, MAX_EMOJI_ALIAS_LEN};

const MAX_TAG_DEPTH: usize = 64;

/// Looks up a `gemoji` alias (the capture group inside `:([\w+-]+):`) in the static sorted table.
#[inline]
pub fn lookup_emoji(alias: &str) -> Option<&'static str> {
    let bytes = alias.as_bytes();
    if bytes.is_empty() || bytes.len() > MAX_EMOJI_ALIAS_LEN {
        return None;
    }

    let idx = EMOJI_ENTRIES
        .binary_search_by(|&entry| {
            let offset = (entry >> 11) as usize;
            let alias_len = ((entry >> 5) & 0x3F) as usize;
            EMOJI_BLOB[offset..offset + alias_len].cmp(bytes)
        })
        .ok()?;

    let entry = EMOJI_ENTRIES[idx];
    let raw_start = ((entry >> 11) as usize) + (((entry >> 5) & 0x3F) as usize);
    let raw_len = (entry & 0x1F) as usize;
    std::str::from_utf8(&EMOJI_BLOB[raw_start..raw_start + raw_len]).ok()
}

#[inline]
fn is_alias_byte(b: u8) -> bool {
    b.is_ascii_alphanumeric() || matches!(b, b'_' | b'+' | b'-')
}

/// Replaces `:([\w+-]+):` shortcodes with their `Emoji.find_by_alias($1)&.raw` Unicode sequences,
/// leaving unknown `:alias:` matches untouched and consuming the closing `:` of every regex match
/// just like Ruby's `html.gsub(/:([\w+-]+):/)`.
///
/// Returns `Cow::Borrowed(html)` without allocating when no emoji shortcode is replaced.
pub fn parse_emojis(html: &str) -> Cow<'_, str> {
    let mut out: Option<String> = None;
    let mut last_copied = 0usize;
    replace_emojis_in_range(html, 0, html.len(), &mut out, &mut last_copied);
    match out {
        None => Cow::Borrowed(html),
        Some(mut s) => {
            s.push_str(&html[last_copied..]);
            Cow::Owned(s)
        }
    }
}

/// Scans `&full_html[range_start..range_end]` for `:([\w+-]+):` matches and lazily writes
/// replacements into `out`, tracking `last_copied` as an index into `full_html`.
fn replace_emojis_in_range(
    full_html: &str,
    range_start: usize,
    range_end: usize,
    out: &mut Option<String>,
    last_copied: &mut usize,
) {
    let slice_bytes = &full_html.as_bytes()[range_start..range_end];
    if !slice_bytes.contains(&b':') {
        return;
    }

    let mut i = 0;
    while i < slice_bytes.len() {
        let Some(rel) = slice_bytes[i..].iter().position(|&b| b == b':') else {
            break;
        };
        let start = i + rel;
        let mut end = start + 1;
        while end < slice_bytes.len() && is_alias_byte(slice_bytes[end]) {
            end += 1;
        }

        if end > start + 1 && slice_bytes.get(end) == Some(&b':') {
            let global_start = range_start + start;
            let global_end = range_start + end;
            let alias = &full_html[global_start + 1..global_end];
            if let Some(raw) = lookup_emoji(alias) {
                let buf = out.get_or_insert_with(|| String::with_capacity(full_html.len()));
                buf.push_str(&full_html[*last_copied..global_start]);
                buf.push_str(raw);
                *last_copied = global_end + 1;
            }
            // Ruby's gsub(/:([\w+-]+):/) consumes the closing ':' even when the alias is unknown.
            i = end + 1;
        } else {
            // None of slice_bytes[start + 1..end] is ':', so the next possible ':' is at `end`.
            i = end;
        }
    }
}

/// Returns `true` if `attr_value` contains any `:([\w+-]+):` pattern.
fn contains_colon_shortcode_pattern(bytes: &[u8]) -> bool {
    let mut i = 0;
    while i < bytes.len() {
        let Some(rel) = bytes[i..].iter().position(|&b| b == b':') else {
            return false;
        };
        let start = i + rel;
        let mut end = start + 1;
        while end < bytes.len() && is_alias_byte(bytes[end]) {
            end += 1;
        }
        if end > start + 1 && bytes.get(end) == Some(&b':') {
            return true;
        }
        i = end;
    }
    false
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Tag {
    // Void tags
    Br,
    Img,
    Hr,
    Col,
    // Code tag (skips emoji expansion in its subtree)
    Code,
    // Non-inline tags starting with 'p' (libxml2 suppresses format newlines inside them)
    P,
    Pre,
    // Formatted block containers (libxml2 format=1 applies Place 1 & Place 2 when child_count >= 2)
    Div,
    Blockquote,
    Center,
    Li,
    Dd,
    Dt,
    Td,
    Th,
    H1,
    H2,
    H3,
    H4,
    H5,
    H6,
    Ul,
    Ol,
    Dl,
    Table,
    Colgroup,
    Thead,
    Tbody,
    Tfoot,
    Tr,
    Title,
    // Inline / HTML5 containers
    A,
    Svg,
    Html5Container,
    Inline,
}

impl Tag {
    fn from_bytes(name: &[u8]) -> Option<Self> {
        match name {
            b"br" => Some(Self::Br),
            b"img" => Some(Self::Img),
            b"hr" => Some(Self::Hr),
            b"col" => Some(Self::Col),
            b"code" => Some(Self::Code),
            b"p" => Some(Self::P),
            b"pre" => Some(Self::Pre),
            b"div" => Some(Self::Div),
            b"blockquote" => Some(Self::Blockquote),
            b"center" => Some(Self::Center),
            b"li" => Some(Self::Li),
            b"dd" => Some(Self::Dd),
            b"dt" => Some(Self::Dt),
            b"td" => Some(Self::Td),
            b"th" => Some(Self::Th),
            b"h1" => Some(Self::H1),
            b"h2" => Some(Self::H2),
            b"h3" => Some(Self::H3),
            b"h4" => Some(Self::H4),
            b"h5" => Some(Self::H5),
            b"h6" => Some(Self::H6),
            b"ul" => Some(Self::Ul),
            b"ol" => Some(Self::Ol),
            b"dl" => Some(Self::Dl),
            b"table" => Some(Self::Table),
            b"colgroup" => Some(Self::Colgroup),
            b"thead" => Some(Self::Thead),
            b"tbody" => Some(Self::Tbody),
            b"tfoot" => Some(Self::Tfoot),
            b"tr" => Some(Self::Tr),
            b"title" => Some(Self::Title),
            b"a" => Some(Self::A),
            b"svg" => Some(Self::Svg),
            b"article" | b"aside" | b"del" | b"details" | b"figure" | b"footer" | b"header"
            | b"ins" | b"main" | b"nav" | b"section" => Some(Self::Html5Container),
            b"abbr" | b"add" | b"b" | b"big" | b"circle" | b"cite" | b"defs" | b"dfn"
            | b"ellipse" | b"em" | b"figcaption" | b"filter" | b"g" | b"i" | b"iframe" | b"kbd"
            | b"line" | b"mark" | b"path" | b"polygon" | b"polyline" | b"q" | b"rect" | b"rp"
            | b"rt" | b"ruby" | b"s" | b"samp" | b"small" | b"source" | b"span" | b"stop"
            | b"strike" | b"strong" | b"sub" | b"summary" | b"sup" | b"time" | b"tt" | b"u"
            | b"use" | b"var" | b"video" => Some(Self::Inline),
            _ => None,
        }
    }

    #[inline]
    fn is_void(self) -> bool {
        matches!(self, Self::Br | Self::Img | Self::Hr | Self::Col)
    }

    /// True if `libxml2` HTML4 (`html40ElementTable`) marks this element as `!info->isinline`.
    #[inline]
    fn is_libxml_non_inline(self) -> bool {
        matches!(
            self,
            Self::Hr
                | Self::Col
                | Self::P
                | Self::Pre
                | Self::Div
                | Self::Blockquote
                | Self::Center
                | Self::Li
                | Self::Dd
                | Self::Dt
                | Self::Td
                | Self::Th
                | Self::H1
                | Self::H2
                | Self::H3
                | Self::H4
                | Self::H5
                | Self::H6
                | Self::Ul
                | Self::Ol
                | Self::Dl
                | Self::Table
                | Self::Colgroup
                | Self::Thead
                | Self::Tbody
                | Self::Tfoot
                | Self::Tr
                | Self::Title
        )
    }

    /// True if `libxml2` `htmlNodeDumpFormatOutput` inserts a newline after `<tag>` and before
    /// `</tag>` when the element has `>= 2` children and its first/last child is not a text node
    /// (`!info->isinline && cur->name[0] != 'p'`).
    #[inline]
    fn is_formatted_block(self) -> bool {
        self.is_libxml_non_inline() && !matches!(self, Self::P | Self::Pre | Self::Hr | Self::Col)
    }

    #[inline]
    fn requires_whitespace_only_text(self) -> bool {
        matches!(
            self,
            Self::Ul
                | Self::Ol
                | Self::Dl
                | Self::Table
                | Self::Colgroup
                | Self::Thead
                | Self::Tbody
                | Self::Tfoot
                | Self::Tr
        )
    }

    #[inline]
    fn is_phrasing_child(self) -> bool {
        matches!(
            self,
            Self::Br
                | Self::Img
                | Self::Code
                | Self::A
                | Self::Svg
                | Self::Html5Container
                | Self::Inline
        )
    }

    #[inline]
    fn is_flow_child(self) -> bool {
        self.is_phrasing_child()
            || matches!(
                self,
                Self::Div
                    | Self::Blockquote
                    | Self::Center
                    | Self::P
                    | Self::Pre
                    | Self::Ul
                    | Self::Ol
                    | Self::Dl
                    | Self::Table
                    | Self::H1
                    | Self::H2
                    | Self::H3
                    | Self::H4
                    | Self::H5
                    | Self::H6
                    | Self::Hr
            )
    }
}

#[derive(Clone, Copy, Debug)]
struct Frame {
    raw_name_start: usize,
    raw_name_end: usize,
    tag: Tag,
    child_count: usize,
    first_child_is_text: bool,
    last_child_is_text: bool,
    prev_child_was_block_elem: bool,
}

impl Frame {
    const EMPTY: Self = Self {
        raw_name_start: 0,
        raw_name_end: 0,
        tag: Tag::Inline,
        child_count: 0,
        first_child_is_text: false,
        last_child_is_text: false,
        prev_child_was_block_elem: false,
    };
}

fn is_valid_child(parent: Option<Tag>, child: Tag, stack: &[Frame], in_code: bool) -> bool {
    if in_code && child == Tag::Code {
        return false;
    }
    if child == Tag::A && stack.iter().any(|f| f.tag == Tag::A) {
        return false;
    }

    match parent {
        None => child.is_flow_child(),
        Some(Tag::Ul | Tag::Ol) => child == Tag::Li,
        Some(Tag::Dl) => matches!(child, Tag::Dt | Tag::Dd),
        Some(Tag::Table) => matches!(
            child,
            Tag::Colgroup | Tag::Thead | Tag::Tbody | Tag::Tfoot | Tag::Tr
        ),
        Some(Tag::Colgroup) => child == Tag::Col,
        Some(Tag::Thead | Tag::Tbody | Tag::Tfoot) => child == Tag::Tr,
        Some(Tag::Tr) => matches!(child, Tag::Td | Tag::Th),
        Some(Tag::Title) => false,
        Some(Tag::Svg) => matches!(child, Tag::Title | Tag::Svg | Tag::Inline),
        Some(
            Tag::Div
            | Tag::Blockquote
            | Tag::Center
            | Tag::Li
            | Tag::Dd
            | Tag::Td
            | Tag::Th
            | Tag::Html5Container,
        ) => child.is_flow_child(),
        Some(
            Tag::P
            | Tag::Pre
            | Tag::H1
            | Tag::H2
            | Tag::H3
            | Tag::H4
            | Tag::H5
            | Tag::H6
            | Tag::Dt
            | Tag::A
            | Tag::Code
            | Tag::Inline,
        ) => child.is_phrasing_child(),
        Some(Tag::Br | Tag::Img | Tag::Hr | Tag::Col) => false,
    }
}

#[inline]
fn is_html4_boolean_attr(name: &[u8]) -> bool {
    matches!(
        name,
        b"checked"
            | b"compact"
            | b"declare"
            | b"defer"
            | b"disabled"
            | b"ismap"
            | b"multiple"
            | b"nohref"
            | b"noresize"
            | b"noshade"
            | b"nowrap"
            | b"readonly"
            | b"selected"
    )
}

#[inline]
fn is_uri_attr(name: &[u8]) -> bool {
    matches!(
        name,
        b"href"
            | b"src"
            | b"action"
            | b"cite"
            | b"data"
            | b"usemap"
            | b"longdesc"
            | b"profile"
            | b"classid"
            | b"codebase"
            | b"background"
    )
}

#[inline]
fn is_canonical_amp_entity(bytes: &[u8], amp_pos: usize) -> bool {
    let rest = &bytes[amp_pos..];
    rest.starts_with(b"&amp;") || rest.starts_with(b"&lt;") || rest.starts_with(b"&gt;")
}

/// True if `bytes[idx..]` starts with an ASCII control character other than `\t`/`\n` or with
/// Unicode noncharacters `U+FFFE` / `U+FFFF`, which `libxml2` (`IS_CHAR`) strips or normalizes.
#[inline]
fn is_disallowed_libxml_byte(bytes: &[u8], idx: usize) -> bool {
    let b = bytes[idx];
    (b < 0x20 && !matches!(b, b'\t' | b'\n'))
        || (b == 0xEF && matches!(bytes.get(idx + 1..idx + 3), Some([0xBF, 0xBE | 0xBF])))
}

/// Parses and validates an opening tag starting at `tag_start` (`bytes[tag_start] == b'<'`).
/// Returns `(name_start, name_end, Tag, tag_end_exclusive)`.
fn parse_opening_tag(bytes: &[u8], tag_start: usize) -> Option<(usize, usize, Tag, usize)> {
    let name_start = tag_start + 1;
    let first = *bytes.get(name_start)?;
    if !first.is_ascii_lowercase() {
        return None;
    }
    let mut name_end = name_start + 1;
    while let Some(&b) = bytes.get(name_end) {
        if b.is_ascii_lowercase() || b.is_ascii_digit() {
            name_end += 1;
        } else {
            break;
        }
    }

    let tag = Tag::from_bytes(&bytes[name_start..name_end])?;
    let mut pos = name_end;
    let mut seen_attrs: [&[u8]; 16] = [&[]; 16];
    let mut attr_count = 0usize;

    loop {
        match bytes.get(pos)? {
            b'>' => return Some((name_start, name_end, tag, pos + 1)),
            b' ' => {
                pos += 1;
                let attr_start = pos;
                let attr_first = *bytes.get(attr_start)?;
                if !attr_first.is_ascii_lowercase() {
                    return None;
                }
                let mut attr_end = attr_start + 1;
                while let Some(&b) = bytes.get(attr_end) {
                    if b.is_ascii_lowercase() || b.is_ascii_digit() || matches!(b, b'_' | b'-') {
                        attr_end += 1;
                    } else {
                        break;
                    }
                }
                let attr_name = &bytes[attr_start..attr_end];
                if is_html4_boolean_attr(attr_name)
                    || attr_count >= seen_attrs.len()
                    || seen_attrs[..attr_count].contains(&attr_name)
                {
                    return None;
                }
                seen_attrs[attr_count] = attr_name;
                attr_count += 1;

                if bytes.get(attr_end..attr_end + 2) != Some(b"=\"") {
                    return None;
                }
                let val_start = attr_end + 2;
                let mut val_end = val_start;
                let is_uri = is_uri_attr(attr_name);

                while let Some(&vb) = bytes.get(val_end) {
                    if vb == b'"' {
                        break;
                    }
                    if matches!(vb, b'<' | b'>') || is_disallowed_libxml_byte(bytes, val_end) {
                        return None;
                    }
                    if is_uri && !(0x21..=0x7E).contains(&vb) {
                        return None;
                    }
                    if vb == b'&' && !is_canonical_amp_entity(bytes, val_end) {
                        return None;
                    }
                    val_end += 1;
                }
                if bytes.get(val_end) != Some(&b'"') {
                    return None;
                }
                if contains_colon_shortcode_pattern(&bytes[val_start..val_end]) {
                    return None;
                }
                pos = val_end + 1;
            }
            _ => return None,
        }
    }
}

/// Replaces `:([\w+-]+):` emoji shortcodes outside `<code>...</code>` elements while validating
/// that `html` is already in canonical `Nokogiri::HTML.fragment(html).to_html` form, matching
/// `Html::Parser#escape_colon_emojis_in_codeblock`.
///
/// Returns `Some(Cow::Borrowed(html))` with zero heap allocations when `html` is valid canonical
/// HTML and no emoji shortcode is replaced, `Some(Cow::Owned(_))` when emoji shortcodes are
/// replaced, or `None` when `html` requires Nokogiri's HTML4 tree builder or serializer.
pub fn escape_colon_emojis_in_codeblock(html: &str) -> Option<Cow<'_, str>> {
    if html.is_empty() {
        return Some(Cow::Borrowed(html));
    }
    if html.starts_with('\u{FEFF}') {
        return None;
    }

    let bytes = html.as_bytes();
    let mut stack = [Frame::EMPTY; MAX_TAG_DEPTH];
    let mut depth = 0usize;
    let mut in_code = false;
    let mut out: Option<String> = None;
    let mut last_copied = 0usize;
    let mut i = 0;

    while i < bytes.len() {
        if bytes[i] == b'<' {
            if bytes.get(i + 1) == Some(&b'/') {
                let name_start = i + 2;
                let mut name_end = name_start;
                while let Some(&b) = bytes.get(name_end) {
                    if b.is_ascii_lowercase() || b.is_ascii_digit() {
                        name_end += 1;
                    } else {
                        break;
                    }
                }
                if name_end == name_start || bytes.get(name_end) != Some(&b'>') || depth == 0 {
                    return None;
                }
                depth -= 1;
                let frame = stack[depth];
                if bytes[frame.raw_name_start..frame.raw_name_end] != bytes[name_start..name_end] {
                    return None;
                }
                // libxml2 omits `</li>` when `<li>` has zero children (`<li></li>` -> `<li>`).
                if frame.tag == Tag::Li && frame.child_count == 0 {
                    return None;
                }
                // libxml2 Place 1 & Place 2 newline formatting on multi-child block elements.
                if frame.tag.is_formatted_block()
                    && frame.child_count >= 2
                    && (!frame.first_child_is_text || !frame.last_child_is_text)
                {
                    return None;
                }
                if frame.tag == Tag::Code {
                    in_code = false;
                }
                i = name_end + 1;
            } else {
                let (name_start, name_end, tag, tag_end) = parse_opening_tag(bytes, i)?;
                let active_stack = &stack[..depth];
                let parent_tag = active_stack.last().map(|f| f.tag);
                if !is_valid_child(parent_tag, tag, active_stack, in_code) {
                    return None;
                }
                if depth > 0 {
                    let parent = &mut stack[depth - 1];
                    // libxml2 Place 3 newline formatting between a non-inline child and a following element.
                    if parent.prev_child_was_block_elem {
                        return None;
                    }
                    if parent.child_count == 0 {
                        parent.first_child_is_text = false;
                    }
                    parent.child_count += 1;
                    parent.last_child_is_text = false;
                    parent.prev_child_was_block_elem = tag.is_libxml_non_inline();
                }
                if !tag.is_void() {
                    if depth >= MAX_TAG_DEPTH {
                        return None;
                    }
                    if tag == Tag::Code {
                        in_code = true;
                    }
                    stack[depth] = Frame {
                        raw_name_start: name_start,
                        raw_name_end: name_end,
                        tag,
                        child_count: 0,
                        first_child_is_text: false,
                        last_child_is_text: false,
                        prev_child_was_block_elem: false,
                    };
                    depth += 1;
                }
                i = tag_end;
            }
        } else {
            let text_end = bytes[i..]
                .iter()
                .position(|&b| b == b'<')
                .map_or(bytes.len(), |rel| i + rel);
            let text_bytes = &bytes[i..text_end];
            let parent_tag = if depth > 0 {
                Some(stack[depth - 1].tag)
            } else {
                None
            };

            if parent_tag.is_some_and(Tag::requires_whitespace_only_text)
                && !text_bytes
                    .iter()
                    .all(|&b| matches!(b, b' ' | b'\n' | b'\t'))
            {
                return None;
            }

            let in_title = parent_tag == Some(Tag::Title);
            let mut ti = 0;
            while ti < text_bytes.len() {
                let tb = text_bytes[ti];
                if tb == b'>' || is_disallowed_libxml_byte(text_bytes, ti) {
                    return None;
                }
                if tb == b'&' && (in_title || !is_canonical_amp_entity(text_bytes, ti)) {
                    return None;
                }
                ti += 1;
            }

            if depth > 0 {
                let parent = &mut stack[depth - 1];
                if parent.child_count == 0 {
                    parent.first_child_is_text = true;
                }
                parent.child_count += 1;
                parent.last_child_is_text = true;
                parent.prev_child_was_block_elem = false;
            }

            if !in_code {
                replace_emojis_in_range(html, i, text_end, &mut out, &mut last_copied);
            }
            i = text_end;
        }
    }

    if depth != 0 {
        return None;
    }

    match out {
        None => Some(Cow::Borrowed(html)),
        Some(mut s) => {
            s.push_str(&html[last_copied..]);
            Some(Cow::Owned(s))
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn looks_up_common_and_disability_emojis() {
        assert_eq!(lookup_emoji("joy"), Some("😂"));
        assert_eq!(lookup_emoji("o"), Some("⭕"));
        assert_eq!(lookup_emoji("+1"), Some("👍"));
        assert_eq!(lookup_emoji("-1"), Some("👎"));
        assert_eq!(lookup_emoji("e-mail"), Some("📧"));
        assert_eq!(lookup_emoji("100"), Some("💯"));
        assert_eq!(lookup_emoji("guide_dog"), Some("🦮"));
        assert_eq!(lookup_emoji("service_dog"), Some("🐕‍🦺"));
        assert_eq!(lookup_emoji("person_in_motorized_wheelchair"), Some("🧑‍🦼"));
        assert_eq!(lookup_emoji(""), None);
        assert_eq!(lookup_emoji("JOY"), None);
        assert_eq!(
            lookup_emoji("no_one_will_ever_create_an_emoji_with_this_alias"),
            None
        );
    }

    #[test]
    fn parses_emojis_matching_ruby_gsub_semantics() {
        assert!(matches!(parse_emojis(""), Cow::Borrowed("")));
        assert!(matches!(
            parse_emojis("<div>Hello World</div>"),
            Cow::Borrowed("<div>Hello World</div>")
        ));
        assert_eq!(parse_emojis(":joy:"), "😂");
        assert_eq!(parse_emojis(":+1: :-1: :100:"), "👍 👎 💯");
        assert_eq!(parse_emojis(":joy:joy:"), "😂joy:");
        assert!(matches!(
            parse_emojis(":not_an_emoji:joy:"),
            Cow::Borrowed(":not_an_emoji:joy:")
        ));
        assert_eq!(parse_emojis(":not_an_emoji::joy:"), ":not_an_emoji:😂");
        assert_eq!(parse_emojis(":hello world:joy:"), ":hello world😂");
        assert_eq!(parse_emojis(":::joy:::"), "::😂::");
    }

    #[test]
    fn escapes_colon_emojis_outside_code_elements() {
        let html = "<span>:o:<code>:o:</code>:o:<code>:o:</code>:o:<span>:o:</span>:o:</span>";
        assert_eq!(
            escape_colon_emojis_in_codeblock(html).as_deref(),
            Some("<span>⭕<code>:o:</code>⭕<code>:o:</code>⭕<span>⭕</span>⭕</span>")
        );

        let block = "<div class=\"highlight js-code-highlight\">\n<pre class=\"highlight rust\"><code><span class=\"k\">fn</span> :rocket:\n</code></pre>\n<div class=\"highlight__panel js-actions-panel\"></div>\n</div>";
        assert!(matches!(
            escape_colon_emojis_in_codeblock(block),
            Some(Cow::Borrowed(_))
        ));
    }

    #[test]
    fn declines_non_canonical_html_fragments() {
        for quirky in [
            "<div class='single'>:joy:</div>",
            "<DIV>:joy:</DIV>",
            "<img src=\"x\"/>",
            "<p>unclosed :joy:",
            "<p>mismatched</span>",
            "<div><p>a</p><p>b</p></div>",
            "<div>\n<p>a</p><p>b</p>\n</div>",
            "<ul>\n<li></li>\n</ul>",
            "<p><div>block in p</div></p>",
            "<a href=\"https://a.com\"><a href=\"https://b.com\">nested a</a></a>",
            "<code><code>:joy:</code></code>",
            "<div title=\":joy:\">text</div>",
            "<a href=\"https://a.com/with space\">x</a>",
            "a & b",
            "<p>&nbsp;</p>",
            "<p>&quot;</p>",
            "<p>a\x01b :joy:</p>",
            "<p>a\x0Cb :joy:</p>",
            "<p title=\"a\x07b\">:joy:</p>",
            "<p>a\u{FFFE}b :joy:</p>",
            "<p>a\u{FFFF}b :joy:</p>",
        ] {
            assert_eq!(
                escape_colon_emojis_in_codeblock(quirky),
                None,
                "expected None for {quirky:?}"
            );
        }
    }
}
