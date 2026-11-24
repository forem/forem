//! Single-pass streaming RSS 2.0 XML serializer and XML/RFC 822 primitives for
//! Forem (`ArticlesController#feed` / `app/views/articles/feed.rss.builder`).
//!
//! Replaces ActionView `Builder::XmlMarkup` (`method_missing`, per-instance
//! `class_eval` method cache invalidation, 4-pass `Builder::XChar.encode`
//! regex/`tr` string allocations on every element, indent, and newline,
//! `Time#to_fs(:rfc822)` allocations, and `cached_tag_list_array` splits) with:
//!
//! - **Tier 1 composable primitives**:
//!   - [`write_xml_escaped_text`] / [`xml_escape_text`]: single-pass XML 1.0
//!     text escaper matching `Builder::XChar.encode` (CP1252 `U+0080..=U+009F`
//!     remapping, invalid XML 1.0 char replacement with `U+FFFD`, and
//!     `&`/`<`/`>` entity escaping).
//!   - [`write_xml_escaped_attribute`] / [`xml_escape_attribute`]: single-pass
//!     XML 1.0 attribute escaper matching `Builder::XmlBase#_escape_attribute`
//!     (text escaping plus `\n` -> `&#10;`, `\r` -> `&#13;`, `"` -> `&quot;`).
//!   - [`write_rfc822_timestamp`] / [`format_rfc822_timestamp`]: stack-allocated
//!     31-byte RFC 822 timestamp formatter matching Ruby's `Time#to_fs(:rfc822)`
//!     (`%a, %d %b %Y %H:%M:%S %z`).
//! - **Tier 2 single-pass streaming kernel**:
//!   - [`serialize_rss_feed_xml`]: streams a complete `indent: 2` RSS 2.0 XML
//!     document into a single pre-sized UTF-8 `String` buffer.

use crate::api_comments::civil_from_days;

const WEEKDAYS: [&[u8; 3]; 7] = [b"Sun", b"Mon", b"Tue", b"Wed", b"Thu", b"Fri", b"Sat"];
const MONTHS: [&[u8; 3]; 12] = [
    b"Jan", b"Feb", b"Mar", b"Apr", b"May", b"Jun", b"Jul", b"Aug", b"Sep", b"Oct", b"Nov", b"Dec",
];

/// CP1252 codepoint remapping table for `U+0080..=U+009F` matching `Builder::XChar::CP1252`.
/// Entries with `'\0'` are unmapped and preserved as-is.
const CP1252_MAP: [char; 32] = [
    '\u{20AC}', // 0x80 -> €
    '\0',       // 0x81 (unmapped)
    '\u{201A}', // 0x82 -> ‚
    '\u{0192}', // 0x83 -> ƒ
    '\u{201E}', // 0x84 -> „
    '\u{2026}', // 0x85 -> …
    '\u{2020}', // 0x86 -> †
    '\u{2021}', // 0x87 -> ‡
    '\u{02C6}', // 0x88 -> ˆ
    '\u{2030}', // 0x89 -> ‰
    '\u{0160}', // 0x8A -> Š
    '\u{2039}', // 0x8B -> ‹
    '\u{0152}', // 0x8C -> Œ
    '\0',       // 0x8D (unmapped)
    '\u{017D}', // 0x8E -> Ž
    '\0',       // 0x8F (unmapped)
    '\0',       // 0x90 (unmapped)
    '\u{2018}', // 0x91 -> ‘
    '\u{2019}', // 0x92 -> ’
    '\u{201C}', // 0x93 -> “
    '\u{201D}', // 0x94 -> ”
    '\u{2022}', // 0x95 -> •
    '\u{2013}', // 0x96 -> –
    '\u{2014}', // 0x97 -> —
    '\u{02DC}', // 0x98 -> ˜
    '\u{2122}', // 0x99 -> ™
    '\u{0161}', // 0x9A -> š
    '\u{203A}', // 0x9B -> ›
    '\u{0153}', // 0x9C -> œ
    '\0',       // 0x9D (unmapped)
    '\u{017E}', // 0x9E -> ž
    '\u{0178}', // 0x9F -> Ÿ
];

const REPLACEMENT_CHAR: char = '\u{FFFD}';

/// Optional `<image>` block for user/organization RSS channels.
#[derive(Debug, Clone, Copy)]
pub struct RssChannelImage<'a> {
    pub url: Option<&'a str>,
    pub title: Option<&'a str>,
    pub link: Option<&'a str>,
}

/// Channel-level metadata for `app/views/articles/feed.rss.builder`.
#[derive(Debug, Clone, Copy)]
pub struct RssChannel<'a> {
    pub title: Option<&'a str>,
    pub description: Option<&'a str>,
    pub link: Option<&'a str>,
    pub image: Option<RssChannelImage<'a>>,
    pub self_href: &'a str,
    pub language: &'a str,
}

/// Item-level metadata for a single `<item>` in `app/views/articles/feed.rss.builder`.
#[derive(Debug, Clone, Copy)]
pub struct RssItem<'a> {
    pub title: Option<&'a str>,
    pub creator: Option<&'a str>,
    /// `(epoch_secs, utc_offset_secs)` matching `Time#tv_sec` and `Time#utc_offset`.
    pub published_at: Option<(i64, i32)>,
    pub link: Option<&'a str>,
    pub guid: Option<&'a str>,
    pub description: Option<&'a str>,
    pub cached_tag_list: Option<&'a str>,
}

/// Escapes `input` for XML 1.0 text nodes into `out`, matching `Builder::XChar.encode`
/// for valid UTF-8 strings byte-for-byte.
pub fn write_xml_escaped_text(out: &mut String, input: &str) {
    write_xml_escaped::<false>(out, input);
}

/// Escapes `input` for XML 1.0 text nodes, matching `Builder::XChar.encode`.
pub fn xml_escape_text(input: &str) -> String {
    let mut out = String::with_capacity(input.len() + input.len() / 8);
    write_xml_escaped_text(&mut out, input);
    out
}

/// Escapes `input` for XML 1.0 double-quoted attribute values into `out`, matching
/// `Builder::XmlBase#_escape_attribute` byte-for-byte.
pub fn write_xml_escaped_attribute(out: &mut String, input: &str) {
    write_xml_escaped::<true>(out, input);
}

/// Escapes `input` for XML 1.0 double-quoted attribute values, matching
/// `Builder::XmlBase#_escape_attribute`.
pub fn xml_escape_attribute(input: &str) -> String {
    let mut out = String::with_capacity(input.len() + input.len() / 8);
    write_xml_escaped_attribute(&mut out, input);
    out
}

#[inline]
fn write_xml_escaped<const ATTR: bool>(out: &mut String, input: &str) {
    let bytes = input.as_bytes();
    let len = bytes.len();
    let mut i = 0;
    let mut last = 0;

    while i < len {
        let b = bytes[i];
        if b < 0x80 {
            match b {
                b'&' => {
                    if last < i {
                        out.push_str(&input[last..i]);
                    }
                    out.push_str("&amp;");
                    i += 1;
                    last = i;
                }
                b'<' => {
                    if last < i {
                        out.push_str(&input[last..i]);
                    }
                    out.push_str("&lt;");
                    i += 1;
                    last = i;
                }
                b'>' => {
                    if last < i {
                        out.push_str(&input[last..i]);
                    }
                    out.push_str("&gt;");
                    i += 1;
                    last = i;
                }
                b'"' if ATTR => {
                    if last < i {
                        out.push_str(&input[last..i]);
                    }
                    out.push_str("&quot;");
                    i += 1;
                    last = i;
                }
                b'\n' if ATTR => {
                    if last < i {
                        out.push_str(&input[last..i]);
                    }
                    out.push_str("&#10;");
                    i += 1;
                    last = i;
                }
                b'\r' if ATTR => {
                    if last < i {
                        out.push_str(&input[last..i]);
                    }
                    out.push_str("&#13;");
                    i += 1;
                    last = i;
                }
                0x00..=0x08 | 0x0B | 0x0C | 0x0E..=0x1F => {
                    if last < i {
                        out.push_str(&input[last..i]);
                    }
                    out.push(REPLACEMENT_CHAR);
                    i += 1;
                    last = i;
                }
                _ => {
                    i += 1;
                }
            }
        } else if b == 0xC2 && i + 1 < len && (0x80..=0x9F).contains(&bytes[i + 1]) {
            // UTF-8 encoding of U+0080..=U+009F is [0xC2, 0x80..=0x9F].
            let mapped = CP1252_MAP[(bytes[i + 1] - 0x80) as usize];
            if mapped != '\0' {
                if last < i {
                    out.push_str(&input[last..i]);
                }
                out.push(mapped);
                i += 2;
                last = i;
            } else {
                i += 2;
            }
        } else if b == 0xEF
            && i + 2 < len
            && bytes[i + 1] == 0xBF
            && (bytes[i + 2] == 0xBE || bytes[i + 2] == 0xBF)
        {
            // UTF-8 encoding of U+FFFE is [0xEF, 0xBF, 0xBE]; U+FFFF is [0xEF, 0xBF, 0xBF].
            if last < i {
                out.push_str(&input[last..i]);
            }
            out.push(REPLACEMENT_CHAR);
            i += 3;
            last = i;
        } else {
            // Any other valid UTF-8 multi-byte sequence is a valid XML 1.0 character
            // and is copied verbatim in the bulk slice.
            let step = utf8_char_width(b);
            i += step;
        }
    }

    if last < len {
        out.push_str(&input[last..len]);
    }
}

#[inline]
const fn utf8_char_width(first_byte: u8) -> usize {
    if first_byte < 0xE0 {
        2
    } else if first_byte < 0xF0 {
        3
    } else {
        4
    }
}

/// Writes `(epoch_secs, utc_offset_secs)` formatted as RFC 822 (`%a, %d %b %Y %H:%M:%S %z`)
/// into `out` using a 31-byte stack buffer, matching Ruby's `Time#to_fs(:rfc822)`.
///
/// Returns `false` if `utc_offset_secs` is not a whole-minute offset in `-86340..=86340`,
/// if `epoch_secs + utc_offset_secs` overflows `i64`, or if the local year is outside
/// `0000..=9999`.
pub fn write_rfc822_timestamp(out: &mut String, epoch_secs: i64, utc_offset_secs: i32) -> bool {
    if utc_offset_secs % 60 != 0 || utc_offset_secs.abs() >= 86_400 {
        return false;
    }

    let Some(local_secs) = epoch_secs.checked_add(i64::from(utc_offset_secs)) else {
        return false;
    };

    let days = local_secs.div_euclid(86_400);
    let secs_of_day = local_secs.rem_euclid(86_400) as u32;

    let (year, month, day) = civil_from_days(days);
    if !(0..=9999).contains(&year) {
        return false;
    }

    let weekday_idx = (days + 4).rem_euclid(7) as usize;
    let wd = WEEKDAYS[weekday_idx];
    let mon = MONTHS[(month - 1) as usize];

    let y = year as u32;
    let hour = secs_of_day / 3600;
    let minute = (secs_of_day % 3600) / 60;
    let second = secs_of_day % 60;

    let offset_sign = if utc_offset_secs < 0 { b'-' } else { b'+' };
    let abs_offset_mins = (utc_offset_secs.unsigned_abs()) / 60;
    let off_hour = abs_offset_mins / 60;
    let off_min = abs_offset_mins % 60;

    let buf: [u8; 31] = [
        wd[0],
        wd[1],
        wd[2],
        b',',
        b' ',
        b'0' + (day / 10) as u8,
        b'0' + (day % 10) as u8,
        b' ',
        mon[0],
        mon[1],
        mon[2],
        b' ',
        b'0' + (y / 1000) as u8,
        b'0' + ((y / 100) % 10) as u8,
        b'0' + ((y / 10) % 10) as u8,
        b'0' + (y % 10) as u8,
        b' ',
        b'0' + (hour / 10) as u8,
        b'0' + (hour % 10) as u8,
        b':',
        b'0' + (minute / 10) as u8,
        b'0' + (minute % 10) as u8,
        b':',
        b'0' + (second / 10) as u8,
        b'0' + (second % 10) as u8,
        b' ',
        offset_sign,
        b'0' + (off_hour / 10) as u8,
        b'0' + (off_hour % 10) as u8,
        b'0' + (off_min / 10) as u8,
        b'0' + (off_min % 10) as u8,
    ];

    // SAFETY: `buf` contains exclusively ASCII bytes.
    let s = unsafe { std::str::from_utf8_unchecked(&buf) };
    out.push_str(s);
    true
}

/// Formats `(epoch_secs, utc_offset_secs)` as RFC 822 (`%a, %d %b %Y %H:%M:%S %z`),
/// matching Ruby's `Time#to_fs(:rfc822)`.
pub fn format_rfc822_timestamp(epoch_secs: i64, utc_offset_secs: i32) -> Option<String> {
    let mut out = String::with_capacity(31);
    if write_rfc822_timestamp(&mut out, epoch_secs, utc_offset_secs) {
        Some(out)
    } else {
        None
    }
}

#[inline]
fn write_element(out: &mut String, indent: &str, tag: &str, value: Option<&str>) {
    out.push_str(indent);
    out.push('<');
    out.push_str(tag);
    match value {
        Some(text) => {
            out.push('>');
            write_xml_escaped_text(out, text);
            out.push_str("</");
            out.push_str(tag);
            out.push_str(">\n");
        }
        None => {
            out.push_str("/>\n");
        }
    }
}

#[inline]
fn write_categories(out: &mut String, cached_tag_list: Option<&str>) {
    let Some(mut rest) = cached_tag_list else {
        return;
    };
    // Match Ruby's `(cached_tag_list || "").split(", ")`, which strips trailing empty fields.
    while let Some(stripped) = rest.strip_suffix(", ") {
        rest = stripped;
    }
    if rest.is_empty() {
        return;
    }
    for tag in rest.split(", ") {
        out.push_str("      <category>");
        write_xml_escaped_text(out, tag);
        out.push_str("</category>\n");
    }
}

/// Streams a complete RSS 2.0 XML document matching `app/views/articles/feed.rss.builder`
/// (`Builder::XmlMarkup.new(indent: 2)`) into a single pre-sized UTF-8 `String` buffer.
///
/// Returns `None` if any item's `published_at` falls outside [`write_rfc822_timestamp`]'s
/// fast-path domain (so the caller can transparently fall back to Ruby).
pub fn serialize_rss_feed_xml(channel: &RssChannel<'_>, items: &[RssItem<'_>]) -> Option<String> {
    let items_cap: usize = items
        .iter()
        .map(|it| {
            320 + it.title.map_or(0, str::len)
                + it.creator.map_or(0, str::len)
                + it.link.map_or(0, str::len)
                + it.guid.map_or(0, str::len)
                + it.description.map_or(0, |d| d.len() + d.len() / 4)
                + it.cached_tag_list.map_or(0, |c| c.len() * 2)
        })
        .sum();
    let mut out = String::with_capacity(512 + items_cap);

    out.push_str("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
    out.push_str(
        "<rss version=\"2.0\" xmlns:atom=\"http://www.w3.org/2005/Atom\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\">\n",
    );
    out.push_str("  <channel>\n");

    write_element(&mut out, "    ", "title", channel.title);
    write_element(&mut out, "    ", "description", channel.description);
    write_element(&mut out, "    ", "link", channel.link);

    if let Some(image) = channel.image {
        out.push_str("    <image>\n");
        write_element(&mut out, "      ", "url", image.url);
        write_element(&mut out, "      ", "title", image.title);
        write_element(&mut out, "      ", "link", image.link);
        out.push_str("    </image>\n");
    }

    out.push_str("    <atom:link rel=\"self\" type=\"application/rss+xml\" href=\"");
    write_xml_escaped_attribute(&mut out, channel.self_href);
    out.push_str("\"/>\n");

    write_element(&mut out, "    ", "language", Some(channel.language));

    for item in items {
        out.push_str("    <item>\n");
        write_element(&mut out, "      ", "title", item.title);
        write_element(&mut out, "      ", "dc:creator", item.creator);

        if let Some((epoch_secs, utc_offset_secs)) = item.published_at {
            out.push_str("      <pubDate>");
            if !write_rfc822_timestamp(&mut out, epoch_secs, utc_offset_secs) {
                return None;
            }
            out.push_str("</pubDate>\n");
        }

        write_element(&mut out, "      ", "link", item.link);
        write_element(&mut out, "      ", "guid", item.guid);
        write_element(&mut out, "      ", "description", item.description);
        write_categories(&mut out, item.cached_tag_list);
        out.push_str("    </item>\n");
    }

    out.push_str("  </channel>\n");
    out.push_str("</rss>\n");

    Some(out)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn xml_escape_text_handles_entities_controls_cp1252_and_utf8() {
        assert_eq!(xml_escape_text(""), "");
        assert_eq!(xml_escape_text("plain ASCII 123"), "plain ASCII 123");
        assert_eq!(
            xml_escape_text("A & B < C > D \"q\" 's'"),
            "A &amp; B &lt; C &gt; D \"q\" 's'"
        );
        // Valid XML whitespace preserved; invalid controls replaced with U+FFFD.
        assert_eq!(
            xml_escape_text("a\tb\nc\rd\x00e\x08f\x0Bg\x0Ch\x1Fi"),
            "a\tb\nc\rd\u{FFFD}e\u{FFFD}f\u{FFFD}g\u{FFFD}h\u{FFFD}i"
        );
        // CP1252 remapping vs unmapped C1 controls.
        assert_eq!(
            xml_escape_text("\u{0080}\u{0081}\u{0085}\u{0093}\u{0094}\u{0099}\u{009F}"),
            "\u{20AC}\u{0081}\u{2026}\u{201C}\u{201D}\u{2122}\u{0178}"
        );
        // Non-characters U+FFFE and U+FFFF replaced with U+FFFD.
        assert_eq!(
            xml_escape_text("x\u{FFFE}y\u{FFFF}z"),
            "x\u{FFFD}y\u{FFFD}z"
        );
        // Multi-byte UTF-8 emojis and CJK preserved verbatim.
        assert_eq!(xml_escape_text("🚀 café 日本語"), "🚀 café 日本語");
    }

    #[test]
    fn xml_escape_attribute_handles_quotes_and_newlines() {
        assert_eq!(
            xml_escape_attribute("https://dev.to/feed?a=1&b=\"2\"\n\r"),
            "https://dev.to/feed?a=1&amp;b=&quot;2&quot;&#10;&#13;"
        );
    }

    #[test]
    fn format_rfc822_timestamp_matches_ruby() {
        assert_eq!(
            format_rfc822_timestamp(0, 0).as_deref(),
            Some("Thu, 01 Jan 1970 00:00:00 +0000")
        );
        // 2026-01-05 09:04:03 UTC
        assert_eq!(
            format_rfc822_timestamp(1_767_603_843, 0).as_deref(),
            Some("Mon, 05 Jan 2026 09:04:03 +0000")
        );
        // 2026-11-24 20:50:48 -0530 -> UTC 2026-11-25 02:20:48 = 1795573248? Let's verify offset arithmetic:
        // 2026-11-24 20:50:48 UTC is 1_795_553_448; with -05:30 (-19800s), local is 15:20:48.
        assert_eq!(
            format_rfc822_timestamp(1_795_553_448, -19_800).as_deref(),
            Some("Tue, 24 Nov 2026 15:20:48 -0530")
        );
        // Positive offset +05:30
        assert_eq!(
            format_rfc822_timestamp(1_795_553_448, 19_800).as_deref(),
            Some("Wed, 25 Nov 2026 02:20:48 +0530")
        );
        // Out-of-domain offsets and years defer to Ruby.
        assert_eq!(format_rfc822_timestamp(0, 30), None);
        assert_eq!(format_rfc822_timestamp(0, 86_400), None);
        assert_eq!(format_rfc822_timestamp(0, -86_400), None);
        assert_eq!(format_rfc822_timestamp(-62_167_219_201, 0), None);
        assert_eq!(format_rfc822_timestamp(253_402_300_800, 0), None);
    }

    #[test]
    fn serialize_rss_feed_xml_matches_builder_structure() {
        let channel = RssChannel {
            title: Some("DEV Community: Alice"),
            description: Some("The latest articles on DEV Community by Alice (@alice)."),
            link: Some("https://dev.to/alice"),
            image: Some(RssChannelImage {
                url: Some("https://dev.to/avatar.png"),
                title: Some("DEV Community: Alice"),
                link: Some("https://dev.to/alice"),
            }),
            self_href: "https://dev.to/feed/alice?a=1&b=2",
            language: "en",
        };
        let items = [RssItem {
            title: Some("Rust & Ruby <3"),
            creator: Some("Alice"),
            published_at: Some((0, 0)),
            link: Some("https://dev.to/alice/rust-ruby"),
            guid: Some("https://dev.to/alice/rust-ruby"),
            description: Some("<p>Hello &amp; world!</p>"),
            cached_tag_list: Some("rust, ruby, "),
        }];

        let xml = serialize_rss_feed_xml(&channel, &items).unwrap();
        let expected = concat!(
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n",
            "<rss version=\"2.0\" xmlns:atom=\"http://www.w3.org/2005/Atom\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\">\n",
            "  <channel>\n",
            "    <title>DEV Community: Alice</title>\n",
            "    <description>The latest articles on DEV Community by Alice (@alice).</description>\n",
            "    <link>https://dev.to/alice</link>\n",
            "    <image>\n",
            "      <url>https://dev.to/avatar.png</url>\n",
            "      <title>DEV Community: Alice</title>\n",
            "      <link>https://dev.to/alice</link>\n",
            "    </image>\n",
            "    <atom:link rel=\"self\" type=\"application/rss+xml\" href=\"https://dev.to/feed/alice?a=1&amp;b=2\"/>\n",
            "    <language>en</language>\n",
            "    <item>\n",
            "      <title>Rust &amp; Ruby &lt;3</title>\n",
            "      <dc:creator>Alice</dc:creator>\n",
            "      <pubDate>Thu, 01 Jan 1970 00:00:00 +0000</pubDate>\n",
            "      <link>https://dev.to/alice/rust-ruby</link>\n",
            "      <guid>https://dev.to/alice/rust-ruby</guid>\n",
            "      <description>&lt;p&gt;Hello &amp;amp; world!&lt;/p&gt;</description>\n",
            "      <category>rust</category>\n",
            "      <category>ruby</category>\n",
            "    </item>\n",
            "  </channel>\n",
            "</rss>\n",
        );
        assert_eq!(xml, expected);
    }

    #[test]
    fn serialize_rss_feed_xml_handles_nil_fields_and_category_edge_cases() {
        let channel = RssChannel {
            title: None,
            description: Some(""),
            link: Some("https://dev.to"),
            image: None,
            self_href: "https://dev.to/feed",
            language: "en",
        };
        let items = [RssItem {
            title: None,
            creator: None,
            published_at: None,
            link: Some("https://dev.to/a"),
            guid: Some("https://dev.to/a"),
            description: None,
            cached_tag_list: Some("a, , b, "),
        }];

        let xml = serialize_rss_feed_xml(&channel, &items).unwrap();
        assert!(xml.contains("    <title/>\n"));
        assert!(xml.contains("    <description></description>\n"));
        assert!(!xml.contains("<image>"));
        assert!(xml.contains("      <title/>\n"));
        assert!(xml.contains("      <dc:creator/>\n"));
        assert!(!xml.contains("<pubDate>"));
        assert!(xml.contains("      <description/>\n"));
        assert!(xml.contains(
            "      <category>a</category>\n      <category></category>\n      <category>b</category>\n"
        ));
    }
}
