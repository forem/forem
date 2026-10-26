//! Inline SVG icons for `CrayonsHelper#crayons_icon_tag`. `inline_svg_tag` re-parses the SVG with
//! Nokogiri once per transformation, but only changes the root `<svg>` tag and prepends a
//! `<title>`, so given the icon's serialization (computed once in Ruby) this is string splicing.

/// The per-call `crayons_icon_tag` options, already converted to strings.
pub struct IconOptions<'a> {
    pub class: &'a str,
    pub width: &'a str,
    pub height: &'a str,
    pub aria_hidden: Option<&'a str>,
    /// The title text and the `aria-labelledby` id `InlineSvg::IdGenerator` made for it.
    pub title: Option<(&'a str, &'a str)>,
}

/// Renders `svg` (an icon's Nokogiri HTML serialization) with `inline_svg_tag`'s
/// `aria: true, class:, width:, height:` (plus optional `title:` and `aria_hidden:`)
/// transformations applied.
///
/// Returns `None` when the result needs Nokogiri: icons that already have a `<title>` or
/// `<desc>` (which get ids of their own), root tags this parser does not expect, an existing
/// class holding an entity, and option values holding a `"` or characters libxml2 rewrites
/// (control characters and U+FFFE/U+FFFF).
pub fn inline_svg_icon(svg: &str, options: &IconOptions) -> Option<String> {
    if svg.contains("<title") || svg.contains("<desc") {
        return None;
    }
    let (mut attributes, rest) = parse_root_start_tag(svg)?;

    let mut values = vec![options.class, options.width, options.height];
    values.extend(options.aria_hidden);
    if let Some((text, id)) = options.title {
        if !is_plain_text(text) || !is_plain_attribute(id) {
            return None;
        }
        values.push(id);
    }
    if !values.into_iter().all(is_plain_attribute) {
        return None;
    }

    set_attribute(&mut attributes, "role", "img".to_owned());
    if let Some((_, id)) = options.title {
        set_attribute(&mut attributes, "aria-labelledby", escape(id));
    }
    if let Some(aria_hidden) = options.aria_hidden {
        set_attribute(&mut attributes, "aria-hidden", escape(aria_hidden));
    }
    // `(svg["class"] || "").split(" ") << value` joined with spaces.
    let class = match attributes.iter().find(|(name, _)| *name == "class") {
        Some((_, existing)) if existing.contains('&') => return None,
        Some((_, existing)) => existing
            .split(|c: char| c == ' ' || ('\t'..='\r').contains(&c))
            .filter(|token| !token.is_empty())
            .chain([&*escape(options.class)])
            .collect::<Vec<_>>()
            .join(" "),
        None => escape(options.class),
    };
    set_attribute(&mut attributes, "class", class);
    set_attribute(&mut attributes, "width", escape(options.width));
    set_attribute(&mut attributes, "height", escape(options.height));

    let mut html = String::with_capacity(svg.len() + 128);
    html.push_str("<svg");
    for (name, value) in &attributes {
        html.push(' ');
        html.push_str(name);
        html.push_str("=\"");
        html.push_str(value);
        html.push('"');
    }
    html.push('>');
    if let Some((text, id)) = options.title {
        html.push_str("<title id=\"");
        html.push_str(id);
        html.push_str("\">");
        html.push_str(&escape(text));
        html.push_str("</title>");
    }
    html.push_str(rest);
    Some(html)
}

type Attributes<'a> = Vec<(&'a str, String)>;

/// Splits `<svg a="1" b="2">rest` into its attributes (values still escaped) and `rest`,
/// accepting only the double-quoted, single-space-separated form libxml2 serializes.
fn parse_root_start_tag(svg: &str) -> Option<(Attributes<'_>, &str)> {
    let mut tail = svg.strip_prefix("<svg")?;
    let mut attributes = Vec::new();
    loop {
        if let Some(rest) = tail.strip_prefix('>') {
            return Some((attributes, rest));
        }
        tail = tail.strip_prefix(' ')?;
        let name_end = tail.find(['=', ' ', '>', '"', '\'', '/'])?;
        let (name, after_name) = tail.split_at(name_end);
        let after_quote = after_name.strip_prefix("=\"")?;
        if name.is_empty() {
            return None;
        }
        let value_end = after_quote.find('"')?;
        if after_quote[..value_end].contains(['<', '>']) {
            return None;
        }
        attributes.push((name, after_quote[..value_end].to_owned()));
        tail = &after_quote[value_end + 1..];
    }
}

/// Nokogiri's `svg[name] = value`: replaces the value in place or appends the attribute.
fn set_attribute<'a>(attributes: &mut Attributes<'a>, name: &'a str, value: String) {
    match attributes
        .iter_mut()
        .find(|(existing, _)| *existing == name)
    {
        Some((_, existing)) => *existing = value,
        None => attributes.push((name, value)),
    }
}

/// Text libxml2 serializes as-is apart from `&`, `<`, and `>`: no control characters (it drops
/// or rewrites them) and no U+FFFE/U+FFFF (not XML characters).
fn is_plain_text(text: &str) -> bool {
    !text.contains(|c: char| c < ' ' || c == '\u{FFFE}' || c == '\u{FFFF}')
}

/// As `is_plain_text`, and without a `"` (libxml2 single-quotes such attribute values).
fn is_plain_attribute(value: &str) -> bool {
    is_plain_text(value) && !value.contains('"')
}

fn escape(text: &str) -> String {
    if !text.contains(['&', '<', '>']) {
        return text.to_owned();
    }
    let mut escaped = String::with_capacity(text.len() + 16);
    for c in text.chars() {
        match c {
            '&' => escaped.push_str("&amp;"),
            '<' => escaped.push_str("&lt;"),
            '>' => escaped.push_str("&gt;"),
            _ => escaped.push(c),
        }
    }
    escaped
}

#[cfg(test)]
mod tests {
    use super::*;

    const MEDAL: &str = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\">\n    <path d=\"M12 8z\"></path>\n</svg>\n";
    const FLAG: &str = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 36 36\"><path fill=\"#66757F\"></path></svg>\n";

    fn options<'a>(class: &'a str) -> IconOptions<'a> {
        IconOptions {
            class,
            width: "24",
            height: "24",
            aria_hidden: None,
            title: None,
        }
    }

    #[test]
    fn replaces_existing_attributes_in_place() {
        assert_eq!(
            inline_svg_icon(MEDAL, &options("crayons-icon")).as_deref(),
            Some("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\" role=\"img\" class=\"crayons-icon\">\n    <path d=\"M12 8z\"></path>\n</svg>\n")
        );
    }

    #[test]
    fn appends_missing_escaped_attributes_in_transformation_order() {
        let opts = IconOptions {
            aria_hidden: Some("true"),
            width: "1<2",
            ..options("crayons-icon a & b")
        };
        assert_eq!(
            inline_svg_icon(FLAG, &opts).as_deref(),
            Some("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 36 36\" role=\"img\" aria-hidden=\"true\" class=\"crayons-icon a &amp; b\" width=\"1&lt;2\" height=\"24\"><path fill=\"#66757F\"></path></svg>\n")
        );
    }

    #[test]
    fn prepends_an_escaped_title() {
        let opts = IconOptions {
            title: Some(("Tom & \"Jerry\" <3 😀", "abc123")),
            ..options("crayons-icon")
        };
        assert_eq!(
            inline_svg_icon(FLAG, &opts).as_deref(),
            Some("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 36 36\" role=\"img\" aria-labelledby=\"abc123\" class=\"crayons-icon\" width=\"24\" height=\"24\"><title id=\"abc123\">Tom &amp; \"Jerry\" &lt;3 😀</title><path fill=\"#66757F\"></path></svg>\n")
        );
    }

    #[test]
    fn appends_to_an_existing_class() {
        let svg = "<svg class=\" a\tb  c \" viewBox=\"0 0 1 1\"></svg>\n";
        assert_eq!(
            inline_svg_icon(svg, &options("x&y")).as_deref(),
            Some("<svg class=\"a b c x&amp;y\" viewBox=\"0 0 1 1\" role=\"img\" width=\"24\" height=\"24\"></svg>\n")
        );
        let entity = "<svg class=\"a&amp;b\"></svg>\n";
        assert_eq!(inline_svg_icon(entity, &options("x")), None);
        assert_eq!(
            inline_svg_icon("<svg></svg>\n", &options("")).as_deref(),
            Some("<svg role=\"img\" class=\"\" width=\"24\" height=\"24\"></svg>\n")
        );
    }

    #[test]
    fn declines_values_libxml2_rewrites() {
        for bad in [
            "a\"b", "a\nb", "a\tb", "a\rb", "\u{1}", "\u{FFFE}", "\u{FFFF}",
        ] {
            assert_eq!(inline_svg_icon(FLAG, &options(bad)), None, "{bad:?}");
            let titled = IconOptions {
                title: Some((bad, "id")),
                ..options("c")
            };
            let expected = bad == "a\"b";
            assert_eq!(
                inline_svg_icon(FLAG, &titled).is_some(),
                expected,
                "{bad:?}"
            );
        }
    }

    #[test]
    fn declines_icons_with_titles_descriptions_or_unexpected_markup() {
        for svg in [
            "<svg><title>t</title></svg>\n",
            "<svg><desc>d</desc></svg>\n",
            "<?xml version=\"1.0\"?><svg></svg>\n",
            "<svg width='1'></svg>\n",
            "<svg  width=\"1\"></svg>\n",
            "<svg disabled></svg>\n",
            "<svg =\"1\"></svg>\n",
            "<svg width=\"1\"",
            "<svgx></svgx>\n",
            "",
        ] {
            assert_eq!(inline_svg_icon(svg, &options("c")), None, "{svg:?}");
        }
    }
}
