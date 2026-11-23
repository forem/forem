//! Pure-Rust kernels for [`Emails::AhoyLinkTracking`] and [`Emails::AhoyLinkDecorator`].
//!
//! Architecture:
//! - **Tier 1 primitives**:
//!   - [`ahoy_signature`] / [`ahoy_signature_bytes`]: stack-allocated streaming Base64 +
//!     RFC 2104 HMAC-SHA256 + unpadded URL-safe Base64 (zero heap allocations for the MAC).
//!   - [`ahoy_decorate_url`]: strict fast-path URL parser, skip-rule checker, query
//!     re-encoder (`Addressable::URI` + `CGI.escape` double encoding), and internal/external
//!     URL builder. Returns [`UrlOutcome::Unchanged`] for non-trackable/skipped strings
//!     (avoiding `Addressable::URI.heuristic_parse` and `InvalidURIError` exception churn)
//!     and [`UrlOutcome::DeferToRuby`] for out-of-domain inputs.
//! - **Tier 2 pipeline kernel**:
//!   - [`ahoy_decorate_html`]: single-pass streaming `<a href>` rewriter that eliminates
//!     `Nokogiri::HTML::DocumentFragment` C-heap DOM construction for clean HTML fragments
//!     while honoring `data-skip-click`, `&amp;` decoding/unescaping, and strict
//!     out-of-domain fallback.

use std::borrow::Cow;

use crate::metal::{sha256, Sha256};

const B64_STD: &[u8; 64] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
const B64_URL: &[u8; 64] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
const HEX_UPPER: &[u8; 16] = b"0123456789ABCDEF";

/// Outcome of decorating a single URL or bare string value.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum UrlOutcome {
    /// The URL was trackable and rewritten to the returned tracked URL.
    Decorated(String),
    /// The input is guaranteed non-trackable or skipped (keep original string unchanged).
    Unchanged,
    /// The input falls outside the strict Rust fast-path domain; defer to Ruby.
    DeferToRuby,
}

/// Streams `Base64.strict_encode64(input)` directly into `hasher` using a stack buffer.
#[inline]
fn feed_base64_strict(hasher: &mut Sha256, input: &[u8]) {
    let mut buf = [0u8; 64];
    let chunks = input.chunks_exact(48);
    let rem = chunks.remainder();
    for chunk in chunks {
        let mut out_idx = 0;
        for triple in chunk.chunks_exact(3) {
            let n = ((triple[0] as u32) << 16) | ((triple[1] as u32) << 8) | (triple[2] as u32);
            buf[out_idx] = B64_STD[((n >> 18) & 0x3f) as usize];
            buf[out_idx + 1] = B64_STD[((n >> 12) & 0x3f) as usize];
            buf[out_idx + 2] = B64_STD[((n >> 6) & 0x3f) as usize];
            buf[out_idx + 3] = B64_STD[(n & 0x3f) as usize];
            out_idx += 4;
        }
        hasher.update(&buf);
    }

    let triples = rem.chunks_exact(3);
    let tail = triples.remainder();
    let mut out_idx = 0;
    for triple in triples {
        let n = ((triple[0] as u32) << 16) | ((triple[1] as u32) << 8) | (triple[2] as u32);
        buf[out_idx] = B64_STD[((n >> 18) & 0x3f) as usize];
        buf[out_idx + 1] = B64_STD[((n >> 12) & 0x3f) as usize];
        buf[out_idx + 2] = B64_STD[((n >> 6) & 0x3f) as usize];
        buf[out_idx + 3] = B64_STD[(n & 0x3f) as usize];
        out_idx += 4;
    }

    match tail.len() {
        1 => {
            let n = (tail[0] as u32) << 16;
            buf[out_idx] = B64_STD[((n >> 18) & 0x3f) as usize];
            buf[out_idx + 1] = B64_STD[((n >> 12) & 0x3f) as usize];
            buf[out_idx + 2] = b'=';
            buf[out_idx + 3] = b'=';
            out_idx += 4;
        }
        2 => {
            let n = ((tail[0] as u32) << 16) | ((tail[1] as u32) << 8);
            buf[out_idx] = B64_STD[((n >> 18) & 0x3f) as usize];
            buf[out_idx + 1] = B64_STD[((n >> 12) & 0x3f) as usize];
            buf[out_idx + 2] = B64_STD[((n >> 6) & 0x3f) as usize];
            buf[out_idx + 3] = b'=';
            out_idx += 4;
        }
        _ => {}
    }

    if out_idx > 0 {
        hasher.update(&buf[..out_idx]);
    }
}

/// Encodes a 32-byte digest into its 43-byte unpadded URL-safe Base64 representation on the stack.
#[inline]
fn base64_urlsafe_32(digest: &[u8; 32]) -> [u8; 43] {
    let mut out = [0u8; 43];
    let mut oi = 0;
    let mut ii = 0;
    while ii < 30 {
        let n =
            ((digest[ii] as u32) << 16) | ((digest[ii + 1] as u32) << 8) | (digest[ii + 2] as u32);
        out[oi] = B64_URL[((n >> 18) & 0x3f) as usize];
        out[oi + 1] = B64_URL[((n >> 12) & 0x3f) as usize];
        out[oi + 2] = B64_URL[((n >> 6) & 0x3f) as usize];
        out[oi + 3] = B64_URL[(n & 0x3f) as usize];
        ii += 3;
        oi += 4;
    }
    // Remaining 2 bytes (indices 30, 31) -> 3 Base64url chars, no padding.
    let n = ((digest[30] as u32) << 16) | ((digest[31] as u32) << 8);
    out[40] = B64_URL[((n >> 18) & 0x3f) as usize];
    out[41] = B64_URL[((n >> 12) & 0x3f) as usize];
    out[42] = B64_URL[((n >> 6) & 0x3f) as usize];
    out
}

/// Computes `AhoyEmail::Utils.signature(token:, campaign:, url:)` on the stack with zero heap allocations.
pub fn ahoy_signature_bytes(
    secret_token: &[u8],
    token: &[u8],
    campaign: &[u8],
    url: &[u8],
) -> [u8; 43] {
    let mut key_block = [0u8; 64];
    if secret_token.len() > 64 {
        let hashed = sha256(secret_token);
        key_block[..32].copy_from_slice(&hashed);
    } else {
        key_block[..secret_token.len()].copy_from_slice(secret_token);
    }

    let mut ipad = [0x36u8; 64];
    let mut opad = [0x5cu8; 64];
    for i in 0..64 {
        ipad[i] ^= key_block[i];
        opad[i] ^= key_block[i];
    }

    let mut inner = Sha256::new();
    inner.update(&ipad);
    feed_base64_strict(&mut inner, token);
    inner.update(b"|");
    feed_base64_strict(&mut inner, campaign);
    inner.update(b"|");
    feed_base64_strict(&mut inner, url);
    let inner_digest = inner.finalize();

    let mut outer = Sha256::new();
    outer.update(&opad);
    outer.update(&inner_digest);
    let mac = outer.finalize();

    base64_urlsafe_32(&mac)
}

/// Computes `AhoyEmail::Utils.signature(token:, campaign:, url:)` as a UTF-8 `String`.
pub fn ahoy_signature(secret_token: &[u8], token: &str, campaign: &str, url: &str) -> String {
    let bytes = ahoy_signature_bytes(
        secret_token,
        token.as_bytes(),
        campaign.as_bytes(),
        url.as_bytes(),
    );
    // SAFETY: `B64_URL` contains only ASCII bytes.
    String::from_utf8(bytes.to_vec()).expect("base64url is always valid UTF-8")
}

#[inline]
fn is_unreserved(b: u8) -> bool {
    b.is_ascii_alphanumeric() || matches!(b, b'-' | b'.' | b'_' | b'~')
}

#[inline]
fn push_pct(out: &mut String, b: u8) {
    out.push('%');
    out.push(HEX_UPPER[(b >> 4) as usize] as char);
    out.push(HEX_UPPER[(b & 0x0f) as usize] as char);
}

/// Appends `CGI.escape(src)` (Ruby 3.3) to `out`.
#[inline]
fn cgi_escape_into(src: &[u8], out: &mut String) {
    for &b in src {
        if is_unreserved(b) {
            out.push(b as char);
        } else if b == b' ' {
            out.push('+');
        } else {
            push_pct(out, b);
        }
    }
}

/// Appends `Addressable::URI.encode_component(src, UNRESERVED)` to `out`.
#[inline]
fn addressable_encode_component_into(src: &[u8], out: &mut String) {
    for &b in src {
        if is_unreserved(b) {
            out.push(b as char);
        } else {
            push_pct(out, b);
        }
    }
}

/// Appends `Addressable::URI.encode_component(CGI.escape(src), UNRESERVED)` in a single pass
/// with zero intermediate allocations.
#[inline]
fn double_encode_href_into(src: &[u8], out: &mut String) {
    for &b in src {
        if is_unreserved(b) {
            out.push(b as char);
        } else if b == b' ' {
            // CGI.escape(' ') == "+", Addressable encodes "+" as "%2B".
            out.push_str("%2B");
        } else {
            // CGI.escape(b) == "%XX", Addressable encodes "%" as "%25" and keeps hex digits.
            out.push_str("%25");
            out.push(HEX_UPPER[(b >> 4) as usize] as char);
            out.push(HEX_UPPER[(b & 0x0f) as usize] as char);
        }
    }
}

#[inline]
fn hex_val(b: u8) -> Option<u8> {
    match b {
        b'0'..=b'9' => Some(b - b'0'),
        b'a'..=b'f' => Some(b - b'a' + 10),
        b'A'..=b'F' => Some(b - b'A' + 10),
        _ => None,
    }
}

/// Decodes a single `Addressable::URI#query_values` component (`%XX` -> byte, and
/// `+` -> space when `plus_as_space` is true — Addressable 2.9.0 converts `+` to space
/// in query values, not keys) and immediately re-encodes it with
/// `Addressable::URI.encode_component(..., UNRESERVED)`.
/// Returns `None` on malformed `%` sequences so Ruby handles any edge-case escaping.
fn reencode_query_component(raw: &[u8], plus_as_space: bool, out: &mut String) -> Option<()> {
    let mut i = 0;
    while i < raw.len() {
        let b = raw[i];
        let decoded = if plus_as_space && b == b'+' {
            i += 1;
            b' '
        } else if b == b'%' {
            if i + 2 >= raw.len() {
                return None;
            }
            let hi = hex_val(raw[i + 1])?;
            let lo = hex_val(raw[i + 2])?;
            i += 3;
            (hi << 4) | lo
        } else {
            i += 1;
            b
        };
        if is_unreserved(decoded) {
            out.push(decoded as char);
        } else {
            push_pct(out, decoded);
        }
    }
    Some(())
}

/// Re-encodes an existing query string matching `uri.query_values = uri.query_values(Array) + ...`,
/// appending a trailing `'&'` when at least one pair was written.
fn reencode_addressable_query_into(query: &[u8], out: &mut String) -> Option<()> {
    if query.is_empty() {
        return Some(());
    }
    for pair in query.split(|&b| b == b'&') {
        // Defer empty segments (`&&`, leading/trailing `&`) to Ruby.
        if pair.is_empty() {
            return None;
        }
        if let Some(eq) = pair.iter().position(|&b| b == b'=') {
            reencode_query_component(&pair[..eq], false, out)?;
            out.push('=');
            reencode_query_component(&pair[eq + 1..], true, out)?;
        } else {
            reencode_query_component(pair, false, out)?;
        }
        out.push('&');
    }
    Some(())
}

/// ASCII case-insensitive substring search (needle must be lowercase ASCII).
#[inline]
fn contains_ascii_ci(haystack: &[u8], lower_needle: &[u8]) -> bool {
    let n = lower_needle.len();
    if n == 0 {
        return true;
    }
    if haystack.len() < n {
        return false;
    }
    let first = lower_needle[0];
    let last_start = haystack.len() - n;
    let mut i = 0;
    while i <= last_start {
        if haystack[i].to_ascii_lowercase() == first {
            let mut matched = true;
            let mut j = 1;
            while j < n {
                if haystack[i + j].to_ascii_lowercase() != lower_needle[j] {
                    matched = false;
                    break;
                }
                j += 1;
            }
            if matched {
                return true;
            }
        }
        i += 1;
    }
    false
}

#[inline]
fn starts_with_ascii_ci(haystack: &[u8], lower_prefix: &[u8]) -> bool {
    haystack.len() >= lower_prefix.len()
        && haystack[..lower_prefix.len()]
            .iter()
            .zip(lower_prefix.iter())
            .all(|(&a, &b)| a.to_ascii_lowercase() == b)
}

#[inline]
fn is_valid_host(host: &[u8]) -> bool {
    if host.is_empty() {
        return false;
    }
    let mut has_alnum = false;
    for &b in host {
        if b.is_ascii_alphanumeric() {
            has_alnum = true;
        } else if b != b'-' && b != b'.' {
            return false;
        }
    }
    has_alnum
}

/// Tier 1 kernel: classifies and decorates a single bare URL or string value.
///
/// Mirrors `Emails::AhoyLinkDecorator#decorate_url` and `Emails::AhoyLinkTracking`.
///
/// - Returns [`UrlOutcome::Unchanged`] for plain text, non-http(s) schemes, unsubscribe links,
///   and already-tracked links (with zero allocations).
/// - Returns [`UrlOutcome::Decorated`] with the exact tracked internal or external URL.
/// - Returns [`UrlOutcome::DeferToRuby`] for ambiguous/exotic inputs (e.g. schemeless domains
///   like `"example.com"`, non-ASCII hosts, userinfo `@`, invalid `%` escapes, or missing
///   `external_base_url` on an external link).
pub fn ahoy_decorate_url(
    href: &str,
    app_domain: &str,
    token: &str,
    campaign: Option<&str>,
    secret_token: &[u8],
    external_base_url: Option<&str>,
) -> UrlOutcome {
    if href.is_empty() {
        return UrlOutcome::Unchanged;
    }

    let bytes = href.as_bytes();

    // Unsubscribe and already-tracked links are always skipped.
    if contains_ascii_ci(bytes, b"unsubscribe") || href.contains("ahoy_click=true") {
        return UrlOutcome::Unchanged;
    }

    // Fast-path check for standard `http://` or `https://` URLs.
    let (scheme, rest) = if starts_with_ascii_ci(bytes, b"https://") {
        ("https", &href[8..])
    } else if starts_with_ascii_ci(bytes, b"http://") {
        ("http", &href[7..])
    } else {
        // Non-`http(s)://` string: prove whether `Addressable::URI.heuristic_parse`
        // can ever produce an `http`/`https` URI.
        let trimmed = href.trim_ascii();
        if trimmed.is_empty() {
            return UrlOutcome::Unchanged;
        }
        let tb = trimmed.as_bytes();
        if tb[0] == b'/' || tb[0] == b'#' {
            return UrlOutcome::Unchanged;
        }
        if starts_with_ascii_ci(tb, b"http:") || starts_with_ascii_ci(tb, b"https:") {
            return UrlOutcome::DeferToRuby;
        }
        if starts_with_ascii_ci(tb, b"mailto:")
            || starts_with_ascii_ci(tb, b"javascript:")
            || starts_with_ascii_ci(tb, b"tel:")
            || starts_with_ascii_ci(tb, b"sms:")
            || starts_with_ascii_ci(tb, b"data:")
            || starts_with_ascii_ci(tb, b"feed:")
            || starts_with_ascii_ci(tb, b"file:")
        {
            return UrlOutcome::Unchanged;
        }
        if !tb.contains(&b'.') {
            return UrlOutcome::Unchanged;
        }
        // If there is a space before the first `/`, `heuristic_parse` tries to assign
        // a host containing a space and raises `InvalidURIError` -> `parse_uri` returns nil.
        let first_slash = tb.iter().position(|&b| b == b'/').unwrap_or(tb.len());
        if tb[..first_slash].contains(&b' ') {
            return UrlOutcome::Unchanged;
        }
        return UrlOutcome::DeferToRuby;
    };

    // Reject trailing whitespace or control characters in `http(s)://` URLs.
    if bytes.last().is_some_and(|b| b.is_ascii_whitespace())
        || bytes.iter().any(|&b| b < 0x20 || b == 0x7f)
    {
        return UrlOutcome::DeferToRuby;
    }

    // Split authority from path/query/fragment.
    let auth_end = rest
        .bytes()
        .position(|b| matches!(b, b'/' | b'?' | b'#'))
        .unwrap_or(rest.len());
    let authority = &rest[..auth_end];
    let tail = &rest[auth_end..];

    if authority.is_empty() || !authority.is_ascii() {
        return UrlOutcome::DeferToRuby;
    }

    // Split optional `:port` (rejecting userinfo `@`, IPv6 `[...]`, spaces, backslashes).
    let (host, port_str) = if let Some(colon) = authority.rfind(':') {
        let h = &authority[..colon];
        let p = &authority[colon + 1..];
        if p.is_empty() || p.starts_with('0') || !p.bytes().all(|b| b.is_ascii_digit()) {
            return UrlOutcome::DeferToRuby;
        }
        if p.parse::<u16>().is_err() {
            return UrlOutcome::DeferToRuby;
        }
        (h, Some(p))
    } else {
        (authority, None)
    };

    if !is_valid_host(host.as_bytes()) {
        return UrlOutcome::DeferToRuby;
    }

    // Split path and query (ignoring `#fragment` for the rewritten internal URL base,
    // while keeping the full `href` for signature and `u`).
    let path_and_query = match tail.find('#') {
        Some(hash_idx) => &tail[..hash_idx],
        None => tail,
    };
    let (path, query) = match path_and_query.find('?') {
        Some(q_idx) => (&path_and_query[..q_idx], Some(&path_and_query[q_idx + 1..])),
        None => (path_and_query, None),
    };

    let is_internal = host == app_domain;
    if is_internal && path.starts_with("/ahoy/") {
        return UrlOutcome::Unchanged;
    }

    let sig_bytes = ahoy_signature_bytes(
        secret_token,
        token.as_bytes(),
        campaign.unwrap_or("").as_bytes(),
        bytes,
    );
    // SAFETY: `base64_urlsafe_32` produces ASCII only.
    let sig_str = std::str::from_utf8(&sig_bytes).expect("base64url is always valid UTF-8");

    if is_internal {
        let mut out = String::with_capacity(href.len() * 2 + token.len() + 112);
        out.push_str(scheme);
        out.push_str("://");
        out.push_str(host);
        if let Some(p) = port_str {
            out.push(':');
            out.push_str(p);
        }
        out.push_str(path);
        out.push('?');
        if let Some(q) = query {
            if reencode_addressable_query_into(q.as_bytes(), &mut out).is_none() {
                return UrlOutcome::DeferToRuby;
            }
        }
        out.push_str("ahoy_click=true");
        if !token.is_empty() {
            out.push_str("&t=");
            addressable_encode_component_into(token.as_bytes(), &mut out);
        }
        out.push_str("&s=");
        out.push_str(sig_str);
        out.push_str("&u=");
        double_encode_href_into(bytes, &mut out);
        if let Some(c) = campaign {
            if !c.is_empty() {
                out.push_str("&c=");
                addressable_encode_component_into(c.as_bytes(), &mut out);
            }
        }
        UrlOutcome::Decorated(out)
    } else {
        let Some(base) = external_base_url else {
            return UrlOutcome::DeferToRuby;
        };
        let mut out = String::with_capacity(base.len() + href.len() * 2 + token.len() + 96);
        out.push_str(base);
        out.push('?');
        if let Some(c) = campaign {
            out.push_str("c=");
            cgi_escape_into(c.as_bytes(), &mut out);
            out.push('&');
        }
        out.push_str("s=");
        out.push_str(sig_str);
        out.push_str("&t=");
        cgi_escape_into(token.as_bytes(), &mut out);
        out.push_str("&u=");
        cgi_escape_into(bytes, &mut out);
        UrlOutcome::Decorated(out)
    }
}

/// Decodes `&amp;` -> `&` inside an `href` attribute value.
/// Returns `None` if any other HTML entity (`&...`) is present so Nokogiri handles full decoding.
fn decode_href_entities(raw: &str) -> Option<Cow<'_, str>> {
    if !raw.contains('&') {
        return Some(Cow::Borrowed(raw));
    }
    let bytes = raw.as_bytes();
    let mut out = String::with_capacity(raw.len());
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'&' {
            if bytes[i..].starts_with(b"&amp;") {
                out.push('&');
                i += 5;
                continue;
            }
            // If followed by ASCII alpha or `#`, it may be another HTML entity (`&#64;`, `&quot;`, etc.).
            if i + 1 < bytes.len() && (bytes[i + 1].is_ascii_alphabetic() || bytes[i + 1] == b'#') {
                return None;
            }
            out.push('&');
            i += 1;
        } else {
            let start = i;
            i += 1;
            while i < bytes.len() && bytes[i] != b'&' {
                i += 1;
            }
            out.push_str(&raw[start..i]);
        }
    }
    Some(Cow::Owned(out))
}

#[inline]
fn push_unescaped_amp(slice: &str, out: &mut String) {
    if !slice.contains("&amp;") {
        out.push_str(slice);
        return;
    }
    let mut rest = slice;
    while let Some(idx) = rest.find("&amp;") {
        out.push_str(&rest[..idx]);
        out.push('&');
        rest = &rest[idx + 5..];
    }
    out.push_str(rest);
}

#[inline]
fn is_html_ws(b: u8) -> bool {
    matches!(b, b' ' | b'\t' | b'\n' | b'\r' | 0x0c)
}

#[derive(Clone, Copy)]
struct ParsedAttr {
    /// Start offset in `html` including leading whitespace before the attribute name.
    full_start: usize,
    /// End offset in `html` immediately after the attribute (including closing quote if any).
    full_end: usize,
    /// Start/end offsets of the attribute name.
    name_start: usize,
    name_end: usize,
    /// Start/end offsets of the attribute value (inside quotes), if quoted.
    val_span: Option<(usize, usize)>,
    /// True if the attribute had `=` with an unquoted value.
    unquoted_val: bool,
}

/// Parses attributes of an `<a ...>` opening tag starting right after `<a`.
/// Returns `(tag_end_inclusive, attrs)` or `None` if malformed.
fn parse_anchor_open_tag(html: &str, after_a: usize) -> Option<(usize, Vec<ParsedAttr>)> {
    let bytes = html.as_bytes();
    let len = bytes.len();
    let mut i = after_a;
    let mut attrs = Vec::with_capacity(4);

    loop {
        let ws_start = i;
        while i < len && is_html_ws(bytes[i]) {
            i += 1;
        }
        if i >= len {
            return None;
        }
        if bytes[i] == b'>' {
            return Some((i + 1, attrs));
        }
        if bytes[i] == b'/' && i + 1 < len && bytes[i + 1] == b'>' {
            return Some((i + 2, attrs));
        }
        if bytes[i] == b'<' || i == ws_start {
            return None;
        }

        let name_start = i;
        while i < len
            && !is_html_ws(bytes[i])
            && !matches!(bytes[i], b'=' | b'>' | b'/' | b'<' | b'"' | b'\'')
        {
            i += 1;
        }
        let name_end = i;
        if name_end == name_start {
            return None;
        }

        // Skip optional whitespace before `=`.
        let mut j = i;
        while j < len && is_html_ws(bytes[j]) {
            j += 1;
        }

        let (val_span, unquoted_val, full_end) = if j < len && bytes[j] == b'=' {
            j += 1;
            while j < len && is_html_ws(bytes[j]) {
                j += 1;
            }
            if j >= len {
                return None;
            }
            if bytes[j] == b'"' || bytes[j] == b'\'' {
                let quote = bytes[j];
                j += 1;
                let v_start = j;
                while j < len && bytes[j] != quote {
                    j += 1;
                }
                if j >= len {
                    return None;
                }
                let v_end = j;
                j += 1; // consume closing quote
                (Some((v_start, v_end)), false, j)
            } else {
                let v_start = j;
                while j < len
                    && !is_html_ws(bytes[j])
                    && !matches!(bytes[j], b'>' | b'<' | b'"' | b'\'')
                {
                    j += 1;
                }
                if j == v_start {
                    return None;
                }
                (Some((v_start, j)), true, j)
            }
        } else {
            // Boolean attribute (e.g., `data-skip-click`).
            (None, false, name_end)
        };

        attrs.push(ParsedAttr {
            full_start: ws_start,
            full_end,
            name_start,
            name_end,
            val_span,
            unquoted_val,
        });
        i = full_end;
    }
}

/// Returns `true` if `tag_name` is an HTML raw-text or RCDATA element whose body
/// may contain literal `<a ...>` text that is NOT an anchor element.
#[inline]
fn is_raw_text_tag(tag_name: &[u8]) -> bool {
    tag_name.eq_ignore_ascii_case(b"script")
        || tag_name.eq_ignore_ascii_case(b"style")
        || tag_name.eq_ignore_ascii_case(b"textarea")
        || tag_name.eq_ignore_ascii_case(b"title")
        || tag_name.eq_ignore_ascii_case(b"xmp")
        || tag_name.eq_ignore_ascii_case(b"iframe")
        || tag_name.eq_ignore_ascii_case(b"noembed")
        || tag_name.eq_ignore_ascii_case(b"noframes")
        || tag_name.eq_ignore_ascii_case(b"plaintext")
}

/// Skips a non-`<a>` opening HTML tag starting at the first byte of its tag name
/// (immediately after `<`), respecting single- and double-quoted attribute values so
/// `<a ...>` inside another tag's attributes is never misidentified as an anchor.
/// Returns `None` on raw-text elements or malformed/unclosed tags so Nokogiri handles them.
fn skip_open_tag(bytes: &[u8], mut i: usize) -> Option<usize> {
    let len = bytes.len();
    let name_start = i;
    while i < len && !is_html_ws(bytes[i]) && bytes[i] != b'>' && bytes[i] != b'/' {
        if bytes[i] == b'<' || bytes[i] == b'"' || bytes[i] == b'\'' {
            return None;
        }
        i += 1;
    }
    if is_raw_text_tag(&bytes[name_start..i]) {
        return None;
    }

    loop {
        while i < len && is_html_ws(bytes[i]) {
            i += 1;
        }
        if i >= len {
            return None;
        }
        if bytes[i] == b'>' {
            return Some(i + 1);
        }
        if bytes[i] == b'/' && i + 1 < len && bytes[i + 1] == b'>' {
            return Some(i + 2);
        }
        if bytes[i] == b'<' {
            return None;
        }
        let attr_start = i;
        while i < len
            && !is_html_ws(bytes[i])
            && !matches!(bytes[i], b'=' | b'>' | b'/' | b'<' | b'"' | b'\'')
        {
            i += 1;
        }
        if i == attr_start {
            return None;
        }
        while i < len && is_html_ws(bytes[i]) {
            i += 1;
        }
        if i < len && bytes[i] == b'=' {
            i += 1;
            while i < len && is_html_ws(bytes[i]) {
                i += 1;
            }
            if i >= len {
                return None;
            }
            if bytes[i] == b'"' || bytes[i] == b'\'' {
                let quote = bytes[i];
                i += 1;
                while i < len && bytes[i] != quote {
                    i += 1;
                }
                if i >= len {
                    return None;
                }
                i += 1;
            } else {
                let v_start = i;
                while i < len
                    && !is_html_ws(bytes[i])
                    && !matches!(bytes[i], b'>' | b'<' | b'"' | b'\'')
                {
                    i += 1;
                }
                if i == v_start {
                    return None;
                }
            }
        }
    }
}

/// Tier 2 kernel: single-pass streaming `<a href>` rewriter for HTML fragments.
///
/// Mirrors `Emails::AhoyLinkDecorator#decorate_html`:
/// - Rewrites every `<a href="...">` with [`ahoy_decorate_url`].
/// - Strips `data-skip-click` and leaves `href` untouched when present.
/// - Unescapes `&amp;` -> `&` (matching `doc.to_s.gsub("&amp;", "&")`).
/// - Returns `None` (`DeferToRuby`) if the fragment contains `<script`, `<style`, raw-text
///   tags, `<!--`, `<![CDATA[`, `<?`, `<!`, malformed tags, non-`&amp;` entities inside `href`,
///   quote-bearing rewritten `href` values, or any out-of-domain URL.
pub fn ahoy_decorate_html<'a>(
    html: &'a str,
    app_domain: &str,
    token: &str,
    campaign: Option<&str>,
    secret_token: &[u8],
    external_base_url: Option<&str>,
) -> Option<Cow<'a, str>> {
    let bytes = html.as_bytes();
    if contains_ascii_ci(bytes, b"<script")
        || contains_ascii_ci(bytes, b"<style")
        || html.contains("<!--")
        || contains_ascii_ci(bytes, b"<![cdata[")
        || html.contains("<?")
    {
        return None;
    }

    let mut out: Option<String> = None;
    let mut last_copied = 0usize;
    let mut i = 0usize;
    let len = bytes.len();

    while i < len {
        if bytes[i] != b'<' {
            i += 1;
            continue;
        }
        if i + 1 >= len {
            i += 1;
            continue;
        }
        let next = bytes[i + 1];
        if next == b'!' || next == b'?' {
            return None;
        }
        if next == b'/' {
            // Closing tag (e.g. `</a>`, `</div>`): skip to `>`.
            let mut j = i + 2;
            while j < len && bytes[j] != b'>' {
                if bytes[j] == b'<' {
                    return None;
                }
                j += 1;
            }
            if j >= len {
                return None;
            }
            i = j + 1;
            continue;
        }
        if !next.is_ascii_alphabetic() {
            // Literal `<` in text (e.g. `1 < 2`).
            i += 1;
            continue;
        }

        if (next == b'a' || next == b'A') && i + 2 < len && is_html_ws(bytes[i + 2]) {
            let tag_start = i;
            let (tag_end, attrs) = parse_anchor_open_tag(html, i + 2)?;

            let mut href_idx: Option<usize> = None;
            let mut skip_idx: Option<usize> = None;
            for (idx, attr) in attrs.iter().enumerate() {
                let name = &html[attr.name_start..attr.name_end];
                if name.eq_ignore_ascii_case("href") {
                    if href_idx.is_some() {
                        return None;
                    }
                    href_idx = Some(idx);
                } else if name.eq_ignore_ascii_case("data-skip-click") {
                    if skip_idx.is_some() {
                        return None;
                    }
                    skip_idx = Some(idx);
                }
            }

            if let Some(h_idx) = href_idx {
                if let Some(s_idx) = skip_idx {
                    // Remove `data-skip-click` attribute and leave `href` untouched.
                    let skip_attr = attrs[s_idx];
                    let buf = out.get_or_insert_with(|| String::with_capacity(html.len() + 128));
                    push_unescaped_amp(&html[last_copied..skip_attr.full_start], buf);
                    push_unescaped_amp(&html[skip_attr.full_end..tag_end], buf);
                    last_copied = tag_end;
                } else {
                    let href_attr = attrs[h_idx];
                    if href_attr.unquoted_val {
                        return None;
                    }
                    if let Some((v_start, v_end)) = href_attr.val_span {
                        let raw_href = &html[v_start..v_end];
                        let decoded_href = decode_href_entities(raw_href)?;
                        match ahoy_decorate_url(
                            decoded_href.as_ref(),
                            app_domain,
                            token,
                            campaign,
                            secret_token,
                            external_base_url,
                        ) {
                            UrlOutcome::Decorated(new_href) => {
                                // Never emit a raw `"` inside a double-quoted `href="..."`;
                                // defer quote-bearing URLs (e.g. from single-quoted `href`)
                                // to Nokogiri so URL data can never break out into attributes.
                                // Also defer spaces and non-ASCII bytes, which libxml2's
                                // serializer percent-escapes inside `href`.
                                if new_href
                                    .bytes()
                                    .any(|b| b == b'"' || b == b' ' || b >= 0x80)
                                {
                                    return None;
                                }
                                let buf = out.get_or_insert_with(|| {
                                    String::with_capacity(html.len() + new_href.len() + 128)
                                });
                                // Copy up to attribute name start, then write `href="<new_href>"`.
                                push_unescaped_amp(&html[last_copied..href_attr.name_start], buf);
                                buf.push_str("href=\"");
                                buf.push_str(&new_href);
                                buf.push('"');
                                push_unescaped_amp(&html[href_attr.full_end..tag_end], buf);
                                last_copied = tag_end;
                            }
                            UrlOutcome::Unchanged => {
                                // Leave tag as-is (still unescaping `&amp;` if `out` is active).
                            }
                            UrlOutcome::DeferToRuby => {
                                return None;
                            }
                        }
                    }
                }
            }
            let _ = tag_start;
            i = tag_end;
        } else {
            i = skip_open_tag(bytes, i + 1)?;
        }
    }

    match out {
        Some(mut buf) => {
            push_unescaped_amp(&html[last_copied..], &mut buf);
            Some(Cow::Owned(buf))
        }
        None => {
            if html.contains("&amp;") {
                let mut buf = String::with_capacity(html.len());
                push_unescaped_amp(html, &mut buf);
                Some(Cow::Owned(buf))
            } else {
                Some(Cow::Borrowed(html))
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn signature_matches_ahoy_email_utils_reference() {
        // Cross-checked against `AhoyEmail::Utils.signature` in Ruby 3.3 / ahoy_email 2.2.0:
        // secret="test_secret", token="abc123token", campaign="", url="https://dev.to/ben/some-post?context=digest"
        let sig = ahoy_signature(
            b"test_secret",
            "abc123token",
            "",
            "https://dev.to/ben/some-post?context=digest",
        );
        assert_eq!(sig, "C2Aret1SU2b07h2Ju0aX4fWepGjhmvReY2RZ-K0vQTI");
        assert_eq!(sig.len(), 43);
        assert!(!sig.contains('='));
        assert!(!sig.contains('+'));
        assert!(!sig.contains('/'));
    }

    #[test]
    fn internal_url_rewrites_and_double_encodes_u() {
        let out = ahoy_decorate_url(
            "https://dev.to/ben/some-post?context=digest",
            "dev.to",
            "abc123token",
            None,
            b"test_secret",
            Some("https://dev.to/ahoy/click"),
        );
        match out {
            UrlOutcome::Decorated(url) => {
                assert!(url.starts_with(
                    "https://dev.to/ben/some-post?context=digest&ahoy_click=true&t=abc123token&s="
                ));
                assert!(url.contains(
                    "&u=https%253A%252F%252Fdev.to%252Fben%252Fsome-post%253Fcontext%253Ddigest"
                ));
                assert!(!url.contains("&c="));
            }
            other => panic!("expected Decorated, got {other:?}"),
        }
    }

    #[test]
    fn external_url_routes_through_ahoy_click() {
        let out = ahoy_decorate_url(
            "https://example.com/post",
            "dev.to",
            "abc123token",
            None,
            b"test_secret",
            Some("https://dev.to/ahoy/click"),
        );
        match out {
            UrlOutcome::Decorated(url) => {
                assert!(url.starts_with("https://dev.to/ahoy/click?s="));
                assert!(url.contains("&t=abc123token&u=https%3A%2F%2Fexample.com%2Fpost"));
                assert!(!url.contains("c="));
            }
            other => panic!("expected Decorated, got {other:?}"),
        }
    }

    #[test]
    fn external_url_includes_empty_campaign_when_some_empty() {
        let out = ahoy_decorate_url(
            "https://example.com/post",
            "dev.to",
            "tok",
            Some(""),
            b"secret",
            Some("https://dev.to/ahoy/click"),
        );
        match out {
            UrlOutcome::Decorated(url) => {
                assert!(url.starts_with("https://dev.to/ahoy/click?c=&s="));
            }
            other => panic!("expected Decorated, got {other:?}"),
        }
    }

    #[test]
    fn plain_text_and_skip_links_return_unchanged() {
        for s in [
            "",
            "Ben",
            "A post you might like",
            "A post you might like.",
            "1.5 minutes read",
            "mailto:yo@example.com",
            "javascript:alert(1)",
            "/relative/path.html",
            "#section.1",
            "https://dev.to/email_subscriptions/unsubscribe?ut=xyz",
            "https://dev.to/post?ahoy_click=true&t=old&s=sig&u=x",
            "https://dev.to/ahoy/click?t=old&s=sig&u=https%3A%2F%2Fexample.com",
        ] {
            assert_eq!(
                ahoy_decorate_url(
                    s,
                    "dev.to",
                    "tok",
                    None,
                    b"sec",
                    Some("https://dev.to/ahoy/click")
                ),
                UrlOutcome::Unchanged,
                "failed for {s:?}"
            );
        }
    }

    #[test]
    fn heuristic_schemeless_domains_defer_to_ruby() {
        for s in ["example.com", "dev.to/ben/post", "  https://dev.to/post  "] {
            assert_eq!(
                ahoy_decorate_url(
                    s,
                    "dev.to",
                    "tok",
                    None,
                    b"sec",
                    Some("https://dev.to/ahoy/click")
                ),
                UrlOutcome::DeferToRuby,
                "expected DeferToRuby for {s:?}"
            );
        }
    }

    #[test]
    fn decorate_html_rewrites_anchors_and_honors_skip_click() {
        let html = r#"<div><a href="https://dev.to/ben/post?a=1&amp;b=2">Read</a> <a href="https://dev.to/skip" data-skip-click="true">Skip</a></div>"#;
        let out = ahoy_decorate_html(
            html,
            "dev.to",
            "tok",
            None,
            b"sec",
            Some("https://dev.to/ahoy/click"),
        )
        .expect("should succeed on clean HTML");
        assert!(out.contains("href=\"https://dev.to/ben/post?a=1&b=2&ahoy_click=true&t=tok&s="));
        assert!(out.contains("<a href=\"https://dev.to/skip\">Skip</a>"));
        assert!(!out.contains("data-skip-click"));
    }

    #[test]
    fn decorate_html_borrows_when_no_anchors() {
        let html = "<article><p>No links here</p></article>";
        let out = ahoy_decorate_html(
            html,
            "dev.to",
            "tok",
            None,
            b"sec",
            Some("https://dev.to/ahoy/click"),
        )
        .unwrap();
        assert!(matches!(out, Cow::Borrowed(_)));
    }

    #[test]
    fn decorate_html_defers_on_comments_and_scripts() {
        for html in [
            "<!-- <a href=\"https://dev.to/a\">A</a> -->",
            "<script>var x = '<a href=\"https://dev.to/a\">A</a>';</script>",
            "<textarea><a href=\"https://dev.to/a\">A</a></textarea>",
            "<a href=\"https://dev.to/a?x=&#64;\">A</a>",
            "<a href='https://dev.to/post\"title=\"x'>Read</a>",
            "<a data-skip-click=\"true\"href=\"https://dev.to/a\">Skip</a>",
            "<a title=\"x\"href=\"https://dev.to/a\">A</a>",
        ] {
            assert!(
                ahoy_decorate_html(
                    html,
                    "dev.to",
                    "tok",
                    None,
                    b"sec",
                    Some("https://dev.to/ahoy/click")
                )
                .is_none(),
                "expected None for {html:?}"
            );
        }
    }

    #[test]
    fn internal_url_preserves_plus_in_query_keys_and_omits_empty_token() {
        match ahoy_decorate_url(
            "https://dev.to/search?a+b=one+two&c+d",
            "dev.to",
            "tok",
            None,
            b"sec",
            Some("https://dev.to/ahoy/click"),
        ) {
            UrlOutcome::Decorated(url) => {
                assert!(
                    url.starts_with(
                        "https://dev.to/search?a%2Bb=one%20two&c%2Bd&ahoy_click=true&t=tok&s="
                    ),
                    "unexpected url: {url}"
                );
            }
            other => panic!("expected Decorated, got {other:?}"),
        }

        match ahoy_decorate_url(
            "https://dev.to/post?t=original",
            "dev.to",
            "",
            None,
            b"sec",
            Some("https://dev.to/ahoy/click"),
        ) {
            UrlOutcome::Decorated(url) => {
                assert!(
                    url.starts_with("https://dev.to/post?t=original&ahoy_click=true&s="),
                    "unexpected url: {url}"
                );
                assert!(!url.contains("&t="));
            }
            other => panic!("expected Decorated, got {other:?}"),
        }
    }

    #[test]
    fn decorate_html_ignores_anchor_text_inside_other_tag_attributes() {
        let html = r#"<img alt="Example: <a href='https://dev.to/post'>">"#;
        let out = ahoy_decorate_html(
            html,
            "dev.to",
            "tok",
            None,
            b"sec",
            Some("https://dev.to/ahoy/click"),
        )
        .expect("should keep img tag untouched");
        assert!(matches!(out, Cow::Borrowed(_)));
        assert_eq!(out.as_ref(), html);
    }

    #[test]
    fn decorate_html_defers_hrefs_that_libxml2_would_escape() {
        for html in [
            "<a href=\"https://dev.to/ben/caf\u{e9}\">Read</a>",
            "<a href=\"https://dev.to/ben/a b\">Read</a>",
        ] {
            assert!(
                ahoy_decorate_html(
                    html,
                    "dev.to",
                    "tok",
                    None,
                    b"sec",
                    Some("https://dev.to/ahoy/click")
                )
                .is_none(),
                "expected None for {html:?}"
            );
        }
    }

    #[test]
    fn streamed_base64_matches_strict_encode64_at_every_chunk_boundary() {
        fn strict_encode64(input: &[u8]) -> Vec<u8> {
            let mut out = Vec::new();
            for chunk in input.chunks(3) {
                let b = [
                    chunk[0],
                    *chunk.get(1).unwrap_or(&0),
                    *chunk.get(2).unwrap_or(&0),
                ];
                let n = ((b[0] as u32) << 16) | ((b[1] as u32) << 8) | (b[2] as u32);
                out.push(B64_STD[((n >> 18) & 0x3f) as usize]);
                out.push(B64_STD[((n >> 12) & 0x3f) as usize]);
                out.push(if chunk.len() > 1 {
                    B64_STD[((n >> 6) & 0x3f) as usize]
                } else {
                    b'='
                });
                out.push(if chunk.len() > 2 {
                    B64_STD[(n & 0x3f) as usize]
                } else {
                    b'='
                });
            }
            out
        }

        let input: Vec<u8> = (0..=200u32).map(|i| (i * 37 % 256) as u8).collect();
        for len in 0..=input.len() {
            let mut streamed = Sha256::new();
            feed_base64_strict(&mut streamed, &input[..len]);
            assert_eq!(
                streamed.finalize(),
                sha256(&strict_encode64(&input[..len])),
                "mismatch at length {len}"
            );
        }
    }
}
