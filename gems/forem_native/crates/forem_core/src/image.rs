//! Image CDN URL building mirroring `Images::Optimizer.cloudflare`.

/// Builds the Cloudflare Images URL that `Images::Optimizer.cloudflare` expands from the
/// `https://{domain}/{directory}/image/{options*}/{src}` `Addressable::Template`:
/// `width=..,height=..,fit=..,gravity=auto` plus `,format=auto` unless `img_src` looks like
/// an animated GIF / WebP, with every value percent-encoded outside RFC 3986 unreserved
/// characters. Callers pass `""` for `nil` values, which Addressable expands the same way.
///
/// Returns `None` when any value has a character at or above U+0300, because Addressable
/// NFC-normalizes values first and only text below U+0300 is guaranteed to be NFC already.
pub fn cloudflare_image_url(
    domain: &str,
    directory: &str,
    width: &str,
    height: &str,
    fit: &str,
    img_src: &str,
    src: &str,
) -> Option<String> {
    let values = [domain, directory, width, height, fit, img_src, src];
    if !values.iter().all(|value| is_nfc_stable(value)) {
        return None;
    }

    let capacity = values.iter().map(|value| value.len() * 3).sum::<usize>() + 80;
    let mut url = String::with_capacity(capacity);
    url.push_str("https://");
    push_encoded(&mut url, domain);
    url.push('/');
    push_encoded(&mut url, directory);
    url.push_str("/image/width=");
    push_encoded(&mut url, width);
    url.push_str(",height=");
    push_encoded(&mut url, height);
    url.push_str(",fit=");
    push_encoded(&mut url, fit);
    url.push_str(",gravity=auto");
    if !is_animated(img_src) {
        url.push_str(",format=auto");
    }
    url.push('/');
    push_encoded(&mut url, src);
    Some(url)
}

/// Whether every character is below U+0300. Those characters are all NFC_QC=Yes with
/// canonical combining class 0, so `String#unicode_normalize(:nfc)` leaves them unchanged.
/// In valid UTF-8 that is exactly "no byte >= 0xCC" (U+0300 is `CC 80`).
fn is_nfc_stable(value: &str) -> bool {
    value.bytes().all(|byte| byte < 0xCC)
}

/// Mirrors `img_src.match?(/\.(gif|webp)(\?.*)?$/i)`. Ruby's `$` matches at the end of the
/// string or before any `\n`, and `(\?.*)?` can always run to the end of the line, so the
/// regex matches iff some `.gif` / `.webp` is followed by the end, a `\n`, or a `?`.
fn is_animated(img_src: &str) -> bool {
    let bytes = img_src.as_bytes();
    bytes.iter().enumerate().any(|(i, &byte)| {
        if byte != b'.' {
            return false;
        }
        let rest = &bytes[i + 1..];
        [&b"gif"[..], &b"webp"[..]].iter().any(|extension| {
            rest.len() >= extension.len()
                && rest[..extension.len()].eq_ignore_ascii_case(extension)
                && matches!(rest.get(extension.len()), None | Some(b'\n' | b'?'))
        })
    })
}

/// Mirrors `Addressable::URI.encode_component(value, UNRESERVED)`: every byte outside
/// `[A-Za-z0-9\-._~]` becomes an uppercase `%XX` escape.
fn push_encoded(url: &mut String, value: &str) {
    const HEX: &[u8; 16] = b"0123456789ABCDEF";
    for &byte in value.as_bytes() {
        if byte.is_ascii_alphanumeric() || matches!(byte, b'-' | b'.' | b'_' | b'~') {
            url.push(byte as char);
        } else {
            url.push('%');
            url.push(HEX[usize::from(byte >> 4)] as char);
            url.push(HEX[usize::from(byte & 0xF)] as char);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const IMG: &str = "https://dev-to-uploads.s3.amazonaws.com/uploads/articles/abc123.png";

    fn url(width: &str, height: &str, fit: &str, img_src: &str) -> Option<String> {
        cloudflare_image_url(
            "media2.dev.to",
            "dynamic",
            width,
            height,
            fit,
            img_src,
            img_src,
        )
    }

    #[test]
    fn builds_the_addressable_template_expansion() {
        assert_eq!(
            url("1000", "420", "cover", IMG).as_deref(),
            Some(
                "https://media2.dev.to/dynamic/image/width=1000,height=420,fit=cover,\
                 gravity=auto,format=auto/https%3A%2F%2Fdev-to-uploads.s3.amazonaws.com\
                 %2Fuploads%2Farticles%2Fabc123.png"
            )
        );
    }

    #[test]
    fn expands_blank_values_as_empty_strings() {
        assert_eq!(
            cloudflare_image_url("", "dynamic", "", "420", "scale-down", "", "").as_deref(),
            Some(
                "https:///dynamic/image/width=,height=420,fit=scale-down,gravity=auto,format=auto/"
            )
        );
    }

    #[test]
    fn percent_encodes_reserved_and_multibyte_characters() {
        assert_eq!(
            cloudflare_image_url("a:b", "x/y", "-1", "1 2", "scale-down", "a b/é~", "a b/é~")
                .as_deref(),
            Some(
                "https://a%3Ab/x%2Fy/image/width=-1,height=1%202,fit=scale-down,\
                 gravity=auto,format=auto/a%20b%2F%C3%A9~"
            )
        );
    }

    #[test]
    fn drops_the_format_for_animated_images() {
        for img_src in [
            "https://x.com/a.gif",
            "https://x.com/a.GIF",
            "https://x.com/a.WebP?w=1",
            "https://x.com/a.gif?",
            "https://x.com/a.gif\nmore",
            "a.png.gif",
            ".webp",
        ] {
            let built = url("1", "1", "cover", img_src).unwrap();
            assert!(!built.contains("format=auto"), "{img_src:?}");
        }
    }

    #[test]
    fn keeps_the_format_for_other_images() {
        for img_src in [
            "",
            "https://x.com/a.png",
            "https://x.com/a.gifv",
            "https://x.com/a.gif#frag",
            "https://x.com/a.gif\r\n",
            "https://x.com/agif",
            "https://x.com/a.web",
            "https://x.com/a.ġif",
        ] {
            let built = url("1", "1", "cover", img_src).unwrap();
            assert!(built.contains("format=auto"), "{img_src:?}");
        }
    }

    #[test]
    fn declines_text_addressable_would_normalize() {
        // U+0301 COMBINING ACUTE ACCENT composes with the preceding `e` under NFC.
        assert_eq!(url("1", "1", "cover", "https://x.com/e\u{301}.png"), None);
        assert_eq!(url("1", "1", "cover", "https://x.com/日本.png"), None);
        assert_eq!(url("1", "1", "cover", "https://x.com/😀.png"), None);
        // U+02FF is the last code point we accept.
        assert!(url("1", "1", "cover", "\u{2FF}").is_some());
    }
}
