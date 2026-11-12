//! HTML-safe JSON encoding matching ActiveSupport's `Object#to_json`.
//!
//! Rails encodes JSON in three steps: `jsonify` walks the value, `JSON.generate` (json 2.7)
//! serializes it, and then five whole-document `gsub!` passes rewrite `>`, `<`, `&`, U+2028,
//! and U+2029 as `\uXXXX` escapes. For large documents such as article JSON-LD (which embeds
//! the rendered article and comment HTML), those passes dominate the cost.
//!
//! This module produces the identical bytes in a single pass:
//! - Tier 1: [`write_json_string`] / [`json_quote`] escape one string into a buffer.
//! - Tier 2: [`JsonWriter`] streams a whole document (objects, arrays, scalars) into one
//!   pre-allocated buffer so a caller can walk a value tree exactly once.

use std::fmt::Write;

/// Escape class for each ASCII byte: `0` = copy verbatim, `1` = always escaped,
/// `2` = escaped only when HTML entities are escaped (`<`, `>`, `&`).
const ASCII_ESCAPE: [u8; 128] = {
    let mut table = [0u8; 128];
    let mut i = 0;
    while i < 0x20 {
        table[i] = 1;
        i += 1;
    }
    table[b'"' as usize] = 1;
    table[b'\\' as usize] = 1;
    table[b'<' as usize] = 2;
    table[b'>' as usize] = 2;
    table[b'&' as usize] = 2;
    table
};

const HEX: &[u8; 16] = b"0123456789abcdef";

/// Appends `s` to `out` as a quoted JSON string, byte-for-byte equal to ActiveSupport's
/// `s.to_json` (json 2.7 escapes plus the Rails ` ` / ` ` and, when
/// `escape_html` is true, `<` / `>` / `&` rewrites).
pub fn write_json_string(out: &mut String, s: &str, escape_html: bool) {
    write_quoted(out, s, escape_html);
}

/// Writes `s` as a quoted, ActiveSupport-escaped JSON string into any [`JsonOutput`] sink.
fn write_quoted<W: JsonOutput>(out: &mut W, s: &str, escape_html: bool) {
    let bytes = s.as_bytes();
    out.reserve(bytes.len() + 2);
    out.push('"');
    let mut start = 0;
    let mut i = 0;
    while i < bytes.len() {
        let b = bytes[i];
        let needs_escape = if b < 0x80 {
            match ASCII_ESCAPE[b as usize] {
                0 => false,
                2 => escape_html,
                _ => true,
            }
        } else {
            b == 0xE2
                && bytes.get(i + 1) == Some(&0x80)
                && matches!(bytes.get(i + 2), Some(0xA8 | 0xA9))
        };
        if !needs_escape {
            i += 1;
            continue;
        }

        out.push_str(&s[start..i]);
        if b == 0xE2 {
            out.push_str(if bytes[i + 2] == 0xA8 {
                "\\u2028"
            } else {
                "\\u2029"
            });
            i += 3;
        } else {
            match b {
                b'"' => out.push_str("\\\""),
                b'\\' => out.push_str("\\\\"),
                b'\n' => out.push_str("\\n"),
                b'\r' => out.push_str("\\r"),
                b'\t' => out.push_str("\\t"),
                0x08 => out.push_str("\\b"),
                0x0C => out.push_str("\\f"),
                _ => {
                    out.push_str("\\u00");
                    out.push(HEX[(b >> 4) as usize] as char);
                    out.push(HEX[(b & 0x0F) as usize] as char);
                }
            }
            i += 1;
        }
        start = i;
    }
    out.push_str(&s[start..]);
    out.push('"');
}

/// Returns `s` as a quoted, HTML-safe JSON string (ActiveSupport's `s.to_json`).
pub fn json_quote(s: &str, escape_html: bool) -> String {
    let mut out = String::with_capacity(s.len() + 2);
    write_json_string(&mut out, s, escape_html);
    out
}

/// Output shared by the encoder and byte counter. Neither implementation can fail.
pub trait JsonOutput: Write {
    /// Reserves capacity for at least `additional` more bytes when backed by a buffer.
    fn reserve(&mut self, additional: usize);
    /// Appends a single UTF-8 character to the output or adds its UTF-8 byte length.
    fn push(&mut self, value: char);
    /// Appends a UTF-8 string slice to the output or adds its byte length.
    fn push_str(&mut self, value: &str);
}

impl JsonOutput for String {
    fn reserve(&mut self, additional: usize) {
        String::reserve(self, additional);
    }
    fn push(&mut self, value: char) {
        String::push(self, value);
    }
    fn push_str(&mut self, value: &str) {
        String::push_str(self, value);
    }
}

/// A counting sink: retains no document bytes, regardless of input size.
#[derive(Default)]
pub struct JsonByteCount(pub usize);

impl Write for JsonByteCount {
    fn write_str(&mut self, value: &str) -> std::fmt::Result {
        self.0 += value.len();
        Ok(())
    }
}

impl JsonOutput for JsonByteCount {
    fn reserve(&mut self, _additional: usize) {}
    fn push(&mut self, value: char) {
        self.0 += value.len_utf8();
    }
    fn push_str(&mut self, value: &str) {
        self.0 += value.len();
    }
}

/// Encoded byte length of a string, including quotes, without allocating its JSON.
pub fn json_quoted_size(value: &str, escape_html: bool) -> usize {
    let mut count = JsonByteCount::default();
    write_quoted(&mut count, value, escape_html);
    count.0
}

/// Streaming JSON document writer producing the same compact output as `JSON.generate`
/// (no whitespace, `,` and `:` separators) with ActiveSupport's string escaping.
///
/// Callers are responsible for balancing `begin_*` / `end_*` calls and for calling
/// [`JsonWriter::key`] before every value inside an object.
pub struct JsonWriter<W = String> {
    buf: W,
    escape_html: bool,
    // One entry per open container: true until its first element has been written.
    first: Vec<bool>,
    // True right after `key`, so the following value is not preceded by a comma.
    after_key: bool,
}

impl JsonWriter {
    /// Creates a string-backed [`JsonWriter`] with the specified initial byte capacity.
    pub fn new(escape_html: bool, capacity: usize) -> Self {
        Self::with_output(escape_html, String::with_capacity(capacity))
    }
}

impl JsonWriter<JsonByteCount> {
    /// Creates a byte-counting [`JsonWriter`] that tracks encoded JSON length without allocating a buffer.
    pub fn counting(escape_html: bool) -> Self {
        Self::with_output(escape_html, JsonByteCount::default())
    }
}

impl<W: JsonOutput> JsonWriter<W> {
    /// Initializes a [`JsonWriter`] wrapping the provided [`JsonOutput`] sink.
    fn with_output(escape_html: bool, buf: W) -> Self {
        Self {
            buf,
            escape_html,
            first: Vec::new(),
            after_key: false,
        }
    }

    /// Number of currently open objects and arrays.
    pub fn depth(&self) -> usize {
        self.first.len()
    }

    fn separate(&mut self) {
        if self.after_key {
            self.after_key = false;
            return;
        }
        if let Some(first) = self.first.last_mut() {
            if *first {
                *first = false;
            } else {
                self.buf.push(',');
            }
        }
    }

    pub fn begin_object(&mut self) {
        self.separate();
        self.buf.push('{');
        self.first.push(true);
    }

    pub fn end_object(&mut self) {
        self.first.pop();
        self.buf.push('}');
    }

    pub fn begin_array(&mut self) {
        self.separate();
        self.buf.push('[');
        self.first.push(true);
    }

    pub fn end_array(&mut self) {
        self.first.pop();
        self.buf.push(']');
    }

    /// Writes an object member key followed by `:`.
    pub fn key(&mut self, key: &str) {
        self.separate();
        write_quoted(&mut self.buf, key, self.escape_html);
        self.buf.push(':');
        self.after_key = true;
    }

    /// Writes a JSON string value.
    pub fn string(&mut self, value: &str) {
        self.separate();
        write_quoted(&mut self.buf, value, self.escape_html);
    }

    pub fn int(&mut self, value: i64) {
        self.separate();
        // Writing into a String cannot fail.
        let _ = write!(self.buf, "{value}");
    }

    pub fn bool(&mut self, value: bool) {
        self.separate();
        self.buf.push_str(if value { "true" } else { "false" });
    }

    pub fn null(&mut self) {
        self.separate();
        self.buf.push_str("null");
    }

    /// Consumes the writer and returns the underlying output sink.
    pub fn finish(self) -> W {
        self.buf
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Verifies that `json_quoted_size` matches the byte length of `json_quote` across escape modes.
    #[test]
    fn counts_quoted_bytes_without_a_buffer() {
        let inputs = [
            "",
            "plain",
            "é 😀 漢字",
            "\"\\\r\n\t",
            "<>&",
            "\u{2028}\u{2029}",
            "\u{0}\u{8}\u{b}\u{c}\u{1f}",
            "&#64; &amp;",
        ];
        for escape_html in [true, false] {
            for input in inputs {
                assert_eq!(
                    json_quoted_size(input, escape_html),
                    json_quote(input, escape_html).len()
                );
            }
        }
    }

    #[test]
    fn counts_nested_documents_and_integer_boundaries() {
        let mut w = JsonWriter::counting(true);
        w.begin_object();
        w.key("<&>");
        w.begin_array();
        w.int(i64::MIN);
        w.int(i64::MAX);
        w.null();
        w.bool(true);
        w.bool(false);
        w.string("😀\u{2028}");
        w.begin_object();
        w.end_object();
        w.end_array();
        w.end_object();
        assert_eq!(w.depth(), 0);
        assert_eq!(w.finish().0, r#"{"\u003c\u0026\u003e":[-9223372036854775808,9223372036854775807,null,true,false,"😀\u2028",{}]}"#.len());
    }

    #[test]
    fn quotes_plain_strings() {
        assert_eq!(json_quote("", true), r#""""#);
        assert_eq!(json_quote("hello", true), r#""hello""#);
        assert_eq!(json_quote("a/b", true), r#""a/b""#);
    }

    #[test]
    fn escapes_json_metacharacters() {
        assert_eq!(json_quote("\"\\", true), r#""\"\\""#);
        assert_eq!(
            json_quote("\u{8}\t\n\u{b}\u{c}\r", true),
            r#""\b\t\n\u000b\f\r""#
        );
        assert_eq!(
            json_quote("\u{0}\u{1}\u{1a}\u{1f}", true),
            r#""\u0000\u0001\u001a\u001f""#
        );
        assert_eq!(json_quote("\u{7f}", true), "\"\u{7f}\"");
    }

    #[test]
    fn escapes_html_entities_only_when_requested() {
        assert_eq!(
            json_quote("<a href=\"x\">&</a>", true),
            r#""\u003ca href=\"x\"\u003e\u0026\u003c/a\u003e""#
        );
        assert_eq!(json_quote("<a>&</a>", false), r#""<a>&</a>""#);
    }

    #[test]
    fn always_escapes_line_and_paragraph_separators() {
        assert_eq!(
            json_quote("a\u{2028}b\u{2029}c", false),
            r#""a\u2028b\u2029c""#
        );
        assert_eq!(json_quote("\u{2028}", true), r#""\u2028""#);
    }

    #[test]
    fn preserves_other_multibyte_characters() {
        // U+2027 and U+202A share the E2 80 prefix but are not escaped.
        let s = "é 😀 漢字 \u{2027}\u{202a} — “q”";
        assert_eq!(json_quote(s, true), format!("\"{s}\""));
    }

    #[test]
    fn writes_nested_documents() {
        let mut w = JsonWriter::new(true, 64);
        w.begin_object();
        w.key("@type");
        w.string("Article");
        w.key("ids");
        w.begin_array();
        w.int(1);
        w.int(-2);
        w.null();
        w.bool(true);
        w.begin_object();
        w.end_object();
        w.begin_array();
        w.end_array();
        w.end_array();
        w.key("nested");
        w.begin_object();
        w.key("a");
        w.bool(false);
        w.key("a");
        w.string("<b>");
        w.end_object();
        w.end_object();
        assert_eq!(w.depth(), 0);
        assert_eq!(
            w.finish(),
            r#"{"@type":"Article","ids":[1,-2,null,true,{},[]],"nested":{"a":false,"a":"\u003cb\u003e"}}"#
        );
    }

    #[test]
    fn writes_top_level_scalars() {
        let mut w = JsonWriter::new(true, 8);
        w.string("x&y");
        assert_eq!(w.finish(), r#""x\u0026y""#);

        let mut w = JsonWriter::new(true, 8);
        w.int(i64::MIN);
        assert_eq!(w.finish(), "-9223372036854775808");
    }

    #[test]
    fn escapes_keys() {
        let mut w = JsonWriter::new(true, 16);
        w.begin_object();
        w.key("<k\n>");
        w.null();
        w.end_object();
        assert_eq!(w.finish(), r#"{"\u003ck\n\u003e":null}"#);
    }
}
