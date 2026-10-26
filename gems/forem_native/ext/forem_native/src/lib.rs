use std::borrow::Cow;

use magnus::{function, prelude::*, Error, Integer, RString, Ruby, Value};

fn split_word_count(text: RString) -> usize {
    // SAFETY: `text.as_slice()` borrows the Ruby String's underlying byte buffer in-place
    // without copying or allocating. `forem_core::markdown::split_word_count_bytes` is a
    // pure Rust function that does not interact with the Ruby VM or trigger GC, and the
    // slice borrow ends before returning.
    let bytes = unsafe { text.as_slice() };
    forem_core::markdown::split_word_count_bytes(bytes)
}

fn calculate_reading_time(text: RString) -> usize {
    // SAFETY: Same zero-copy `RString` slice borrow; `forem_core` never calls into Ruby.
    let bytes = unsafe { text.as_slice() };
    forem_core::markdown::calculate_reading_time_bytes(bytes)
}

fn color_brightness(hex: RString, amount: f64, only_values: bool) -> Option<String> {
    // SAFETY: Same zero-copy `RString` slice borrow; `forem_core` never calls into Ruby.
    // Returns `nil` for inputs outside the strict `#rrggbb` domain so Ruby can fall back.
    let bytes = unsafe { hex.as_slice() };
    forem_core::color::brightness(bytes, amount, only_values)
}

fn color_opacity(hex: RString, alpha: f64) -> Option<String> {
    // SAFETY: Same zero-copy `RString` slice borrow; `forem_core` never calls into Ruby.
    // Returns `nil` for malformed hexes and alphas needing rounding so Ruby can fall back.
    let bytes = unsafe { hex.as_slice() };
    forem_core::color::opacity(bytes, alpha)
}

fn convert_deeply_nested_links_to_html(ruby: &Ruby, content: RString) -> Option<RString> {
    // SAFETY: Same zero-copy `RString` slice borrow; `forem_core` never calls into Ruby,
    // and the borrow ends before we allocate any Ruby objects.
    // Returns `nil` for invalid UTF-8 so Ruby raises its usual `ArgumentError`.
    let converted = {
        let text = std::str::from_utf8(unsafe { content.as_slice() }).ok()?;
        match forem_core::markdown::convert_deeply_nested_links_to_html(text) {
            Cow::Borrowed(_) => None,
            Cow::Owned(converted) => Some(converted),
        }
    };
    // Like `gsub` without matches, hand back a cheap copy-on-write copy of the input.
    Some(converted.map_or_else(|| RString::new_shared(content), |s| ruby.str_new(&s)))
}

fn escape_liquid_tags_in_codeblock(ruby: &Ruby, content: RString) -> Option<RString> {
    // SAFETY: Same zero-copy `RString` slice borrow; `forem_core` never calls into Ruby,
    // and the borrow ends before we allocate any Ruby objects.
    // Returns `nil` for invalid UTF-8 so Ruby raises its usual `ArgumentError`.
    let escaped = {
        let text = std::str::from_utf8(unsafe { content.as_slice() }).ok()?;
        match forem_core::markdown::escape_liquid_tags_in_codeblock(text) {
            Cow::Borrowed(_) => None,
            Cow::Owned(escaped) => Some(escaped),
        }
    };
    Some(escaped.map_or_else(|| RString::new_shared(content), |s| ruby.str_new(&s)))
}

fn convert_escaped_pipes_outside_codeblocks(ruby: &Ruby, content: RString) -> Option<RString> {
    // SAFETY: Same zero-copy `RString` slice borrow; `forem_core` never calls into Ruby,
    // and the borrow ends before we allocate any Ruby objects.
    // Returns `nil` for invalid UTF-8 so Ruby raises its usual `ArgumentError`.
    let converted = {
        let text = std::str::from_utf8(unsafe { content.as_slice() }).ok()?;
        match forem_core::markdown::convert_escaped_pipes_outside_codeblocks(text) {
            Cow::Borrowed(_) => None,
            Cow::Owned(converted) => Some(converted),
        }
    };
    Some(converted.map_or_else(|| RString::new_shared(content), |s| ruby.str_new(&s)))
}

fn fixer_add_quotes_to_section(
    ruby: &Ruby,
    markdown: RString,
    section: RString,
) -> Option<RString> {
    // SAFETY: Same zero-copy `RString` slice borrows; `forem_core` never calls into Ruby,
    // and the borrows end before we allocate any Ruby objects.
    // Returns `nil` for invalid UTF-8 and non-word sections so Ruby keeps its semantics.
    let quoted = {
        let text = std::str::from_utf8(unsafe { markdown.as_slice() }).ok()?;
        let section = std::str::from_utf8(unsafe { section.as_slice() }).ok()?;
        match forem_core::fixer::add_quotes_to_section(text, section)? {
            Cow::Borrowed(_) => None,
            Cow::Owned(quoted) => Some(quoted),
        }
    };
    // Like `sub` without changes, hand back a cheap copy-on-write copy of the input.
    Some(quoted.map_or_else(|| RString::new_shared(markdown), |s| ruby.str_new(&s)))
}

fn fixer_split_tags(ruby: &Ruby, markdown: RString) -> Option<RString> {
    // SAFETY: Same zero-copy `RString` slice borrow; `forem_core` never calls into Ruby,
    // and the borrow ends before we allocate any Ruby objects.
    // Returns `nil` for invalid UTF-8 so Ruby raises its usual `ArgumentError`.
    let split = {
        let text = std::str::from_utf8(unsafe { markdown.as_slice() }).ok()?;
        match forem_core::fixer::split_tags(text) {
            Cow::Borrowed(_) => None,
            Cow::Owned(split) => Some(split),
        }
    };
    Some(split.map_or_else(|| RString::new_shared(markdown), |s| ruby.str_new(&s)))
}

fn fixer_lowercase_published(ruby: &Ruby, markdown: RString) -> Option<RString> {
    // SAFETY: Same zero-copy `RString` slice borrow; `forem_core` never calls into Ruby,
    // and the borrow ends before we allocate any Ruby objects.
    // Returns `nil` for invalid UTF-8 so Ruby raises its usual `ArgumentError`.
    let lowercased = {
        let text = std::str::from_utf8(unsafe { markdown.as_slice() }).ok()?;
        match forem_core::fixer::lowercase_published(text) {
            Cow::Borrowed(_) => None,
            Cow::Owned(lowercased) => Some(lowercased),
        }
    };
    Some(lowercased.map_or_else(|| RString::new_shared(markdown), |s| ruby.str_new(&s)))
}

fn fixer_underscores_in_usernames(ruby: &Ruby, markdown: RString) -> Option<RString> {
    // SAFETY: Same zero-copy `RString` slice borrow; `forem_core` never calls into Ruby,
    // and the borrow ends before we allocate any Ruby objects.
    // Returns `nil` for invalid UTF-8 so Ruby raises its usual `ArgumentError`.
    let escaped = {
        let text = std::str::from_utf8(unsafe { markdown.as_slice() }).ok()?;
        match forem_core::fixer::underscores_in_usernames(text) {
            Cow::Borrowed(_) => None,
            Cow::Owned(escaped) => Some(escaped),
        }
    };
    // Like the legacy `match?` early return, hand back the input itself when nothing changes.
    Some(escaped.map_or(markdown, |s| ruby.str_new(&s)))
}

fn convert_code_tags_to_triple_backticks(ruby: &Ruby, content: RString) -> Option<RString> {
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before we allocate any Ruby objects. `test_as_str` reuses Ruby's cached
    // coderange instead of re-validating the whole body, and returns `None` for invalid
    // UTF-8 so Ruby raises its usual `ArgumentError`.
    let converted = {
        let text = unsafe { content.test_as_str() }?;
        match forem_core::markdown::convert_code_tags_to_triple_backticks(text) {
            Cow::Borrowed(_) => None,
            Cow::Owned(converted) => Some(converted),
        }
    };
    // Like the legacy early returns, hand back the input itself when nothing changes.
    Some(converted.map_or(content, |s| ruby.str_new(&s)))
}

fn markdown_xss_attempt(content: RString) -> Option<bool> {
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before returning. `test_as_str` reuses Ruby's cached coderange and returns
    // `None` for invalid UTF-8 so Ruby raises its usual `ArgumentError`.
    let text = unsafe { content.test_as_str() }?;
    Some(forem_core::markdown::contains_xss_attempt(text))
}

fn strip_default_image_alt_text(ruby: &Ruby, content: RString) -> Option<RString> {
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before we allocate any Ruby objects. `test_as_str` reuses Ruby's cached
    // coderange and returns `None` for invalid UTF-8 so Ruby raises its usual `ArgumentError`.
    let stripped = {
        let text = unsafe { content.test_as_str() }?;
        match forem_core::markdown::strip_default_image_alt_text(text) {
            Cow::Borrowed(_) => None,
            Cow::Owned(stripped) => Some(stripped),
        }
    };
    // Like `gsub` without matches, hand back a cheap copy-on-write copy of the input.
    Some(stripped.map_or_else(|| RString::new_shared(content), |s| ruby.str_new(&s)))
}

/// Converts an `Addressable::Template` value the way `Images::Optimizer.cloudflare` sees it:
/// `nil` expands like `""` and Integers like `to_s`. Strings must be UTF-8 (or US-ASCII) and
/// valid; everything else returns `None` so Ruby keeps Addressable's semantics.
fn template_value(value: Value) -> Option<String> {
    if value.is_nil() {
        return Some(String::new());
    }
    if let Some(integer) = Integer::from_value(value) {
        return integer.to_i64().ok().map(|integer| integer.to_string());
    }
    let string = RString::from_value(value)?;
    if !string.is_utf8_compatible_encoding() {
        return None;
    }
    // SAFETY: Same zero-copy `RString` borrow, copied out before returning. `test_as_str`
    // reuses Ruby's cached coderange and returns `None` for invalid UTF-8.
    unsafe { string.test_as_str() }.map(str::to_owned)
}

fn cloudflare_image_url(
    domain: Value,
    directory: Value,
    width: Value,
    height: Value,
    fit: Value,
    img_src: Value,
    src: Value,
) -> Option<String> {
    forem_core::image::cloudflare_image_url(
        &template_value(domain)?,
        &template_value(directory)?,
        &template_value(width)?,
        &template_value(height)?,
        &template_value(fit)?,
        &template_value(img_src)?,
        &template_value(src)?,
    )
}

fn normalize_url(url: RString) -> Option<String> {
    if !url.is_utf8_compatible_encoding() {
        return None;
    }
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before the result is converted. `test_as_str` returns `None` for invalid
    // UTF-8, which `forem_core` would decline anyway (it only accepts printable ASCII).
    forem_core::url::normalize_url(unsafe { url.test_as_str() }?)
}

fn join_url(base: RString, reference: RString) -> Option<String> {
    if !base.is_utf8_compatible_encoding() || !reference.is_utf8_compatible_encoding() {
        return None;
    }
    // SAFETY: Same zero-copy `RString` borrows; `forem_core` never calls into Ruby, and the
    // borrows end before the result is converted. Invalid UTF-8 returns `None`.
    unsafe { forem_core::url::join_url(base.test_as_str()?, reference.test_as_str()?) }
}

fn host_without_www(url: RString) -> Option<String> {
    if !url.is_utf8_compatible_encoding() {
        return None;
    }
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before the result is converted. Invalid UTF-8 returns `None`.
    forem_core::url::host_without_www(unsafe { url.test_as_str() }?)
}

fn quickie_title_html(title: RString, truncate_for_feed: bool) -> Option<String> {
    // Binary (and other non-UTF-8) titles count URL lengths in bytes, so leave them to Ruby.
    if !title.is_utf8_compatible_encoding() {
        return None;
    }
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before returning. `test_as_str` reuses Ruby's cached coderange and returns
    // `None` for invalid UTF-8 so `Article` can use its legacy `gsub` pipeline.
    let text = unsafe { title.test_as_str() }?;
    Some(forem_core::title::quickie_title_html(
        text,
        truncate_for_feed,
    ))
}

fn content_includes_title(content: RString, title: RString) -> Option<bool> {
    // SAFETY: Same zero-copy `RString` borrows; `forem_core` never calls into Ruby, and the
    // borrows end before returning. `test_as_str` reuses Ruby's cached coderange and returns
    // `None` for invalid UTF-8 so Ruby raises its usual `ArgumentError`.
    let content = unsafe { content.test_as_str() }?;
    let title = unsafe { title.test_as_str() }?;
    Some(forem_core::text::content_includes_title(content, title))
}

/// Hosts arrive as binary (Puma headers) or UTF-8 (query params); both are ASCII-compatible,
/// which is all the hostname byte checks rely on.
fn is_ascii_compatible_host(ruby: &Ruby, s: RString) -> bool {
    s.is_utf8_compatible_encoding() || s.enc_get() == ruby.ascii8bit_encindex()
}

fn subforem_request_domain(ruby: &Ruby, raw: RString) -> Option<RString> {
    if !is_ascii_compatible_host(ruby, raw) {
        return None;
    }
    // SAFETY: Same zero-copy `RString` slice borrow; `forem_core` never calls into Ruby, and
    // the borrow ends before we allocate any Ruby objects.
    let bytes = unsafe { raw.as_slice() };
    let len = forem_core::url::subforem_request_domain_len(bytes)?;
    if len == bytes.len() {
        // Without a port the domain is the host itself, so skip the copy.
        return Some(raw);
    }
    let domain = bytes[..len].to_vec();
    Some(ruby.enc_str_new(domain, raw.enc_get()))
}

fn subforem_subdomain_host(ruby: &Ruby, host: RString, sld: RString, tld: RString) -> Option<bool> {
    if ![host, sld, tld]
        .into_iter()
        .all(|s| is_ascii_compatible_host(ruby, s))
    {
        return None;
    }
    // SAFETY: Same zero-copy `RString` slice borrows; `forem_core` never calls into Ruby, and
    // the borrows end before returning.
    unsafe {
        forem_core::url::subforem_subdomain_host(host.as_slice(), sld.as_slice(), tld.as_slice())
    }
}

fn public_suffix_domain(ruby: &Ruby, host: RString) -> Value {
    if !is_ascii_compatible_host(ruby, host) {
        return ruby.qnil().as_value();
    }
    // SAFETY: Same zero-copy `RString` slice borrow; `forem_core` never calls into Ruby, and
    // the borrow ends before we allocate any Ruby objects.
    let domain = {
        let bytes = unsafe { host.as_slice() };
        match forem_core::url::public_suffix_domain(bytes) {
            None => return ruby.qnil().as_value(),
            Some(Err(())) => return ruby.qfalse().as_value(),
            Some(Ok(domain)) => {
                if domain.as_bytes() == bytes {
                    None
                } else {
                    Some(domain.into_owned().into_bytes())
                }
            }
        }
    };
    match domain {
        None => host.as_value(),
        Some(bytes) => ruby.enc_str_new(bytes, host.enc_get()).as_value(),
    }
}

fn public_suffix_subdomain_host(ruby: &Ruby, host: RString) -> Value {
    if !is_ascii_compatible_host(ruby, host) {
        return ruby.qnil().as_value();
    }
    // SAFETY: Same zero-copy `RString` slice borrow; `forem_core` never calls into Ruby, and
    // the borrow ends before we touch the Ruby VM.
    let outcome = forem_core::url::public_suffix_subdomain_host(unsafe { host.as_slice() });
    match outcome {
        None => ruby.qnil().as_value(),
        Some(forem_core::url::SubforemSubdomain::InvalidDomain) => {
            ruby.to_symbol("invalid").as_value()
        }
        Some(forem_core::url::SubforemSubdomain::Subdomain(true)) => ruby.qtrue().as_value(),
        Some(forem_core::url::SubforemSubdomain::Subdomain(false)) => ruby.qfalse().as_value(),
    }
}

fn original_host_valid(ruby: &Ruby, host: RString) -> Option<bool> {
    if !is_ascii_compatible_host(ruby, host) {
        return None;
    }
    // SAFETY: Same zero-copy `RString` slice borrow; `forem_core` never calls into Ruby, and
    // the borrow ends before returning.
    forem_core::url::original_host_valid(unsafe { host.as_slice() })
}

fn inline_svg_icon(
    svg: RString,
    class: RString,
    width: RString,
    height: RString,
    aria_hidden: Option<RString>,
    title: Option<RString>,
    title_id: Option<RString>,
) -> Option<String> {
    let strings = [
        Some(svg),
        Some(class),
        Some(width),
        Some(height),
        aria_hidden,
        title,
        title_id,
    ];
    if !strings
        .iter()
        .flatten()
        .all(|s| s.is_utf8_compatible_encoding())
    {
        return None;
    }
    // SAFETY: Same zero-copy `RString` borrows; `forem_core` never calls into Ruby, and the
    // borrows end before the result is converted. Invalid UTF-8 returns `None`.
    unsafe {
        let title = match (title.as_ref(), title_id.as_ref()) {
            (Some(text), Some(id)) => Some((text.test_as_str()?, id.test_as_str()?)),
            (None, None) => None,
            _ => return None,
        };
        let options = forem_core::svg::IconOptions {
            class: class.test_as_str()?,
            width: width.test_as_str()?,
            height: height.test_as_str()?,
            aria_hidden: match aria_hidden.as_ref() {
                Some(value) => Some(value.test_as_str()?),
                None => None,
            },
            title,
        };
        forem_core::svg::inline_svg_icon(svg.test_as_str()?, &options)
    }
}

#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    let forem_native = ruby.define_module("ForemNative")?;
    let native_mod = forem_native.define_module("Native")?;
    native_mod.define_singleton_method("split_word_count", function!(split_word_count, 1))?;
    native_mod.define_singleton_method(
        "calculate_reading_time",
        function!(calculate_reading_time, 1),
    )?;
    native_mod.define_singleton_method("color_brightness", function!(color_brightness, 3))?;
    native_mod.define_singleton_method("color_opacity", function!(color_opacity, 2))?;
    native_mod.define_singleton_method(
        "convert_deeply_nested_links_to_html",
        function!(convert_deeply_nested_links_to_html, 1),
    )?;
    native_mod.define_singleton_method(
        "escape_liquid_tags_in_codeblock",
        function!(escape_liquid_tags_in_codeblock, 1),
    )?;
    native_mod.define_singleton_method(
        "convert_escaped_pipes_outside_codeblocks",
        function!(convert_escaped_pipes_outside_codeblocks, 1),
    )?;
    native_mod.define_singleton_method(
        "fixer_add_quotes_to_section",
        function!(fixer_add_quotes_to_section, 2),
    )?;
    native_mod.define_singleton_method("fixer_split_tags", function!(fixer_split_tags, 1))?;
    native_mod.define_singleton_method(
        "fixer_lowercase_published",
        function!(fixer_lowercase_published, 1),
    )?;
    native_mod.define_singleton_method(
        "fixer_underscores_in_usernames",
        function!(fixer_underscores_in_usernames, 1),
    )?;
    native_mod.define_singleton_method(
        "convert_code_tags_to_triple_backticks",
        function!(convert_code_tags_to_triple_backticks, 1),
    )?;
    native_mod
        .define_singleton_method("markdown_xss_attempt", function!(markdown_xss_attempt, 1))?;
    native_mod.define_singleton_method(
        "strip_default_image_alt_text",
        function!(strip_default_image_alt_text, 1),
    )?;
    native_mod
        .define_singleton_method("cloudflare_image_url", function!(cloudflare_image_url, 7))?;
    native_mod.define_singleton_method("normalize_url", function!(normalize_url, 1))?;
    native_mod.define_singleton_method("join_url", function!(join_url, 2))?;
    native_mod.define_singleton_method("quickie_title_html", function!(quickie_title_html, 2))?;
    native_mod.define_singleton_method("host_without_www", function!(host_without_www, 1))?;
    native_mod.define_singleton_method(
        "content_includes_title",
        function!(content_includes_title, 2),
    )?;
    native_mod.define_singleton_method(
        "subforem_request_domain",
        function!(subforem_request_domain, 1),
    )?;
    native_mod.define_singleton_method(
        "subforem_subdomain_host",
        function!(subforem_subdomain_host, 3),
    )?;
    native_mod
        .define_singleton_method("public_suffix_domain", function!(public_suffix_domain, 1))?;
    native_mod.define_singleton_method(
        "public_suffix_subdomain_host",
        function!(public_suffix_subdomain_host, 1),
    )?;
    native_mod.define_singleton_method("original_host_valid", function!(original_host_valid, 1))?;
    native_mod.define_singleton_method("inline_svg_icon", function!(inline_svg_icon, 7))?;
    Ok(())
}
