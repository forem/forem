//! Canonical HTML4 fragment & document post-processing primitives and pipelines for
//! `Html::Parser` and `Mentions::CreateAll`.
//!
//! Validates that inputs conform to `libxml2` HTML4 (`Nokogiri::HTML.fragment` /
//! `Nokogiri::HTML`) canonical serialization rules, performing zero-copy borrowed returns
//! when no transformation applies and single-pass buffer writes when elements match,
//! while returning `None` on non-canonical HTML so Ruby callers transparently fall back
//! to `legacy_<method>`.

use std::borrow::Cow;

const MAX_TAG_DEPTH: usize = 64;
const RAW_TAG: &str = "{----% raw %----}";
const END_RAW_TAG: &str = "{----% endraw %----}";
const RAW_TAG_UNESCAPED: &str = "{% raw %}";
const END_RAW_TAG_UNESCAPED: &str = "{% endraw %}";
const RAW_TAG_DELIMITERS: [&str; 5] = ["{", "}", "raw", "endraw", "----"];

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Tag {
    // Void tags
    Br,
    Img,
    Hr,
    Col,
    // Code tag
    Code,
    // Non-inline tags starting with 'p' (libxml2 suppresses Place 1/2/3 format newlines inside them)
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
    Video,
    Figure,
    Figcaption,
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
            b"video" => Some(Self::Video),
            b"figure" => Some(Self::Figure),
            b"figcaption" => Some(Self::Figcaption),
            b"article" | b"aside" | b"del" | b"details" | b"footer" | b"header" | b"ins"
            | b"main" | b"nav" | b"section" => Some(Self::Html5Container),
            b"abbr" | b"add" | b"b" | b"big" | b"circle" | b"cite" | b"defs" | b"dfn"
            | b"ellipse" | b"em" | b"filter" | b"g" | b"i" | b"iframe" | b"kbd" | b"line"
            | b"mark" | b"path" | b"polygon" | b"polyline" | b"q" | b"rect" | b"rp" | b"rt"
            | b"ruby" | b"s" | b"samp" | b"small" | b"source" | b"span" | b"stop" | b"strike"
            | b"strong" | b"sub" | b"summary" | b"sup" | b"time" | b"tt" | b"u" | b"use"
            | b"var" => Some(Self::Inline),
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
                | Self::Video
                | Self::Figure
                | Self::Figcaption
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
    open_tag_start: usize,
    open_tag_end: usize,
    tag: Tag,
    child_count: usize,
    first_child_is_text: bool,
    last_child_is_text: bool,
    first_child_was_block_elem: bool,
    prev_child_was_block_elem: bool,
    flag: bool,
}

impl Frame {
    const EMPTY: Self = Self {
        raw_name_start: 0,
        raw_name_end: 0,
        open_tag_start: 0,
        open_tag_end: 0,
        tag: Tag::Inline,
        child_count: 0,
        first_child_is_text: false,
        last_child_is_text: false,
        first_child_was_block_elem: false,
        prev_child_was_block_elem: false,
        flag: false,
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
            | Tag::Figure
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
            | Tag::Video
            | Tag::Figcaption
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

#[inline]
fn is_disallowed_libxml_byte(bytes: &[u8], idx: usize) -> bool {
    let b = bytes[idx];
    (b < 0x20 && !matches!(b, b'\t' | b'\n'))
        || (b == 0xEF && matches!(bytes.get(idx + 1..idx + 3), Some([0xBF, 0xBE | 0xBF])))
}

#[derive(Clone, Copy, Debug)]
struct ParsedOpenTag {
    name_start: usize,
    name_end: usize,
    tag: Tag,
    tag_end: usize,
    class_range: Option<(usize, usize)>,
    src_range: Option<(usize, usize)>,
}

/// Parses and validates a canonical opening tag starting at `tag_start` (`bytes[tag_start] == b'<'`).
fn parse_opening_tag(bytes: &[u8], tag_start: usize) -> Option<ParsedOpenTag> {
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
    let mut class_range = None;
    let mut src_range = None;

    loop {
        match bytes.get(pos)? {
            b'>' => {
                return Some(ParsedOpenTag {
                    name_start,
                    name_end,
                    tag,
                    tag_end: pos + 1,
                    class_range,
                    src_range,
                })
            }
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
                if attr_name == b"class" {
                    class_range = Some((val_start, val_end));
                } else if attr_name == b"src" {
                    src_range = Some((val_start, val_end));
                }
                pos = val_end + 1;
            }
            _ => return None,
        }
    }
}

#[inline]
fn parse_closing_tag_name(bytes: &[u8], tag_start: usize) -> Option<(usize, usize, usize)> {
    let name_start = tag_start + 2;
    let mut name_end = name_start;
    while let Some(&b) = bytes.get(name_end) {
        if b.is_ascii_lowercase() || b.is_ascii_digit() {
            name_end += 1;
        } else {
            break;
        }
    }
    if name_end == name_start || bytes.get(name_end) != Some(&b'>') {
        return None;
    }
    Some((name_start, name_end, name_end + 1))
}

#[inline]
fn validate_text_node(text_bytes: &[u8], parent_tag: Option<Tag>) -> bool {
    if parent_tag.is_some_and(Tag::requires_whitespace_only_text)
        && !text_bytes
            .iter()
            .all(|&b| matches!(b, b' ' | b'\n' | b'\t'))
    {
        return false;
    }

    let in_title = parent_tag == Some(Tag::Title);
    let mut ti = 0;
    while ti < text_bytes.len() {
        let tb = text_bytes[ti];
        if tb == b'>' || is_disallowed_libxml_byte(text_bytes, ti) {
            return false;
        }
        if tb == b'&' && (in_title || !is_canonical_amp_entity(text_bytes, ti)) {
            return false;
        }
        ti += 1;
    }
    true
}

#[inline]
fn record_element_on_parent(stack: &mut [Frame], depth: usize, tag: Tag) -> bool {
    if depth > 0 {
        let parent = &mut stack[depth - 1];
        if parent.prev_child_was_block_elem {
            return false;
        }
        if parent.child_count == 0 {
            parent.first_child_is_text = false;
            parent.first_child_was_block_elem = tag.is_libxml_non_inline();
        }
        parent.child_count += 1;
        parent.last_child_is_text = false;
        parent.prev_child_was_block_elem = tag.is_libxml_non_inline();
    }
    true
}

#[inline]
fn record_text_on_parent(stack: &mut [Frame], depth: usize) {
    if depth > 0 {
        let parent = &mut stack[depth - 1];
        if parent.child_count == 0 {
            parent.first_child_is_text = true;
            parent.first_child_was_block_elem = false;
        }
        parent.child_count += 1;
        parent.last_child_is_text = true;
        parent.prev_child_was_block_elem = false;
    }
}

#[inline]
fn validate_closed_frame(frame: &Frame, bytes: &[u8], name_start: usize, name_end: usize) -> bool {
    if bytes[frame.raw_name_start..frame.raw_name_end] != bytes[name_start..name_end] {
        return false;
    }
    if frame.tag == Tag::Li && frame.child_count == 0 {
        return false;
    }
    if frame.tag.is_formatted_block()
        && frame.child_count >= 2
        && (!frame.first_child_is_text || !frame.last_child_is_text)
    {
        return false;
    }
    true
}

#[inline]
fn has_class_token(class_str: &str, target: &str) -> bool {
    class_str.split_ascii_whitespace().any(|tok| tok == target)
}

#[inline]
fn is_canonical_class_whitespace(class_str: &str) -> bool {
    let bytes = class_str.as_bytes();
    if bytes.is_empty() || bytes[0] == b' ' || bytes[bytes.len() - 1] == b' ' {
        return false;
    }
    let mut prev_space = false;
    for &b in bytes {
        if matches!(b, b'\t' | b'\n' | b'\r' | 0x0B | 0x0C) {
            return false;
        }
        if b == b' ' {
            if prev_space {
                return false;
            }
            prev_space = true;
        } else {
            prev_space = false;
        }
    }
    true
}

/// Adds the `"js-code-highlight"` class to every `<div class="...highlight...">` element on
/// canonical `Nokogiri::HTML.fragment(html).to_html` inputs, matching
/// `Html::Parser#add_control_class_to_codeblock`.
pub fn add_control_class_to_codeblock(html: &str) -> Option<Cow<'_, str>> {
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
    let mut i = 0usize;

    while i < bytes.len() {
        if bytes[i] == b'<' {
            if bytes.get(i + 1) == Some(&b'/') {
                let (name_start, name_end, close_end) = parse_closing_tag_name(bytes, i)?;
                if depth == 0 {
                    return None;
                }
                depth -= 1;
                let frame = stack[depth];
                if !validate_closed_frame(&frame, bytes, name_start, name_end) {
                    return None;
                }
                if frame.tag == Tag::Code {
                    in_code = false;
                }
                i = close_end;
            } else {
                let parsed = parse_opening_tag(bytes, i)?;
                let active_stack = &stack[..depth];
                let parent_tag = active_stack.last().map(|f| f.tag);
                if !is_valid_child(parent_tag, parsed.tag, active_stack, in_code) {
                    return None;
                }
                if !record_element_on_parent(&mut stack, depth, parsed.tag) {
                    return None;
                }

                if parsed.tag == Tag::Div {
                    if let Some((cs, ce)) = parsed.class_range {
                        let class_str = &html[cs..ce];
                        if has_class_token(class_str, "highlight") {
                            if !is_canonical_class_whitespace(class_str) {
                                return None;
                            }
                            if !has_class_token(class_str, "js-code-highlight") {
                                let buf = out
                                    .get_or_insert_with(|| String::with_capacity(html.len() + 64));
                                buf.push_str(&html[last_copied..ce]);
                                buf.push_str(" js-code-highlight");
                                last_copied = ce;
                            }
                        }
                    }
                }

                if !parsed.tag.is_void() {
                    if depth >= MAX_TAG_DEPTH {
                        return None;
                    }
                    if parsed.tag == Tag::Code {
                        in_code = true;
                    }
                    stack[depth] = Frame {
                        raw_name_start: parsed.name_start,
                        raw_name_end: parsed.name_end,
                        open_tag_start: i,
                        open_tag_end: parsed.tag_end,
                        tag: parsed.tag,
                        child_count: 0,
                        first_child_is_text: false,
                        last_child_is_text: false,
                        first_child_was_block_elem: false,
                        prev_child_was_block_elem: false,
                        flag: false,
                    };
                    depth += 1;
                }
                i = parsed.tag_end;
            }
        } else {
            let text_end = bytes[i..]
                .iter()
                .position(|&b| b == b'<')
                .map_or(bytes.len(), |rel| i + rel);
            let parent_tag = if depth > 0 {
                Some(stack[depth - 1].tag)
            } else {
                None
            };
            if !validate_text_node(&bytes[i..text_end], parent_tag) {
                return None;
            }
            record_text_on_parent(&mut stack, depth);
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

/// Appends `<div class="highlight__panel js-actions-panel"></div>` to every `div.highlight`
/// element on canonical `Nokogiri::HTML.fragment(html).to_html` inputs, matching
/// `Html::Parser#add_control_panel_to_codeblock`.
pub fn add_control_panel_to_codeblock(html: &str) -> Option<Cow<'_, str>> {
    const PANEL_HTML: &str = "<div class=\"highlight__panel js-actions-panel\"></div>";

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
    let mut i = 0usize;

    while i < bytes.len() {
        if bytes[i] == b'<' {
            if bytes.get(i + 1) == Some(&b'/') {
                let (name_start, name_end, close_end) = parse_closing_tag_name(bytes, i)?;
                if depth == 0 {
                    return None;
                }
                depth -= 1;
                let frame = stack[depth];
                if !validate_closed_frame(&frame, bytes, name_start, name_end) {
                    return None;
                }
                if frame.tag == Tag::Code {
                    in_code = false;
                }
                if frame.flag {
                    let buf = out.get_or_insert_with(|| String::with_capacity(html.len() + 128));
                    match frame.child_count {
                        0 => {
                            buf.push_str(&html[last_copied..i]);
                            buf.push_str(PANEL_HTML);
                            last_copied = i;
                        }
                        1 if frame.first_child_is_text => {
                            buf.push_str(&html[last_copied..i]);
                            buf.push_str(PANEL_HTML);
                            buf.push('\n');
                            last_copied = i;
                        }
                        1 => {
                            buf.push_str(&html[last_copied..frame.open_tag_end]);
                            buf.push('\n');
                            buf.push_str(&html[frame.open_tag_end..i]);
                            if frame.first_child_was_block_elem {
                                buf.push('\n');
                            }
                            buf.push_str(PANEL_HTML);
                            buf.push('\n');
                            last_copied = i;
                        }
                        _ => return None,
                    }
                }
                i = close_end;
            } else {
                let parsed = parse_opening_tag(bytes, i)?;
                let active_stack = &stack[..depth];
                let parent_tag = active_stack.last().map(|f| f.tag);
                if !is_valid_child(parent_tag, parsed.tag, active_stack, in_code) {
                    return None;
                }
                if !record_element_on_parent(&mut stack, depth, parsed.tag) {
                    return None;
                }

                let mut is_highlight_div = false;
                if parsed.tag == Tag::Div {
                    if let Some((cs, ce)) = parsed.class_range {
                        if has_class_token(&html[cs..ce], "highlight") {
                            if stack[..depth].iter().any(|f| f.flag) {
                                return None;
                            }
                            is_highlight_div = true;
                        }
                    }
                }

                if !parsed.tag.is_void() {
                    if depth >= MAX_TAG_DEPTH {
                        return None;
                    }
                    if parsed.tag == Tag::Code {
                        in_code = true;
                    }
                    stack[depth] = Frame {
                        raw_name_start: parsed.name_start,
                        raw_name_end: parsed.name_end,
                        open_tag_start: i,
                        open_tag_end: parsed.tag_end,
                        tag: parsed.tag,
                        child_count: 0,
                        first_child_is_text: false,
                        last_child_is_text: false,
                        first_child_was_block_elem: false,
                        prev_child_was_block_elem: false,
                        flag: is_highlight_div,
                    };
                    depth += 1;
                }
                i = parsed.tag_end;
            }
        } else {
            let text_end = bytes[i..]
                .iter()
                .position(|&b| b == b'<')
                .map_or(bytes.len(), |rel| i + rel);
            let parent_tag = if depth > 0 {
                Some(stack[depth - 1].tag)
            } else {
                None
            };
            if !validate_text_node(&bytes[i..text_end], parent_tag) {
                return None;
            }
            record_text_on_parent(&mut stack, depth);
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

/// Wraps every `<table>...</table>` element in `<div class="table-wrapper-paragraph">...</div>`
/// on canonical `Nokogiri::HTML.fragment(html).to_html` inputs, matching
/// `Html::Parser#wrap_all_tables`.
pub fn wrap_all_tables(html: &str) -> Option<Cow<'_, str>> {
    const TABLE_WRAPPER_OPEN: &str = "<div class=\"table-wrapper-paragraph\">";
    const TABLE_WRAPPER_CLOSE: &str = "</div>";

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
    let mut i = 0usize;

    while i < bytes.len() {
        if bytes[i] == b'<' {
            if bytes.get(i + 1) == Some(&b'/') {
                let (name_start, name_end, close_end) = parse_closing_tag_name(bytes, i)?;
                if depth == 0 {
                    return None;
                }
                depth -= 1;
                let frame = stack[depth];
                if !validate_closed_frame(&frame, bytes, name_start, name_end) {
                    return None;
                }
                if frame.tag == Tag::Code {
                    in_code = false;
                }
                if frame.tag == Tag::Table {
                    let buf = out.get_or_insert_with(|| String::with_capacity(html.len() + 64));
                    buf.push_str(&html[last_copied..close_end]);
                    buf.push_str(TABLE_WRAPPER_CLOSE);
                    last_copied = close_end;
                }
                i = close_end;
            } else {
                let parsed = parse_opening_tag(bytes, i)?;
                let active_stack = &stack[..depth];
                let parent_tag = active_stack.last().map(|f| f.tag);
                if !is_valid_child(parent_tag, parsed.tag, active_stack, in_code) {
                    return None;
                }
                if !record_element_on_parent(&mut stack, depth, parsed.tag) {
                    return None;
                }

                if parsed.tag == Tag::Table {
                    if stack[..depth].iter().any(|f| f.tag == Tag::Table) {
                        return None;
                    }
                    let buf = out.get_or_insert_with(|| String::with_capacity(html.len() + 64));
                    buf.push_str(&html[last_copied..i]);
                    buf.push_str(TABLE_WRAPPER_OPEN);
                    last_copied = i;
                }

                if !parsed.tag.is_void() {
                    if depth >= MAX_TAG_DEPTH {
                        return None;
                    }
                    if parsed.tag == Tag::Code {
                        in_code = true;
                    }
                    stack[depth] = Frame {
                        raw_name_start: parsed.name_start,
                        raw_name_end: parsed.name_end,
                        open_tag_start: i,
                        open_tag_end: parsed.tag_end,
                        tag: parsed.tag,
                        child_count: 0,
                        first_child_is_text: false,
                        last_child_is_text: false,
                        first_child_was_block_elem: false,
                        prev_child_was_block_elem: false,
                        flag: false,
                    };
                    depth += 1;
                }
                i = parsed.tag_end;
            }
        } else {
            let text_end = bytes[i..]
                .iter()
                .position(|&b| b == b'<')
                .map_or(bytes.len(), |rel| i + rel);
            let parent_tag = if depth > 0 {
                Some(stack[depth - 1].tag)
            } else {
                None
            };
            if !validate_text_node(&bytes[i..text_end], parent_tag) {
                return None;
            }
            record_text_on_parent(&mut stack, depth);
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

/// Removes `<p>...</p>` elements whose children are all blank (whitespace-only text or `<br>`)
/// on canonical `Nokogiri::HTML.fragment(html).to_html` inputs, matching
/// `Html::Parser#remove_empty_paragraphs`.
pub fn remove_empty_paragraphs(html: &str) -> Option<Cow<'_, str>> {
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
    let mut i = 0usize;

    while i < bytes.len() {
        if bytes[i] == b'<' {
            if bytes.get(i + 1) == Some(&b'/') {
                let (name_start, name_end, close_end) = parse_closing_tag_name(bytes, i)?;
                if depth == 0 {
                    return None;
                }
                depth -= 1;
                let frame = stack[depth];
                if !validate_closed_frame(&frame, bytes, name_start, name_end) {
                    return None;
                }
                if frame.tag == Tag::Code {
                    in_code = false;
                }
                if frame.tag == Tag::P && frame.flag {
                    // If an empty <p> is nested inside a block element, defer to Nokogiri so any
                    // parent Place 1/2/3 newline adjustments are handled by libxml2.
                    if depth > 0 {
                        return None;
                    }
                    let buf = out.get_or_insert_with(|| String::with_capacity(html.len()));
                    buf.push_str(&html[last_copied..frame.open_tag_start]);
                    last_copied = close_end;
                }
                i = close_end;
            } else {
                let parsed = parse_opening_tag(bytes, i)?;
                let active_stack = &stack[..depth];
                let parent_tag = active_stack.last().map(|f| f.tag);
                if !is_valid_child(parent_tag, parsed.tag, active_stack, in_code) {
                    return None;
                }
                if !record_element_on_parent(&mut stack, depth, parsed.tag) {
                    return None;
                }
                if depth > 0 && stack[depth - 1].tag == Tag::P && parsed.tag != Tag::Br {
                    stack[depth - 1].flag = false;
                }

                if !parsed.tag.is_void() {
                    if depth >= MAX_TAG_DEPTH {
                        return None;
                    }
                    if parsed.tag == Tag::Code {
                        in_code = true;
                    }
                    stack[depth] = Frame {
                        raw_name_start: parsed.name_start,
                        raw_name_end: parsed.name_end,
                        open_tag_start: i,
                        open_tag_end: parsed.tag_end,
                        tag: parsed.tag,
                        child_count: 0,
                        first_child_is_text: false,
                        last_child_is_text: false,
                        first_child_was_block_elem: false,
                        prev_child_was_block_elem: false,
                        flag: parsed.tag == Tag::P,
                    };
                    depth += 1;
                }
                i = parsed.tag_end;
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
            if !validate_text_node(text_bytes, parent_tag) {
                return None;
            }
            if depth > 0
                && stack[depth - 1].tag == Tag::P
                && !text_bytes
                    .iter()
                    .all(|&b| matches!(b, b' ' | b'\t' | b'\n'))
            {
                stack[depth - 1].flag = false;
            }
            record_text_on_parent(&mut stack, depth);
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

/// Wraps `<img ...>` elements inside `<p>` (unless already inside `<a>`) in
/// `<a href="..." class="article-body-image-wrapper"><img ...></a>` on canonical
/// `Nokogiri::HTML.fragment(html).to_html` inputs, matching
/// `Html::Parser#wrap_all_images_in_links`.
pub fn wrap_all_images_in_links(html: &str) -> Option<Cow<'_, str>> {
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
    let mut i = 0usize;

    while i < bytes.len() {
        if bytes[i] == b'<' {
            if bytes.get(i + 1) == Some(&b'/') {
                let (name_start, name_end, close_end) = parse_closing_tag_name(bytes, i)?;
                if depth == 0 {
                    return None;
                }
                depth -= 1;
                let frame = stack[depth];
                if !validate_closed_frame(&frame, bytes, name_start, name_end) {
                    return None;
                }
                if frame.tag == Tag::Code {
                    in_code = false;
                }
                i = close_end;
            } else {
                let parsed = parse_opening_tag(bytes, i)?;
                let active_stack = &stack[..depth];
                let parent_tag = active_stack.last().map(|f| f.tag);
                if !is_valid_child(parent_tag, parsed.tag, active_stack, in_code) {
                    return None;
                }
                if !record_element_on_parent(&mut stack, depth, parsed.tag) {
                    return None;
                }

                if parsed.tag == Tag::Img
                    && stack[..depth].iter().any(|f| f.tag == Tag::P)
                    && parent_tag != Some(Tag::A)
                {
                    if stack[..depth].iter().any(|f| f.tag == Tag::A) {
                        return None;
                    }
                    let src_str = parsed.src_range.map_or("", |(s, e)| &html[s..e]);
                    let buf = out.get_or_insert_with(|| String::with_capacity(html.len() + 128));
                    buf.push_str(&html[last_copied..i]);
                    buf.push_str("<a href=\"");
                    buf.push_str(src_str);
                    buf.push_str("\" class=\"article-body-image-wrapper\">");
                    buf.push_str(&html[i..parsed.tag_end]);
                    buf.push_str("</a>");
                    last_copied = parsed.tag_end;
                }

                if !parsed.tag.is_void() {
                    if depth >= MAX_TAG_DEPTH {
                        return None;
                    }
                    if parsed.tag == Tag::Code {
                        in_code = true;
                    }
                    stack[depth] = Frame {
                        raw_name_start: parsed.name_start,
                        raw_name_end: parsed.name_end,
                        open_tag_start: i,
                        open_tag_end: parsed.tag_end,
                        tag: parsed.tag,
                        child_count: 0,
                        first_child_is_text: false,
                        last_child_is_text: false,
                        first_child_was_block_elem: false,
                        prev_child_was_block_elem: false,
                        flag: false,
                    };
                    depth += 1;
                }
                i = parsed.tag_end;
            }
        } else {
            let text_end = bytes[i..]
                .iter()
                .position(|&b| b == b'<')
                .map_or(bytes.len(), |rel| i + rel);
            let parent_tag = if depth > 0 {
                Some(stack[depth - 1].tag)
            } else {
                None
            };
            if !validate_text_node(&bytes[i..text_end], parent_tag) {
                return None;
            }
            record_text_on_parent(&mut stack, depth);
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

fn decode_canonical_entities(slice: &str) -> Cow<'_, str> {
    if !slice.as_bytes().contains(&b'&') {
        return Cow::Borrowed(slice);
    }
    let bytes = slice.as_bytes();
    let mut out = String::with_capacity(slice.len());
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'&' {
            if bytes[i..].starts_with(b"&amp;") {
                out.push('&');
                i += 5;
                continue;
            } else if bytes[i..].starts_with(b"&lt;") {
                out.push('<');
                i += 4;
                continue;
            } else if bytes[i..].starts_with(b"&gt;") {
                out.push('>');
                i += 4;
                continue;
            }
        }
        out.push(bytes[i] as char);
        i += 1;
    }
    Cow::Owned(out)
}

/// Inspects a `//body/div/pre/code` element's inner HTML `[inner_start..inner_end]` when it
/// contains `"----"`. Returns `Some(Some(rewritten_inner))` if split raw tags were unescaped,
/// `Some(None)` if `codeblock.content` did not contain `RAW_TAG` or `END_RAW_TAG`, or `None`
/// if a child element has nested elements requiring Nokogiri.
fn unescape_split_raw_tags_in_code_inner(
    html: &str,
    inner_start: usize,
    inner_end: usize,
) -> Option<Option<String>> {
    #[derive(Clone, Copy)]
    struct CodeChild {
        text_start: usize,
        text_end: usize,
    }

    let bytes = html.as_bytes();
    let mut children: Vec<CodeChild> = Vec::new();
    let mut i = inner_start;

    while i < inner_end {
        if bytes[i] == b'<' {
            if bytes.get(i + 1) == Some(&b'/') {
                return None;
            }
            let parsed = parse_opening_tag(bytes, i)?;
            if !parsed.tag.is_phrasing_child() || parsed.tag == Tag::Code {
                return None;
            }
            if parsed.tag.is_void() {
                children.push(CodeChild {
                    text_start: parsed.tag_end,
                    text_end: parsed.tag_end,
                });
                i = parsed.tag_end;
            } else {
                let text_start = parsed.tag_end;
                let rel_lt = bytes[text_start..inner_end]
                    .iter()
                    .position(|&b| b == b'<')?;
                let text_end = text_start + rel_lt;
                if !validate_text_node(&bytes[text_start..text_end], Some(parsed.tag)) {
                    return None;
                }
                if bytes.get(text_end + 1) != Some(&b'/') {
                    // Nested element inside a child of <code> when "----" is present: defer to Nokogiri.
                    return None;
                }
                let (name_start, name_end, close_end) = parse_closing_tag_name(bytes, text_end)?;
                if bytes[parsed.name_start..parsed.name_end] != bytes[name_start..name_end] {
                    return None;
                }
                children.push(CodeChild {
                    text_start,
                    text_end,
                });
                i = close_end;
            }
        } else {
            let text_end = bytes[i..inner_end]
                .iter()
                .position(|&b| b == b'<')
                .map_or(inner_end, |rel| i + rel);
            if !validate_text_node(&bytes[i..text_end], Some(Tag::Code)) {
                return None;
            }
            children.push(CodeChild {
                text_start: i,
                text_end,
            });
            i = text_end;
        }
    }

    let children_content: Vec<Cow<'_, str>> = children
        .iter()
        .map(|c| decode_canonical_entities(&html[c.text_start..c.text_end]))
        .collect();

    let mut full_content = String::with_capacity(inner_end - inner_start);
    for content in &children_content {
        full_content.push_str(content);
    }

    if !full_content.contains(RAW_TAG) && !full_content.contains(END_RAW_TAG) {
        return Some(None);
    }

    let mut out = String::with_capacity(inner_end - inner_start);
    let mut last_copied = inner_start;
    for (idx, child) in children.iter().enumerate() {
        let window_end = (idx + 3).min(children_content.len());
        let matches_delimiter = children_content[idx..window_end]
            .iter()
            .any(|c| RAW_TAG_DELIMITERS.contains(&c.as_ref()));
        if matches_delimiter && html[child.text_start..child.text_end].contains('-') {
            out.push_str(&html[last_copied..child.text_start]);
            for ch in html[child.text_start..child.text_end].chars() {
                if ch != '-' {
                    out.push(ch);
                }
            }
            last_copied = child.text_end;
        }
    }
    out.push_str(&html[last_copied..inner_end]);
    Some(Some(out))
}

fn replace_literal_raw_tags(html: &str) -> Cow<'_, str> {
    if !html.contains(RAW_TAG) && !html.contains(END_RAW_TAG) {
        return Cow::Borrowed(html);
    }
    let step = html.replace(RAW_TAG, RAW_TAG_UNESCAPED);
    if step.contains(END_RAW_TAG) {
        Cow::Owned(step.replace(END_RAW_TAG, END_RAW_TAG_UNESCAPED))
    } else {
        Cow::Owned(step)
    }
}

#[inline]
fn is_valid_bare_text_for_document(text: &str) -> bool {
    let bytes = text.as_bytes();
    if bytes.is_empty()
        || bytes[0].is_ascii_whitespace()
        || text.starts_with('\u{FEFF}')
        || bytes.contains(&b'<')
    {
        return false;
    }
    validate_text_node(bytes, Some(Tag::P))
}

/// Unescapes `{----% raw %----}` and `{----% endraw %----}` markers (including markers split
/// across Rouge syntax-highlighting `<span>` children inside `//body/div/pre/code`) on
/// canonical `Nokogiri::HTML(html)` inputs, matching `Html::Parser#unescape_raw_tag_in_codeblocks`.
pub fn unescape_raw_tag_in_codeblocks(html: &str) -> Option<Cow<'_, str>> {
    if html.is_empty() || html.starts_with('\u{FEFF}') {
        return None;
    }

    let step1 = replace_literal_raw_tags(html);
    let text = step1.as_ref();
    let bytes = text.as_bytes();

    if !bytes.contains(&b'<') {
        if !is_valid_bare_text_for_document(text) {
            return None;
        }
        let mut wrapped = String::with_capacity(text.len() + 7);
        wrapped.push_str("<p>");
        wrapped.push_str(text);
        wrapped.push_str("</p>");
        return Some(Cow::Owned(wrapped));
    }

    if bytes[0] != b'<' {
        return None;
    }

    let mut stack = [Frame::EMPTY; MAX_TAG_DEPTH];
    let mut depth = 0usize;
    let mut in_code = false;
    let mut root_prev_child_was_block_elem = false;
    let mut out: Option<String> = None;
    let mut last_copied = 0usize;
    let mut i = 0usize;

    while i < bytes.len() {
        if bytes[i] == b'<' {
            if bytes.get(i + 1) == Some(&b'/') {
                let (name_start, name_end, close_end) = parse_closing_tag_name(bytes, i)?;
                if depth == 0 {
                    return None;
                }
                depth -= 1;
                let frame = stack[depth];
                if !validate_closed_frame(&frame, bytes, name_start, name_end) {
                    return None;
                }
                if frame.tag == Tag::Code {
                    in_code = false;
                    // Check `//body/div/pre/code` (`depth == 2` after popping `Code`)
                    if depth == 2
                        && stack[0].tag == Tag::Div
                        && stack[1].tag == Tag::Pre
                        && text[frame.open_tag_end..i].contains("----")
                    {
                        if let Some(rewritten) =
                            unescape_split_raw_tags_in_code_inner(text, frame.open_tag_end, i)?
                        {
                            let buf = out.get_or_insert_with(|| String::with_capacity(text.len()));
                            buf.push_str(&text[last_copied..frame.open_tag_end]);
                            buf.push_str(&rewritten);
                            last_copied = i;
                        }
                    }
                }
                i = close_end;
            } else {
                let parsed = parse_opening_tag(bytes, i)?;
                let active_stack = &stack[..depth];
                let parent_tag = active_stack.last().map(|f| f.tag);
                if !is_valid_child(parent_tag, parsed.tag, active_stack, in_code) {
                    return None;
                }
                if depth == 0 {
                    if root_prev_child_was_block_elem {
                        return None;
                    }
                    root_prev_child_was_block_elem = parsed.tag.is_libxml_non_inline();
                } else if !record_element_on_parent(&mut stack, depth, parsed.tag) {
                    return None;
                }

                if !parsed.tag.is_void() {
                    if depth >= MAX_TAG_DEPTH {
                        return None;
                    }
                    if parsed.tag == Tag::Code {
                        in_code = true;
                    }
                    stack[depth] = Frame {
                        raw_name_start: parsed.name_start,
                        raw_name_end: parsed.name_end,
                        open_tag_start: i,
                        open_tag_end: parsed.tag_end,
                        tag: parsed.tag,
                        child_count: 0,
                        first_child_is_text: false,
                        last_child_is_text: false,
                        first_child_was_block_elem: false,
                        prev_child_was_block_elem: false,
                        flag: false,
                    };
                    depth += 1;
                }
                i = parsed.tag_end;
            }
        } else {
            let text_end = bytes[i..]
                .iter()
                .position(|&b| b == b'<')
                .map_or(bytes.len(), |rel| i + rel);
            let parent_tag = if depth > 0 {
                Some(stack[depth - 1].tag)
            } else {
                None
            };
            if !validate_text_node(&bytes[i..text_end], parent_tag) {
                return None;
            }
            if depth == 0 {
                root_prev_child_was_block_elem = false;
            } else {
                record_text_on_parent(&mut stack, depth);
            }
            i = text_end;
        }
    }

    if depth != 0 {
        return None;
    }

    match out {
        None => Some(step1),
        Some(mut s) => {
            s.push_str(&text[last_copied..]);
            Some(Cow::Owned(s))
        }
    }
}

#[inline]
fn is_mention_username_byte(b: u8) -> bool {
    b.is_ascii_alphanumeric() || matches!(b, b'_' | b'-')
}

#[inline]
fn is_ascii_word_byte(b: u8) -> bool {
    b.is_ascii_alphanumeric() || b == b'_'
}

fn scan_mentions_in_text_range(
    html: &str,
    range_start: usize,
    range_end: usize,
    mut on_mention: impl FnMut(usize, usize, String),
) -> bool {
    let slice = &html.as_bytes()[range_start..range_end];
    if !slice.contains(&b'@') {
        return true;
    }

    let mut i = 0usize;
    while i < slice.len() {
        let Some(rel) = slice[i..].iter().position(|&b| b == b'@') else {
            break;
        };
        let at_pos = i + rel;
        if at_pos > 0 {
            let prev = slice[at_pos - 1];
            if prev >= 0x80 {
                // Defer non-ASCII bytes immediately preceding `@` so Ruby's Unicode `\B` decides.
                return false;
            }
            if is_ascii_word_byte(prev) {
                i = at_pos + 1;
                continue;
            }
        }

        let mut end = at_pos + 1;
        while end < slice.len() && is_mention_username_byte(slice[end]) {
            end += 1;
        }

        if end > at_pos + 1 {
            let username = html[range_start + at_pos + 1..range_start + end].to_ascii_lowercase();
            on_mention(range_start + at_pos, range_start + end, username);
            i = end;
        } else {
            i = at_pos + 1;
        }
    }
    true
}

/// Extracts unique lowercased candidate `@username` strings (in first-seen order) outside
/// `<code>` and `<a>` elements on canonical `Nokogiri::HTML(html)` inputs, matching the
/// traversal and `/\B@[a-z0-9_-]+/i` pattern in `Html::Parser#wrap_mentions_with_links`.
pub fn extract_mention_usernames(html: &str) -> Option<Vec<String>> {
    if html.is_empty() || html.starts_with('\u{FEFF}') {
        return None;
    }

    let bytes = html.as_bytes();
    let mut usernames: Vec<String> = Vec::new();

    if !bytes.contains(&b'<') {
        if !is_valid_bare_text_for_document(html) {
            return None;
        }
        if !scan_mentions_in_text_range(html, 0, html.len(), |_start, _end, username| {
            if !usernames.contains(&username) {
                usernames.push(username);
            }
        }) {
            return None;
        }
        return Some(usernames);
    }

    if bytes[0] != b'<' {
        return None;
    }

    let mut stack = [Frame::EMPTY; MAX_TAG_DEPTH];
    let mut depth = 0usize;
    let mut in_code = false;
    let mut in_a = false;
    let mut root_prev_child_was_block_elem = false;
    let mut i = 0usize;

    while i < bytes.len() {
        if bytes[i] == b'<' {
            if bytes.get(i + 1) == Some(&b'/') {
                let (name_start, name_end, close_end) = parse_closing_tag_name(bytes, i)?;
                if depth == 0 {
                    return None;
                }
                depth -= 1;
                let frame = stack[depth];
                if !validate_closed_frame(&frame, bytes, name_start, name_end) {
                    return None;
                }
                if frame.tag == Tag::Code {
                    in_code = false;
                } else if frame.tag == Tag::A {
                    in_a = false;
                }
                i = close_end;
            } else {
                let parsed = parse_opening_tag(bytes, i)?;
                let active_stack = &stack[..depth];
                let parent_tag = active_stack.last().map(|f| f.tag);
                if !is_valid_child(parent_tag, parsed.tag, active_stack, in_code) {
                    return None;
                }
                if depth == 0 {
                    if root_prev_child_was_block_elem {
                        return None;
                    }
                    root_prev_child_was_block_elem = parsed.tag.is_libxml_non_inline();
                } else if !record_element_on_parent(&mut stack, depth, parsed.tag) {
                    return None;
                }

                if !parsed.tag.is_void() {
                    if depth >= MAX_TAG_DEPTH {
                        return None;
                    }
                    if parsed.tag == Tag::Code {
                        in_code = true;
                    } else if parsed.tag == Tag::A {
                        in_a = true;
                    }
                    stack[depth] = Frame {
                        raw_name_start: parsed.name_start,
                        raw_name_end: parsed.name_end,
                        open_tag_start: i,
                        open_tag_end: parsed.tag_end,
                        tag: parsed.tag,
                        child_count: 0,
                        first_child_is_text: false,
                        last_child_is_text: false,
                        first_child_was_block_elem: false,
                        prev_child_was_block_elem: false,
                        flag: false,
                    };
                    depth += 1;
                }
                i = parsed.tag_end;
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
            if !validate_text_node(text_bytes, parent_tag) {
                return None;
            }
            if depth == 0 {
                if text_bytes.contains(&b'@') {
                    return None;
                }
                root_prev_child_was_block_elem = false;
            } else {
                record_text_on_parent(&mut stack, depth);

                if !in_code
                    && !in_a
                    && !scan_mentions_in_text_range(html, i, text_end, |_start, _end, username| {
                        if !usernames.contains(&username) {
                            usernames.push(username);
                        }
                    })
                {
                    return None;
                }
            }
            i = text_end;
        }
    }

    if depth != 0 {
        return None;
    }

    Some(usernames)
}

#[inline]
fn is_valid_base_url(base_url: &str) -> bool {
    !base_url.is_empty()
        && base_url
            .bytes()
            .all(|b| (0x21..=0x7E).contains(&b) && !matches!(b, b'"' | b'\'' | b'<' | b'>' | b'&'))
}

/// Replaces `/\B@[a-z0-9_-]+/i` mentions whose lowercased username is in `existing_usernames`
/// with `<a class="mentioned-user" href="{base_url}/{username}">@{username}</a>` outside
/// `<code>` and `<a>` elements on canonical `Nokogiri::HTML(html)` inputs, matching
/// `Html::Parser#wrap_mentions_with_links`.
pub fn wrap_mentions_with_links<'a>(
    html: &'a str,
    existing_usernames: &[String],
    base_url: &str,
) -> Option<Cow<'a, str>> {
    if html.is_empty() || html.starts_with('\u{FEFF}') || !is_valid_base_url(base_url) {
        return None;
    }

    let bytes = html.as_bytes();

    if !bytes.contains(&b'<') {
        if !is_valid_bare_text_for_document(html) {
            return None;
        }
        let mut out = String::with_capacity(html.len() + 64);
        out.push_str("<p>");
        let mut last_copied = 0usize;
        if !scan_mentions_in_text_range(html, 0, html.len(), |start, end, username| {
            if existing_usernames.iter().any(|u| u == &username) {
                out.push_str(&html[last_copied..start]);
                out.push_str("<a class=\"mentioned-user\" href=\"");
                out.push_str(base_url);
                out.push('/');
                out.push_str(&username);
                out.push_str("\">@");
                out.push_str(&username);
                out.push_str("</a>");
                last_copied = end;
            }
        }) {
            return None;
        }
        out.push_str(&html[last_copied..]);
        out.push_str("</p>");
        return Some(Cow::Owned(out));
    }

    if bytes[0] != b'<' {
        return None;
    }

    let mut stack = [Frame::EMPTY; MAX_TAG_DEPTH];
    let mut depth = 0usize;
    let mut in_code = false;
    let mut in_a = false;
    let mut root_prev_child_was_block_elem = false;
    let mut out: Option<String> = None;
    let mut last_copied = 0usize;
    let mut i = 0usize;

    while i < bytes.len() {
        if bytes[i] == b'<' {
            if bytes.get(i + 1) == Some(&b'/') {
                let (name_start, name_end, close_end) = parse_closing_tag_name(bytes, i)?;
                if depth == 0 {
                    return None;
                }
                depth -= 1;
                let frame = stack[depth];
                if !validate_closed_frame(&frame, bytes, name_start, name_end) {
                    return None;
                }
                if frame.tag == Tag::Code {
                    in_code = false;
                } else if frame.tag == Tag::A {
                    in_a = false;
                }
                i = close_end;
            } else {
                let parsed = parse_opening_tag(bytes, i)?;
                let active_stack = &stack[..depth];
                let parent_tag = active_stack.last().map(|f| f.tag);
                if !is_valid_child(parent_tag, parsed.tag, active_stack, in_code) {
                    return None;
                }
                if depth == 0 {
                    if root_prev_child_was_block_elem {
                        return None;
                    }
                    root_prev_child_was_block_elem = parsed.tag.is_libxml_non_inline();
                } else if !record_element_on_parent(&mut stack, depth, parsed.tag) {
                    return None;
                }

                if !parsed.tag.is_void() {
                    if depth >= MAX_TAG_DEPTH {
                        return None;
                    }
                    if parsed.tag == Tag::Code {
                        in_code = true;
                    } else if parsed.tag == Tag::A {
                        in_a = true;
                    }
                    stack[depth] = Frame {
                        raw_name_start: parsed.name_start,
                        raw_name_end: parsed.name_end,
                        open_tag_start: i,
                        open_tag_end: parsed.tag_end,
                        tag: parsed.tag,
                        child_count: 0,
                        first_child_is_text: false,
                        last_child_is_text: false,
                        first_child_was_block_elem: false,
                        prev_child_was_block_elem: false,
                        flag: false,
                    };
                    depth += 1;
                }
                i = parsed.tag_end;
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
            if !validate_text_node(text_bytes, parent_tag) {
                return None;
            }
            if depth == 0 {
                if text_bytes.contains(&b'@') {
                    return None;
                }
                root_prev_child_was_block_elem = false;
            } else {
                let parent_prior_children = stack[depth - 1].child_count;
                let parent_prev_child_was_block_elem = stack[depth - 1].prev_child_was_block_elem;
                let parent_is_formatted_block = parent_tag.is_some_and(Tag::is_formatted_block);
                let followed_by_closing_tag = bytes.get(text_end..text_end + 2) == Some(b"</");
                record_text_on_parent(&mut stack, depth);

                if !in_code && !in_a && text_bytes.contains(&b'@') {
                    let mut replacements: Vec<(usize, usize, String)> = Vec::new();
                    if !scan_mentions_in_text_range(html, i, text_end, |start, end, username| {
                        if existing_usernames.iter().any(|u| u == &username) {
                            replacements.push((start, end, username));
                        }
                    }) {
                        return None;
                    }
                    if !replacements.is_empty() {
                        let first_start = replacements[0].0;
                        let last_end = replacements[replacements.len() - 1].1;
                        let is_sole_single_replacement = replacements.len() == 1
                            && first_start == i
                            && last_end == text_end
                            && parent_prior_children == 0
                            && followed_by_closing_tag;
                        let needs_leading_newline = first_start == i
                            && (parent_prev_child_was_block_elem
                                || (parent_is_formatted_block
                                    && !is_sole_single_replacement
                                    && parent_prior_children == 0));
                        let needs_trailing_newline = last_end == text_end
                            && parent_is_formatted_block
                            && !is_sole_single_replacement
                            && followed_by_closing_tag;

                        let buf =
                            out.get_or_insert_with(|| String::with_capacity(html.len() + 128));
                        if needs_leading_newline {
                            buf.push_str(&html[last_copied..i]);
                            buf.push('\n');
                            last_copied = i;
                        }
                        for (start, end, username) in replacements {
                            buf.push_str(&html[last_copied..start]);
                            buf.push_str("<a class=\"mentioned-user\" href=\"");
                            buf.push_str(base_url);
                            buf.push('/');
                            buf.push_str(&username);
                            buf.push_str("\">@");
                            buf.push_str(&username);
                            buf.push_str("</a>");
                            last_copied = end;
                        }
                        if needs_trailing_newline {
                            buf.push('\n');
                        }
                    }
                }
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

#[inline]
fn is_liquid_excluded_class(class_str: &str) -> bool {
    has_class_token(class_str, "liquid-comment")
        || class_str.starts_with("ltag")
        || class_str.contains(" ltag")
}

/// Extracts lowercased `@`-stripped usernames from `.mentioned-user` elements outside
/// `.liquid-comment`, `[class^=ltag]`, and `[class*=' ltag']` ancestors, matching
/// `Mentions::CreateAll#extract_usernames_from_mentions_in_text`.
pub fn extract_mentioned_usernames(html: &str) -> Option<Vec<String>> {
    if html.is_empty() {
        return Some(Vec::new());
    }
    if !html.contains("mentioned-user") && !html.contains('&') {
        return Some(Vec::new());
    }
    if html.starts_with('\u{FEFF}') {
        return None;
    }

    let bytes = html.as_bytes();
    let mut stack = [Frame::EMPTY; MAX_TAG_DEPTH];
    let mut liquid_depth = 0usize;
    let mut depth = 0usize;
    let mut in_code = false;
    let mut usernames: Vec<String> = Vec::new();
    let mut i = 0usize;

    while i < bytes.len() {
        if bytes[i] == b'<' {
            if bytes.get(i + 1) == Some(&b'/') {
                let (name_start, name_end, close_end) = parse_closing_tag_name(bytes, i)?;
                if depth == 0 {
                    return None;
                }
                depth -= 1;
                let frame = stack[depth];
                if !validate_closed_frame(&frame, bytes, name_start, name_end) {
                    return None;
                }
                if frame.tag == Tag::Code {
                    in_code = false;
                }
                if frame.flag {
                    liquid_depth -= 1;
                }
                if frame.open_tag_start != usize::MAX {
                    let inner = &html[frame.open_tag_end..i];
                    if inner.contains('<') || inner.contains('&') {
                        return None;
                    }
                    let username: String = inner
                        .chars()
                        .filter(|&c| c != '@')
                        .flat_map(char::to_lowercase)
                        .collect();
                    usernames.push(username);
                }
                i = close_end;
            } else {
                let parsed = parse_opening_tag(bytes, i)?;
                let active_stack = &stack[..depth];
                let parent_tag = active_stack.last().map(|f| f.tag);
                if !is_valid_child(parent_tag, parsed.tag, active_stack, in_code) {
                    return None;
                }
                if !record_element_on_parent(&mut stack, depth, parsed.tag) {
                    return None;
                }
                // Disallow child elements inside `.mentioned-user`
                if stack[..depth]
                    .iter()
                    .any(|f| f.open_tag_start != usize::MAX)
                {
                    return None;
                }

                let mut is_mentioned = false;
                let mut is_liquid = false;
                if let Some((cs, ce)) = parsed.class_range {
                    let class_str = &html[cs..ce];
                    is_mentioned = has_class_token(class_str, "mentioned-user");
                    is_liquid = is_liquid_excluded_class(class_str);
                }

                if parsed.tag.is_void() {
                    if is_mentioned {
                        return None;
                    }
                } else {
                    if depth >= MAX_TAG_DEPTH {
                        return None;
                    }
                    if parsed.tag == Tag::Code {
                        in_code = true;
                    }
                    if is_liquid {
                        liquid_depth += 1;
                    }
                    let capture_mention = is_mentioned && liquid_depth == 0;
                    stack[depth] = Frame {
                        raw_name_start: parsed.name_start,
                        raw_name_end: parsed.name_end,
                        open_tag_start: if capture_mention { i } else { usize::MAX },
                        open_tag_end: parsed.tag_end,
                        tag: parsed.tag,
                        child_count: 0,
                        first_child_is_text: false,
                        last_child_is_text: false,
                        first_child_was_block_elem: false,
                        prev_child_was_block_elem: false,
                        flag: is_liquid,
                    };
                    depth += 1;
                }
                i = parsed.tag_end;
            }
        } else {
            let text_end = bytes[i..]
                .iter()
                .position(|&b| b == b'<')
                .map_or(bytes.len(), |rel| i + rel);
            let parent_tag = if depth > 0 {
                Some(stack[depth - 1].tag)
            } else {
                None
            };
            if !validate_text_node(&bytes[i..text_end], parent_tag) {
                return None;
            }
            record_text_on_parent(&mut stack, depth);
            i = text_end;
        }
    }

    if depth != 0 {
        return None;
    }

    Some(usernames)
}

#[derive(Clone, Copy, Debug)]
struct AttrSpan {
    name_start: usize,
    name_end: usize,
    val_start: usize,
    val_end: usize,
}

/// Parses attribute `(name, value)` byte ranges from an already-validated canonical opening tag.
fn parse_canonical_tag_attrs(
    bytes: &[u8],
    name_end: usize,
    tag_end: usize,
) -> ([AttrSpan; 16], usize) {
    let mut attrs = [AttrSpan {
        name_start: 0,
        name_end: 0,
        val_start: 0,
        val_end: 0,
    }; 16];
    let mut count = 0usize;
    let mut pos = name_end;

    while pos + 1 < tag_end && bytes[pos] == b' ' {
        pos += 1;
        let attr_start = pos;
        while pos < tag_end && bytes[pos] != b'=' {
            pos += 1;
        }
        let attr_end = pos;
        // Skip `="`
        pos += 2;
        let val_start = pos;
        while pos < tag_end && bytes[pos] != b'"' {
            pos += 1;
        }
        let val_end = pos;
        pos += 1;
        if count < attrs.len() {
            attrs[count] = AttrSpan {
                name_start: attr_start,
                name_end: attr_end,
                val_start,
                val_end,
            };
            count += 1;
        }
    }

    (attrs, count)
}

#[inline]
fn is_safe_uri_attr_value(val: &[u8]) -> bool {
    // `parse_opening_tag` already ensures `0x21..=0x7E` and only `&amp;`/`&lt;`/`&gt;`.
    // Reject `&lt;` / `&gt;` conservatively and permit known-safe URI prefixes or relative
    // paths with no `:` or `&`.
    let has_lt_gt_entity = val.windows(4).any(|w| w == b"&lt;" || w == b"&gt;");
    if has_lt_gt_entity {
        return false;
    }

    if val.starts_with(b"http://")
        || val.starts_with(b"https://")
        || val.starts_with(b"//")
        || val.starts_with(b"/")
        || val.starts_with(b"#")
        || val.starts_with(b"mailto:")
        || val.starts_with(b"tel:")
        || val.starts_with(b"ftp://")
    {
        return true;
    }

    !val.contains(&b':') && !val.contains(&b'&')
}

/// Validates that all `href` and `src` attributes on a canonical opening tag pass
/// `Loofah::HTML5::Scrub.scrub_uri_attribute` without modification.
fn all_uri_attrs_safe(bytes: &[u8], name_end: usize, tag_end: usize) -> bool {
    let (attrs, count) = parse_canonical_tag_attrs(bytes, name_end, tag_end);
    for span in &attrs[..count] {
        let name = &bytes[span.name_start..span.name_end];
        if (name == b"href" || name == b"src")
            && !is_safe_uri_attr_value(&bytes[span.val_start..span.val_end])
        {
            return false;
        }
    }
    true
}

/// Validates that `html` is canonical `libxml2` HTML4 markup. When `check_root_block_spacing`
/// is true, also enforces root-level block spacing rules matching `Nokogiri::HTML` `body.inner_html`.
fn is_canonical_html(html: &str, check_root_block_spacing: bool) -> bool {
    if html.is_empty() {
        return true;
    }
    if html.starts_with('\u{FEFF}') {
        return false;
    }
    let bytes = html.as_bytes();
    if check_root_block_spacing && bytes[0] != b'<' {
        return false;
    }

    let mut stack = [Frame::EMPTY; MAX_TAG_DEPTH];
    let mut depth = 0usize;
    let mut in_code = false;
    let mut root_prev_child_was_block_elem = false;
    let mut root_had_non_ws = false;
    let mut i = 0usize;

    while i < bytes.len() {
        if bytes[i] == b'<' {
            if bytes.get(i + 1) == Some(&b'/') {
                let Some((name_start, name_end, close_end)) = parse_closing_tag_name(bytes, i)
                else {
                    return false;
                };
                if depth == 0 {
                    return false;
                }
                depth -= 1;
                let frame = stack[depth];
                if !validate_closed_frame(&frame, bytes, name_start, name_end) {
                    return false;
                }
                if frame.tag == Tag::Code {
                    in_code = false;
                }
                i = close_end;
            } else {
                let Some(parsed) = parse_opening_tag(bytes, i) else {
                    return false;
                };
                let active_stack = &stack[..depth];
                let parent_tag = active_stack.last().map(|f| f.tag);
                if !is_valid_child(parent_tag, parsed.tag, active_stack, in_code) {
                    return false;
                }
                if depth == 0 {
                    if check_root_block_spacing {
                        if root_prev_child_was_block_elem
                            || (root_had_non_ws && parsed.tag.is_libxml_non_inline())
                        {
                            return false;
                        }
                        root_prev_child_was_block_elem = parsed.tag.is_libxml_non_inline();
                        root_had_non_ws = true;
                    }
                } else if !record_element_on_parent(&mut stack, depth, parsed.tag) {
                    return false;
                }

                if !parsed.tag.is_void() {
                    if depth >= MAX_TAG_DEPTH {
                        return false;
                    }
                    if parsed.tag == Tag::Code {
                        in_code = true;
                    }
                    stack[depth] = Frame {
                        raw_name_start: parsed.name_start,
                        raw_name_end: parsed.name_end,
                        open_tag_start: i,
                        open_tag_end: parsed.tag_end,
                        tag: parsed.tag,
                        child_count: 0,
                        first_child_is_text: false,
                        last_child_is_text: false,
                        first_child_was_block_elem: false,
                        prev_child_was_block_elem: false,
                        flag: false,
                    };
                    depth += 1;
                }
                i = parsed.tag_end;
            }
        } else {
            let text_end = bytes[i..]
                .iter()
                .position(|&b| b == b'<')
                .map_or(bytes.len(), |rel| i + rel);
            let parent_tag = if depth > 0 {
                Some(stack[depth - 1].tag)
            } else {
                None
            };
            if !validate_text_node(&bytes[i..text_end], parent_tag) {
                return false;
            }
            if depth == 0 {
                if check_root_block_spacing {
                    root_prev_child_was_block_elem = false;
                    root_had_non_ws = false;
                }
            } else {
                record_text_on_parent(&mut stack, depth);
            }
            i = text_end;
        }
    }

    depth == 0
}

fn build_merged_rel(existing: &str) -> String {
    let mut seen = std::collections::HashSet::with_capacity(4);
    let mut tokens: Vec<&str> = Vec::with_capacity(4);
    for tok in existing.split_ascii_whitespace() {
        if seen.insert(tok) {
            tokens.push(tok);
        }
    }
    if seen.insert("noopener") {
        tokens.push("noopener");
    }
    if seen.insert("noreferrer") {
        tokens.push("noreferrer");
    }
    tokens.join(" ")
}

/// Scrubs unsafe `href`/`src` URIs and adds `target="_blank"` + `rel="noopener noreferrer"`
/// to outbound `a[href^="http"]` links whose `href` does not include `app_domain` on canonical
/// `Nokogiri::HTML.fragment(html).to_html` inputs, matching `MarkdownProcessor::Parser#add_target_blank_to_outbound_links`.
pub fn add_target_blank_to_outbound_links<'a>(
    html: &'a str,
    app_domain: &str,
) -> Option<Cow<'a, str>> {
    if html.is_empty() {
        return Some(Cow::Borrowed(html));
    }
    if html.starts_with('\u{FEFF}')
        || app_domain.is_empty()
        || app_domain
            .bytes()
            .any(|b| b < 0x20 || matches!(b, b'<' | b'>' | b'"' | b'&'))
    {
        return None;
    }

    let bytes = html.as_bytes();
    let mut stack = [Frame::EMPTY; MAX_TAG_DEPTH];
    let mut depth = 0usize;
    let mut in_code = false;
    let mut out: Option<String> = None;
    let mut last_copied = 0usize;
    let mut i = 0usize;

    while i < bytes.len() {
        if bytes[i] == b'<' {
            if bytes.get(i + 1) == Some(&b'/') {
                let (name_start, name_end, close_end) = parse_closing_tag_name(bytes, i)?;
                if depth == 0 {
                    return None;
                }
                depth -= 1;
                let frame = stack[depth];
                if !validate_closed_frame(&frame, bytes, name_start, name_end) {
                    return None;
                }
                if frame.tag == Tag::Code {
                    in_code = false;
                }
                i = close_end;
            } else {
                let parsed = parse_opening_tag(bytes, i)?;
                let active_stack = &stack[..depth];
                let parent_tag = active_stack.last().map(|f| f.tag);
                if !is_valid_child(parent_tag, parsed.tag, active_stack, in_code) {
                    return None;
                }
                if !record_element_on_parent(&mut stack, depth, parsed.tag) {
                    return None;
                }

                if !all_uri_attrs_safe(bytes, parsed.name_end, parsed.tag_end) {
                    return None;
                }

                if parsed.tag == Tag::A {
                    let (attrs, count) =
                        parse_canonical_tag_attrs(bytes, parsed.name_end, parsed.tag_end);
                    let mut href_span: Option<AttrSpan> = None;
                    let mut target_span: Option<AttrSpan> = None;
                    let mut rel_span: Option<AttrSpan> = None;
                    for span in &attrs[..count] {
                        match &bytes[span.name_start..span.name_end] {
                            b"href" => href_span = Some(*span),
                            b"target" => target_span = Some(*span),
                            b"rel" => rel_span = Some(*span),
                            _ => {}
                        }
                    }

                    if let Some(href) = href_span {
                        let href_str = &html[href.val_start..href.val_end];
                        if href_str.starts_with("http") {
                            let decoded_href = decode_canonical_entities(href_str);
                            if !decoded_href.contains(app_domain) {
                                let target_ok = target_span
                                    .is_some_and(|t| &html[t.val_start..t.val_end] == "_blank");
                                let new_rel = match rel_span {
                                    Some(r) => {
                                        let rel_str = &html[r.val_start..r.val_end];
                                        if rel_str.contains('&') {
                                            return None;
                                        }
                                        let merged = build_merged_rel(rel_str);
                                        if merged == rel_str {
                                            None
                                        } else {
                                            Some(merged)
                                        }
                                    }
                                    None => Some("noopener noreferrer".to_string()),
                                };

                                if !target_ok || new_rel.is_some() {
                                    let buf = out.get_or_insert_with(|| {
                                        String::with_capacity(html.len() + 128)
                                    });
                                    buf.push_str(&html[last_copied..i]);
                                    buf.push_str("<a");
                                    for span in &attrs[..count] {
                                        let name = &bytes[span.name_start..span.name_end];
                                        if name == b"target" {
                                            buf.push_str(" target=\"_blank\"");
                                        } else if name == b"rel" {
                                            if let Some(ref rel_val) = new_rel {
                                                buf.push_str(" rel=\"");
                                                buf.push_str(rel_val);
                                                buf.push('"');
                                            } else {
                                                buf.push(' ');
                                                buf.push_str(&html[span.name_start..span.val_end]);
                                                buf.push('"');
                                            }
                                        } else {
                                            buf.push(' ');
                                            buf.push_str(&html[span.name_start..span.val_end]);
                                            buf.push('"');
                                        }
                                    }
                                    if target_span.is_none() {
                                        buf.push_str(" target=\"_blank\"");
                                    }
                                    if rel_span.is_none() {
                                        buf.push_str(" rel=\"noopener noreferrer\"");
                                    }
                                    buf.push('>');
                                    last_copied = parsed.tag_end;
                                }
                            }
                        }
                    }
                }

                if !parsed.tag.is_void() {
                    if depth >= MAX_TAG_DEPTH {
                        return None;
                    }
                    if parsed.tag == Tag::Code {
                        in_code = true;
                    }
                    stack[depth] = Frame {
                        raw_name_start: parsed.name_start,
                        raw_name_end: parsed.name_end,
                        open_tag_start: i,
                        open_tag_end: parsed.tag_end,
                        tag: parsed.tag,
                        child_count: 0,
                        first_child_is_text: false,
                        last_child_is_text: false,
                        first_child_was_block_elem: false,
                        prev_child_was_block_elem: false,
                        flag: false,
                    };
                    depth += 1;
                }
                i = parsed.tag_end;
            }
        } else {
            let text_end = bytes[i..]
                .iter()
                .position(|&b| b == b'<')
                .map_or(bytes.len(), |rel| i + rel);
            let parent_tag = if depth > 0 {
                Some(stack[depth - 1].tag)
            } else {
                None
            };
            if !validate_text_node(&bytes[i..text_end], parent_tag) {
                return None;
            }
            record_text_on_parent(&mut stack, depth);
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

/// Removes `<br>` elements whose immediate parent is `ul`, `ol`, or `li` on canonical
/// `Nokogiri::HTML.fragment(html).to_html` inputs, returning `Cow::Borrowed` when none exist.
pub fn remove_nested_linebreak_in_list_fragment(html: &str) -> Option<Cow<'_, str>> {
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
    let mut i = 0usize;

    while i < bytes.len() {
        if bytes[i] == b'<' {
            if bytes.get(i + 1) == Some(&b'/') {
                let (name_start, name_end, close_end) = parse_closing_tag_name(bytes, i)?;
                if depth == 0 {
                    return None;
                }
                depth -= 1;
                let frame = stack[depth];
                if !validate_closed_frame(&frame, bytes, name_start, name_end) {
                    return None;
                }
                if frame.tag == Tag::Li && frame.flag && frame.child_count == 0 {
                    // Removing the sole `<br>` leaves an empty `<li>` which libxml2 omits `</li>` for.
                    return None;
                }
                if frame.tag == Tag::Code {
                    in_code = false;
                }
                i = close_end;
            } else {
                let parsed = parse_opening_tag(bytes, i)?;
                let active_stack = &stack[..depth];
                let parent_tag = active_stack.last().map(|f| f.tag);
                if !is_valid_child(parent_tag, parsed.tag, active_stack, in_code) {
                    return None;
                }

                if parsed.tag == Tag::Br && matches!(parent_tag, Some(Tag::Ul | Tag::Ol | Tag::Li))
                {
                    if depth == 0 || stack[depth - 1].prev_child_was_block_elem {
                        return None;
                    }
                    stack[depth - 1].flag = true;
                    let buf = out.get_or_insert_with(|| String::with_capacity(html.len()));
                    buf.push_str(&html[last_copied..i]);
                    last_copied = parsed.tag_end;
                    i = parsed.tag_end;
                    continue;
                }

                if !record_element_on_parent(&mut stack, depth, parsed.tag) {
                    return None;
                }

                if !parsed.tag.is_void() {
                    if depth >= MAX_TAG_DEPTH {
                        return None;
                    }
                    if parsed.tag == Tag::Code {
                        in_code = true;
                    }
                    stack[depth] = Frame {
                        raw_name_start: parsed.name_start,
                        raw_name_end: parsed.name_end,
                        open_tag_start: i,
                        open_tag_end: parsed.tag_end,
                        tag: parsed.tag,
                        child_count: 0,
                        first_child_is_text: false,
                        last_child_is_text: false,
                        first_child_was_block_elem: false,
                        prev_child_was_block_elem: false,
                        flag: false,
                    };
                    depth += 1;
                }
                i = parsed.tag_end;
            }
        } else {
            let text_end = bytes[i..]
                .iter()
                .position(|&b| b == b'<')
                .map_or(bytes.len(), |rel| i + rel);
            let parent_tag = if depth > 0 {
                Some(stack[depth - 1].tag)
            } else {
                None
            };
            if !validate_text_node(&bytes[i..text_end], parent_tag) {
                return None;
            }
            record_text_on_parent(&mut stack, depth);
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

/// Enforces GIF-like attributes (`data-gif-video="true"`, `autoplay`, `loop`, `muted`,
/// `playsinline`, `preload`) on `<video>` elements on canonical `Nokogiri::HTML.fragment(html).to_html`
/// inputs, matching `Html::Parser#enforce_gif_like_videos`.
pub fn enforce_gif_like_videos(html: &str) -> Option<Cow<'_, str>> {
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
    let mut i = 0usize;

    while i < bytes.len() {
        if bytes[i] == b'<' {
            if bytes.get(i + 1) == Some(&b'/') {
                let (name_start, name_end, close_end) = parse_closing_tag_name(bytes, i)?;
                if depth == 0 {
                    return None;
                }
                depth -= 1;
                let frame = stack[depth];
                if !validate_closed_frame(&frame, bytes, name_start, name_end) {
                    return None;
                }
                if frame.tag == Tag::Code {
                    in_code = false;
                }
                i = close_end;
            } else {
                let parsed = parse_opening_tag(bytes, i)?;
                let active_stack = &stack[..depth];
                let parent_tag = active_stack.last().map(|f| f.tag);
                if !is_valid_child(parent_tag, parsed.tag, active_stack, in_code) {
                    return None;
                }
                if !record_element_on_parent(&mut stack, depth, parsed.tag) {
                    return None;
                }

                if parsed.tag == Tag::Video {
                    let (attrs, count) =
                        parse_canonical_tag_attrs(bytes, parsed.name_end, parsed.tag_end);
                    let mut has_data_gif = false;
                    let mut data_gif_is_true = false;
                    let mut has_autoplay = false;
                    let mut has_loop = false;
                    let mut has_muted = false;
                    let mut has_playsinline = false;
                    let mut has_preload = false;
                    for span in &attrs[..count] {
                        match &bytes[span.name_start..span.name_end] {
                            b"data-gif-video" => {
                                has_data_gif = true;
                                data_gif_is_true = &bytes[span.val_start..span.val_end] == b"true";
                            }
                            b"autoplay" => has_autoplay = true,
                            b"loop" => has_loop = true,
                            b"muted" => has_muted = true,
                            b"playsinline" => has_playsinline = true,
                            b"preload" => has_preload = true,
                            _ => {}
                        }
                    }

                    if !(data_gif_is_true
                        && has_autoplay
                        && has_loop
                        && has_muted
                        && has_playsinline
                        && has_preload)
                    {
                        let buf =
                            out.get_or_insert_with(|| String::with_capacity(html.len() + 128));
                        buf.push_str(&html[last_copied..i]);
                        buf.push_str("<video");
                        for span in &attrs[..count] {
                            let name = &bytes[span.name_start..span.name_end];
                            if name == b"data-gif-video" {
                                buf.push_str(" data-gif-video=\"true\"");
                            } else {
                                buf.push(' ');
                                buf.push_str(&html[span.name_start..span.val_end]);
                                buf.push('"');
                            }
                        }
                        if !has_data_gif {
                            buf.push_str(" data-gif-video=\"true\"");
                        }
                        if !has_autoplay {
                            buf.push_str(" autoplay=\"autoplay\"");
                        }
                        if !has_loop {
                            buf.push_str(" loop=\"loop\"");
                        }
                        if !has_muted {
                            buf.push_str(" muted=\"muted\"");
                        }
                        if !has_playsinline {
                            buf.push_str(" playsinline=\"playsinline\"");
                        }
                        if !has_preload {
                            buf.push_str(" preload=\"metadata\"");
                        }
                        buf.push('>');
                        last_copied = parsed.tag_end;
                    }
                }

                if !parsed.tag.is_void() {
                    if depth >= MAX_TAG_DEPTH {
                        return None;
                    }
                    if parsed.tag == Tag::Code {
                        in_code = true;
                    }
                    stack[depth] = Frame {
                        raw_name_start: parsed.name_start,
                        raw_name_end: parsed.name_end,
                        open_tag_start: i,
                        open_tag_end: parsed.tag_end,
                        tag: parsed.tag,
                        child_count: 0,
                        first_child_is_text: false,
                        last_child_is_text: false,
                        first_child_was_block_elem: false,
                        prev_child_was_block_elem: false,
                        flag: false,
                    };
                    depth += 1;
                }
                i = parsed.tag_end;
            }
        } else {
            let text_end = bytes[i..]
                .iter()
                .position(|&b| b == b'<')
                .map_or(bytes.len(), |rel| i + rel);
            let parent_tag = if depth > 0 {
                Some(stack[depth - 1].tag)
            } else {
                None
            };
            if !validate_text_node(&bytes[i..text_end], parent_tag) {
                return None;
            }
            record_text_on_parent(&mut stack, depth);
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

#[inline]
fn is_valid_fullscreen_action_html(action_html: &str) -> bool {
    action_html.starts_with('<')
        && action_html.ends_with('\n')
        && is_canonical_html(action_html, false)
}

/// Inserts `action_html` into every `div.highlight__panel` element on canonical
/// `Nokogiri::HTML.fragment(html).to_html` inputs, matching `Html::Parser#add_fullscreen_button_to_panel`.
pub fn add_fullscreen_button_to_panel<'a>(
    html: &'a str,
    action_html: &str,
) -> Option<Cow<'a, str>> {
    if html.is_empty() {
        return Some(Cow::Borrowed(html));
    }
    if html.starts_with('\u{FEFF}') || !is_valid_fullscreen_action_html(action_html) {
        return None;
    }

    let bytes = html.as_bytes();
    let mut stack = [Frame::EMPTY; MAX_TAG_DEPTH];
    let mut depth = 0usize;
    let mut in_code = false;
    let mut out: Option<String> = None;
    let mut last_copied = 0usize;
    let mut i = 0usize;

    while i < bytes.len() {
        if bytes[i] == b'<' {
            if bytes.get(i + 1) == Some(&b'/') {
                let (name_start, name_end, close_end) = parse_closing_tag_name(bytes, i)?;
                if depth == 0 {
                    return None;
                }
                depth -= 1;
                let frame = stack[depth];
                if !validate_closed_frame(&frame, bytes, name_start, name_end) {
                    return None;
                }
                if frame.tag == Tag::Code {
                    in_code = false;
                }
                if frame.flag {
                    let buf = out.get_or_insert_with(|| {
                        String::with_capacity(html.len() + action_html.len() + 32)
                    });
                    match frame.child_count {
                        0 => {
                            buf.push_str(&html[last_copied..frame.open_tag_end]);
                            buf.push('\n');
                            buf.push_str(action_html);
                            last_copied = i;
                        }
                        1 if frame.first_child_is_text => {
                            buf.push_str(&html[last_copied..i]);
                            buf.push_str(action_html);
                            last_copied = i;
                        }
                        1 => {
                            buf.push_str(&html[last_copied..frame.open_tag_end]);
                            buf.push('\n');
                            buf.push_str(&html[frame.open_tag_end..i]);
                            if frame.first_child_was_block_elem {
                                buf.push('\n');
                            }
                            buf.push_str(action_html);
                            last_copied = i;
                        }
                        _ => return None,
                    }
                }
                i = close_end;
            } else {
                let parsed = parse_opening_tag(bytes, i)?;
                let active_stack = &stack[..depth];
                let parent_tag = active_stack.last().map(|f| f.tag);
                if !is_valid_child(parent_tag, parsed.tag, active_stack, in_code) {
                    return None;
                }
                if !record_element_on_parent(&mut stack, depth, parsed.tag) {
                    return None;
                }

                let mut is_panel_div = false;
                if parsed.tag == Tag::Div {
                    if let Some((cs, ce)) = parsed.class_range {
                        if has_class_token(&html[cs..ce], "highlight__panel") {
                            if stack[..depth].iter().any(|f| f.flag) {
                                return None;
                            }
                            is_panel_div = true;
                        }
                    }
                }

                if !parsed.tag.is_void() {
                    if depth >= MAX_TAG_DEPTH {
                        return None;
                    }
                    if parsed.tag == Tag::Code {
                        in_code = true;
                    }
                    stack[depth] = Frame {
                        raw_name_start: parsed.name_start,
                        raw_name_end: parsed.name_end,
                        open_tag_start: i,
                        open_tag_end: parsed.tag_end,
                        tag: parsed.tag,
                        child_count: 0,
                        first_child_is_text: false,
                        last_child_is_text: false,
                        first_child_was_block_elem: false,
                        prev_child_was_block_elem: false,
                        flag: is_panel_div,
                    };
                    depth += 1;
                }
                i = parsed.tag_end;
            }
        } else {
            let text_end = bytes[i..]
                .iter()
                .position(|&b| b == b'<')
                .map_or(bytes.len(), |rel| i + rel);
            let parent_tag = if depth > 0 {
                Some(stack[depth - 1].tag)
            } else {
                None
            };
            if !validate_text_node(&bytes[i..text_end], parent_tag) {
                return None;
            }
            record_text_on_parent(&mut stack, depth);
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

/// Fuses `add_control_class_to_codeblock`, `add_control_panel_to_codeblock`, and
/// `add_fullscreen_button_to_panel` into a single pass when no `highlight__panel` already exists.
fn apply_codeblock_enhancements<'a>(
    html: &'a str,
    fullscreen_action_html: &str,
) -> Option<Cow<'a, str>> {
    const PANEL_OPEN: &str = "<div class=\"highlight__panel js-actions-panel\">\n";
    const PANEL_CLOSE: &str = "</div>";

    if html.is_empty() {
        return Some(Cow::Borrowed(html));
    }
    if html.starts_with('\u{FEFF}') || !is_valid_fullscreen_action_html(fullscreen_action_html) {
        return None;
    }
    if html.contains("highlight__panel") {
        let step1 = add_control_class_to_codeblock(html)?;
        let step2 = add_control_panel_to_codeblock(step1.as_ref())?;
        return match add_fullscreen_button_to_panel(step2.as_ref(), fullscreen_action_html)? {
            Cow::Borrowed(_) => match step2 {
                Cow::Borrowed(_) => Some(step1),
                Cow::Owned(s) => Some(Cow::Owned(s)),
            },
            Cow::Owned(s) => Some(Cow::Owned(s)),
        };
    }

    let bytes = html.as_bytes();
    let mut stack = [Frame::EMPTY; MAX_TAG_DEPTH];
    let mut depth = 0usize;
    let mut in_code = false;
    let mut out: Option<String> = None;
    let mut last_copied = 0usize;
    let mut i = 0usize;

    while i < bytes.len() {
        if bytes[i] == b'<' {
            if bytes.get(i + 1) == Some(&b'/') {
                let (name_start, name_end, close_end) = parse_closing_tag_name(bytes, i)?;
                if depth == 0 {
                    return None;
                }
                depth -= 1;
                let frame = stack[depth];
                if !validate_closed_frame(&frame, bytes, name_start, name_end) {
                    return None;
                }
                if frame.tag == Tag::Code {
                    in_code = false;
                }
                if frame.flag {
                    let buf = out.get_or_insert_with(|| {
                        String::with_capacity(html.len() + fullscreen_action_html.len() + 128)
                    });
                    match frame.child_count {
                        0 => {
                            buf.push_str(&html[last_copied..i]);
                            buf.push_str(PANEL_OPEN);
                            buf.push_str(fullscreen_action_html);
                            buf.push_str(PANEL_CLOSE);
                            last_copied = i;
                        }
                        1 if frame.first_child_is_text => {
                            buf.push_str(&html[last_copied..i]);
                            buf.push_str(PANEL_OPEN);
                            buf.push_str(fullscreen_action_html);
                            buf.push_str(PANEL_CLOSE);
                            buf.push('\n');
                            last_copied = i;
                        }
                        1 => {
                            buf.push_str(&html[last_copied..frame.open_tag_end]);
                            buf.push('\n');
                            buf.push_str(&html[frame.open_tag_end..i]);
                            if frame.first_child_was_block_elem {
                                buf.push('\n');
                            }
                            buf.push_str(PANEL_OPEN);
                            buf.push_str(fullscreen_action_html);
                            buf.push_str(PANEL_CLOSE);
                            buf.push('\n');
                            last_copied = i;
                        }
                        _ if frame.last_child_is_text && i > 0 && bytes[i - 1] == b'\n' => {
                            buf.push_str(&html[last_copied..i]);
                            buf.push_str(PANEL_OPEN);
                            buf.push_str(fullscreen_action_html);
                            buf.push_str(PANEL_CLOSE);
                            buf.push('\n');
                            last_copied = i;
                        }
                        _ => return None,
                    }
                }
                i = close_end;
            } else {
                let parsed = parse_opening_tag(bytes, i)?;
                let active_stack = &stack[..depth];
                let parent_tag = active_stack.last().map(|f| f.tag);
                if !is_valid_child(parent_tag, parsed.tag, active_stack, in_code) {
                    return None;
                }
                if !record_element_on_parent(&mut stack, depth, parsed.tag) {
                    return None;
                }

                let mut is_highlight_div = false;
                if parsed.tag == Tag::Div {
                    if let Some((cs, ce)) = parsed.class_range {
                        let class_str = &html[cs..ce];
                        if has_class_token(class_str, "highlight") {
                            if stack[..depth].iter().any(|f| f.flag) {
                                return None;
                            }
                            if !is_canonical_class_whitespace(class_str) {
                                return None;
                            }
                            is_highlight_div = true;
                            if !has_class_token(class_str, "js-code-highlight") {
                                let buf = out.get_or_insert_with(|| {
                                    String::with_capacity(
                                        html.len() + fullscreen_action_html.len() + 128,
                                    )
                                });
                                buf.push_str(&html[last_copied..ce]);
                                buf.push_str(" js-code-highlight");
                                last_copied = ce;
                            }
                        }
                    }
                }

                if !parsed.tag.is_void() {
                    if depth >= MAX_TAG_DEPTH {
                        return None;
                    }
                    if parsed.tag == Tag::Code {
                        in_code = true;
                    }
                    stack[depth] = Frame {
                        raw_name_start: parsed.name_start,
                        raw_name_end: parsed.name_end,
                        open_tag_start: i,
                        open_tag_end: parsed.tag_end,
                        tag: parsed.tag,
                        child_count: 0,
                        first_child_is_text: false,
                        last_child_is_text: false,
                        first_child_was_block_elem: false,
                        prev_child_was_block_elem: false,
                        flag: is_highlight_div,
                    };
                    depth += 1;
                }
                i = parsed.tag_end;
            }
        } else {
            let text_end = bytes[i..]
                .iter()
                .position(|&b| b == b'<')
                .map_or(bytes.len(), |rel| i + rel);
            let parent_tag = if depth > 0 {
                Some(stack[depth - 1].tag)
            } else {
                None
            };
            if !validate_text_node(&bytes[i..text_end], parent_tag) {
                return None;
            }
            record_text_on_parent(&mut stack, depth);
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

/// Tier 2 single-FFI HTML post-processing pipeline combining outbound link tagging/scrubbing,
/// list `<br>` removal, image link wrapping, GIF-like `<video>` normalization, fused codeblock
/// control class/panel/fullscreen-button insertion, table wrapping, empty `<p>` pruning,
/// colon-emoji replacement, split `{----% raw %----}` unescaping, `@mention` linking, and
/// optional `Nokogiri::HTML` `body.inner_html` newline normalization.
/// Configuration for `prefix_all_images`, mirroring `Html::Parser#prefix_all_images` in
/// Cloudflare or passthrough mode (when `synchronous_detail_detection` is `false` and neither
/// `imgproxy` nor `cloudinary` is active).
#[derive(Clone, Copy, Debug)]
pub struct PrefixImagesConfig<'a> {
    pub width: &'a str,
    pub app_host: Option<&'a str>,
    pub asset_host: Option<&'a str>,
    pub cloudflare_domain: Option<&'a str>,
    pub cloudflare_directory: &'a str,
}

#[derive(Clone, Copy, Debug)]
struct SimpleImageUri<'a> {
    is_root_relative: bool,
    scheme: Option<&'a str>,
    host: Option<&'a str>,
    port: Option<u16>,
    path: &'a str,
    has_query: bool,
    has_fragment: bool,
}

#[inline]
fn is_valid_rfc3986_uri_byte(b: u8) -> bool {
    matches!(
        b,
        b'A'..=b'Z'
            | b'a'..=b'z'
            | b'0'..=b'9'
            | b'-'
            | b'.'
            | b'_'
            | b'~'
            | b':'
            | b'/'
            | b'?'
            | b'#'
            | b'@'
            | b'!'
            | b'$'
            | b'&'
            | b'\''
            | b'('
            | b')'
            | b'*'
            | b'+'
            | b','
            | b';'
            | b'='
            | b'%'
    )
}

fn parse_simple_image_uri(src: &str) -> Option<SimpleImageUri<'_>> {
    let bytes = src.as_bytes();
    if bytes.is_empty() {
        return None;
    }

    // Validate RFC 3986 ASCII characters and well-formed `%XX` escapes so invalid URIs
    // defer to Ruby's `URI(src)` (which raises `URI::InvalidURIError`).
    let mut i = 0usize;
    let mut seen_fragment = false;
    while i < bytes.len() {
        let b = bytes[i];
        if !is_valid_rfc3986_uri_byte(b) {
            return None;
        }
        if b == b'#' {
            if seen_fragment {
                return None;
            }
            seen_fragment = true;
        }
        if b == b'%' {
            let h1 = *bytes.get(i + 1)?;
            let h2 = *bytes.get(i + 2)?;
            if !h1.is_ascii_hexdigit() || !h2.is_ascii_hexdigit() {
                return None;
            }
            i += 3;
            continue;
        }
        i += 1;
    }

    // Root-relative path (e.g. `/assets/foo.png`, but NOT protocol-relative `//host/...`).
    if bytes[0] == b'/' {
        if bytes.get(1) == Some(&b'/') {
            return None;
        }
        let path_end = bytes
            .iter()
            .position(|&b| b == b'?' || b == b'#')
            .unwrap_or(bytes.len());
        return Some(SimpleImageUri {
            is_root_relative: true,
            scheme: None,
            host: None,
            port: None,
            path: &src[..path_end],
            has_query: bytes.contains(&b'?'),
            has_fragment: bytes.contains(&b'#'),
        });
    }

    let (scheme, rest) = if let Some(rest) = src.strip_prefix("https://") {
        ("https", rest)
    } else {
        ("http", src.strip_prefix("http://")?)
    };

    let rest_bytes = rest.as_bytes();
    let auth_end = rest_bytes
        .iter()
        .position(|&b| b == b'/' || b == b'?' || b == b'#')
        .unwrap_or(rest_bytes.len());
    let authority = &rest[..auth_end];
    if authority.is_empty() || authority.as_bytes().contains(&b'@') {
        return None;
    }

    let (host, port) = if let Some(colon) = authority.find(':') {
        let h = &authority[..colon];
        let p_str = &authority[colon + 1..];
        if h.is_empty() || p_str.is_empty() || !p_str.bytes().all(|b| b.is_ascii_digit()) {
            return None;
        }
        let p = p_str.parse::<u16>().ok()?;
        (h, Some(p))
    } else {
        (authority, None)
    };

    if !host
        .bytes()
        .all(|b| b.is_ascii_alphanumeric() || b == b'.' || b == b'-')
    {
        return None;
    }

    let after_auth = &rest[auth_end..];
    let after_bytes = after_auth.as_bytes();
    let path_end = after_bytes
        .iter()
        .position(|&b| b == b'?' || b == b'#')
        .unwrap_or(after_bytes.len());
    let path = &after_auth[..path_end];
    let tail = &after_auth[path_end..];
    let has_fragment = tail.as_bytes().contains(&b'#');
    let has_query = tail.starts_with('?');

    Some(SimpleImageUri {
        is_root_relative: false,
        scheme: Some(scheme),
        host: Some(host),
        port,
        path,
        has_query,
        has_fragment,
    })
}

#[inline]
fn file_basename(path: &str) -> &str {
    let trimmed = path.trim_end_matches('/');
    if trimmed.is_empty() {
        return if path.is_empty() { "" } else { "/" };
    }
    match trimmed.rfind('/') {
        Some(idx) => &trimmed[idx + 1..],
        None => trimmed,
    }
}

#[inline]
fn is_allowed_image_host(
    uri: &SimpleImageUri<'_>,
    app_host: Option<&str>,
    asset_host: Option<&str>,
) -> bool {
    if uri.is_root_relative {
        return true;
    }
    if let Some(host) = uri.host {
        if app_host.is_some_and(|h| !h.is_empty() && host == h) {
            return true;
        }
        if asset_host.is_some_and(|h| !h.is_empty() && host == h) {
            return true;
        }
        if uri.scheme == Some("https") && host == "camo.githubusercontent.com" {
            return true;
        }
        if uri.scheme == Some("https")
            && host == "github.com"
            && file_basename(uri.path) == "badge.svg"
        {
            return true;
        }
    }
    false
}

#[inline]
fn is_valid_giphy_image_url(uri: &SimpleImageUri<'_>) -> bool {
    uri.scheme == Some("https")
        && !uri.has_query
        && !uri.has_fragment
        && (uri.port.is_none() || uri.port == Some(443))
        && matches!(uri.host, Some("media.giphy.com" | "i.giphy.com"))
        && uri.path.ends_with(".gif")
}

fn push_html4_attr_escaped(out: &mut String, val: &str) {
    for b in val.bytes() {
        match b {
            b'&' => out.push_str("&amp;"),
            b'"' => out.push_str("&quot;"),
            b'<' => out.push_str("&lt;"),
            b'>' => out.push_str("&gt;"),
            _ => out.push(b as char),
        }
    }
}

fn push_html4_text_escaped(out: &mut String, val: &str) {
    for ch in val.chars() {
        match ch {
            '&' => out.push_str("&amp;"),
            '<' => out.push_str("&lt;"),
            '>' => out.push_str("&gt;"),
            _ => out.push(ch),
        }
    }
}

/// Rewrites `<img>` `src` attributes (Cloudflare Images / Giphy / passthrough) and sets
/// `loading="lazy"` on canonical `Nokogiri::HTML.fragment(html).to_html` inputs, matching
/// `Html::Parser#prefix_all_images` when `synchronous_detail_detection` is `false`.
pub fn prefix_all_images<'a>(
    html: &'a str,
    config: &PrefixImagesConfig<'_>,
) -> Option<Cow<'a, str>> {
    if html.is_empty() {
        return Some(Cow::Borrowed(html));
    }
    if html.starts_with('\u{FEFF}') {
        return None;
    }
    if let Some(domain) = config.cloudflare_domain {
        if domain.is_empty() {
            return None;
        }
    }

    let bytes = html.as_bytes();
    let mut stack = [Frame::EMPTY; MAX_TAG_DEPTH];
    let mut depth = 0usize;
    let mut in_code = false;
    let mut out: Option<String> = None;
    let mut last_copied = 0usize;
    let mut i = 0usize;

    while i < bytes.len() {
        if bytes[i] == b'<' {
            if bytes.get(i + 1) == Some(&b'/') {
                let (name_start, name_end, close_end) = parse_closing_tag_name(bytes, i)?;
                if depth == 0 {
                    return None;
                }
                depth -= 1;
                let frame = stack[depth];
                if !validate_closed_frame(&frame, bytes, name_start, name_end) {
                    return None;
                }
                if frame.tag == Tag::Code {
                    in_code = false;
                }
                i = close_end;
            } else {
                let parsed = parse_opening_tag(bytes, i)?;
                let active_stack = &stack[..depth];
                let parent_tag = active_stack.last().map(|f| f.tag);
                if !is_valid_child(parent_tag, parsed.tag, active_stack, in_code) {
                    return None;
                }
                if !record_element_on_parent(&mut stack, depth, parsed.tag) {
                    return None;
                }

                if parsed.tag == Tag::Img {
                    let (attrs, count) =
                        parse_canonical_tag_attrs(bytes, parsed.name_end, parsed.tag_end);
                    if count >= attrs.len() {
                        return None;
                    }
                    let mut src_span: Option<AttrSpan> = None;
                    let mut loading_span: Option<AttrSpan> = None;
                    let mut ignore_prefix = false;
                    for span in &attrs[..count] {
                        match &bytes[span.name_start..span.name_end] {
                            b"src" => src_span = Some(*span),
                            b"loading" => loading_span = Some(*span),
                            b"data-ignore-prefix"
                                if &html[span.val_start..span.val_end] == "true" =>
                            {
                                ignore_prefix = true;
                            }
                            _ => {}
                        }
                    }

                    if let Some(src) = src_span {
                        let raw_src = &html[src.val_start..src.val_end];
                        if !raw_src.is_ascii() {
                            return None;
                        }
                        let decoded_src = decode_canonical_entities(raw_src);
                        let parsed_uri = parse_simple_image_uri(decoded_src.as_ref())?;

                        if !ignore_prefix
                            && !is_allowed_image_host(
                                &parsed_uri,
                                config.app_host,
                                config.asset_host,
                            )
                        {
                            let new_src: String = if is_valid_giphy_image_url(&parsed_uri) {
                                decoded_src.replace("https://media.", "https://i.")
                            } else if decoded_src.contains("/agent_sessions/") {
                                decoded_src.replace(',', "%2C")
                            } else if let Some(cf_domain) = config.cloudflare_domain {
                                // Defer already-prefixed Cloudflare URLs to Ruby's
                                // `extract_suffix_url`.
                                if let Some(after_https) = decoded_src.strip_prefix("https://") {
                                    if let Some(after_dom) = after_https.strip_prefix(cf_domain) {
                                        if let Some(after_slash) = after_dom.strip_prefix('/') {
                                            if let Some(after_dir) = after_slash
                                                .strip_prefix(config.cloudflare_directory)
                                            {
                                                if after_dir.starts_with("/image") {
                                                    return None;
                                                }
                                            }
                                        }
                                    }
                                }
                                let cf_url = crate::image::cloudflare_image_url(
                                    cf_domain,
                                    config.cloudflare_directory,
                                    config.width,
                                    "",
                                    "scale-down",
                                    decoded_src.as_ref(),
                                    decoded_src.as_ref(),
                                )?;
                                cf_url.replace(',', "%2C")
                            } else {
                                decoded_src.replace(',', "%2C")
                            };

                            let mut encoded_new_src = String::with_capacity(new_src.len() + 8);
                            push_html4_attr_escaped(&mut encoded_new_src, &new_src);
                            let loading_ok = loading_span
                                .is_some_and(|l| &html[l.val_start..l.val_end] == "lazy");

                            if encoded_new_src != raw_src || !loading_ok {
                                let buf = out
                                    .get_or_insert_with(|| String::with_capacity(html.len() + 128));
                                buf.push_str(&html[last_copied..i]);
                                buf.push_str("<img");
                                for span in &attrs[..count] {
                                    match &bytes[span.name_start..span.name_end] {
                                        b"src" => {
                                            buf.push_str(" src=\"");
                                            buf.push_str(&encoded_new_src);
                                            buf.push('"');
                                        }
                                        b"loading" => {
                                            buf.push_str(" loading=\"lazy\"");
                                        }
                                        _ => {
                                            buf.push(' ');
                                            buf.push_str(&html[span.name_start..span.name_end]);
                                            buf.push_str("=\"");
                                            buf.push_str(&html[span.val_start..span.val_end]);
                                            buf.push('"');
                                        }
                                    }
                                }
                                if loading_span.is_none() {
                                    buf.push_str(" loading=\"lazy\"");
                                }
                                buf.push('>');
                                last_copied = parsed.tag_end;
                            }
                        }
                    }
                }

                if !parsed.tag.is_void() {
                    if depth >= MAX_TAG_DEPTH {
                        return None;
                    }
                    if parsed.tag == Tag::Code {
                        in_code = true;
                    }
                    stack[depth] = Frame {
                        raw_name_start: parsed.name_start,
                        raw_name_end: parsed.name_end,
                        open_tag_start: i,
                        open_tag_end: parsed.tag_end,
                        tag: parsed.tag,
                        child_count: 0,
                        first_child_is_text: false,
                        last_child_is_text: false,
                        first_child_was_block_elem: false,
                        prev_child_was_block_elem: false,
                        flag: false,
                    };
                    depth += 1;
                }
                i = parsed.tag_end;
            }
        } else {
            let text_start = i;
            while i < bytes.len() && bytes[i] != b'<' {
                i += 1;
            }
            let parent_tag = if depth > 0 {
                Some(stack[depth - 1].tag)
            } else {
                None
            };
            if !validate_text_node(&bytes[text_start..i], parent_tag) {
                return None;
            }
            record_text_on_parent(&mut stack, depth);
        }
    }

    if depth != 0 {
        return None;
    }

    match out {
        None => Some(Cow::Borrowed(html)),
        Some(mut buf) => {
            buf.push_str(&html[last_copied..]);
            Some(Cow::Owned(buf))
        }
    }
}

const ALERT_TYPE_NAMES: [&str; 5] = ["note", "tip", "important", "warning", "caution"];

#[inline]
fn is_ruby_ascii_ws(b: u8) -> bool {
    matches!(b, b' ' | b'\t' | b'\n' | b'\r' | 0x0b | 0x0c)
}

/// Matches `\A\[!(note|tip|important|warning|caution)\](?=\s|\z)\s*` (case-insensitive) on
/// leading paragraph text. Returns `Some(Some((alert_idx, consumed_len)))` on match,
/// `Some(None)` on definitive non-match, or `None` if an ambiguous character (like non-ASCII
/// whitespace after `]`) requires Ruby.
fn match_alert_token(text: &str) -> Option<Option<(usize, usize)>> {
    let bytes = text.as_bytes();
    if bytes.len() < 6 || bytes[0] != b'[' || bytes[1] != b'!' {
        return Some(None);
    }
    let close_bracket = match bytes[2..bytes.len().min(12)]
        .iter()
        .position(|&b| b == b']')
    {
        Some(rel) => 2 + rel,
        None => return Some(None),
    };
    let word = &bytes[2..close_bracket];
    let alert_idx = if word.eq_ignore_ascii_case(b"note") {
        0
    } else if word.eq_ignore_ascii_case(b"tip") {
        1
    } else if word.eq_ignore_ascii_case(b"important") {
        2
    } else if word.eq_ignore_ascii_case(b"warning") {
        3
    } else if word.eq_ignore_ascii_case(b"caution") {
        4
    } else {
        return Some(None);
    };

    let after_bracket = close_bracket + 1;
    if after_bracket < bytes.len() {
        let next_b = bytes[after_bracket];
        if next_b >= 0x80 {
            return None;
        }
        if !is_ruby_ascii_ws(next_b) {
            return Some(None);
        }
    }

    let mut pos = after_bracket;
    while pos < bytes.len() {
        let b = bytes[pos];
        if b >= 0x80 {
            return None;
        }
        if !is_ruby_ascii_ws(b) {
            break;
        }
        pos += 1;
    }

    Some(Some((alert_idx, pos)))
}

/// Inspects a `<p>` element's inner HTML `[inner_start..inner_end]` after the `[!TYPE]\s*`
/// token has been stripped (leaving `[after_token..inner_end]`), mimicking
/// `Html::Parser#strip_alert_token`.
///
/// Returns `Some(None)` if the `<p>` becomes completely blank and should be removed,
/// `Some(Some(rem_start))` if the `<p>` should be kept starting at `rem_start`, or `None`
/// if an ambiguous entity or nested structure requires Ruby.
fn strip_alert_p_inner(html: &str, after_token: usize, inner_end: usize) -> Option<Option<usize>> {
    let bytes = html.as_bytes();
    let mut pos = after_token;

    // 1. Strip leading blank children (whitespace-only text nodes or `<br>` with any attrs).
    while pos < inner_end {
        if bytes[pos] == b'<' {
            if let Some(br_tag) = parse_opening_tag(&bytes[..inner_end], pos) {
                if br_tag.tag == Tag::Br {
                    pos = br_tag.tag_end;
                    continue;
                }
            }
            break;
        }
        let text_start = pos;
        while pos < inner_end && bytes[pos] != b'<' {
            pos += 1;
        }
        let slice = &bytes[text_start..pos];
        if slice.contains(&b'&') {
            return None;
        }
        if slice.iter().all(|&b| b.is_ascii_whitespace()) {
            continue;
        }
        // Non-blank text node: keep starting at `text_start`.
        pos = text_start;
        break;
    }

    if pos >= inner_end {
        return Some(None);
    }

    // 2. Check if all remaining children in `[pos..inner_end]` are blank (`<br>` or whitespace).
    let mut scan = pos;
    let mut all_blank = true;
    while scan < inner_end {
        if bytes[scan] == b'<' {
            if let Some(br_tag) = parse_opening_tag(&bytes[..inner_end], scan) {
                if br_tag.tag == Tag::Br {
                    scan = br_tag.tag_end;
                    continue;
                }
            }
            all_blank = false;
            break;
        }
        let text_start = scan;
        while scan < inner_end && bytes[scan] != b'<' {
            scan += 1;
        }
        let slice = &bytes[text_start..scan];
        if slice.contains(&b'&') {
            return None;
        }
        if !slice.iter().all(|&b| b.is_ascii_whitespace()) {
            all_blank = false;
            break;
        }
    }

    if all_blank {
        Some(None)
    } else {
        Some(Some(pos))
    }
}

/// Validates and locates the closing tag of an open element starting right after its opening
/// tag at `start_pos`, ensuring canonical HTML4 structure and rejecting nested `<blockquote>`.
fn find_matching_close_no_nested_bq(
    bytes: &[u8],
    start_pos: usize,
    root_frame: Frame,
    mut in_code: bool,
) -> Option<(usize, usize)> {
    let mut stack = [Frame::EMPTY; MAX_TAG_DEPTH];
    stack[0] = root_frame;
    let mut depth = 1usize;
    let mut i = start_pos;

    while i < bytes.len() {
        if bytes[i] == b'<' {
            if bytes.get(i + 1) == Some(&b'/') {
                let (name_start, name_end, close_end) = parse_closing_tag_name(bytes, i)?;
                depth -= 1;
                let frame = stack[depth];
                if !validate_closed_frame(&frame, bytes, name_start, name_end) {
                    return None;
                }
                if frame.tag == Tag::Code {
                    in_code = false;
                }
                if depth == 0 {
                    return Some((i, close_end));
                }
                i = close_end;
            } else {
                let parsed = parse_opening_tag(bytes, i)?;
                if parsed.tag == Tag::Blockquote {
                    return None;
                }
                let active_stack = &stack[..depth];
                let parent_tag = active_stack.last().map(|f| f.tag);
                if !is_valid_child(parent_tag, parsed.tag, active_stack, in_code) {
                    return None;
                }
                if !record_element_on_parent(&mut stack, depth, parsed.tag) {
                    return None;
                }
                if !parsed.tag.is_void() {
                    if depth >= MAX_TAG_DEPTH {
                        return None;
                    }
                    if parsed.tag == Tag::Code {
                        in_code = true;
                    }
                    stack[depth] = Frame {
                        raw_name_start: parsed.name_start,
                        raw_name_end: parsed.name_end,
                        open_tag_start: i,
                        open_tag_end: parsed.tag_end,
                        tag: parsed.tag,
                        child_count: 0,
                        first_child_is_text: false,
                        last_child_is_text: false,
                        first_child_was_block_elem: false,
                        prev_child_was_block_elem: false,
                        flag: false,
                    };
                    depth += 1;
                }
                i = parsed.tag_end;
            }
        } else {
            let text_start = i;
            while i < bytes.len() && bytes[i] != b'<' {
                i += 1;
            }
            let parent_tag = if depth > 0 {
                Some(stack[depth - 1].tag)
            } else {
                None
            };
            if !validate_text_node(&bytes[text_start..i], parent_tag) {
                return None;
            }
            record_text_on_parent(&mut stack, depth);
        }
    }

    None
}

/// Transforms GitHub-style Markdown alerts (`<blockquote><p>[!NOTE]...</p></blockquote>`) on
/// canonical `Nokogiri::HTML.fragment(html).to_html` inputs, matching
/// `Html::Parser#transform_markdown_alerts`.
///
/// `alert_labels` must contain the 5 localized labels in `Html::Parser::ALERT_TYPES` order:
/// `[note, tip, important, warning, caution]`.
pub fn transform_markdown_alerts<'a>(
    html: &'a str,
    alert_labels: &[&str; 5],
) -> Option<Cow<'a, str>> {
    if html.is_empty() {
        return Some(Cow::Borrowed(html));
    }
    if html.starts_with('\u{FEFF}') {
        return None;
    }

    let bytes = html.as_bytes();
    let last_alert_marker = html.rfind("[!").max(bytes.iter().rposition(|&b| b == b'&'));
    let mut stack = [Frame::EMPTY; MAX_TAG_DEPTH];
    let mut depth = 0usize;
    let mut in_code = false;
    let mut out: Option<String> = None;
    let mut last_copied = 0usize;
    let mut i = 0usize;

    while i < bytes.len() {
        if bytes[i] == b'<' {
            if bytes.get(i + 1) == Some(&b'/') {
                let (name_start, name_end, close_end) = parse_closing_tag_name(bytes, i)?;
                if depth == 0 {
                    return None;
                }
                depth -= 1;
                let frame = stack[depth];
                if !validate_closed_frame(&frame, bytes, name_start, name_end) {
                    return None;
                }
                if frame.tag == Tag::Code {
                    in_code = false;
                }
                i = close_end;
            } else {
                let parsed = parse_opening_tag(bytes, i)?;
                let active_stack = &stack[..depth];
                let parent_tag = active_stack.last().map(|f| f.tag);
                if !is_valid_child(parent_tag, parsed.tag, active_stack, in_code) {
                    return None;
                }
                if !record_element_on_parent(&mut stack, depth, parsed.tag) {
                    return None;
                }

                if parsed.tag == Tag::Blockquote {
                    let (bq_attrs, bq_attr_count) =
                        parse_canonical_tag_attrs(bytes, parsed.name_end, parsed.tag_end);
                    if bq_attrs[..bq_attr_count]
                        .iter()
                        .any(|a| &bytes[a.name_start..a.name_end] == b"data-alert")
                    {
                        return None;
                    }

                    // Peek past leading ASCII whitespace inside `<blockquote>`.
                    let bq_inner_start = parsed.tag_end;
                    let mut p_pos = bq_inner_start;
                    while p_pos < bytes.len() && bytes[p_pos].is_ascii_whitespace() {
                        p_pos += 1;
                    }

                    // If non-whitespace text precedes the first element child, defer to Ruby
                    // when `[!` or `&` appears anywhere in the remainder (O(1) precomputed check).
                    if p_pos < bytes.len() && bytes[p_pos] != b'<' {
                        if last_alert_marker.is_some_and(|marker_pos| marker_pos >= p_pos) {
                            return None;
                        }
                    } else if p_pos < bytes.len() && bytes.get(p_pos + 1) != Some(&b'/') {
                        let p_parsed = parse_opening_tag(bytes, p_pos)?;
                        if p_parsed.tag == Tag::P {
                            let text_start = p_parsed.tag_end;
                            let mut text_end = text_start;
                            while text_end < bytes.len() && bytes[text_end] != b'<' {
                                text_end += 1;
                            }
                            let leading_text = &html[text_start..text_end];
                            if leading_text.as_bytes().contains(&b'&') {
                                return None;
                            }
                            if let Some((alert_idx, consumed_len)) =
                                match_alert_token(leading_text)?
                            {
                                // Validate and locate `</p>` and `</blockquote>`.
                                let p_frame = Frame {
                                    raw_name_start: p_parsed.name_start,
                                    raw_name_end: p_parsed.name_end,
                                    open_tag_start: p_pos,
                                    open_tag_end: p_parsed.tag_end,
                                    tag: Tag::P,
                                    child_count: 0,
                                    first_child_is_text: false,
                                    last_child_is_text: false,
                                    first_child_was_block_elem: false,
                                    prev_child_was_block_elem: false,
                                    flag: false,
                                };
                                let (p_close_start, p_close_end) =
                                    find_matching_close_no_nested_bq(
                                        bytes,
                                        p_parsed.tag_end,
                                        p_frame,
                                        in_code,
                                    )?;

                                let mut bq_frame = Frame {
                                    raw_name_start: parsed.name_start,
                                    raw_name_end: parsed.name_end,
                                    open_tag_start: i,
                                    open_tag_end: parsed.tag_end,
                                    tag: Tag::Blockquote,
                                    child_count: 0,
                                    first_child_is_text: false,
                                    last_child_is_text: false,
                                    first_child_was_block_elem: false,
                                    prev_child_was_block_elem: false,
                                    flag: false,
                                };
                                if p_pos > bq_inner_start {
                                    bq_frame.child_count += 1;
                                    bq_frame.first_child_is_text = true;
                                }
                                bq_frame.child_count += 1;
                                bq_frame.first_child_was_block_elem = !bq_frame.first_child_is_text;
                                bq_frame.prev_child_was_block_elem = true;

                                let (bq_close_start, bq_close_end) =
                                    find_matching_close_no_nested_bq(
                                        bytes,
                                        p_close_end,
                                        bq_frame,
                                        in_code,
                                    )?;

                                let rem_p_start = strip_alert_p_inner(
                                    html,
                                    text_start + consumed_len,
                                    p_close_start,
                                )?;
                                let ws_before = &html[bq_inner_start..p_pos];
                                let after_p = &html[p_close_end..bq_close_start];
                                let alert_type = ALERT_TYPE_NAMES[alert_idx];
                                let label = alert_labels[alert_idx];

                                let mode = if rem_p_start.is_none()
                                    && ws_before.is_empty()
                                    && after_p.is_empty()
                                {
                                    1u8
                                } else if rem_p_start.is_some()
                                    && ws_before.is_empty()
                                    && after_p.is_empty()
                                {
                                    2u8
                                } else if ws_before == "\n" && after_p.ends_with('\n') {
                                    3u8
                                } else {
                                    return None;
                                };

                                let buf = out
                                    .get_or_insert_with(|| String::with_capacity(html.len() + 96));
                                buf.push_str(&html[last_copied..i]);
                                buf.push_str(&html[i..parsed.tag_end - 1]);
                                buf.push_str(" data-alert=\"");
                                buf.push_str(alert_type);
                                buf.push_str("\">");

                                match mode {
                                    1 => {
                                        buf.push_str("<p data-alert-label=\"");
                                        buf.push_str(alert_type);
                                        buf.push_str("\">");
                                        push_html4_text_escaped(buf, label);
                                        buf.push_str("</p></blockquote>");
                                    }
                                    2 => {
                                        let rem_start = rem_p_start.unwrap();
                                        buf.push_str("\n<p data-alert-label=\"");
                                        buf.push_str(alert_type);
                                        buf.push_str("\">");
                                        push_html4_text_escaped(buf, label);
                                        buf.push_str("</p>\n");
                                        buf.push_str(&html[p_pos..p_parsed.tag_end]);
                                        buf.push_str(&html[rem_start..p_close_end]);
                                        buf.push_str("\n</blockquote>");
                                    }
                                    _ => {
                                        buf.push_str("\n<p data-alert-label=\"");
                                        buf.push_str(alert_type);
                                        buf.push_str("\">");
                                        push_html4_text_escaped(buf, label);
                                        buf.push_str("</p>\n");
                                        if let Some(rem_start) = rem_p_start {
                                            buf.push_str(&html[p_pos..p_parsed.tag_end]);
                                            buf.push_str(&html[rem_start..p_close_end]);
                                        }
                                        buf.push_str(after_p);
                                        buf.push_str("</blockquote>");
                                    }
                                }

                                last_copied = bq_close_end;
                                i = bq_close_end;
                                continue;
                            }
                        }
                    }
                }

                if !parsed.tag.is_void() {
                    if depth >= MAX_TAG_DEPTH {
                        return None;
                    }
                    if parsed.tag == Tag::Code {
                        in_code = true;
                    }
                    stack[depth] = Frame {
                        raw_name_start: parsed.name_start,
                        raw_name_end: parsed.name_end,
                        open_tag_start: i,
                        open_tag_end: parsed.tag_end,
                        tag: parsed.tag,
                        child_count: 0,
                        first_child_is_text: false,
                        last_child_is_text: false,
                        first_child_was_block_elem: false,
                        prev_child_was_block_elem: false,
                        flag: false,
                    };
                    depth += 1;
                }
                i = parsed.tag_end;
            }
        } else {
            let text_start = i;
            while i < bytes.len() && bytes[i] != b'<' {
                i += 1;
            }
            let parent_tag = if depth > 0 {
                Some(stack[depth - 1].tag)
            } else {
                None
            };
            if !validate_text_node(&bytes[text_start..i], parent_tag) {
                return None;
            }
            record_text_on_parent(&mut stack, depth);
        }
    }

    if depth != 0 {
        return None;
    }

    match out {
        None => Some(Cow::Borrowed(html)),
        Some(mut buf) => {
            buf.push_str(&html[last_copied..]);
            Some(Cow::Owned(buf))
        }
    }
}

#[derive(Clone, Copy, Debug)]
struct PrevSiblingElem {
    start: usize,
    end: usize,
    tag: Tag,
    preceded_by_non_inline_without_ws: bool,
    only_ws_since_end: bool,
}

/// Wraps `<figcaption>` elements (not already inside `<figure>`) together with their
/// immediately preceding sibling element in `<figure>...</figure>`, matching
/// `Html::Parser#wrap_all_figures_with_tags` on canonical HTML4 inputs.
pub fn wrap_all_figures_with_tags(html: &str) -> Option<Cow<'_, str>> {
    if html.is_empty() {
        return Some(Cow::Borrowed(html));
    }
    if html.starts_with('\u{FEFF}') {
        return None;
    }
    if !html.contains("<figcaption") {
        return if is_canonical_html(html, false) {
            Some(Cow::Borrowed(html))
        } else {
            None
        };
    }

    let bytes = html.as_bytes();
    let mut stack = [Frame::EMPTY; MAX_TAG_DEPTH];
    // `prev_sibling[d]` tracks the last completed child element at nesting depth `d`
    // (0 = root level, `d` = inside `stack[d - 1]`).
    let mut prev_sibling: [Option<PrevSiblingElem>; MAX_TAG_DEPTH + 1] = [None; MAX_TAG_DEPTH + 1];
    let mut depth = 0usize;
    let mut in_code = false;
    let mut out: Option<String> = None;
    let mut last_copied = 0usize;
    let mut i = 0usize;

    while i < bytes.len() {
        if bytes[i] == b'<' {
            if bytes.get(i + 1) == Some(&b'/') {
                let (name_start, name_end, close_end) = parse_closing_tag_name(bytes, i)?;
                if depth == 0 {
                    return None;
                }
                depth -= 1;
                let frame = stack[depth];
                if !validate_closed_frame(&frame, bytes, name_start, name_end) {
                    return None;
                }
                if frame.tag == Tag::Code {
                    in_code = false;
                }
                prev_sibling[depth + 1] = None;
                let preceded_non_inline_no_ws = prev_sibling[depth]
                    .is_some_and(|p| p.tag.is_libxml_non_inline() && p.end == frame.open_tag_start);
                prev_sibling[depth] = Some(PrevSiblingElem {
                    start: frame.open_tag_start,
                    end: close_end,
                    tag: frame.tag,
                    preceded_by_non_inline_without_ws: preceded_non_inline_no_ws,
                    only_ws_since_end: true,
                });
                i = close_end;
            } else {
                let parsed = parse_opening_tag(bytes, i)?;
                let active_stack = &stack[..depth];
                let parent_tag = active_stack.last().map(|f| f.tag);
                if !is_valid_child(parent_tag, parsed.tag, active_stack, in_code) {
                    return None;
                }
                if !record_element_on_parent(&mut stack, depth, parsed.tag) {
                    return None;
                }

                if parsed.tag == Tag::Figcaption && parent_tag != Some(Tag::Figure) {
                    if let Some(prev) = prev_sibling[depth] {
                        if !prev.only_ws_since_end || prev.start < last_copied {
                            return None;
                        }
                        // Find matching `</figcaption>` while validating canonical inner HTML.
                        let cap_frame = Frame {
                            raw_name_start: parsed.name_start,
                            raw_name_end: parsed.name_end,
                            open_tag_start: i,
                            open_tag_end: parsed.tag_end,
                            tag: Tag::Figcaption,
                            child_count: 0,
                            first_child_is_text: false,
                            last_child_is_text: false,
                            first_child_was_block_elem: false,
                            prev_child_was_block_elem: false,
                            flag: false,
                        };
                        let (_cap_close_start, cap_close_end) = find_matching_close_no_nested_bq(
                            bytes,
                            parsed.tag_end,
                            cap_frame,
                            in_code,
                        )?;
                        // Reject nested `<figcaption>` inside `<figcaption>`.
                        if html[parsed.tag_end..cap_close_end].contains("<figcaption") {
                            return None;
                        }

                        let buf = out.get_or_insert_with(|| String::with_capacity(html.len() + 32));
                        buf.push_str(&html[last_copied..prev.start]);
                        if prev.preceded_by_non_inline_without_ws {
                            buf.push('\n');
                        }
                        buf.push_str("<figure>");
                        buf.push_str(&html[prev.start..prev.end]);
                        if prev.tag.is_libxml_non_inline() {
                            buf.push('\n');
                        }
                        buf.push_str(&html[i..cap_close_end]);
                        buf.push_str("</figure>");
                        // Preserve any whitespace between `prev` and `<figcaption>` after `</figure>`.
                        buf.push_str(&html[prev.end..i]);

                        last_copied = cap_close_end;
                        prev_sibling[depth] = Some(PrevSiblingElem {
                            start: prev.start,
                            end: cap_close_end,
                            tag: Tag::Figure,
                            preceded_by_non_inline_without_ws: false,
                            only_ws_since_end: true,
                        });
                        i = cap_close_end;
                        continue;
                    }
                }

                if parsed.tag.is_void() {
                    let preceded_non_inline_no_ws = prev_sibling[depth]
                        .is_some_and(|p| p.tag.is_libxml_non_inline() && p.end == i);
                    prev_sibling[depth] = Some(PrevSiblingElem {
                        start: i,
                        end: parsed.tag_end,
                        tag: parsed.tag,
                        preceded_by_non_inline_without_ws: preceded_non_inline_no_ws,
                        only_ws_since_end: true,
                    });
                } else {
                    if depth >= MAX_TAG_DEPTH {
                        return None;
                    }
                    if parsed.tag == Tag::Code {
                        in_code = true;
                    }
                    stack[depth] = Frame {
                        raw_name_start: parsed.name_start,
                        raw_name_end: parsed.name_end,
                        open_tag_start: i,
                        open_tag_end: parsed.tag_end,
                        tag: parsed.tag,
                        child_count: 0,
                        first_child_is_text: false,
                        last_child_is_text: false,
                        first_child_was_block_elem: false,
                        prev_child_was_block_elem: false,
                        flag: false,
                    };
                    depth += 1;
                    prev_sibling[depth] = None;
                }
                i = parsed.tag_end;
            }
        } else {
            let text_start = i;
            while i < bytes.len() && bytes[i] != b'<' {
                i += 1;
            }
            let parent_tag = if depth > 0 {
                Some(stack[depth - 1].tag)
            } else {
                None
            };
            if !validate_text_node(&bytes[text_start..i], parent_tag) {
                return None;
            }
            record_text_on_parent(&mut stack, depth);
            if !bytes[text_start..i]
                .iter()
                .all(|&b| b.is_ascii_whitespace())
            {
                if let Some(prev) = &mut prev_sibling[depth] {
                    prev.only_ws_since_end = false;
                }
            }
        }
    }

    if depth != 0 {
        return None;
    }

    match out {
        None => Some(Cow::Borrowed(html)),
        Some(mut buf) => {
            buf.push_str(&html[last_copied..]);
            Some(Cow::Owned(buf))
        }
    }
}

/// Fused Tier 2 HTML post-processing pipeline for `MarkdownProcessor::Parser#finalize`.
///
/// Runs all deterministic HTML transforms across one FFI boundary in exact order:
/// 1. `add_target_blank_to_outbound_links` (when `run_target_blank` is `true`)
/// 2. `remove_nested_linebreak_in_list_fragment`
/// 3. `prefix_all_images` (when `prefix_images_config` is `Some`)
/// 4. `wrap_all_images_in_links`
/// 5. `enforce_gif_like_videos`
/// 6. `apply_codeblock_enhancements` (control class + control panel + fullscreen button)
/// 7. `wrap_all_tables`
/// 8. `transform_markdown_alerts` (when `alert_labels` is `Some`)
/// 9. `remove_empty_paragraphs`
/// 10. `escape_colon_emojis_in_codeblock`
/// 11. `unescape_raw_tag_in_codeblocks`
/// 12. `wrap_all_figures_with_tags`
/// 13. `wrap_mentions_with_links`
#[allow(clippy::too_many_arguments)]
pub fn postprocess_rendered_html_full<'a>(
    html: &'a str,
    app_domain: &str,
    fullscreen_action_html: &str,
    existing_usernames: &[String],
    base_url: &str,
    run_target_blank: bool,
    normalize_document: bool,
    prefix_images_config: Option<&PrefixImagesConfig<'_>>,
    alert_labels: Option<&[&str; 5]>,
) -> Option<Cow<'a, str>> {
    if html.is_empty() || html.bytes().all(|b| b.is_ascii_whitespace()) {
        return Some(Cow::Borrowed(html));
    }
    if html.starts_with('\u{FEFF}') {
        return None;
    }
    if !existing_usernames.is_empty() && !is_valid_base_url(base_url) {
        return None;
    }

    if !html.as_bytes().contains(&b'<') {
        if !normalize_document || !is_valid_bare_text_for_document(html) {
            return None;
        }
        let mut cur = format!("<p>{html}</p>");
        if cur.as_bytes().contains(&b':') {
            cur = crate::emoji::escape_colon_emojis_in_codeblock(&cur)?.into_owned();
        }
        if cur.contains("----") {
            cur = unescape_raw_tag_in_codeblocks(&cur)?.into_owned();
        }
        if !existing_usernames.is_empty() && cur.as_bytes().contains(&b'@') {
            cur = wrap_mentions_with_links(&cur, existing_usernames, base_url)?.into_owned();
        }
        cur.push('\n');
        return Some(Cow::Owned(cur));
    }

    let mut cur: Cow<'a, str> = if run_target_blank {
        add_target_blank_to_outbound_links(html, app_domain)?
    } else {
        if !is_canonical_html(html, normalize_document) {
            return None;
        }
        Cow::Borrowed(html)
    };

    if normalize_document && run_target_blank && !is_canonical_html(cur.as_ref(), true) {
        return None;
    }

    if cur.contains("<br") {
        if let Cow::Owned(s) = remove_nested_linebreak_in_list_fragment(cur.as_ref())? {
            cur = Cow::Owned(s);
        }
    }
    if let Some(cfg) = prefix_images_config {
        if cur.contains("<img") {
            if let Cow::Owned(s) = prefix_all_images(cur.as_ref(), cfg)? {
                cur = Cow::Owned(s);
            }
        }
    }
    if cur.contains("<img") {
        if let Cow::Owned(s) = wrap_all_images_in_links(cur.as_ref())? {
            cur = Cow::Owned(s);
        }
    }
    if cur.contains("<video") {
        if let Cow::Owned(s) = enforce_gif_like_videos(cur.as_ref())? {
            cur = Cow::Owned(s);
        }
    }
    if cur.contains("highlight") {
        if fullscreen_action_html.is_empty() {
            return None;
        }
        if let Cow::Owned(s) = apply_codeblock_enhancements(cur.as_ref(), fullscreen_action_html)? {
            cur = Cow::Owned(s);
        }
    }
    if cur.contains("<table") {
        if let Cow::Owned(s) = wrap_all_tables(cur.as_ref())? {
            cur = Cow::Owned(s);
        }
    }
    if let Some(labels) = alert_labels {
        if cur.contains("<blockquote") && (cur.contains("[!") || cur.as_bytes().contains(&b'&')) {
            if let Cow::Owned(s) = transform_markdown_alerts(cur.as_ref(), labels)? {
                cur = Cow::Owned(s);
            }
        }
    }
    if cur.contains("<p") {
        if let Cow::Owned(s) = remove_empty_paragraphs(cur.as_ref())? {
            let trimmed = s.trim_start_matches(|c: char| c.is_ascii_whitespace());
            if trimmed.is_empty() || !trimmed.starts_with('<') {
                return None;
            }
            cur = if trimmed.len() == s.len() {
                Cow::Owned(s)
            } else {
                Cow::Owned(trimmed.to_string())
            };
        }
    }
    if cur.as_bytes().contains(&b':') {
        if let Cow::Owned(s) = crate::emoji::escape_colon_emojis_in_codeblock(cur.as_ref())? {
            cur = Cow::Owned(s);
        }
    }
    if cur.contains("----") {
        if let Cow::Owned(s) = unescape_raw_tag_in_codeblocks(cur.as_ref())? {
            cur = Cow::Owned(s);
        }
    }
    if cur.contains("<figcaption") {
        if let Cow::Owned(s) = wrap_all_figures_with_tags(cur.as_ref())? {
            cur = Cow::Owned(s);
        }
    }
    if !existing_usernames.is_empty() && cur.as_bytes().contains(&b'@') {
        if let Cow::Owned(s) = wrap_mentions_with_links(cur.as_ref(), existing_usernames, base_url)?
        {
            cur = Cow::Owned(s);
        }
    }

    if normalize_document {
        let mut owned = cur.into_owned();
        owned.push('\n');
        return Some(Cow::Owned(owned));
    }

    Some(cur)
}

pub fn postprocess_rendered_html<'a>(
    html: &'a str,
    app_domain: &str,
    fullscreen_action_html: &str,
    existing_usernames: &[String],
    base_url: &str,
    run_target_blank: bool,
    normalize_document: bool,
) -> Option<Cow<'a, str>> {
    postprocess_rendered_html_full(
        html,
        app_domain,
        fullscreen_action_html,
        existing_usernames,
        base_url,
        run_target_blank,
        normalize_document,
        None,
        None,
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn adds_control_class_to_highlight_codeblocks() {
        let html = "<div class=\"highlight\"><pre class=\"highlight ruby\"><code>puts 1\n</code></pre></div>";
        assert_eq!(
            add_control_class_to_codeblock(html).as_deref(),
            Some("<div class=\"highlight js-code-highlight\"><pre class=\"highlight ruby\"><code>puts 1\n</code></pre></div>")
        );
        let unchanged = "<div>Hello world!</div>";
        assert!(matches!(
            add_control_class_to_codeblock(unchanged),
            Some(Cow::Borrowed("<div>Hello world!</div>"))
        ));
        assert_eq!(
            add_control_class_to_codeblock("<div class=\"high&#108;ight\">x</div>"),
            None
        );
    }

    #[test]
    fn adds_control_panel_to_highlight_codeblocks() {
        let html = "<div class=\"highlight js-code-highlight\"><pre class=\"highlight ruby\"><code>puts 1\n</code></pre></div>";
        assert_eq!(
            add_control_panel_to_codeblock(html).as_deref(),
            Some(
                "<div class=\"highlight js-code-highlight\">\n<pre class=\"highlight ruby\"><code>puts 1\n</code></pre>\n<div class=\"highlight__panel js-actions-panel\"></div>\n</div>"
            )
        );
        let text_child = "<div class=\"highlight\">Hello world!</div>";
        assert_eq!(
            add_control_panel_to_codeblock(text_child).as_deref(),
            Some("<div class=\"highlight\">Hello world!<div class=\"highlight__panel js-actions-panel\"></div>\n</div>")
        );
    }

    #[test]
    fn wraps_tables_and_removes_empty_paragraphs() {
        let table = "<table>\n<thead>\n<tr>\n<th>H</th>\n</tr>\n</thead>\n<tbody>\n<tr>\n<td>D</td>\n</tr>\n</tbody>\n</table>";
        assert_eq!(
            wrap_all_tables(table).as_deref(),
            Some("<div class=\"table-wrapper-paragraph\"><table>\n<thead>\n<tr>\n<th>H</th>\n</tr>\n</thead>\n<tbody>\n<tr>\n<td>D</td>\n</tr>\n</tbody>\n</table></div>")
        );
        assert_eq!(wrap_all_tables("<TABLE><tr><td>a</td></tr></TABLE>"), None);

        assert_eq!(remove_empty_paragraphs("<p></p>").as_deref(), Some(""));
        assert_eq!(
            remove_empty_paragraphs("<p>   \n\t </p><p><br></p><p>Hello World!</p>").as_deref(),
            Some("<p>Hello World!</p>")
        );
        assert!(matches!(
            remove_empty_paragraphs("<p>Hello World!</p>"),
            Some(Cow::Borrowed("<p>Hello World!</p>"))
        ));
    }

    #[test]
    fn wraps_images_in_links_inside_paragraphs() {
        let html = "<p><img src=\"https://image.com/image.jpg\" alt=\"test\"></p>";
        assert_eq!(
            wrap_all_images_in_links(html).as_deref(),
            Some("<p><a href=\"https://image.com/image.jpg\" class=\"article-body-image-wrapper\"><img src=\"https://image.com/image.jpg\" alt=\"test\"></a></p>")
        );
        let already_linked =
            "<p><a href=\"https://example.com\"><img src=\"https://image.com/image.jpg\"></a></p>";
        assert!(matches!(
            wrap_all_images_in_links(already_linked),
            Some(Cow::Borrowed(_))
        ));
    }

    #[test]
    fn unescapes_raw_tags_in_codeblocks_and_spans() {
        let highlighted = "<div class=\"highlight\"><pre class=\"highlight javascript\"><code><span class=\"p\">{</span><span class=\"o\">----%</span> <span class=\"nx\">raw</span> <span class=\"o\">%----</span><span class=\"p\">}</span><span class=\"nx\">some</span> <span class=\"nx\">text</span><span class=\"p\">{</span><span class=\"o\">----%</span> <span class=\"nx\">endraw</span> <span class=\"o\">%----</span><span class=\"p\">}</span>\n</code></pre></div>";
        assert_eq!(
            unescape_raw_tag_in_codeblocks(highlighted).as_deref(),
            Some("<div class=\"highlight\"><pre class=\"highlight javascript\"><code><span class=\"p\">{</span><span class=\"o\">%</span> <span class=\"nx\">raw</span> <span class=\"o\">%</span><span class=\"p\">}</span><span class=\"nx\">some</span> <span class=\"nx\">text</span><span class=\"p\">{</span><span class=\"o\">%</span> <span class=\"nx\">endraw</span> <span class=\"o\">%</span><span class=\"p\">}</span>\n</code></pre></div>")
        );
        let dashes = "<div class=\"highlight\"><pre class=\"highlight plaintext\"><code>----\n</code></pre></div>";
        assert_eq!(
            unescape_raw_tag_in_codeblocks(dashes).as_deref(),
            Some(dashes)
        );
        let bare = "```\n{----% raw %----}some text{----% endraw %----}\n```";
        assert_eq!(
            unescape_raw_tag_in_codeblocks(bare).as_deref(),
            Some("<p>```\n{% raw %}some text{% endraw %}\n```</p>")
        );
    }

    #[test]
    fn extracts_and_wraps_mentions_and_mentioned_user_links() {
        let html = "<p><code>@alice</code> one two, @Alice and @bob_1:</p>\n<ul>\n<li><code>@alice</code></li>\n</ul>";
        assert_eq!(
            extract_mention_usernames(html),
            Some(vec!["alice".to_string(), "bob_1".to_string()])
        );
        let linked =
            wrap_mentions_with_links(html, &["alice".to_string()], "http://forem.test").unwrap();
        assert_eq!(
            linked,
            "<p><code>@alice</code> one two, <a class=\"mentioned-user\" href=\"http://forem.test/alice\">@alice</a> and @bob_1:</p>\n<ul>\n<li><code>@alice</code></li>\n</ul>"
        );
        assert_eq!(
            extract_mentioned_usernames(&linked),
            Some(vec!["alice".to_string()])
        );

        let with_ltag = "<p><a class=\"mentioned-user\" href=\"http://forem.test/alice\">@alice</a></p>\n<div class=\"ltag-github\"><p><a class=\"mentioned-user\" href=\"http://forem.test/bob\">@bob</a></p></div>";
        assert_eq!(
            extract_mentioned_usernames(with_ltag),
            Some(vec!["alice".to_string()])
        );
    }

    #[test]
    fn adds_target_blank_and_rel_to_outbound_links() {
        let html = "<p><a href=\"https://github.com\">gh</a> <a href=\"https://forem.test/post\">internal</a> <a href=\"https://example.com\" rel=\"nofollow\">ext</a></p>";
        assert_eq!(
            add_target_blank_to_outbound_links(html, "forem.test").as_deref(),
            Some("<p><a href=\"https://github.com\" target=\"_blank\" rel=\"noopener noreferrer\">gh</a> <a href=\"https://forem.test/post\">internal</a> <a href=\"https://example.com\" rel=\"nofollow noopener noreferrer\" target=\"_blank\">ext</a></p>")
        );

        let already_ok = "<p><a href=\"https://github.com\" target=\"_blank\" rel=\"noopener noreferrer\">gh</a></p>";
        assert!(matches!(
            add_target_blank_to_outbound_links(already_ok, "forem.test"),
            Some(Cow::Borrowed(_))
        ));

        assert_eq!(
            add_target_blank_to_outbound_links(
                "<p><a href=\"javascript:alert(1)\">x</a></p>",
                "forem.test"
            ),
            None
        );

        let many_tokens: Vec<String> = (0..64).map(|idx| format!("tok{idx}")).collect();
        let rel_input = format!("{} tok0 noopener", many_tokens.join(" "));
        let rel_html =
            format!("<p><a href=\"https://example.com\" rel=\"{rel_input}\">ext</a></p>");
        let expected_rel = format!("{} noopener noreferrer", many_tokens.join(" "));
        assert_eq!(
            add_target_blank_to_outbound_links(&rel_html, "forem.test").as_deref(),
            Some(
                format!(
                    "<p><a href=\"https://example.com\" rel=\"{expected_rel}\" target=\"_blank\">ext</a></p>"
                )
                .as_str()
            )
        );
    }

    #[test]
    fn removes_nested_linebreak_in_list_and_enforces_gif_videos() {
        let list = "<ul>\n<li>a<br>b</li>\n</ul>";
        assert_eq!(
            remove_nested_linebreak_in_list_fragment(list).as_deref(),
            Some("<ul>\n<li>ab</li>\n</ul>")
        );
        assert_eq!(
            remove_nested_linebreak_in_list_fragment("<ul>\n<li><br></li>\n</ul>"),
            None
        );

        let video = "<p><video src=\"a.mp4\"></video></p>";
        assert_eq!(
            enforce_gif_like_videos(video).as_deref(),
            Some("<p><video src=\"a.mp4\" data-gif-video=\"true\" autoplay=\"autoplay\" loop=\"loop\" muted=\"muted\" playsinline=\"playsinline\" preload=\"metadata\"></video></p>")
        );
    }

    #[test]
    fn adds_fullscreen_button_and_runs_fused_postprocess_pipeline() {
        let action = "<div class=\"highlight__panel-action js-fullscreen-code-action\">\n  <svg xmlns=\"http://www.w3.org/2000/svg\" width=\"20px\" height=\"20px\" viewbox=\"0 0 24 24\"><title>Enter</title>\n    <path d=\"M0 0\"></path>\n</svg>\n</div>\n";
        let panel = "<div class=\"highlight__panel js-actions-panel\"></div>";
        assert_eq!(
            add_fullscreen_button_to_panel(panel, action).as_deref(),
            Some(
                format!("<div class=\"highlight__panel js-actions-panel\">\n{action}</div>")
                    .as_str()
            )
        );

        let article = "<p>Hi @alice :joy: <a href=\"https://github.com\">gh</a></p>\n<div class=\"highlight\"><pre class=\"highlight ruby\"><code>puts 1\n</code></pre></div>\n<p></p>\n";
        let result = postprocess_rendered_html(
            article,
            "forem.test",
            action,
            &["alice".to_string()],
            "http://forem.test",
            true,
            true,
        )
        .unwrap();
        assert!(result.contains("target=\"_blank\" rel=\"noopener noreferrer\""));
        assert!(result.contains("href=\"http://forem.test/alice\""));
        assert!(result.contains("😂"));
        assert!(result.contains("js-code-highlight"));
        assert!(result.contains("js-fullscreen-code-action"));
        assert!(!result.contains("<p></p>"));
        assert!(result.ends_with("\n\n"));
    }

    #[test]
    fn prefixes_images_with_cloudflare_giphy_and_allowed_hosts() {
        let cf_config = PrefixImagesConfig {
            width: "880",
            app_host: Some("dev.to"),
            asset_host: Some("assets.dev.to"),
            cloudflare_domain: Some("media2.dev.to"),
            cloudflare_directory: "dynamic",
        };
        let html = "<p><img src=\"https://example.com/photo.jpg\" alt=\"p\"></p>";
        assert_eq!(
            prefix_all_images(html, &cf_config).as_deref(),
            Some(
                "<p><img src=\"https://media2.dev.to/dynamic/image/width=880%2Cheight=%2Cfit=scale-down%2Cgravity=auto%2Cformat=auto/https%3A%2F%2Fexample.com%2Fphoto.jpg\" alt=\"p\" loading=\"lazy\"></p>"
            )
        );

        let giphy = "<p><img src=\"https://media.giphy.com/media/abc/giphy.gif\"></p>";
        assert_eq!(
            prefix_all_images(giphy, &cf_config).as_deref(),
            Some("<p><img src=\"https://i.giphy.com/media/abc/giphy.gif\" loading=\"lazy\"></p>")
        );

        // Allowed hosts and data-ignore-prefix remain borrowed with zero allocation.
        let allowed = "<p><img src=\"https://dev.to/a.png\"><img src=\"https://camo.githubusercontent.com/x\"><img src=\"https://github.com/org/repo/actions/workflows/ci.yml/badge.svg\"><img src=\"/local.png\"><img src=\"https://example.com/b.png\" data-ignore-prefix=\"true\"></p>";
        assert!(matches!(
            prefix_all_images(allowed, &cf_config),
            Some(Cow::Borrowed(_))
        ));

        // Invalid URI or already-prefixed Cloudflare URL defers to Ruby.
        assert_eq!(
            prefix_all_images(
                "<p><img src=\"https://example.com/bad url.png\"></p>",
                &cf_config
            ),
            None
        );
        assert_eq!(
            prefix_all_images(
                "<p><img src=\"https://media2.dev.to/dynamic/image/width=880/https://example.com/a.png\"></p>",
                &cf_config
            ),
            None
        );
    }

    #[test]
    fn transforms_markdown_alerts_matching_nokogiri() {
        let labels = ["Note", "Tip", "Important", "Warning", "Caution"];
        assert_eq!(
            transform_markdown_alerts("<blockquote><p>[!TIP] Body</p></blockquote>", &labels)
                .as_deref(),
            Some("<blockquote data-alert=\"tip\">\n<p data-alert-label=\"tip\">Tip</p>\n<p>Body</p>\n</blockquote>")
        );
        assert_eq!(
            transform_markdown_alerts(
                "<blockquote>\n<p>[!WARNING]\nCareful here.</p>\n</blockquote>",
                &labels
            )
            .as_deref(),
            Some("<blockquote data-alert=\"warning\">\n<p data-alert-label=\"warning\">Warning</p>\n<p>Careful here.</p>\n</blockquote>")
        );
        assert_eq!(
            transform_markdown_alerts("<blockquote><p>[!TIP]<br>Body</p></blockquote>", &labels)
                .as_deref(),
            Some("<blockquote data-alert=\"tip\">\n<p data-alert-label=\"tip\">Tip</p>\n<p>Body</p>\n</blockquote>")
        );
        assert_eq!(
            transform_markdown_alerts("<blockquote><p>[!TIP]</p></blockquote>", &labels).as_deref(),
            Some("<blockquote data-alert=\"tip\"><p data-alert-label=\"tip\">Tip</p></blockquote>")
        );
        assert_eq!(
            transform_markdown_alerts(
                "<blockquote><blockquote><p>[!TIP] Inner</p></blockquote></blockquote>",
                &labels
            )
            .as_deref(),
            Some("<blockquote><blockquote data-alert=\"tip\">\n<p data-alert-label=\"tip\">Tip</p>\n<p>Inner</p>\n</blockquote></blockquote>")
        );
        let non_alert = "<blockquote><p>[!NOTE]worthy of attention</p></blockquote>";
        assert!(matches!(
            transform_markdown_alerts(non_alert, &labels),
            Some(Cow::Borrowed(_))
        ));
    }

    #[test]
    fn wraps_figcaptions_matching_nokogiri() {
        assert_eq!(
            wrap_all_figures_with_tags(
                "<p>case: </p><p>Statement</p>\n<figcaption>A fig</figcaption>"
            )
            .as_deref(),
            Some("<p>case: </p>\n<figure><p>Statement</p>\n<figcaption>A fig</figcaption></figure>\n")
        );
        assert_eq!(
            wrap_all_figures_with_tags("<p>Statement</p><figcaption>A fig</figcaption>").as_deref(),
            Some("<figure><p>Statement</p>\n<figcaption>A fig</figcaption></figure>")
        );
        let already = "<figure><p>Statement</p>\n<figcaption>A fig</figcaption></figure>";
        assert!(matches!(
            wrap_all_figures_with_tags(already),
            Some(Cow::Borrowed(_))
        ));
        let orphan = "<figcaption>A fig</figcaption>";
        assert!(matches!(
            wrap_all_figures_with_tags(orphan),
            Some(Cow::Borrowed(_))
        ));
    }

    #[test]
    fn postprocesses_full_article_with_images_alerts_and_figures() {
        let cf_config = PrefixImagesConfig {
            width: "800",
            app_host: Some("forem.test"),
            asset_host: None,
            cloudflare_domain: Some("media2.dev.to"),
            cloudflare_directory: "dynamic",
        };
        let labels = ["Note", "Tip", "Important", "Warning", "Caution"];
        let html = "<p><img src=\"https://example.com/pic.png\" alt=\"pic\"></p>\n<figcaption>A caption</figcaption>\n<blockquote>\n<p>[!TIP]\nUse Rust.</p>\n</blockquote>";
        let result = postprocess_rendered_html_full(
            html,
            "forem.test",
            "",
            &[],
            "http://forem.test",
            true,
            true,
            Some(&cf_config),
            Some(&labels),
        )
        .unwrap();
        assert!(result.contains("media2.dev.to/dynamic/image/width=800"));
        assert!(result.contains("loading=\"lazy\""));
        assert!(result.contains("class=\"article-body-image-wrapper\""));
        assert!(result.contains("<figure><p><a href=\""));
        assert!(result.contains("<figcaption>A caption</figcaption></figure>"));
        assert!(result.contains("<blockquote data-alert=\"tip\">"));
        assert!(result.contains("<p data-alert-label=\"tip\">Tip</p>"));
    }
}
