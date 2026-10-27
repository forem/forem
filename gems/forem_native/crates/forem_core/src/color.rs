//! Hex color math mirroring `Color::CompareHex#brightness`.

/// Largest rounded channel value we format natively. Anything bigger (or negative,
/// NaN, infinite) returns `None` so the caller can use the Ruby implementation, which
/// owns the Bignum / two's-complement (`..f`) / `FloatDomainError` rescue semantics.
const MAX_CHANNEL: f64 = 9_007_199_254_740_992.0; // 2^53
const ACCENT_MODIFIERS: [f64; 8] = [1.14, 1.08, 1.06, 0.96, 0.9, 0.8, 0.7, 0.6];

/// Parses a strict `#?[0-9a-fA-F]{6}` hex color into its RGB channels.
///
/// Returns `None` for anything else (whitespace, newlines, signs, `0x` prefixes,
/// multi-byte characters, wrong length). Those inputs hit Ruby's line-anchored
/// `/^#?(?<r>..)(?<g>..)(?<b>..)$/` + `String#hex` quirks and are left to Ruby.
pub fn parse_hex_rgb(hex: &[u8]) -> Option<[u8; 3]> {
    let digits = hex.strip_prefix(b"#").unwrap_or(hex);
    if digits.len() != 6 {
        return None;
    }

    let mut rgb = [0u8; 3];
    for (i, channel) in rgb.iter_mut().enumerate() {
        *channel = (hex_digit(digits[2 * i])? << 4) | hex_digit(digits[2 * i + 1])?;
    }
    Some(rgb)
}

fn hex_digit(byte: u8) -> Option<u8> {
    match byte {
        b'0'..=b'9' => Some(byte - b'0'),
        b'a'..=b'f' => Some(byte - b'a' + 10),
        b'A'..=b'F' => Some(byte - b'A' + 10),
        _ => None,
    }
}

/// Scales each channel by `amount`, rounding half away from zero like Ruby's
/// `Float#round`. Returns `None` when a channel is negative, non-finite, or too large.
fn scale_channel(channel: u8, amount: f64) -> Option<u64> {
    let rounded = (f64::from(channel) * amount).round();
    // NaN and infinities fall outside the range; `-0.0` is inside it, matching Ruby
    // where `(-0.4).round == 0`.
    if (0.0..=MAX_CHANNEL).contains(&rounded) {
        Some(rounded as u64)
    } else {
        None
    }
}

/// Equivalent of `Color::CompareHex#brightness(amount, only_values:)` for a strict
/// 6-digit hex color. Returns `"#rrggbb"` (lowercase, zero-padded) or `"r, g, b"`
/// when `only_values` is set, and `None` when the input is outside the natively
/// supported domain.
pub fn brightness(hex: &[u8], amount: f64, only_values: bool) -> Option<String> {
    let [r, g, b] = parse_hex_rgb(hex)?;
    let r = scale_channel(r, amount)?;
    let g = scale_channel(g, amount)?;
    let b = scale_channel(b, amount)?;

    Some(if only_values {
        format!("{r}, {g}, {b}")
    } else {
        format!("#{r:02x}{g:02x}{b:02x}")
    })
}

/// Equivalent of `Color::CompareHex#accent` for a strict 6-digit hex color.
/// Returns the first brightness variant with seven characters, or the last variant
/// when none has that length. Unsupported channels return `None` for Ruby's edge path.
pub fn accent(hex: &[u8], amount: f64) -> Option<String> {
    let mut last = None;
    for modifier in ACCENT_MODIFIERS {
        let result = brightness(hex, modifier.powf(amount), false)?;
        let found = result.len() == 7;
        last = Some(result);
        if found {
            break;
        }
    }
    last
}

/// Largest alpha magnitude formatted natively; keeps `alpha * 100` far inside the
/// range where every integer is an exact `f64` and the half-ulp error stays tiny.
const MAX_ALPHA: f64 = 1e9;

/// Equivalent of `Color::CompareHex#opacity(alpha)` for a strict 6-digit hex color:
/// `"rgba(r, g, b, a)"` with `a` formatted like Ruby's `%.2f`.
///
/// Only alphas whose shortest decimal form has at most two fractional digits
/// (`0.1`, `0.5`, `1`, `-0.0`, ...) are handled natively, so no rounding is ever
/// needed and the output is exactly those digits. Anything else returns `None` and
/// stays with Ruby's `sprintf`, whose float rounding differs from correctly rounded
/// formatting (Ruby prints `2.675` as `"2.68"`, Rust as `"2.67"`).
pub fn opacity(hex: &[u8], alpha: f64) -> Option<String> {
    let [r, g, b] = parse_hex_rgb(hex)?;
    // NaN fails this range check too.
    if !(0.0..MAX_ALPHA).contains(&alpha.abs()) {
        return None;
    }

    let hundredths = (alpha * 100.0).round();
    // `hundredths` is an exact integer, so this holds exactly when `alpha` is the
    // double nearest to `hundredths / 100`, i.e. it round-trips with two decimals.
    if hundredths / 100.0 != alpha {
        return None;
    }

    let hundredths = hundredths.abs() as u64;
    // `is_sign_negative` keeps Ruby's `"-0.00"` for `-0.0`.
    let sign = if alpha.is_sign_negative() { "-" } else { "" };
    Some(format!(
        "rgba({r}, {g}, {b}, {sign}{}.{:02})",
        hundredths / 100,
        hundredths % 100
    ))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn rgba(input: &str, alpha: f64) -> Option<String> {
        opacity(input.as_bytes(), alpha)
    }

    #[test]
    fn matches_existing_compare_hex_opacity_spec() {
        assert_eq!(
            rgba("#123456", 0.5),
            Some("rgba(18, 52, 86, 0.50)".to_string())
        );
        assert_eq!(
            rgba("#3B49DF", 0.1),
            Some("rgba(59, 73, 223, 0.10)".to_string())
        );
        assert_eq!(
            rgba("ffffff", 0.0),
            Some("rgba(255, 255, 255, 0.00)".to_string())
        );
    }

    #[test]
    fn formats_two_decimal_alphas_like_ruby_sprintf() {
        for (alpha, expected) in [
            (0.29, "0.29"),
            (0.07, "0.07"),
            (1.0, "1.00"),
            (12.34, "12.34"),
            (-0.1, "-0.10"),
            (-0.0, "-0.00"),
            (-2.5, "-2.50"),
            (123_456_789.99, "123456789.99"),
        ] {
            assert_eq!(
                rgba("#000000", alpha),
                Some(format!("rgba(0, 0, 0, {expected})")),
                "{alpha}"
            );
        }
    }

    #[test]
    fn defers_alphas_that_need_rounding_or_are_out_of_range() {
        for alpha in [
            0.125,
            2.675,
            0.015,
            1.0 / 3.0,
            0.001,
            -0.004,
            f64::MIN_POSITIVE,
            1e9,
            -1e9,
            1e300,
            f64::NAN,
            f64::INFINITY,
            f64::NEG_INFINITY,
        ] {
            assert_eq!(rgba("#123456", alpha), None, "{alpha}");
        }
    }

    #[test]
    fn defers_malformed_hexes_for_opacity() {
        for input in ["", "#fff", "#12345g", "#123456\n", "#🚀1234", "#1234567"] {
            assert_eq!(rgba(input, 0.1), None, "{input:?}");
        }
    }

    fn hex(input: &str, amount: f64) -> Option<String> {
        brightness(input.as_bytes(), amount, false)
    }

    fn values(input: &str, amount: f64) -> Option<String> {
        brightness(input.as_bytes(), amount, true)
    }

    #[test]
    fn parses_strict_hex_colors() {
        assert_eq!(parse_hex_rgb(b"#123456"), Some([0x12, 0x34, 0x56]));
        assert_eq!(parse_hex_rgb(b"abcdef"), Some([0xab, 0xcd, 0xef]));
        assert_eq!(parse_hex_rgb(b"#ABCdef"), Some([0xab, 0xcd, 0xef]));
    }

    #[test]
    fn rejects_inputs_ruby_handles_with_quirks() {
        for input in [
            "",
            "#",
            "#12345",
            "#1234567",
            "##12345",
            "12345",
            "#12 456",
            "#-12345",
            "#0x1234",
            "#12345g",
            "#123456\n",
            "\n#123456",
            "#1_2345",
            "#12345é",
            "#🚀1234",
            "#ffffff ",
        ] {
            assert_eq!(parse_hex_rgb(input.as_bytes()), None, "{input:?}");
            assert_eq!(hex(input, 1.0), None, "{input:?}");
        }
    }

    #[test]
    fn matches_existing_compare_hex_spec() {
        assert_eq!(hex("#ccddee", 0.5), Some("#666f77".to_string()));
        assert_eq!(hex("#ccddee", 1.14), Some("#e9fc10f".to_string()));
        assert_eq!(hex("#ccddee", 1.06), Some("#d8eafc".to_string()));
    }

    #[test]
    fn formats_rgb_values() {
        assert_eq!(values("#123456", 1.0), Some("18, 52, 86".to_string()));
        assert_eq!(values("#3b49df", 1.35), Some("80, 99, 301".to_string()));
        assert_eq!(values("#3b49df", 0.8), Some("47, 58, 178".to_string()));
    }

    #[test]
    fn rounds_half_away_from_zero() {
        // 0x01 * 0.5 == 0.5 -> 1 (Ruby `0.5.round == 1`), 0x03 * 0.5 == 1.5 -> 2
        assert_eq!(values("010303", 0.5), Some("1, 2, 2".to_string()));
        assert_eq!(values("050505", 0.5), Some("3, 3, 3".to_string()));
    }

    #[test]
    fn handles_zero_and_negative_zero() {
        assert_eq!(hex("#ffffff", 0.0), Some("#000000".to_string()));
        assert_eq!(hex("#000000", -1.0), Some("#000000".to_string()));
        assert_eq!(hex("#010101", -0.4), Some("#000000".to_string()));
    }

    #[test]
    fn finds_first_seven_character_accent_variant() {
        assert_eq!(accent(b"#ccddee", 1.0), Some("#d8eafc".to_string()));
        assert_eq!(accent(b"#000000", 1.0), Some("#000000".to_string()));
    }

    #[test]
    fn defers_malformed_and_out_of_domain_accent_inputs() {
        assert_eq!(accent(b"#ccddee\n", 1.0), None);
        assert_eq!(accent(b"#ffffff", f64::INFINITY), None);
        assert_eq!(accent(b"#010101", 1_000.0), None);
    }

    #[test]
    fn defers_negative_non_finite_and_huge_channels() {
        assert_eq!(hex("#010101", -0.6), None);
        assert_eq!(hex("#ffffff", f64::NAN), None);
        assert_eq!(hex("#ffffff", f64::INFINITY), None);
        assert_eq!(hex("#000000", f64::INFINITY), None); // 0 * inf == NaN
        assert_eq!(hex("#ffffff", 1e300), None);
    }

    #[test]
    fn formats_wide_channels_without_truncation() {
        assert_eq!(hex("#ff0001", 4096.0), Some("#ff000001000".to_string()));
        assert_eq!(
            values("#ff0001", 4096.0),
            Some("1044480, 0, 4096".to_string())
        );
    }
}
