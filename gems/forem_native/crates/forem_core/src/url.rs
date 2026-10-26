//! URL normalization mirroring `Addressable::URI.parse(url).normalize.to_s`.

/// Normalizes `http`/`https` URLs and `/`-rooted paths the way Addressable 2.9 does:
/// lowercases the scheme and host, drops a single trailing host dot and the default port,
/// turns an empty `http(s)` path into `/`, and re-encodes the path, query, and fragment
/// (decoding `%XX` and percent-encoding everything outside each component's character class
/// with uppercase hex, keeping `%2B` encoded in queries and dropping empty queries and
/// fragments).
///
/// Returns `None` for everything else so Ruby keeps Addressable's semantics: other schemes,
/// relative references, non-ASCII text or `%XX` decoding to non-ASCII bytes (NFC/IDNA), any
/// whitespace or control character, userinfo, IPv6 literals, hosts outside
/// `[A-Za-z0-9._~-]`, empty hosts, unusual ports, and `.`/`..` path segments.
pub fn normalize_url(url: &str) -> Option<String> {
    let bytes = url.as_bytes();
    if !bytes.iter().all(|&byte| (0x21..0x7F).contains(&byte)) {
        return None;
    }

    let (end_of_ref, fragment) = match url.find('#') {
        Some(i) => (i, Some(&url[i + 1..])),
        None => (url.len(), None),
    };
    let (end_of_path, query) = match url[..end_of_ref].find('?') {
        Some(i) => (i, Some(&url[i + 1..end_of_ref])),
        None => (end_of_ref, None),
    };
    let reference = &url[..end_of_path];

    let mut out = String::with_capacity(url.len() + 16);
    let path = if reference.starts_with('/') {
        if reference.starts_with("//") {
            return None;
        }
        reference
    } else {
        let colon = reference.find(':')?;
        let scheme = &reference[..colon];
        let default_port = if scheme.eq_ignore_ascii_case("https") {
            443
        } else if scheme.eq_ignore_ascii_case("http") {
            80
        } else {
            return None;
        };
        let rest = reference[colon + 1..].strip_prefix("//")?;
        let (authority, path) = rest.split_at(rest.find('/').unwrap_or(rest.len()));
        out.push_str(if default_port == 443 {
            "https://"
        } else {
            "http://"
        });
        push_authority(&mut out, authority, default_port)?;
        if path.is_empty() {
            out.push('/');
        }
        path
    };

    for (i, segment) in path.split('/').enumerate() {
        if i > 0 {
            out.push('/');
        }
        let segment_start = out.len();
        push_normalized(&mut out, &decode(segment, false)?, is_pchar, false);
        let normalized = &out[segment_start..];
        if normalized == "." || normalized == ".." {
            return None;
        }
    }

    if let Some(query) = query {
        let start_of_query = out.len();
        out.push('?');
        for (i, pair) in query.split('&').enumerate() {
            if i > 0 {
                out.push('&');
            }
            push_normalized(&mut out, &decode(pair, true)?, is_query_char, true);
        }
        if out.len() == start_of_query + 1 {
            out.truncate(start_of_query);
        } else {
            upcase_encoded_plus(&mut out, start_of_query);
        }
    }

    if let Some(fragment) = fragment {
        if !fragment.is_empty() {
            out.push('#');
            push_normalized(&mut out, &decode(fragment, false)?, is_fragment_char, false);
        }
    }

    Some(out)
}

/// Resolves `reference` against a bare `http(s)://host[:port]` base and normalizes the result,
/// mirroring `Addressable::URI.parse(base).join(reference).normalize.to_s` (as `URL.url` does).
///
/// Against a base without path, query, or fragment, RFC 3986 resolution of a scheme-less,
/// authority-less reference without dot segments is plain concatenation (with a `/` before a
/// relative path), so the joined string is handed to [`normalize_url`].
///
/// Returns `None` for bases with a path, query, or fragment, for references with a scheme, an
/// authority (`//`), or `.`/`..` path segments, and for everything [`normalize_url`] declines.
pub fn join_url(base: &str, reference: &str) -> Option<String> {
    let colon = base.find("://")?;
    let scheme = &base[..colon];
    if !(scheme.eq_ignore_ascii_case("https") || scheme.eq_ignore_ascii_case("http"))
        || base[colon + 3..].contains(['/', '?', '#'])
    {
        return None;
    }

    if reference.starts_with("//") {
        return None;
    }
    let path = &reference[..reference.find(['?', '#']).unwrap_or(reference.len())];
    if path
        .split('/')
        .next()
        .is_some_and(|first| first.contains(':'))
        || path
            .split('/')
            .any(|segment| segment == "." || segment == "..")
    {
        return None;
    }

    let mut joined = String::with_capacity(base.len() + 1 + reference.len());
    joined.push_str(base);
    if !path.is_empty() && !path.starts_with('/') {
        joined.push('/');
    }
    joined.push_str(reference);
    normalize_url(&joined)
}

/// Mirrors `normalized_authority` for `host[:port]` authorities: the host is lowercased with a
/// single trailing dot removed (Addressable's `/[^\.]\.$/` rule), and the port is dropped when
/// empty, zero, or the scheme's default (Addressable stores ports via `to_i`).
fn push_authority(out: &mut String, authority: &str, default_port: u64) -> Option<()> {
    let (host, port) = match authority.find(':') {
        Some(i) => (&authority[..i], Some(&authority[i + 1..])),
        None => (authority, None),
    };
    if host.is_empty()
        || !host
            .bytes()
            .all(|byte| byte.is_ascii_alphanumeric() || matches!(byte, b'.' | b'_' | b'~' | b'-'))
    {
        return None;
    }
    let host_bytes = host.as_bytes();
    let host = if host_bytes.len() >= 2
        && host_bytes[host_bytes.len() - 1] == b'.'
        && host_bytes[host_bytes.len() - 2] != b'.'
    {
        &host[..host.len() - 1]
    } else {
        host
    };
    out.extend(host.chars().map(|c| c.to_ascii_lowercase()));

    if let Some(port) = port {
        if port.len() > 18 || !port.bytes().all(|byte| byte.is_ascii_digit()) {
            return None;
        }
        let number = if port.is_empty() {
            0
        } else {
            port.parse::<u64>().ok()?
        };
        if number != 0 && number != default_port {
            out.push(':');
            out.push_str(&number.to_string());
        }
    }
    Some(())
}

/// Mirrors `Addressable::URI.unencode_component`: every `%XX` (case-insensitive hex) becomes
/// its byte, except that queries keep `%2B` / `%2b` verbatim. Returns `None` when a decoded byte
/// is non-ASCII, because Addressable would then NFC-normalize (or re-encode invalid UTF-8).
fn decode(component: &str, keep_encoded_plus: bool) -> Option<Vec<u8>> {
    let bytes = component.as_bytes();
    let mut decoded = Vec::with_capacity(bytes.len());
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'%' && i + 2 < bytes.len() {
            if let (Some(high), Some(low)) = (hex_value(bytes[i + 1]), hex_value(bytes[i + 2])) {
                let byte = (high << 4) | low;
                if byte >= 0x80 {
                    return None;
                }
                if keep_encoded_plus && byte == b'+' {
                    decoded.extend_from_slice(&bytes[i..i + 3]);
                } else {
                    decoded.push(byte);
                }
                i += 3;
                continue;
            }
        }
        decoded.push(bytes[i]);
        i += 1;
    }
    Some(decoded)
}

fn hex_value(byte: u8) -> Option<u8> {
    match byte {
        b'0'..=b'9' => Some(byte - b'0'),
        b'a'..=b'f' => Some(byte - b'a' + 10),
        b'A'..=b'F' => Some(byte - b'A' + 10),
        _ => None,
    }
}

/// Mirrors `Addressable::URI.encode_component` with a negated character class: bytes outside
/// the class become uppercase `%XX`. In queries a `%` stays literal when followed by `2B`/`2b`
/// (`NormalizeCharacterClasses::QUERY`'s `%(?!2B|2b)`).
fn push_normalized(out: &mut String, decoded: &[u8], allowed: fn(u8) -> bool, query: bool) {
    const HEX: &[u8; 16] = b"0123456789ABCDEF";
    for (i, &byte) in decoded.iter().enumerate() {
        let keep = if byte == b'%' {
            query && matches!(&decoded[i + 1..], [b'2', b'B' | b'b', ..])
        } else {
            allowed(byte)
        };
        if keep {
            out.push(byte as char);
        } else {
            out.push('%');
            out.push(HEX[(byte >> 4) as usize] as char);
            out.push(HEX[(byte & 0xF) as usize] as char);
        }
    }
}

/// Mirrors the `upcase_encoded` pass for `"+"`: `gsub(/%(2b)/, &:upcase)`.
fn upcase_encoded_plus(out: &mut String, from: usize) {
    if out[from..].contains("%2b") {
        let fixed = out[from..].replace("%2b", "%2B");
        out.truncate(from);
        out.push_str(&fixed);
    }
}

/// RFC 3986 `pchar` without `%`: unreserved, sub-delims, `:` and `@`.
fn is_pchar(byte: u8) -> bool {
    byte.is_ascii_alphanumeric()
        || matches!(
            byte,
            b'-' | b'.'
                | b'_'
                | b'~'
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
                | b':'
                | b'@'
        )
}

fn is_fragment_char(byte: u8) -> bool {
    is_pchar(byte) || byte == b'/' || byte == b'?'
}

/// `NormalizeCharacterClasses::QUERY` without `%`: pchar minus `&` and `;`, plus `/` and `?`.
fn is_query_char(byte: u8) -> bool {
    byte != b'&' && byte != b';' && is_fragment_char(byte)
}

/// Returns the lowercased host of a (possibly scheme-less) URL without a leading `www.`,
/// matching `ArticlesHelper`'s `url.strip`, `"http://#{url}"` when `Addressable::URI.parse`
/// finds no scheme, then `Addressable::URI.parse(url).host.downcase.delete_prefix("www.")`.
///
/// Returns `None` for anything outside printable ASCII after stripping, invalid schemes, URLs
/// without an authority or with an empty host, userinfo, IP literals, non-digit ports, and
/// characters Addressable rejects in hosts, so Ruby can fall back to Addressable.
pub fn host_without_www(url: &str) -> Option<String> {
    // Ruby's `String#strip` removes NUL and ASCII whitespace from both ends.
    let url = url.trim_matches(|c| matches!(c, '\0' | '\t' | '\n' | '\x0b' | '\x0c' | '\r' | ' '));
    if !url.bytes().all(|byte| byte.is_ascii_graphic()) {
        return None;
    }

    // `URIREGEX`'s scheme is a non-empty run of non-`:/?#` characters followed by `:`.
    let rest = match url.find([':', '/', '?', '#']) {
        Some(end) if end > 0 && url.as_bytes()[end] == b':' => {
            let scheme = &url.as_bytes()[..end];
            let valid = scheme[0].is_ascii_alphabetic()
                && scheme
                    .iter()
                    .all(|&b| b.is_ascii_alphanumeric() || matches!(b, b'.' | b'+' | b'-'));
            if !valid {
                return None;
            }
            url[end + 1..].strip_prefix("//")?
        }
        // A scheme-less path starting with `:` is ambiguous (`NORMPATH`), so `to_s` raises.
        Some(0) if url.starts_with(':') => return None,
        // Without a scheme the URL gets `http://` prepended, so all of it follows the `//`.
        _ => url,
    };

    let authority = &rest[..rest.find(['/', '?', '#']).unwrap_or(rest.len())];
    if authority.contains(['@', '[', ']']) {
        return None;
    }
    let host = match authority.rfind(':') {
        Some(colon) => {
            if !authority.as_bytes()[colon + 1..]
                .iter()
                .all(u8::is_ascii_digit)
            {
                return None;
            }
            &authority[..colon]
        }
        None => authority,
    };
    if host.is_empty() || host.contains(['<', '>', '{', '}', '\\', '"']) {
        return None;
    }

    let host = host.to_ascii_lowercase();
    Some(match host.strip_prefix("www.") {
        Some(stripped) => stripped.to_owned(),
        None => host,
    })
}

fn is_hostname_byte(byte: u8) -> bool {
    byte.is_ascii_alphanumeric() || matches!(byte, b'.' | b'-')
}

/// Byte length of the domain `Middlewares::SetSubforem` looks up for a request host (or its
/// `passed_domain` param): `URI.parse(raw).host.presence`, else `raw` without an `http(s)://`
/// prefix, path, or port, else `raw` itself.
///
/// Only bare hostnames (`[A-Za-z0-9.-]+`) with an optional all-digit `:port` are handled.
/// Without a `//` `URI` finds no host in those, so the domain is everything before the colon.
/// Returns `None` for anything else so Ruby can run its `URI.parse` fallback chain.
pub fn subforem_request_domain_len(raw: &[u8]) -> Option<usize> {
    let end = raw
        .iter()
        .position(|&byte| byte == b':')
        .unwrap_or(raw.len());
    let (host, port) = raw.split_at(end);
    let valid = !host.is_empty()
        && host.iter().all(|&byte| is_hostname_byte(byte))
        && port.iter().skip(1).all(u8::is_ascii_digit);
    valid.then_some(end)
}

/// Whether `host` matches `/^([^.]+)\.#{sld}\.#{tld}$/`, the subdomain check
/// `Middlewares::SetSubforem` builds from `PublicSuffix.parse(host)` on every request.
///
/// The labels are interpolated unescaped, so each `.` in `tld` matches any character. Only
/// `[A-Za-z0-9.-]` hosts with non-empty `[A-Za-z0-9-]` `sld`s and `[A-Za-z0-9.-]` `tld`s are
/// handled: without newlines `^` and `$` anchor the whole host, and `-` is a literal outside a
/// character class. Returns `None` for anything else so Ruby can build the `Regexp`.
pub fn subforem_subdomain_host(host: &[u8], sld: &[u8], tld: &[u8]) -> Option<bool> {
    let valid = host.iter().all(|&byte| is_hostname_byte(byte))
        && !sld.is_empty()
        && sld
            .iter()
            .all(|&byte| byte.is_ascii_alphanumeric() || byte == b'-')
        && !tld.is_empty()
        && tld.iter().all(|&byte| is_hostname_byte(byte));
    if !valid {
        return None;
    }

    // `\.#{sld}\.#{tld}` has a fixed length, and `([^.]+)` needs at least one byte before it.
    let suffix_len = sld.len() + tld.len() + 2;
    if host.len() <= suffix_len {
        return Some(false);
    }
    let (subdomain, suffix) = host.split_at(host.len() - suffix_len);
    let (dot_sld, dot_tld) = suffix.split_at(sld.len() + 1);
    Some(
        !subdomain.contains(&b'.')
            && dot_sld[0] == b'.'
            && &dot_sld[1..] == sld
            && dot_tld[0] == b'.'
            && dot_tld[1..]
                .iter()
                .zip(tld)
                .all(|(&byte, &pattern)| pattern == b'.' || byte == pattern),
    )
}

/// Whether `host` passes `Middlewares::RestoreOriginalHost#valid_host?`: the part before its
/// first `:` matches `/\A[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,}\z/i` or is `localhost`.
///
/// That `Regexp` means `.`/`-`-separated non-empty alphanumeric labels whose last separator is
/// a `.` followed by two or more letters. Only ASCII hosts are handled: under `/i` the Kelvin
/// sign and long s fold onto `k` and `s`, and `split` raises on invalid UTF-8. Hosts with
/// nothing before the first `:` return `None` too, since `split(":").first` can be `nil`.
pub fn original_host_valid(host: &[u8]) -> Option<bool> {
    if !host.is_ascii() {
        return None;
    }
    let end = host
        .iter()
        .position(|&byte| byte == b':')
        .unwrap_or(host.len());
    let name = &host[..end];
    if name.is_empty() {
        return None;
    }
    Some(name == b"localhost" || is_dotted_hostname(name))
}

fn is_dotted_hostname(name: &[u8]) -> bool {
    let is_separator = |byte: &u8| matches!(byte, b'.' | b'-');
    let Some(last_separator) = name.iter().rposition(is_separator) else {
        return false;
    };
    let (labels, tld) = name.split_at(last_separator);
    tld[0] == b'.'
        && tld.len() > 2
        && tld[1..].iter().all(u8::is_ascii_alphabetic)
        && labels.first().is_some_and(u8::is_ascii_alphanumeric)
        && labels.last().is_some_and(u8::is_ascii_alphanumeric)
        && labels
            .iter()
            .all(|byte| byte.is_ascii_alphanumeric() || is_separator(byte))
        && !labels
            .windows(2)
            .any(|pair| is_separator(&pair[0]) && is_separator(&pair[1]))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn n(url: &str) -> Option<String> {
        normalize_url(url)
    }

    #[test]
    fn leaves_already_normal_urls_unchanged() {
        let url = "https://media2.dev.to/dynamic/image/quality=100/https://dev-to-uploads.s3.amazonaws.com/uploads/logos/resized_logo.png";
        assert_eq!(n(url).as_deref(), Some(url));
        assert_eq!(
            n("https://media2.dev.to/image/width=190/https%3A%2F%2Fa.com%2Flogo.png").as_deref(),
            Some("https://media2.dev.to/image/width=190/https:%2F%2Fa.com%2Flogo.png")
        );
        assert_eq!(
            n("/assets/12-abc123.png").as_deref(),
            Some("/assets/12-abc123.png")
        );
    }

    #[test]
    fn lowercases_scheme_and_host_and_fills_empty_path() {
        assert_eq!(
            n("HTTPS://Example.COM").as_deref(),
            Some("https://example.com/")
        );
        assert_eq!(n("http://a.com?x=1").as_deref(), Some("http://a.com/?x=1"));
        assert_eq!(n("https://a.com./x").as_deref(), Some("https://a.com/x"));
        assert_eq!(n("https://a.com../x").as_deref(), Some("https://a.com../x"));
        assert_eq!(n("https://./x").as_deref(), Some("https://./x"));
    }

    #[test]
    fn drops_default_and_zero_ports() {
        assert_eq!(n("https://a.com:443/x").as_deref(), Some("https://a.com/x"));
        assert_eq!(n("http://a.com:080/x").as_deref(), Some("http://a.com/x"));
        assert_eq!(n("http://a.com:/x").as_deref(), Some("http://a.com/x"));
        assert_eq!(n("http://a.com:0/x").as_deref(), Some("http://a.com/x"));
        assert_eq!(
            n("http://a.com:08080/x").as_deref(),
            Some("http://a.com:8080/x")
        );
        assert_eq!(
            n("http://a.com:443/x").as_deref(),
            Some("http://a.com:443/x")
        );
    }

    #[test]
    fn normalizes_percent_encoding_in_path() {
        assert_eq!(
            n("/a%41%2f%7e%25%zz%").as_deref(),
            Some("/aA%2F~%25%25zz%25")
        );
        assert_eq!(
            n("/a\"b<c>{d}|e^`\\").as_deref(),
            Some("/a%22b%3Cc%3E%7Bd%7D%7Ce%5E%60%5C")
        );
        assert_eq!(n("/a[b]").as_deref(), Some("/a%5Bb%5D"));
        assert_eq!(n("/a%3F%23").as_deref(), Some("/a%3F%23"));
    }

    #[test]
    fn normalizes_queries() {
        assert_eq!(
            n("/a?b;c&d=%3d&e+f%2bg%2B").as_deref(),
            Some("/a?b%3Bc&d==&e+f%2Bg%2B")
        );
        assert_eq!(n("/a?%252b%25").as_deref(), Some("/a?%2B%25"));
        assert_eq!(n("/a?").as_deref(), Some("/a"));
        assert_eq!(n("/a?&").as_deref(), Some("/a?&"));
        assert_eq!(n("/a?%26").as_deref(), Some("/a?%26"));
    }

    #[test]
    fn normalizes_fragments() {
        assert_eq!(n("/a#").as_deref(), Some("/a"));
        assert_eq!(n("/a#b#c?/%41").as_deref(), Some("/a#b%23c?/A"));
        assert_eq!(n("/a?#b").as_deref(), Some("/a#b"));
    }

    #[test]
    fn joins_references_against_bare_bases() {
        for (base, reference, expected) in [
            ("https://dev.to", "", "https://dev.to/"),
            ("https://dev.to", "terms", "https://dev.to/terms"),
            ("https://dev.to", "/terms", "https://dev.to/terms"),
            ("https://dev.to", "?a=1", "https://dev.to/?a=1"),
            ("https://dev.to", "#x", "https://dev.to/#x"),
            ("https://dev.to", "x?y#z", "https://dev.to/x?y#z"),
            ("https://dev.to", "/x?", "https://dev.to/x"),
            ("https://dev.to", "/x#", "https://dev.to/x"),
            ("https://dev.to", "/a:b", "https://dev.to/a:b"),
            ("https://dev.to", "/a//b", "https://dev.to/a//b"),
            (
                "https://dev.to",
                "/t/c%2B%2B/page/2",
                "https://dev.to/t/c++/page/2",
            ),
            (
                "https://dev.to",
                "ben/comment/1abc",
                "https://dev.to/ben/comment/1abc",
            ),
            ("http://localhost:3000", "/a?b", "http://localhost:3000/a?b"),
            ("https://Dev.To.", "terms", "https://dev.to/terms"),
            ("HTTPS://dev.to:443", "x", "https://dev.to/x"),
        ] {
            assert_eq!(
                join_url(base, reference).as_deref(),
                Some(expected),
                "{base:?} + {reference:?}"
            );
        }
    }

    #[test]
    fn declines_joins_needing_addressable() {
        for (base, reference) in [
            ("https://dev.to/base", "x"),
            ("https://dev.to?q", "x"),
            ("https://dev.to#f", "x"),
            ("https://", "x"),
            ("ftp://dev.to", "x"),
            ("dev.to", "x"),
            ("https://dev.to", "//x.com/a"),
            ("https://dev.to", "https://other.com/A"),
            ("https://dev.to", "a:b"),
            ("https://dev.to", "/a/../b"),
            ("https://dev.to", "a/./b"),
            ("https://dev.to", ".."),
            ("https://dev.to", "%2E%2E/x"),
            ("https://dev.to", "/a b"),
            ("https://dev.to", "/caf\u{e9}"),
            ("https://user@dev.to", "x"),
        ] {
            assert_eq!(join_url(base, reference), None, "{base:?} + {reference:?}");
        }
    }

    #[test]
    fn declines_out_of_domain_inputs() {
        for url in [
            "",
            "relative.png",
            "//cdn.example.com/a.png",
            "ftp://a.com/x",
            "feed:http://a.com",
            "data:image/png;base64,AAAA",
            "https://user@a.com/x",
            "https://[::1]/x",
            "https:///x",
            "https:/a.com/x",
            "https://a b.com/x",
            "https://a.com/ x",
            "https://a.com/x\n",
            "https://exämple.com/x",
            "https://a.com/%C3%A9",
            "https://a.com/x?%80",
            "https://a.com:12a/x",
            "https://a.com:1:2/x",
            "https://a.com/./x",
            "https://a.com/x/..",
            "/%2E%2E/x",
            "https://a%41.com/x",
        ] {
            assert_eq!(n(url), None, "{url:?}");
        }
    }

    #[test]
    fn extracts_hosts_without_www() {
        for (url, host) in [
            ("https://www.example.com", "example.com"),
            ("https://www.EXAMPLE.COM", "example.com"),
            ("https://www.medium.com", "medium.com"),
            ("https://premedium.com", "premedium.com"),
            ("www.example.com", "example.com"),
            (" www.example.com ", "example.com"),
            ("\0\t\x0bwww.a.com/x \r\n\0", "a.com"),
            ("http://a.com:/x", "a.com"),
            ("https://a.com#frag", "a.com"),
            ("a.com?q=1:2", "a.com"),
            ("a.com/b:c", "a.com"),
            ("HTTPS://WwW.medium.com/@user/post", "medium.com"),
            ("https://a.com:080", "a.com"),
            ("https://www.www.a.com", "www.a.com"),
            ("git+ssh://Host.example.org/repo", "host.example.org"),
        ] {
            assert_eq!(host_without_www(url).as_deref(), Some(host), "{url:?}");
        }
    }

    #[test]
    fn declines_hosts_addressable_rejects_or_lacks() {
        for url in [
            "",
            "   ",
            "WWW.Dev.To:443/a",
            "x:y",
            "a.com:8080",
            "http:a.com",
            "1http://a.com",
            "http://",
            "/path",
            ":foo",
            "::1",
            " :,:",
            "//a.com:x",
            "https://user@a.com",
            "https://[::1]/x",
            "https://a.com:1a",
            "https://a.com:%31",
            "https://a<b.com",
            "https://a b.com",
            "https://ex\u{e4}mple.com",
            "https://a.com/\u{1f600}",
        ] {
            assert_eq!(host_without_www(url), None, "{url:?}");
        }
    }

    #[test]
    fn subforem_request_domain_drops_only_a_port() {
        for (raw, domain) in [
            ("dev.to", "dev.to"),
            ("DEV.to", "DEV.to"),
            ("community.example.com", "community.example.com"),
            ("localhost", "localhost"),
            ("localhost:3000", "localhost"),
            ("dev.to:443", "dev.to"),
            ("dev.to:", "dev.to"),
            ("127.0.0.1:3000", "127.0.0.1"),
            ("1a:2", "1a"),
            ("a-b.c-d:0", "a-b.c-d"),
            (".:1", "."),
            ("...", "..."),
            ("-", "-"),
        ] {
            let len = subforem_request_domain_len(raw.as_bytes());
            assert_eq!(len.map(|len| &raw[..len]), Some(domain), "{raw:?}");
        }
    }

    #[test]
    fn subforem_request_domain_declines_urls_and_odd_hosts() {
        for raw in [
            "",
            " ",
            ":3000",
            "https://dev.to",
            "dev.to/path",
            "dev.to:443:1",
            "dev.to:x",
            "dev.to:44 ",
            " dev.to",
            "dev_to",
            "user@example.com",
            "[::1]:3000",
            "d\u{e9}v.to",
            "dev.to\n",
        ] {
            assert_eq!(subforem_request_domain_len(raw.as_bytes()), None, "{raw:?}");
        }
    }

    #[test]
    fn subforem_subdomain_host_matches_the_interpolated_regexp() {
        for (host, sld, tld, expected) in [
            ("dev.to", "dev", "to", false),
            ("www.dev.to", "dev", "to", true),
            ("a.b.dev.to", "dev", "to", false),
            ("xdev.to", "dev", "to", false),
            ("a.dev.to", "dev", "to", true),
            ("a.DEV.to", "dev", "to", false),
            ("a.bbc.co.uk", "bbc", "co.uk", true),
            ("a.bbc.coxuk", "bbc", "co.uk", true),
            ("a.bbc.co-uk", "bbc", "co.uk", true),
            (".dev.to", "dev", "to", false),
            ("a.dev.to.", "dev", "to", false),
            ("a.devxto", "dev", "to", false),
            ("a-b.my-site.io", "my-site", "io", true),
            ("", "dev", "to", false),
        ] {
            assert_eq!(
                subforem_subdomain_host(host.as_bytes(), sld.as_bytes(), tld.as_bytes()),
                Some(expected),
                "{host:?} {sld:?} {tld:?}"
            );
        }
    }

    #[test]
    fn subforem_subdomain_host_declines_regexp_metacharacters() {
        for (host, sld, tld) in [
            ("a.dev.to", "", "to"),
            ("a.dev.to", "dev", ""),
            ("a.dev.to", "d.v", "to"),
            ("a.dev.to", "de*", "to"),
            ("a.dev.to", "dev", "t+"),
            ("a.dev.to\n", "dev", "to"),
            ("a b.dev.to", "dev", "to"),
            ("a_b.dev.to", "dev", "to"),
            ("\u{e4}.dev.to", "dev", "to"),
        ] {
            assert_eq!(
                subforem_subdomain_host(host.as_bytes(), sld.as_bytes(), tld.as_bytes()),
                None,
                "{host:?} {sld:?} {tld:?}"
            );
        }
    }

    #[test]
    fn original_host_valid_matches_the_host_regexp() {
        for (host, expected) in [
            ("mlh.forem.wtf", true),
            ("sub-domain.example.com", true),
            ("localhost", true),
            ("localhost:3000", true),
            ("DEV.TO", true),
            ("dev.to:443", true),
            ("a.bc", true),
            ("a-b.cd", true),
            ("1.2.3.ab", true),
            ("a.cd:x:y", true),
            ("a.cd:", true),
            ("a.b", false),
            ("a.b2", false),
            ("a.b-cd", false),
            ("a..cd", false),
            ("-a.cd", false),
            ("a-.cd", false),
            ("a.cd.", false),
            (".a.cd", false),
            ("a.c1d", false),
            ("1.2.3.4", false),
            ("xn--d1a.com", false),
            ("LOCALHOST", false),
            ("localhost.:", false),
            ("a.cd-ef", false),
            ("a--b.cd", false),
            ("ab", false),
            ("cd.", false),
            ("a:b.cd", false),
            ("invalid host", false),
            ("host\nname", false),
            ("host;name", false),
            ("http://host.com", false),
        ] {
            assert_eq!(
                original_host_valid(host.as_bytes()),
                Some(expected),
                "{host:?}"
            );
        }
    }

    #[test]
    fn original_host_valid_declines_non_ascii_and_empty_names() {
        for host in [
            "",
            ":",
            ":::",
            ":3000",
            "\u{212a}a.com",
            "a.co\u{17f}",
            "d\u{e9}v.to",
        ] {
            assert_eq!(original_host_valid(host.as_bytes()), None, "{host:?}");
        }
        assert_eq!(original_host_valid(b"a.com:\xff"), None);
    }
}
