//! Pure-Rust HTML processing kernels for Forem's Billboard subsystem:
//! - Declarative Shadow DOM wrapping & script/base/meta neutralization
//!   (`Billboards::ShadowDomWrapper`)
//! - Affiliate/tracking `bb=<id>` query parameter injection (`Billboard#with_bb_param`)
//! - Internal article link path extraction (`Billboard#extract_internal_article_paths`)
//!
//! All functions enforce strict fast-path domains and return `None` whenever an input
//! requires full HTML5/HTML4 error-recovery, entity decoding, or exotic URI parsing,
//! allowing the Ruby caller to fall back transparently to Nokogiri/URI with 100% parity.

use std::collections::HashSet;

/// HTML5 void elements that have no closing tag and must not be pushed onto the open-tag stack.
fn is_void_element(tag: &str) -> bool {
    matches!(
        tag,
        "area"
            | "base"
            | "br"
            | "col"
            | "embed"
            | "hr"
            | "img"
            | "input"
            | "link"
            | "meta"
            | "param"
            | "source"
            | "track"
            | "wbr"
    )
}

/// Elements whose HTML5/HTML4 parser rules involve special insertion modes, foreign namespaces,
/// implicit tbody insertion, table fostering, or raw/RCDATA text modes other than `<style>`/`<script>`.
fn is_unsupported_special_element(tag: &str) -> bool {
    matches!(
        tag,
        "template"
            | "svg"
            | "math"
            | "table"
            | "thead"
            | "tbody"
            | "tfoot"
            | "tr"
            | "td"
            | "th"
            | "caption"
            | "colgroup"
            | "col"
            | "html"
            | "head"
            | "body"
            | "frameset"
            | "frame"
            | "noframes"
            | "noscript"
            | "plaintext"
            | "xmp"
            | "iframe"
            | "noembed"
            | "textarea"
            | "title"
            | "select"
            | "optgroup"
            | "option"
            | "ruby"
            | "rt"
            | "rp"
            | "listing"
            | "pre"
    )
}

/// Block-level elements that cause an open `<p>` element to be implicitly closed in HTML5/HTML4.
fn closes_open_p(tag: &str) -> bool {
    matches!(
        tag,
        "address"
            | "article"
            | "aside"
            | "blockquote"
            | "details"
            | "dialog"
            | "dd"
            | "div"
            | "dl"
            | "dt"
            | "fieldset"
            | "figcaption"
            | "figure"
            | "footer"
            | "form"
            | "h1"
            | "h2"
            | "h3"
            | "h4"
            | "h5"
            | "h6"
            | "header"
            | "hgroup"
            | "hr"
            | "li"
            | "main"
            | "menu"
            | "nav"
            | "ol"
            | "p"
            | "pre"
            | "search"
            | "section"
            | "table"
            | "ul"
    )
}

/// Top-level block elements that libxml2 (`Nokogiri::HTML`) will NOT implicitly wrap in `<p>`.
fn is_safe_top_level_block(tag: &str) -> bool {
    matches!(
        tag,
        "article"
            | "aside"
            | "blockquote"
            | "div"
            | "dl"
            | "figure"
            | "footer"
            | "form"
            | "h1"
            | "h2"
            | "h3"
            | "h4"
            | "h5"
            | "h6"
            | "header"
            | "hr"
            | "main"
            | "nav"
            | "ol"
            | "p"
            | "section"
            | "style"
            | "script"
            | "ul"
    )
}

#[derive(Clone, Debug)]
struct HtmlAttr {
    name: String,
    value: String,
}

fn is_ascii_ws(b: u8) -> bool {
    matches!(b, b' ' | b'\t' | b'\n' | b'\r' | 0x0C)
}

fn is_tag_name_byte(b: u8) -> bool {
    b.is_ascii_alphanumeric() || b == b'-'
}

fn is_attr_name_byte(b: u8) -> bool {
    b.is_ascii_alphanumeric() || matches!(b, b'-' | b'_' | b':' | b'.')
}

/// Returns true if `s` has only safe HTML text entities (`&amp;`, `&lt;`, `&gt;`, and optionally
/// `&nbsp;` for HTML5 where libgumbo preserves it rather than decoding to U+00A0) and no `\r`/`\0`.
fn validate_and_write_text(
    text: &str,
    out: &mut String,
    escape_gt: bool,
    allow_nbsp: bool,
) -> bool {
    let bytes = text.as_bytes();
    let mut i = 0;
    let mut start = 0;
    while i < bytes.len() {
        let b = bytes[i];
        match b {
            b'\r' | 0 => return false,
            b'&' => {
                let rest = &bytes[i..];
                if rest.starts_with(b"&amp;") {
                    i += 5;
                } else if rest.starts_with(b"&lt;") || rest.starts_with(b"&gt;") {
                    i += 4;
                } else if allow_nbsp && rest.starts_with(b"&nbsp;") {
                    i += 6;
                } else {
                    return false;
                }
            }
            b'>' if escape_gt => {
                out.push_str(&text[start..i]);
                out.push_str("&gt;");
                i += 1;
                start = i;
            }
            _ => i += 1,
        }
    }
    out.push_str(&text[start..]);
    true
}

/// Validates an attribute value for HTML5 double-quoted serialization.
/// Allows `&amp;`, `&quot;`, `&nbsp;` verbatim; escapes `"` -> `&quot;`.
/// Rejects `\r`, `\0`, or other `&` entity references that Nokogiri would decode differently.
fn normalize_attr_value_html5(raw: &str) -> Option<String> {
    let bytes = raw.as_bytes();
    let mut i = 0;
    let mut out = String::with_capacity(raw.len());
    let mut start = 0;
    while i < bytes.len() {
        match bytes[i] {
            b'\r' | 0 => return None,
            b'"' => {
                out.push_str(&raw[start..i]);
                out.push_str("&quot;");
                i += 1;
                start = i;
            }
            b'&' => {
                let rest = &bytes[i..];
                if rest.starts_with(b"&amp;") {
                    i += 5;
                } else if rest.starts_with(b"&quot;") || rest.starts_with(b"&nbsp;") {
                    i += 6;
                } else {
                    return None;
                }
            }
            _ => i += 1,
        }
    }
    out.push_str(&raw[start..]);
    Some(out)
}

/// Validates an attribute value for libxml2 HTML4 double-quoted serialization (`Nokogiri::HTML`).
/// Rejects `"` / `&quot;` (libxml2 switches to single-quoted attributes) and `&nbsp;` (libxml2
/// decodes to literal U+00A0), allowing only `&amp;` verbatim.
fn normalize_attr_value_html4(raw: &str) -> Option<String> {
    let bytes = raw.as_bytes();
    let mut i = 0;
    while i < bytes.len() {
        match bytes[i] {
            b'\r' | 0 | b'"' => return None,
            b'&' => {
                if bytes[i..].starts_with(b"&amp;") {
                    i += 5;
                } else {
                    return None;
                }
            }
            _ => i += 1,
        }
    }
    Some(raw.to_string())
}

/// Returns true if a normalized HTML5 attribute value (`normalize_attr_value_html5`) is blank
/// after HTML entity decoding (matching Rails `String#blank?` on Nokogiri's decoded value).
fn is_blank_html5_attr(val: &str) -> bool {
    let mut rest = val;
    while !rest.is_empty() {
        if let Some(after) = rest.strip_prefix("&nbsp;") {
            rest = after;
            continue;
        }
        let mut chars = rest.chars();
        match chars.next() {
            Some(c) if c.is_whitespace() => rest = chars.as_str(),
            _ => return false,
        }
    }
    true
}

/// Escapes `value` matching `ERB::Util.html_escape`: `&`, `"`, `'`, `<`, `>`.
fn write_erb_html_escape(s: &str, out: &mut String) {
    let bytes = s.as_bytes();
    let mut start = 0;
    for (i, &b) in bytes.iter().enumerate() {
        let replacement = match b {
            b'&' => "&amp;",
            b'"' => "&quot;",
            b'\'' => "&#39;",
            b'<' => "&lt;",
            b'>' => "&gt;",
            _ => continue,
        };
        out.push_str(&s[start..i]);
        out.push_str(replacement);
        start = i + 1;
    }
    out.push_str(&s[start..]);
}

/// Parses an HTML start tag starting right after `<` at `pos`.
/// Returns `(tag_name_lower, attrs, is_self_closing, next_pos)` or `None` if outside fast-path domain.
fn parse_start_tag(
    html: &str,
    pos: usize,
    allow_unquoted_and_boolean: bool,
    html4_strict_attrs: bool,
) -> Option<(String, Vec<HtmlAttr>, bool, usize)> {
    let bytes = html.as_bytes();
    let len = bytes.len();
    if pos >= len || !bytes[pos].is_ascii_alphabetic() {
        return None;
    }

    let name_start = pos;
    let mut i = pos;
    while i < len && is_tag_name_byte(bytes[i]) {
        i += 1;
    }
    // Require whitespace, `>`, or `/` immediately after tag name so `<a_widget>` is not split into
    // `<a _widget>` (matching libxml2/libgumbo tokenization).
    if i >= len || (!is_ascii_ws(bytes[i]) && bytes[i] != b'>' && bytes[i] != b'/') {
        return None;
    }
    let tag_name = html[name_start..i].to_ascii_lowercase();

    let mut attrs: Vec<HtmlAttr> = Vec::new();
    let mut seen_names: Vec<String> = Vec::new();

    loop {
        while i < len && is_ascii_ws(bytes[i]) {
            if bytes[i] == b'\r' {
                return None;
            }
            i += 1;
        }
        if i >= len {
            return None;
        }
        if bytes[i] == b'>' {
            return Some((tag_name, attrs, false, i + 1));
        }
        if bytes[i] == b'/' {
            if i + 1 < len && bytes[i + 1] == b'>' {
                return Some((tag_name, attrs, true, i + 2));
            }
            return None;
        }

        // Attribute name
        let attr_start = i;
        while i < len && is_attr_name_byte(bytes[i]) {
            i += 1;
        }
        if i == attr_start {
            return None;
        }
        let attr_name = html[attr_start..i].to_ascii_lowercase();
        if seen_names.iter().any(|n| n == &attr_name) {
            // HTML5/HTML4 deduplicates repeated attributes; defer to Nokogiri.
            return None;
        }
        seen_names.push(attr_name.clone());

        while i < len && is_ascii_ws(bytes[i]) {
            if bytes[i] == b'\r' {
                return None;
            }
            i += 1;
        }

        let attr_value = if i < len && bytes[i] == b'=' {
            i += 1;
            while i < len && is_ascii_ws(bytes[i]) {
                if bytes[i] == b'\r' {
                    return None;
                }
                i += 1;
            }
            if i >= len {
                return None;
            }
            match bytes[i] {
                b'"' | b'\'' => {
                    let quote = bytes[i];
                    i += 1;
                    let val_start = i;
                    while i < len && bytes[i] != quote {
                        if bytes[i] == b'\r' || bytes[i] == 0 {
                            return None;
                        }
                        i += 1;
                    }
                    if i >= len {
                        return None;
                    }
                    let raw_val = &html[val_start..i];
                    i += 1;
                    // Require whitespace, `>`, or `/>` immediately after closing quote
                    if i < len && !is_ascii_ws(bytes[i]) && bytes[i] != b'>' && bytes[i] != b'/' {
                        return None;
                    }
                    if html4_strict_attrs {
                        normalize_attr_value_html4(raw_val)?
                    } else {
                        normalize_attr_value_html5(raw_val)?
                    }
                }
                _ => {
                    if !allow_unquoted_and_boolean {
                        return None;
                    }
                    let val_start = i;
                    while i < len && !is_ascii_ws(bytes[i]) && bytes[i] != b'>' {
                        if matches!(bytes[i], b'"' | b'\'' | b'<' | b'=' | b'`' | b'\r' | 0) {
                            return None;
                        }
                        i += 1;
                    }
                    let raw_val = &html[val_start..i];
                    if raw_val.is_empty() {
                        return None;
                    }
                    if html4_strict_attrs {
                        normalize_attr_value_html4(raw_val)?
                    } else {
                        normalize_attr_value_html5(raw_val)?
                    }
                }
            }
        } else {
            if !allow_unquoted_and_boolean {
                return None;
            }
            String::new()
        };

        attrs.push(HtmlAttr {
            name: attr_name,
            value: attr_value,
        });
    }
}

/// Matches `Billboards::ShadowDomWrapper::EXECUTABLE_SCRIPT_TYPES`:
/// `/\A\s*(?:text\/javascript|application\/javascript|text\/ecmascript|application\/ecmascript|module)\s*(?:;.*)?\z/i`
/// Note: Ruby's `.` does NOT match `\n` without `/m`, so a `;...` parameter suffix containing LF
/// does not match and leaves the script unchanged.
fn is_executable_script_type(script_type: &str) -> bool {
    let trimmed = script_type.trim();
    if trimmed.is_empty() {
        return true;
    }
    let mime = match trimmed.find(';') {
        Some(idx) => {
            if trimmed[idx + 1..].contains('\n') {
                return false;
            }
            trimmed[..idx].trim_end()
        }
        None => trimmed,
    };
    mime.eq_ignore_ascii_case("text/javascript")
        || mime.eq_ignore_ascii_case("application/javascript")
        || mime.eq_ignore_ascii_case("text/ecmascript")
        || mime.eq_ignore_ascii_case("application/ecmascript")
        || mime.eq_ignore_ascii_case("module")
}

fn set_attr(attrs: &mut Vec<HtmlAttr>, name: &str, value: String) {
    if let Some(existing) = attrs.iter_mut().find(|a| a.name == name) {
        existing.value = value;
    } else {
        attrs.push(HtmlAttr {
            name: name.to_string(),
            value,
        });
    }
}

fn remove_attr(attrs: &mut Vec<HtmlAttr>, name: &str) {
    attrs.retain(|a| a.name != name);
}

fn get_attr<'a>(attrs: &'a [HtmlAttr], name: &str) -> Option<&'a str> {
    attrs
        .iter()
        .find(|a| a.name == name)
        .map(|a| a.value.as_str())
}

/// Finds the matching closing tag `</tag_name>` (ASCII case-insensitive, optional trailing
/// whitespace before `>`) for raw text elements `<style>` or `<script>`.
/// Returns `(raw_body_end, after_close_tag)` or `None` if unclosed or containing `\r`/`\0`.
fn find_raw_text_close(html: &str, start: usize, tag_name: &str) -> Option<(usize, usize)> {
    let bytes = html.as_bytes();
    let len = bytes.len();
    let tag_bytes = tag_name.as_bytes();
    let is_script = tag_name == "script";
    let mut i = start;
    while i < len {
        if bytes[i] == b'\r' || bytes[i] == 0 {
            return None;
        }
        if is_script && bytes[i..].starts_with(b"<!--") {
            return None;
        }
        if bytes[i] == b'<' && i + 2 + tag_bytes.len() <= len && bytes[i + 1] == b'/' {
            let candidate = &bytes[i + 2..i + 2 + tag_bytes.len()];
            if candidate.eq_ignore_ascii_case(tag_bytes) {
                let after_name = i + 2 + tag_bytes.len();
                let mut j = after_name;
                while j < len && is_ascii_ws(bytes[j]) {
                    if bytes[j] == b'\r' {
                        return None;
                    }
                    j += 1;
                }
                if j < len && bytes[j] == b'>' {
                    return Some((i, j + 1));
                }
                if after_name < len && (is_ascii_ws(bytes[after_name]) || bytes[after_name] == b'/')
                {
                    return None;
                }
            }
        }
        i += 1;
    }
    None
}

fn write_start_tag(tag_name: &str, attrs: &[HtmlAttr], out: &mut String) {
    out.push('<');
    out.push_str(tag_name);
    for attr in attrs {
        out.push(' ');
        out.push_str(&attr.name);
        out.push_str("=\"");
        out.push_str(&attr.value);
        out.push('"');
    }
    out.push('>');
}

/// Tier 1 primitive: prepares inner billboard HTML for Declarative Shadow DOM isolation,
/// matching `Billboards::ShadowDomWrapper#prepare_inner_html` (`Nokogiri::HTML5.fragment`):
/// - Strips `<base>` elements
/// - Strips `<meta http-equiv="refresh">` (case-insensitive, trimmed)
/// - Neutralizes executable `<script>` elements (sets `data-original-type`, `type`,
///   `data-billboard-script="true"`, and moves non-blank `src` to `data-billboard-script-src`)
///
/// Returns `None` whenever the HTML contains unbalanced tags, `<template>`, tables/foreign
/// elements, or exotic entities requiring full HTML5 libgumbo parsing.
pub fn billboard_prepare_shadow_inner_html(
    raw_html: &str,
    script_mime_type: &str,
) -> Option<String> {
    if raw_html.is_empty() || raw_html.chars().all(char::is_whitespace) {
        return Some(String::new());
    }

    let bytes = raw_html.as_bytes();
    let len = bytes.len();
    let mut out = String::with_capacity(len + 128);
    let mut stack: Vec<String> = Vec::with_capacity(16);
    let mut i = 0;

    while i < len {
        if bytes[i] != b'<' {
            let text_start = i;
            while i < len && bytes[i] != b'<' {
                i += 1;
            }
            if !validate_and_write_text(&raw_html[text_start..i], &mut out, true, true) {
                return None;
            }
            continue;
        }

        // Handle comments `<!-- ... -->`
        if bytes[i..].starts_with(b"<!--") {
            let comment_body_start = i + 4;
            let rel_end = raw_html[comment_body_start..].find("-->")?;
            let comment_body = &raw_html[comment_body_start..comment_body_start + rel_end];
            // Defer on malformed HTML5 comment edge cases (`<!-->`, `<!--->`, `--`, `\r`, `\0`)
            if comment_body.is_empty()
                || comment_body.starts_with('>')
                || comment_body.starts_with("->")
                || comment_body.contains("--")
                || comment_body.contains('\r')
                || comment_body.contains('\0')
            {
                return None;
            }
            let comment_end = comment_body_start + rel_end + 3;
            out.push_str(&raw_html[i..comment_end]);
            i = comment_end;
            continue;
        }

        // Defer on DOCTYPE / CDATA / processing instructions
        if i + 1 >= len || bytes[i + 1] == b'!' || bytes[i + 1] == b'?' {
            return None;
        }

        // Closing tag `</...>`
        if bytes[i + 1] == b'/' {
            let name_start = i + 2;
            let mut j = name_start;
            while j < len && is_tag_name_byte(bytes[j]) {
                j += 1;
            }
            if j == name_start {
                return None;
            }
            let close_name = raw_html[name_start..j].to_ascii_lowercase();
            while j < len && is_ascii_ws(bytes[j]) {
                if bytes[j] == b'\r' {
                    return None;
                }
                j += 1;
            }
            if j >= len || bytes[j] != b'>' {
                return None;
            }
            if is_void_element(&close_name) || is_unsupported_special_element(&close_name) {
                return None;
            }
            let expected = stack.pop()?;
            if expected != close_name {
                return None;
            }
            out.push_str("</");
            out.push_str(&close_name);
            out.push('>');
            i = j + 1;
            continue;
        }

        // Opening tag `<tag ...>`
        let (tag_name, mut attrs, is_self_closing, next_pos) =
            parse_start_tag(raw_html, i + 1, true, false)?;
        if is_unsupported_special_element(&tag_name) {
            return None;
        }

        let void_elem = is_void_element(&tag_name);
        if is_self_closing && !void_elem {
            return None;
        }

        // HTML5 implicit end-tag and nested-form guards
        if tag_name == "form" && stack.iter().any(|t| t == "form") {
            return None;
        }
        if let Some(top) = stack.last() {
            if top == "p" && closes_open_p(&tag_name) {
                return None;
            }
            if (top == "li" && tag_name == "li")
                || (top == "a" && tag_name == "a")
                || (top == "button" && tag_name == "button")
                || ((top == "dt" || top == "dd") && (tag_name == "dt" || tag_name == "dd"))
            {
                return None;
            }
        }

        // Strip `<base>`
        if tag_name == "base" {
            i = next_pos;
            continue;
        }

        // Strip `<meta http-equiv="refresh">`
        if tag_name == "meta" {
            if let Some(http_equiv) = get_attr(&attrs, "http-equiv") {
                if http_equiv.contains('&') || !http_equiv.is_ascii() {
                    return None;
                }
                if http_equiv.trim().eq_ignore_ascii_case("refresh") {
                    i = next_pos;
                    continue;
                }
            }
            write_start_tag("meta", &attrs, &mut out);
            i = next_pos;
            continue;
        }

        // Raw text elements: `<style>` and `<script>`
        if tag_name == "style" || tag_name == "script" {
            let (body_end, after_close) = find_raw_text_close(raw_html, next_pos, &tag_name)?;
            let body = &raw_html[next_pos..body_end];

            if tag_name == "script" {
                let orig_type_owned = get_attr(&attrs, "type").map(|s| s.to_string());
                if let Some(ref ot) = orig_type_owned {
                    if ot.contains('&') || !ot.is_ascii() {
                        return None;
                    }
                }
                let trimmed_type = orig_type_owned.as_deref().unwrap_or("").trim();
                if is_executable_script_type(trimmed_type) {
                    if !trimmed_type.is_empty() {
                        set_attr(&mut attrs, "data-original-type", trimmed_type.to_string());
                    }
                    set_attr(&mut attrs, "type", script_mime_type.to_string());
                    set_attr(&mut attrs, "data-billboard-script", "true".to_string());

                    if let Some(src_val) = get_attr(&attrs, "src").map(|s| s.to_string()) {
                        if !is_blank_html5_attr(&src_val) {
                            set_attr(&mut attrs, "data-billboard-script-src", src_val);
                            remove_attr(&mut attrs, "src");
                        }
                    }
                }
            }

            write_start_tag(&tag_name, &attrs, &mut out);
            out.push_str(body);
            out.push_str("</");
            out.push_str(&tag_name);
            out.push('>');
            i = after_close;
            continue;
        }

        write_start_tag(&tag_name, &attrs, &mut out);
        if !void_elem {
            stack.push(tag_name);
        }
        i = next_pos;
    }

    if !stack.is_empty() {
        return None;
    }

    Some(out)
}

/// Tier 2 single-pass pipeline kernel: prepares inner billboard HTML AND wraps it in the
/// complete Declarative Shadow DOM host envelope in a single pre-allocated Rust buffer.
pub fn billboard_wrap_shadow_dom(
    raw_html: &str,
    billboard_id: &str,
    template: &str,
    base_styles: &str,
    bootstrap_script: &str,
    script_mime_type: &str,
) -> Option<String> {
    let prepared = billboard_prepare_shadow_inner_html(raw_html, script_mime_type)?;

    let cap = 260
        + billboard_id.len()
        + template.len()
        + base_styles.len()
        + prepared.len()
        + bootstrap_script.len();
    let mut out = String::with_capacity(cap);

    out.push_str(
        "<div class=\"billboard-shadow-host\" data-billboard-shadow-host=\"true\" data-billboard-id=\"",
    );
    write_erb_html_escape(billboard_id, &mut out);
    out.push_str("\" data-billboard-template=\"");
    write_erb_html_escape(template, &mut out);
    out.push_str(
        "\"><template shadowrootmode=\"open\"><style data-billboard-base-styles=\"true\">",
    );
    out.push_str(base_styles);
    out.push_str("</style><div class=\"billboard-shadow-body\">");
    out.push_str(&prepared);
    out.push_str("</div></template></div><script data-billboard-shadow-bootstrap=\"true\">");
    out.push_str(bootstrap_script);
    out.push_str("</script>");

    Some(out)
}

/// Returns true if `b` is a pass-through character for existing `application/x-www-form-urlencoded`
/// query keys/values (where `+` already represents a space).
fn is_www_form_unencoded_byte(b: u8) -> bool {
    b.is_ascii_alphanumeric() || matches!(b, b'-' | b'.' | b'_' | b'*' | b'+')
}

/// Returns true if `b` passes through `URI.encode_www_form_component` unchanged (note `+` is
/// encoded as `%2B` by Ruby, so it is excluded here).
fn is_billboard_id_unencoded_byte(b: u8) -> bool {
    b.is_ascii_alphanumeric() || matches!(b, b'-' | b'.' | b'_' | b'*')
}

/// Validates that every `%` in `s` is followed by two ASCII hex digits.
fn has_valid_percent_escapes(s: &str) -> bool {
    let bytes = s.as_bytes();
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'%' {
            if i + 2 >= bytes.len()
                || !bytes[i + 1].is_ascii_hexdigit()
                || !bytes[i + 2].is_ascii_hexdigit()
            {
                return false;
            }
            i += 3;
        } else {
            i += 1;
        }
    }
    true
}

/// Returns true if `b` is a safe ASCII URI character that `URI.parse` accepts without
/// raising `URI::InvalidURIError` or normalizing escapes.
fn is_safe_uri_base_byte(b: u8) -> bool {
    b.is_ascii_alphanumeric()
        || matches!(
            b,
            b'-' | b'.'
                | b'_'
                | b'~'
                | b':'
                | b'/'
                | b'@'
                | b'!'
                | b'$'
                | b'\''
                | b'('
                | b')'
                | b'*'
                | b'+'
                | b','
                | b';'
                | b'='
        )
}

/// Rewrites `href` to set or append `bb=<billboard_id>`, matching `Billboard#with_bb_param`:
/// - `URI.decode_www_form` + update/append `bb` + `URI.encode_www_form`
/// - Exact `Nokogiri::HTML` + `gsub!(/href="([^"]*)&amp;([^"]*)"/, 'href="\1&\2"')` escaping
///   (all query separators `&amp;` except the final separator `&`).
///
/// Returns `None` if `href` requires full `URI.parse` / `URI.decode_www_form` fallback.
fn rewrite_href_with_bb_param(href: &str, billboard_id: &str) -> Option<String> {
    if href.is_empty() || (!href.starts_with("http") && !href.starts_with('/')) {
        // Not rewritten — only allow if it has no `&amp;` (which legacy gsub! would touch)
        if href.contains("&amp;") {
            return None;
        }
        return Some(href.to_string());
    }

    // Require standard `http://`, `https://`, or `/` prefix
    if href.starts_with("http") && !href.starts_with("http://") && !href.starts_with("https://") {
        return None;
    }

    // Split optional `#fragment`
    let (before_frag, frag) = match href.find('#') {
        Some(idx) => {
            let f = &href[idx + 1..];
            // Defer if fragment contains another `#`, `&`, or non-URI chars
            if f.contains('#') || f.contains('&') || !f.bytes().all(is_safe_uri_base_byte) {
                return None;
            }
            (&href[..idx], Some(f))
        }
        None => (href, None),
    };

    // Split optional `?query`
    let (base, query_opt) = match before_frag.find('?') {
        Some(idx) => (&before_frag[..idx], Some(&before_frag[idx + 1..])),
        None => (before_frag, None),
    };

    // Validate base URI bytes (no spaces, brackets, percent-encoding edge cases, or `&`)
    if base.is_empty() || !base.bytes().all(is_safe_uri_base_byte) {
        return None;
    }

    // Defer on explicit ports or userinfo in authority so Ruby's URI.parse handles default-port
    // stripping (e.g. `https://example.com:443/offer` -> `https://example.com/offer`) identically.
    if let Some(after_scheme) = base
        .strip_prefix("https://")
        .or_else(|| base.strip_prefix("http://"))
    {
        let authority = match after_scheme.find('/') {
            Some(idx) => &after_scheme[..idx],
            None => after_scheme,
        };
        if authority.is_empty() || authority.contains(':') || authority.contains('@') {
            return None;
        }
    }

    // Parse query parameters
    let mut params: Vec<(&str, &str)> = Vec::new();
    let mut found_bb = false;

    if let Some(q) = query_opt {
        if !q.is_empty() {
            // Split on `&amp;` or raw `&`
            let mut rest = q;
            while !rest.is_empty() {
                let (part, next_rest) = match rest.find('&') {
                    Some(idx) => {
                        let after = &rest[idx..];
                        if let Some(stripped) = after.strip_prefix("&amp;") {
                            (&rest[..idx], stripped)
                        } else {
                            (&rest[..idx], &rest[idx + 1..])
                        }
                    }
                    None => (rest, ""),
                };
                if part.is_empty() {
                    return None;
                }
                let (k, v) = match part.find('=') {
                    Some(eq) => {
                        let key = &part[..eq];
                        let val = &part[eq + 1..];
                        if val.contains('=') {
                            return None;
                        }
                        (key, val)
                    }
                    None => (part, ""),
                };
                if !k.bytes().all(is_www_form_unencoded_byte)
                    || !v.bytes().all(is_www_form_unencoded_byte)
                {
                    return None;
                }
                if k == "bb" && !found_bb {
                    params.push((k, billboard_id));
                    found_bb = true;
                } else {
                    params.push((k, v));
                }
                rest = next_rest;
            }
        }
    }

    if !found_bb {
        params.push(("bb", billboard_id));
    }

    let mut out = String::with_capacity(href.len() + billboard_id.len() + 8);
    out.push_str(base);
    out.push('?');
    let last_sep_idx = params.len().saturating_sub(1);
    for (idx, (k, v)) in params.iter().enumerate() {
        if idx > 0 {
            if idx == last_sep_idx {
                out.push('&');
            } else {
                out.push_str("&amp;");
            }
        }
        out.push_str(k);
        out.push('=');
        out.push_str(v);
    }
    if let Some(f) = frag {
        out.push('#');
        out.push_str(f);
    }
    Some(out)
}

/// Elements that libxml2's HTML4 element table (`html40ElementTable`) flags as non-inline.
/// `htmlNodeDumpFormatOutput` (used by `Nokogiri::XML::Node#inner_html`) inserts formatting
/// newlines around these; HTML5-only elements (`section`, `article`, ...) are unknown to libxml2
/// and are therefore serialized like inline elements.
fn is_libxml2_block_element(tag: &str) -> bool {
    matches!(
        tag,
        "address"
            | "area"
            | "base"
            | "blockquote"
            | "center"
            | "dd"
            | "dir"
            | "div"
            | "dl"
            | "dt"
            | "fieldset"
            | "form"
            | "h1"
            | "h2"
            | "h3"
            | "h4"
            | "h5"
            | "h6"
            | "hr"
            | "isindex"
            | "legend"
            | "li"
            | "link"
            | "menu"
            | "meta"
            | "ol"
            | "p"
            | "param"
            | "style"
            | "ul"
    )
}

/// HTML4 boolean attributes that libxml2's `htmlIsBooleanAttr` collapses to bare names
/// (`disabled` instead of `disabled="disabled"`).
fn is_libxml2_boolean_attr(name: &str) -> bool {
    matches!(
        name,
        "checked"
            | "compact"
            | "declare"
            | "defer"
            | "disabled"
            | "ismap"
            | "multiple"
            | "nohref"
            | "noresize"
            | "noshade"
            | "nowrap"
            | "readonly"
            | "selected"
    )
}

/// HTML5 void elements that libxml2's HTML4 parser does not treat as empty (or legacy empty
/// elements the HTML5 scanner does not know); defer these to Nokogiri.
fn is_libxml2_void_mismatch(tag: &str) -> bool {
    matches!(
        tag,
        "embed" | "source" | "track" | "wbr" | "basefont" | "isindex"
    )
}

/// Returns `true` if libxml2's HTML4 parser (`htmlAutoClose` / `htmlStartClose` table) would
/// implicitly close an open `parent` element when a `child` start tag is encountered, which
/// restructures the tree; the `bb` param fast path defers these inputs to Nokogiri.
fn libxml2_autocloses(parent: &str, child: &str) -> bool {
    let heading_closers = ["fieldset", "form", "li", "p"];
    match parent {
        "a" => matches!(child, "a" | "fieldset"),
        "address" => matches!(child, "dd" | "dl" | "dt" | "form" | "li" | "ul"),
        "b" | "i" => matches!(child, "center" | "p"),
        "big" | "s" | "small" | "strike" | "tt" | "u" => child == "p",
        "dd" => matches!(child, "dd" | "dt"),
        "dt" => matches!(child, "dd" | "dl" | "dt"),
        "dir" | "menu" => matches!(child, "dd" | "dl" | "dt" | "form" | "ul"),
        "dl" => matches!(child, "form" | "li"),
        "font" => child == "center",
        "form" | "ol" => child == "form",
        "h1" | "h2" | "h3" | "h4" | "h5" | "h6" => heading_closers.contains(&child),
        "legend" => child == "fieldset",
        "li" => child == "li",
        "p" => closes_open_p(child) || matches!(child, "center" | "dir"),
        "ul" => matches!(child, "address" | "form" | "menu"),
        "button" => child == "button",
        _ => false,
    }
}

/// Maximum element nesting depth accepted by the `bb` param fast path.
const BB_PARAM_MAX_DEPTH: usize = 256;

/// Lightweight parsed node used to replay libxml2's HTML serializer formatting.
enum BbNode {
    /// Already-escaped text exactly as it will be emitted.
    Text(String),
    Element {
        name: String,
        start_tag: String,
        void: bool,
        children: Vec<BbNode>,
    },
}

impl BbNode {
    fn is_element(&self) -> bool {
        matches!(self, BbNode::Element { .. })
    }
}

/// Serializes `nodes` (children of `parent_name`) following libxml2's
/// `htmlNodeDumpFormatOutput` formatting rules with `format = 1`.
fn serialize_bb_nodes(nodes: &[BbNode], parent_name: &str, out: &mut String) {
    let parent_allows_newline = !parent_name.starts_with('p');
    for (idx, node) in nodes.iter().enumerate() {
        match node {
            BbNode::Text(text) => out.push_str(text),
            BbNode::Element {
                name,
                start_tag,
                void,
                children,
            } => {
                let block = is_libxml2_block_element(name);
                out.push_str(start_tag);
                if !*void {
                    let format_children = block && children.len() > 1 && !name.starts_with('p');
                    if format_children && children[0].is_element() {
                        out.push('\n');
                    }
                    serialize_bb_nodes(children, name, out);
                    if format_children && children[children.len() - 1].is_element() {
                        out.push('\n');
                    }
                    // libxml2 omits the optional end tag of an empty `<li>` (`saveEndTag`).
                    if !(children.is_empty() && name == "li") {
                        out.push_str("</");
                        out.push_str(name);
                        out.push('>');
                    }
                }
                if block
                    && parent_allows_newline
                    && nodes.get(idx + 1).is_some_and(BbNode::is_element)
                {
                    out.push('\n');
                }
            }
        }
    }
}

/// Tier 1 primitive: injects or updates `bb=<billboard_id>` on every `http`/`https`/`/`
/// `<a href="...">` link in `html`, matching `Billboard#with_bb_param` (including the
/// formatting newlines libxml2 inserts around block-level elements on serialization).
///
/// Returns `None` if `html` falls outside the strict fast-path domain (bare top-level text
/// or inline tags that libxml2 wraps in `<p>`, unbalanced tags, complex URI encoding, etc.).
pub fn billboard_append_bb_param(html: &str, billboard_id: &str) -> Option<String> {
    if html.is_empty() || html.chars().all(char::is_whitespace) {
        return Some(html.to_string());
    }
    if billboard_id.is_empty() || !billboard_id.bytes().all(is_billboard_id_unencoded_byte) {
        return None;
    }

    let bytes = html.as_bytes();
    let len = bytes.len();
    let mut roots: Vec<BbNode> = Vec::new();
    // Open elements: (name, start_tag, children)
    let mut stack: Vec<(String, String, Vec<BbNode>)> = Vec::with_capacity(16);
    let mut i = 0;

    while i < len {
        if bytes[i] != b'<' {
            let text_start = i;
            while i < len && bytes[i] != b'<' {
                i += 1;
            }
            let text = &html[text_start..i];
            // libxml2 may wrap non-whitespace top-level text in `<p>`; defer to Nokogiri.
            if stack.is_empty() && !text.bytes().all(is_ascii_ws) {
                return None;
            }
            let mut escaped = String::with_capacity(text.len());
            if !validate_and_write_text(text, &mut escaped, true, false) {
                return None;
            }
            let siblings = match stack.last_mut() {
                Some((_, _, children)) => children,
                None => &mut roots,
            };
            siblings.push(BbNode::Text(escaped));
            continue;
        }

        // Defer on comments, DOCTYPE, CDATA, processing instructions
        if i + 1 >= len || bytes[i + 1] == b'!' || bytes[i + 1] == b'?' {
            return None;
        }

        // Closing tag
        if bytes[i + 1] == b'/' {
            let name_start = i + 2;
            let mut j = name_start;
            while j < len && is_tag_name_byte(bytes[j]) {
                j += 1;
            }
            if j == name_start {
                return None;
            }
            let close_name = html[name_start..j].to_ascii_lowercase();
            while j < len && is_ascii_ws(bytes[j]) {
                if bytes[j] == b'\r' {
                    return None;
                }
                j += 1;
            }
            if j >= len || bytes[j] != b'>' {
                return None;
            }
            if is_void_element(&close_name)
                || is_unsupported_special_element(&close_name)
                || is_libxml2_void_mismatch(&close_name)
            {
                return None;
            }
            let (name, start_tag, children) = stack.pop()?;
            if name != close_name {
                return None;
            }
            let element = BbNode::Element {
                name,
                start_tag,
                void: false,
                children,
            };
            match stack.last_mut() {
                Some((_, _, siblings)) => siblings.push(element),
                None => roots.push(element),
            }
            i = j + 1;
            continue;
        }

        // Opening tag (require quoted HTML4-strict attributes for exact libxml2 parity)
        let (tag_name, mut attrs, is_self_closing, next_pos) =
            parse_start_tag(html, i + 1, false, true)?;
        if is_unsupported_special_element(&tag_name) || is_libxml2_void_mismatch(&tag_name) {
            return None;
        }
        let void_elem = is_void_element(&tag_name);
        if is_self_closing && !void_elem {
            return None;
        }
        if stack.is_empty() && !is_safe_top_level_block(&tag_name) {
            return None;
        }
        if tag_name == "form" && stack.iter().any(|(t, _, _)| t == "form") {
            return None;
        }
        if attrs.iter().any(|a| is_libxml2_boolean_attr(&a.name)) {
            return None;
        }
        if let Some((top, _, _)) = stack.last() {
            if libxml2_autocloses(top, &tag_name) {
                return None;
            }
        }

        if tag_name == "a" {
            if let Some(href_attr) = attrs.iter_mut().find(|a| a.name == "href") {
                href_attr.value = rewrite_href_with_bb_param(&href_attr.value, billboard_id)?;
            }
        } else if attrs
            .iter()
            .any(|a| a.name == "href" && a.value.contains("&amp;"))
        {
            return None;
        }

        let mut start_tag = String::with_capacity(next_pos - i + 16);
        write_start_tag(&tag_name, &attrs, &mut start_tag);

        let element = if tag_name == "style" || tag_name == "script" {
            let (body_end, after_close) = find_raw_text_close(html, next_pos, &tag_name)?;
            let body = &html[next_pos..body_end];
            let children = if body.is_empty() {
                Vec::new()
            } else {
                vec![BbNode::Text(body.to_string())]
            };
            i = after_close;
            BbNode::Element {
                name: tag_name,
                start_tag,
                void: false,
                children,
            }
        } else if void_elem {
            i = next_pos;
            BbNode::Element {
                name: tag_name,
                start_tag,
                void: true,
                children: Vec::new(),
            }
        } else {
            if stack.len() >= BB_PARAM_MAX_DEPTH {
                return None;
            }
            stack.push((tag_name, start_tag, Vec::new()));
            i = next_pos;
            continue;
        };

        match stack.last_mut() {
            Some((_, _, siblings)) => siblings.push(element),
            None => roots.push(element),
        }
    }

    if !stack.is_empty() {
        return None;
    }

    let mut out = String::with_capacity(len + 64);
    serialize_bb_nodes(&roots, "body", &mut out);
    Some(out)
}

/// Validates and parses an `href` for `billboard_extract_internal_article_paths`.
/// Returns `Ok(Some(path))` if internal & non-root, `Ok(None)` if external/ignored,
/// or `Err(())` to defer to Ruby `URI.parse`.
fn extract_internal_path_from_href(
    href: &str,
    internal_hosts: &[&str],
) -> Result<Option<String>, ()> {
    if href.is_empty() || (!href.starts_with("http") && !href.starts_with('/')) {
        return Ok(None);
    }
    // Defer on non-ASCII characters (so Ruby handles Unicode case-folding / URI errors)
    if !href.is_ascii() {
        return Err(());
    }
    // Reject whitespace, unsafe URI characters, or invalid percent escapes by deferring to Ruby
    if href.bytes().any(|b| {
        b <= 0x20
            || b >= 0x7F
            || matches!(
                b,
                b'<' | b'>' | b'"' | b'\\' | b'^' | b'`' | b'{' | b'|' | b'}' | b'[' | b']'
            )
    }) || !has_valid_percent_escapes(href)
    {
        return Err(());
    }

    // Strip `#fragment` and `?query`
    let before_frag = match href.find('#') {
        Some(idx) => {
            if href[idx + 1..].contains('#') {
                return Err(());
            }
            &href[..idx]
        }
        None => href,
    };
    let before_query = match before_frag.find('?') {
        Some(idx) => {
            // Allow `&amp;` in query string (valid `&` after Nokogiri entity decode),
            // but defer on any other HTML entity in the query string.
            let qbytes = &before_frag.as_bytes()[idx + 1..];
            let mut qi = 0;
            while qi < qbytes.len() {
                if qbytes[qi] == b'&' {
                    if qbytes[qi..].starts_with(b"&amp;") {
                        qi += 5;
                        continue;
                    }
                    return Err(());
                }
                qi += 1;
            }
            &before_frag[..idx]
        }
        None => before_frag,
    };
    // Defer on any `&` entity in scheme/host/path or fragment
    if before_query.contains('&')
        || (href.len() > before_frag.len() && href[before_frag.len()..].contains('&'))
    {
        return Err(());
    }

    let (host_opt, path) = if let Some(after_scheme) = before_query
        .strip_prefix("https://")
        .or_else(|| before_query.strip_prefix("http://"))
    {
        let (authority, path_part) = match after_scheme.find('/') {
            Some(idx) => (&after_scheme[..idx], &after_scheme[idx..]),
            None => (after_scheme, ""),
        };
        if authority.is_empty() || authority.contains('@') {
            return Err(());
        }
        let host_raw = match authority.find(':') {
            Some(idx) => {
                let port = &authority[idx + 1..];
                if !port.bytes().all(|b| b.is_ascii_digit()) {
                    return Err(());
                }
                &authority[..idx]
            }
            None => authority,
        };
        if host_raw.is_empty() {
            return Err(());
        }
        (Some(host_raw), path_part)
    } else if let Some(after_slashes) = before_query.strip_prefix("//") {
        let (authority, path_part) = match after_slashes.find('/') {
            Some(idx) => (&after_slashes[..idx], &after_slashes[idx..]),
            None => (after_slashes, ""),
        };
        if authority.is_empty() || authority.contains('@') {
            return Err(());
        }
        let host_raw = match authority.find(':') {
            Some(idx) => {
                let port = &authority[idx + 1..];
                if !port.bytes().all(|b| b.is_ascii_digit()) {
                    return Err(());
                }
                &authority[..idx]
            }
            None => authority,
        };
        if host_raw.is_empty() {
            return Err(());
        }
        (Some(host_raw), path_part)
    } else if before_query.starts_with('/') {
        (None, before_query)
    } else {
        // e.g. `httpfoo` without `://`
        return Err(());
    };

    if let Some(host_raw) = host_opt {
        let host_lower = host_raw.to_ascii_lowercase();
        let normalized_host = host_lower.strip_prefix("www.").unwrap_or(&host_lower);
        if !internal_hosts.contains(&normalized_host) {
            return Ok(None);
        }
    }

    if path.is_empty() || path == "/" {
        return Ok(None);
    }

    let trimmed = path.strip_suffix('/').unwrap_or(path);
    Ok(Some(trimmed.to_ascii_lowercase()))
}

/// Tier 1 primitive: extracts unique lowercased internal article paths from `<a href="...">`
/// tags in `html`, matching `Billboard#extract_internal_article_paths`.
///
/// `internal_hosts` must be pre-normalized (lowercase, without leading `"www."`).
/// Returns `None` if `html` contains entities or exotic URI/HTML constructs requiring
/// full Nokogiri + Ruby `URI.parse`.
pub fn billboard_extract_internal_article_paths(
    html: &str,
    internal_hosts: &[&str],
) -> Option<Vec<String>> {
    if html.is_empty() || html.chars().all(char::is_whitespace) {
        return Some(Vec::new());
    }

    // Fast-exit when no `<a` / `<A` tag exists anywhere in the HTML.
    let bytes = html.as_bytes();
    let len = bytes.len();
    let mut has_anchor = false;
    for idx in 0..len.saturating_sub(1) {
        if bytes[idx] == b'<' && (bytes[idx + 1] == b'a' || bytes[idx + 1] == b'A') {
            let after = bytes.get(idx + 2).copied();
            if matches!(after, Some(b' ' | b'\t' | b'\n' | b'\r' | b'/' | b'>')) {
                has_anchor = true;
                break;
            }
        }
    }
    if !has_anchor {
        return Some(Vec::new());
    }

    let mut paths: Vec<String> = Vec::new();
    let mut seen: HashSet<String> = HashSet::new();
    let mut i = 0;

    while i < len {
        if bytes[i] != b'<' {
            i += 1;
            continue;
        }

        // Skip well-formed HTML comments; defer on ambiguous bodies (e.g. `--!>`)
        if bytes[i..].starts_with(b"<!--") {
            let comment_body_start = i + 4;
            let rel_end = html[comment_body_start..].find("-->")?;
            let comment_body = &html[comment_body_start..comment_body_start + rel_end];
            if comment_body.is_empty()
                || comment_body.starts_with('>')
                || comment_body.starts_with("->")
                || comment_body.contains("--")
                || comment_body.contains('\r')
                || comment_body.contains('\0')
            {
                return None;
            }
            i = comment_body_start + rel_end + 3;
            continue;
        }

        // Defer on DOCTYPE / CDATA / processing instructions
        if i + 1 >= len || bytes[i + 1] == b'!' || bytes[i + 1] == b'?' {
            return None;
        }

        // Skip closing tags
        if bytes[i + 1] == b'/' {
            let rel_gt = html[i + 2..].find('>')?;
            i = i + 2 + rel_gt + 1;
            continue;
        }

        // Parse start tag
        let (tag_name, attrs, _is_self_closing, next_pos) =
            parse_start_tag(html, i + 1, true, false)?;
        if matches!(
            tag_name.as_str(),
            "noscript" | "textarea" | "xmp" | "iframe" | "title" | "plaintext" | "noembed"
        ) {
            return None;
        }

        if tag_name == "script" || tag_name == "style" {
            let (_body_end, after_close) = find_raw_text_close(html, next_pos, &tag_name)?;
            i = after_close;
            continue;
        }

        if tag_name == "a" {
            if let Some(href) = get_attr(&attrs, "href") {
                match extract_internal_path_from_href(href, internal_hosts) {
                    Ok(Some(path)) => {
                        if seen.insert(path.clone()) {
                            paths.push(path);
                        }
                    }
                    Ok(None) => {}
                    Err(()) => return None,
                }
            }
        }

        i = next_pos;
    }

    Some(paths)
}

#[cfg(test)]
mod tests {
    use super::*;

    const MIME: &str = "application/x-forem-billboard-script";

    #[test]
    fn prepare_shadow_inner_html_preserves_clean_markup() {
        let html = r#"<style>h1 { color: red; }</style><div class="promo"><h1>Hello &amp; Welcome</h1></div>"#;
        assert_eq!(
            billboard_prepare_shadow_inner_html(html, MIME).as_deref(),
            Some(html)
        );
    }

    #[test]
    fn prepare_shadow_inner_html_strips_base_and_meta_refresh() {
        let html = r#"<base href="https://evil.example.com/"><meta http-equiv=" Refresh " content="0;url=https://evil.example.com/"><meta name="author" content="DEV"><div>Safe</div>"#;
        assert_eq!(
            billboard_prepare_shadow_inner_html(html, MIME).as_deref(),
            Some(r#"<meta name="author" content="DEV"><div>Safe</div>"#)
        );
    }

    #[test]
    fn prepare_shadow_inner_html_neutralizes_executable_scripts_only() {
        let html = concat!(
            r#"<script>if (1 < 2 && 3 > 1) { window.x = 1; }</script>"#,
            r#"<script type="text/javascript">window.y = 2;</script>"#,
            r#"<script type="module">export const z = 3;</script>"#,
            r#"<script src="https://cdn.example.com/widget.js" defer></script>"#,
            r#"<script type="application/json" id="cfg">{"ok":true}</script>"#,
        );
        let expected = concat!(
            r#"<script type="application/x-forem-billboard-script" data-billboard-script="true">if (1 < 2 && 3 > 1) { window.x = 1; }</script>"#,
            r#"<script type="application/x-forem-billboard-script" data-original-type="text/javascript" data-billboard-script="true">window.y = 2;</script>"#,
            r#"<script type="application/x-forem-billboard-script" data-original-type="module" data-billboard-script="true">export const z = 3;</script>"#,
            r#"<script defer="" type="application/x-forem-billboard-script" data-billboard-script="true" data-billboard-script-src="https://cdn.example.com/widget.js"></script>"#,
            r#"<script type="application/json" id="cfg">{"ok":true}</script>"#,
        );
        assert_eq!(
            billboard_prepare_shadow_inner_html(html, MIME).as_deref(),
            Some(expected)
        );
    }

    #[test]
    fn prepare_shadow_inner_html_defers_on_stray_template_or_unbalanced_tags() {
        assert_eq!(
            billboard_prepare_shadow_inner_html("<div>Safe</template><div>More", MIME),
            None
        );
        assert_eq!(
            billboard_prepare_shadow_inner_html("<div>Unclosed", MIME),
            None
        );
        assert_eq!(
            billboard_prepare_shadow_inner_html("<p><div>Implicit close</div></p>", MIME),
            None
        );
    }

    #[test]
    fn wrap_shadow_dom_escapes_id_and_template() {
        let wrapped = billboard_wrap_shadow_dom(
            "<p>Hi</p>",
            "42\"&<>'",
            "authorship_box",
            "BASE",
            "BOOT",
            MIME,
        )
        .unwrap();
        assert_eq!(
            wrapped,
            "<div class=\"billboard-shadow-host\" data-billboard-shadow-host=\"true\" data-billboard-id=\"42&quot;&amp;&lt;&gt;&#39;\" data-billboard-template=\"authorship_box\"><template shadowrootmode=\"open\"><style data-billboard-base-styles=\"true\">BASE</style><div class=\"billboard-shadow-body\"><p>Hi</p></div></template></div><script data-billboard-shadow-bootstrap=\"true\">BOOT</script>"
        );
    }

    #[test]
    fn append_bb_param_handles_all_standard_cases() {
        assert_eq!(
            billboard_append_bb_param(
                r#"<p>Some content with <a href="https://example.com">a link</a>.</p>"#,
                "42"
            )
            .as_deref(),
            Some(r#"<p>Some content with <a href="https://example.com?bb=42">a link</a>.</p>"#)
        );
        assert_eq!(
            billboard_append_bb_param(
                "<p>Check this <a href='https://example.com?bb=123'>link</a>.</p>",
                "42"
            )
            .as_deref(),
            Some(r#"<p>Check this <a href="https://example.com?bb=42">link</a>.</p>"#)
        );
        assert_eq!(
            billboard_append_bb_param(
                r#"<p>Check this <a href="https://example.com?foo=bar&amp;baz=1">link</a>.</p>"#,
                "42"
            )
            .as_deref(),
            Some(
                r#"<p>Check this <a href="https://example.com?foo=bar&amp;baz=1&bb=42">link</a>.</p>"#
            )
        );
        assert_eq!(
            billboard_append_bb_param(
                r#"<p>Check this <a href="https://example.com/path?a=1#frag">link</a>.</p>"#,
                "42"
            )
            .as_deref(),
            Some(
                r#"<p>Check this <a href="https://example.com/path?a=1&bb=42#frag">link</a>.</p>"#
            )
        );
        assert_eq!(
            billboard_append_bb_param(
                "<p>Check this <a href='mailto:test@example.com'>email link</a>.</p>",
                "42"
            )
            .as_deref(),
            Some(r#"<p>Check this <a href="mailto:test@example.com">email link</a>.</p>"#)
        );
        assert_eq!(
            billboard_append_bb_param(
                "<p>Check this <a href='/articles/123?foo=bar'>link</a>.</p>",
                "42"
            )
            .as_deref(),
            Some(r#"<p>Check this <a href="/articles/123?foo=bar&bb=42">link</a>.</p>"#)
        );
    }

    #[test]
    fn append_bb_param_replays_libxml2_block_formatting_newlines() {
        assert_eq!(
            billboard_append_bb_param(
                r#"<style>.billyb { color: red }</style><div class="billyb">This is a raw div <a href="https://example.com">hello</a></div>"#,
                "50"
            )
            .as_deref(),
            Some(
                "<style>.billyb { color: red }</style>\n<div class=\"billyb\">This is a raw div <a href=\"https://example.com?bb=50\">hello</a>\n</div>"
            )
        );
        assert_eq!(
            billboard_append_bb_param("<div><span>a</span><span>b</span></div><div></div>", "1")
                .as_deref(),
            Some("<div>\n<span>a</span><span>b</span>\n</div>\n<div></div>")
        );
        assert_eq!(
            billboard_append_bb_param("<div> <p>a</p> </div><p><b>x</b><i>y</i></p>", "1")
                .as_deref(),
            Some("<div> <p>a</p> </div>\n<p><b>x</b><i>y</i></p>")
        );
        assert_eq!(
            billboard_append_bb_param("<section><div>a</div><div>b</div></section>", "1")
                .as_deref(),
            Some("<section><div>a</div>\n<div>b</div></section>")
        );
        assert_eq!(billboard_append_bb_param("<div><source></div>", "1"), None);
    }

    #[test]
    fn extract_internal_article_paths_matches_internal_and_relative_links() {
        let html = concat!(
            r#"<p><a href="/ben/my-post/">One</a>"#,
            r#" <a href="https://www.dev.to/Ben/My-Post?utm=1#top">Dup</a>"#,
            r#" <a href="https://sub.dev.to/alice/post-2">Sub</a>"#,
            r#" <a href="https://external.example.com/other/post">Ext</a>"#,
            r#" <a href="/">Root</a>"#,
            r#" <a href="mailto:user@example.com">Mail</a></p>"#,
        );
        let hosts = ["dev.to", "sub.dev.to"];
        assert_eq!(
            billboard_extract_internal_article_paths(html, &hosts),
            Some(vec![
                "/ben/my-post".to_string(),
                "/alice/post-2".to_string()
            ])
        );
    }

    #[test]
    fn extract_internal_article_paths_fast_exits_without_anchors() {
        assert_eq!(
            billboard_extract_internal_article_paths("<p>No links here!</p>", &["dev.to"]),
            Some(vec![])
        );
    }

    #[test]
    fn handles_review_parity_edge_cases() {
        assert_eq!(
            billboard_prepare_shadow_inner_html(
                "<script type=\"module; note=first\nsecond\">x()</script>",
                MIME
            )
            .as_deref(),
            Some("<script type=\"module; note=first\nsecond\">x()</script>")
        );
        assert_eq!(
            billboard_prepare_shadow_inner_html(r#"<script src="&nbsp;"></script>"#, MIME)
                .as_deref(),
            Some(
                r#"<script src="&nbsp;" type="application/x-forem-billboard-script" data-billboard-script="true"></script>"#
            )
        );
        assert_eq!(
            billboard_append_bb_param(
                r#"<p><a href="https://example.com:443/offer">x</a></p>"#,
                "42"
            ),
            None
        );
        assert_eq!(
            billboard_append_bb_param(r#"<p><a href="/offer">x</a></p>"#, "A+B"),
            None
        );
        assert_eq!(
            billboard_append_bb_param(r#"<p>a&nbsp;b <a href="/x">link</a></p>"#, "42"),
            None
        );
        assert_eq!(
            billboard_extract_internal_article_paths(r#"<a href="/ben/offer%">x</a>"#, &["dev.to"]),
            None
        );
        assert_eq!(
            billboard_extract_internal_article_paths(
                r#"<!-- note --!><a href="/ben/my-post">Post</a><!-- tail -->"#,
                &["dev.to"]
            ),
            None
        );
        // Tag name delimiter, nested <form>, and HTML4 boolean attribute guards
        assert_eq!(
            billboard_extract_internal_article_paths(
                r#"<a href="/ben/one">1</a><a_widget href="/ben/other">2</a_widget>"#,
                &["dev.to"]
            ),
            None
        );
        assert_eq!(
            billboard_prepare_shadow_inner_html(
                r#"<form id="outer"><div><form id="inner"><input name="email"></form></div></form>"#,
                MIME
            ),
            None
        );
        assert_eq!(
            billboard_append_bb_param(
                r#"<div><button disabled="disabled">Go</button><a href="/x">x</a></div>"#,
                "42"
            ),
            None
        );
    }
}
