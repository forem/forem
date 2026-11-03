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
}
