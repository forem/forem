use std::borrow::Cow;
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::{SystemTime, UNIX_EPOCH};

use magnus::{
    function,
    prelude::*,
    r_hash::ForEach,
    value::{Qfalse, Qtrue},
    Error, Float, Integer, RArray, RHash, RString, RStruct, Ruby, Symbol, Value,
};

static RNG_COUNTER: AtomicU64 = AtomicU64::new(1);

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

fn color_accent(hex: RString, amount: f64) -> Option<String> {
    // SAFETY: Same zero-copy `RString` slice borrow; `forem_core` never calls into Ruby.
    // Returns `nil` for malformed hexes or unsupported channel values so Ruby can fall back.
    let bytes = unsafe { hex.as_slice() };
    forem_core::color::accent(bytes, amount)
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

fn fixer_convert_new_lines(ruby: &Ruby, markdown: RString) -> Option<RString> {
    // SAFETY: The borrowed bytes are inspected only by pure forem_core code, and the borrow
    // ends before any Ruby object is allocated. Invalid UTF-8 is left to the Ruby caller.
    let converted = {
        let text = unsafe { markdown.test_as_str() }?;
        match forem_core::fixer::convert_new_lines(text) {
            Cow::Borrowed(_) => None,
            Cow::Owned(converted) => Some(converted),
        }
    };
    Some(converted.map_or_else(|| RString::new_shared(markdown), |s| ruby.str_new(&s)))
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

fn fixer_fix_all(ruby: &Ruby, markdown: RString) -> Option<RString> {
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before we allocate any Ruby objects. `test_as_str` reuses Ruby's cached
    // coderange and returns `None` for invalid UTF-8 so `FixAll.call` falls back to Ruby.
    let fixed = {
        let text = unsafe { markdown.test_as_str() }?;
        match forem_core::fixer::fix_all(text) {
            Cow::Borrowed(_) => None,
            Cow::Owned(fixed) => Some(fixed),
        }
    };
    Some(fixed.map_or_else(|| RString::new_shared(markdown), |s| ruby.str_new(&s)))
}

fn fixer_fix_for_preview(ruby: &Ruby, markdown: RString) -> Option<RString> {
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before we allocate any Ruby objects.
    let fixed = {
        let text = unsafe { markdown.test_as_str() }?;
        match forem_core::fixer::fix_for_preview(text) {
            Cow::Borrowed(_) => None,
            Cow::Owned(fixed) => Some(fixed),
        }
    };
    Some(fixed.map_or_else(|| RString::new_shared(markdown), |s| ruby.str_new(&s)))
}

fn fixer_fix_for_comment(ruby: &Ruby, markdown: RString) -> Option<RString> {
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before we allocate any Ruby objects.
    let fixed = {
        let text = unsafe { markdown.test_as_str() }?;
        match forem_core::fixer::fix_for_comment(text) {
            Cow::Borrowed(_) => None,
            Cow::Owned(fixed) => Some(fixed),
        }
    };
    Some(fixed.map_or(markdown, |s| ruby.str_new(&s)))
}

fn preprocess_markdown_for_finalize(ruby: &Ruby, content: RString) -> Value {
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before we touch the Ruby VM or allocate Ruby objects.
    let outcome = {
        let Some(text) = (unsafe { content.test_as_str() }) else {
            return ruby.qnil().as_value();
        };
        match forem_core::markdown::preprocess_for_finalize(text) {
            forem_core::markdown::FinalizePreprocessOutcome::XssAttempt => Err(()),
            forem_core::markdown::FinalizePreprocessOutcome::Ready(Cow::Borrowed(_)) => Ok(None),
            forem_core::markdown::FinalizePreprocessOutcome::Ready(Cow::Owned(s)) => Ok(Some(s)),
        }
    };
    match outcome {
        Err(()) => ruby.to_symbol("xss_attempt").as_value(),
        Ok(None) => RString::new_shared(content).as_value(),
        Ok(Some(s)) => ruby.str_new(&s).as_value(),
    }
}

fn contains_unlabeled_code_blocks(markdown: RString) -> Option<bool> {
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby.
    let text = unsafe { markdown.test_as_str() }?;
    Some(forem_core::markdown::contains_unlabeled_code_blocks(text))
}

fn extract_unlabeled_code_blocks(ruby: &Ruby, markdown: RString) -> Option<RArray> {
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and all
    // slices are copied into owned Rust Strings before allocating the Ruby Array.
    let blocks: Vec<String> = {
        let text = unsafe { markdown.test_as_str() }?;
        forem_core::markdown::extract_unlabeled_code_blocks(text)
            .into_iter()
            .map(str::to_owned)
            .collect()
    };
    let ary = ruby.ary_new_capa(blocks.len());
    for block in blocks {
        ary.push(ruby.str_new(&block)).ok()?;
    }
    Some(ary)
}

fn apply_code_block_languages(
    ruby: &Ruby,
    markdown: RString,
    languages: RArray,
) -> Option<RString> {
    // SAFETY: Borrow `languages` and `markdown` in-place without calling into the Ruby VM.
    let lang_vec: Vec<String> = {
        let slice = unsafe { languages.as_slice() };
        let mut out = Vec::with_capacity(slice.len());
        for &val in slice {
            let rstr = RString::from_value(val)?;
            if !rstr.is_utf8_compatible_encoding() {
                return None;
            }
            out.push(unsafe { rstr.test_as_str() }?.to_owned());
        }
        out
    };
    let updated = {
        let text = unsafe { markdown.test_as_str() }?;
        match forem_core::markdown::apply_code_block_languages(text, &lang_vec) {
            Cow::Borrowed(_) => None,
            Cow::Owned(updated) => Some(updated),
        }
    };
    Some(updated.map_or_else(|| RString::new_shared(markdown), |s| ruby.str_new(&s)))
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

fn title_for_metadata(ruby: &Ruby, title: RString) -> Option<RString> {
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before we allocate any Ruby objects. `test_as_str` reuses Ruby's cached
    // coderange and returns `None` for invalid UTF-8 so `Article#title_for_metadata` can
    // fall back to `legacy_title_for_metadata`.
    let normalized = {
        let text = unsafe { title.test_as_str() }?;
        match forem_core::title::title_for_metadata(text) {
            Cow::Borrowed(slice) if slice.len() == text.len() => None,
            Cow::Borrowed(slice) => Some(slice.to_owned()),
            Cow::Owned(owned) => Some(owned),
        }
    };
    Some(normalized.map_or_else(|| RString::new_shared(title), |s| ruby.str_new(&s)))
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

fn full_sanitize(html: RString) -> Option<String> {
    if !html.is_utf8_compatible_encoding() {
        return None;
    }
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before returning. `test_as_str` reuses Ruby's cached coderange and returns
    // `None` for invalid UTF-8 so callers can fall back to `ActionView::Base.full_sanitizer`.
    forem_core::sanitize::full_sanitize(unsafe { html.test_as_str() }?)
}

fn slugify_heading_anchor(heading_html: RString) -> Option<String> {
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before returning. `test_as_str` reuses Ruby's cached coderange and returns
    // `None` for invalid UTF-8 so `HeadingAnchors.slugify` can fall back to `legacy_slugify`.
    let text = unsafe { heading_html.test_as_str() }?;
    forem_core::text::slugify_heading_anchor(text)
}

fn beautified_url(ruby: &Ruby, url: RString) -> Option<RString> {
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before we allocate any Ruby objects. `test_as_str` reuses Ruby's cached
    // coderange and returns `None` for invalid UTF-8 so `ApplicationHelper#beautified_url`
    // can fall back to `legacy_beautified_url`.
    let beautified = {
        let text = unsafe { url.test_as_str() }?;
        match forem_core::text::beautified_url(text) {
            Cow::Borrowed(slice) if slice.len() == text.len() => None,
            Cow::Borrowed(slice) => Some(slice.to_owned()),
            Cow::Owned(owned) => Some(owned),
        }
    };
    Some(beautified.map_or_else(|| RString::new_shared(url), |s| ruby.str_new(&s)))
}

fn parse_emojis(ruby: &Ruby, html: RString) -> Option<RString> {
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before we allocate any Ruby objects. `test_as_str` reuses Ruby's cached
    // coderange and returns `None` for invalid UTF-8 so `Html::Parser` keeps Ruby's semantics.
    let parsed = {
        let text = unsafe { html.test_as_str() }?;
        match forem_core::emoji::parse_emojis(text) {
            Cow::Borrowed(_) => None,
            Cow::Owned(parsed) => Some(parsed),
        }
    };
    Some(parsed.map_or(html, |s| ruby.str_new(&s)))
}

fn escape_colon_emojis_in_codeblock(ruby: &Ruby, html: RString) -> Option<RString> {
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before we allocate any Ruby objects. Returns `None` for invalid UTF-8 or
    // HTML fragments needing Nokogiri normalization so `Html::Parser` falls back to Nokogiri.
    let escaped = {
        let text = unsafe { html.test_as_str() }?;
        match forem_core::emoji::escape_colon_emojis_in_codeblock(text)? {
            Cow::Borrowed(_) => None,
            Cow::Owned(escaped) => Some(escaped),
        }
    };
    Some(escaped.map_or_else(|| RString::new_shared(html), |s| ruby.str_new(&s)))
}

fn emoji_by_alias(alias_name: RString) -> Option<&'static str> {
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // returned `&'static str` lives in `.rodata`.
    let text = unsafe { alias_name.test_as_str() }?;
    forem_core::emoji::lookup_emoji(text)
}

fn strip_rgi_emoji(ruby: &Ruby, text: RString) -> Option<RString> {
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before we allocate any Ruby objects.
    let stripped = {
        let s = unsafe { text.test_as_str() }?;
        match forem_core::emoji::strip_rgi_emoji(s) {
            Cow::Borrowed(_) => None,
            Cow::Owned(stripped) => Some(stripped),
        }
    };
    Some(stripped.map_or(text, |s| ruby.str_new(&s)))
}

fn wcag_contrast_ratio(rgb1: RString, rgb2: RString) -> Option<f64> {
    // SAFETY: Same zero-copy `RString` slice borrows; `forem_core` never calls into Ruby.
    let bytes1 = unsafe { rgb1.as_slice() };
    let bytes2 = unsafe { rgb2.as_slice() };
    forem_core::color::wcag_contrast_ratio(bytes1, bytes2)
}

#[derive(Clone, Copy)]
enum TimestampEntryOutcome {
    Parsed(forem_core::feed::ParsedTimestamp),
    Skip,
    DeferToRuby,
}

fn classify_timestamp_value(value: Value) -> TimestampEntryOutcome {
    if value.is_nil() {
        return TimestampEntryOutcome::Skip;
    }
    if let Some(rstr) = RString::from_value(value) {
        if !rstr.is_utf8_compatible_encoding() {
            return TimestampEntryOutcome::DeferToRuby;
        }
        // SAFETY: `rstr.as_slice()` borrows the Ruby String's byte buffer in-place.
        // `forem_core::feed::parse_timestamp` is pure Rust and never touches the Ruby VM.
        let bytes = unsafe { rstr.as_slice() };
        if let Some(ts) = forem_core::feed::parse_timestamp(bytes) {
            return TimestampEntryOutcome::Parsed(ts);
        }
        // If there are no ASCII digits (e.g. `"not-a-timestamp"`, `"invalid"`, `""`),
        // `String#to_datetime` is guaranteed to raise `Date::Error`, which callers rescue as nil.
        if !bytes.iter().any(|b| b.is_ascii_digit()) {
            return TimestampEntryOutcome::Skip;
        }
        return TimestampEntryOutcome::DeferToRuby;
    }
    if value.respond_to("tv_sec", false).unwrap_or(false) {
        let Ok(tv_sec) = value.funcall::<_, _, i64>("tv_sec", ()) else {
            return TimestampEntryOutcome::DeferToRuby;
        };
        let tv_nsec: u32 = value.funcall("tv_nsec", ()).unwrap_or(0);
        let utc_offset: i64 = value.funcall("utc_offset", ()).unwrap_or(0);
        return TimestampEntryOutcome::Parsed(
            forem_core::feed::ParsedTimestamp::from_epoch_and_offset(tv_sec, tv_nsec, utc_offset),
        );
    }
    if value.respond_to("to_time", false).unwrap_or(false) {
        let Ok(time_val) = value.funcall::<_, _, Value>("to_time", ()) else {
            return TimestampEntryOutcome::DeferToRuby;
        };
        if time_val.respond_to("tv_sec", false).unwrap_or(false) {
            let Ok(tv_sec) = time_val.funcall::<_, _, i64>("tv_sec", ()) else {
                return TimestampEntryOutcome::DeferToRuby;
            };
            let tv_nsec: u32 = time_val.funcall("tv_nsec", ()).unwrap_or(0);
            let utc_offset: i64 = time_val.funcall("utc_offset", ()).unwrap_or(0);
            return TimestampEntryOutcome::Parsed(
                forem_core::feed::ParsedTimestamp::from_epoch_and_offset(
                    tv_sec, tv_nsec, utc_offset,
                ),
            );
        }
    }
    TimestampEntryOutcome::DeferToRuby
}

fn extract_activity_timestamps(entries: RArray) -> Option<Vec<forem_core::feed::ParsedTimestamp>> {
    // Copy the top-level Value handles so we never hold an `as_slice()` reference across a
    // fallback `funcall` when an RSpec double stores in-memory `TimeWithZone` objects.
    let items: Vec<Value> = unsafe { entries.as_slice() }.to_vec();
    let mut parsed = Vec::with_capacity(items.len());
    for entry in items {
        let Some(tuple) = RArray::from_value(entry) else {
            // Non-Array entries in `recently_viewed_articles` are ignored by `active_user?`.
            continue;
        };
        let ts_val = {
            let slice = unsafe { tuple.as_slice() };
            let Some(&val) = slice.get(1) else {
                continue;
            };
            val
        };
        match classify_timestamp_value(ts_val) {
            TimestampEntryOutcome::Parsed(ts) => parsed.push(ts),
            TimestampEntryOutcome::Skip => continue,
            TimestampEntryOutcome::DeferToRuby => return None,
        }
    }
    Some(parsed)
}

fn activity_distinct_days_since(
    entries: RArray,
    cutoff_sec: i64,
    cutoff_nanos: u32,
) -> Option<usize> {
    let parsed = extract_activity_timestamps(entries)?;
    Some(forem_core::feed::count_distinct_activity_days(
        &parsed,
        cutoff_sec,
        cutoff_nanos,
    ))
}

fn activity_pageviews_since(entries: RArray, cutoff_sec: i64, cutoff_nanos: u32) -> Option<usize> {
    let parsed = extract_activity_timestamps(entries)?;
    Some(forem_core::feed::count_pageviews_since(
        &parsed,
        cutoff_sec,
        cutoff_nanos,
    ))
}

fn dynamic_shuffle_count(
    most_recent: Value,
    now_sec: i64,
    now_nanos: u32,
    shuffle_weight: f64,
) -> Option<usize> {
    match classify_timestamp_value(most_recent) {
        TimestampEntryOutcome::Parsed(ts) => {
            Some(forem_core::feed::calculate_dynamic_shuffle_count(
                ts,
                now_sec,
                now_nanos,
                shuffle_weight,
            ))
        }
        TimestampEntryOutcome::Skip => Some(5),
        TimestampEntryOutcome::DeferToRuby => None,
    }
}

#[inline]
fn extract_f64_value(value: Value) -> Option<f64> {
    if let Some(fl) = Float::from_value(value) {
        return Some(fl.to_f64());
    }
    if let Some(int) = Integer::from_value(value) {
        return int.to_i64().ok().map(|v| v as f64);
    }
    None
}

fn weighted_shuffle(
    ruby: &Ruby,
    items: RArray,
    shuffle_weight: f64,
    randoms: Option<RArray>,
) -> Option<RArray> {
    let len = items.len();
    if len <= 1 || shuffle_weight <= 0.0 || !shuffle_weight.is_finite() {
        return Some(items);
    }

    let rand_vec: Vec<f64> = if let Some(r_arr) = randoms {
        let slice = unsafe { r_arr.as_slice() };
        if slice.len() < len {
            return None;
        }
        let mut v = Vec::with_capacity(len);
        for &val in &slice[..len] {
            v.push(extract_f64_value(val)?);
        }
        v
    } else {
        let nanos = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|d| d.as_nanos() as u64)
            .unwrap_or(0x5DEECE66D);
        let seq = RNG_COUNTER.fetch_add(0x9E37_79B9_7F4A_7C15, Ordering::Relaxed);
        forem_core::feed::xorshift64_star_unit_floats(nanos ^ seq, len)
    };

    let indices = forem_core::feed::weighted_shuffle_indices(len, shuffle_weight, &rand_vec)?;
    let source_items: Vec<Value> = unsafe { items.as_slice() }.to_vec();
    let out = ruby.ary_new_capa(len);
    for idx in indices {
        out.push(source_items[idx]).ok()?;
    }
    Some(out)
}

fn format_video_duration(seconds: i64) -> Option<String> {
    forem_core::feed::format_video_duration(seconds)
}

fn append_compact_blank_ids(arr: RArray, cap: usize, out: &mut Vec<i64>) -> Option<()> {
    // SAFETY: `arr.as_slice()` borrows the Ruby Array buffer in-place and we only inspect
    // immediate Integers, nil/false, or RString byte slices without calling into Ruby.
    let slice = unsafe { arr.as_slice() };
    let limit = if cap == 0 {
        slice.len()
    } else {
        cap.min(slice.len())
    };
    for &val in &slice[..limit] {
        if !val.to_bool() {
            continue;
        }
        if let Some(int) = Integer::from_value(val) {
            out.push(int.to_i64().ok()?);
            continue;
        }
        if let Some(rstr) = RString::from_value(val) {
            if !rstr.is_utf8_compatible_encoding() {
                return None;
            }
            let bytes = unsafe { rstr.as_slice() };
            if bytes.iter().all(|b| b.is_ascii_whitespace()) {
                continue;
            }
            let text = std::str::from_utf8(bytes).ok()?.trim();
            let parsed = text.parse::<i64>().ok()?;
            out.push(parsed);
            continue;
        }
        return None;
    }
    Some(())
}

fn extract_string_vec(arr: RArray, max_items: usize) -> Option<Vec<String>> {
    // SAFETY: `arr.as_slice()` borrows the Ruby Array buffer in-place and copies UTF-8 strings
    // out before returning.
    let slice = unsafe { arr.as_slice() };
    let limit = if max_items == 0 {
        slice.len()
    } else {
        max_items.min(slice.len())
    };
    let mut out = Vec::with_capacity(limit);
    for &val in &slice[..limit] {
        let rstr = RString::from_value(val)?;
        if !rstr.is_utf8_compatible_encoding() {
            return None;
        }
        let s = unsafe { rstr.test_as_str() }?;
        if s.contains('\0') {
            return None;
        }
        out.push(s.to_owned());
    }
    Some(out)
}

fn sql_int_list(ids: RArray, empty_fallback: RString) -> Option<String> {
    if !empty_fallback.is_utf8_compatible_encoding() {
        return None;
    }
    let mut int_ids = Vec::with_capacity(ids.len());
    append_compact_blank_ids(ids, 0, &mut int_ids)?;
    let fallback = unsafe { empty_fallback.test_as_str() }?;
    Some(forem_core::feed::sql_int_list(&int_ids, fallback))
}

fn sql_string_array_literal(items: RArray, pg_type: RString) -> Option<String> {
    if !pg_type.is_utf8_compatible_encoding() {
        return None;
    }
    let strings = extract_string_vec(items, 0)?;
    let pg_type_str = unsafe { pg_type.test_as_str() }?;
    Some(forem_core::feed::sql_string_array_literal(
        &strings,
        pg_type_str,
    ))
}

fn sql_vector_literal(values: RArray) -> Option<String> {
    let slice = unsafe { values.as_slice() };
    let mut floats = Vec::with_capacity(slice.len());
    for &val in slice {
        floats.push(extract_f64_value(val)?);
    }
    forem_core::feed::sql_vector_literal(&floats)
}

fn sql_squish(sql: RString) -> Option<String> {
    if !sql.is_utf8_compatible_encoding() {
        return None;
    }
    let text = unsafe { sql.test_as_str() }?;
    Some(forem_core::feed::sql_squish(text))
}

fn feed_config_score_sql(weights_arr: RArray, ctx_arr: RArray) -> Option<String> {
    let w = {
        let ws = unsafe { weights_arr.as_slice() };
        if ws.len() < 29 {
            return None;
        }
        forem_core::feed::FeedScoreWeights {
            feed_success_weight: extract_f64_value(ws[0])?,
            comment_score_weight: extract_f64_value(ws[1])?,
            score_weight: extract_f64_value(ws[2])?,
            organization_follow_weight: extract_f64_value(ws[3])?,
            user_follow_weight: extract_f64_value(ws[4])?,
            follow_status_weight: extract_f64_value(ws[5])?,
            tag_follow_weight: extract_f64_value(ws[6])?,
            subforem_follow_weight: extract_f64_value(ws[7])?,
            label_match_weight: extract_f64_value(ws[8])?,
            recency_weight: extract_f64_value(ws[9])?,
            comment_recency_weight: extract_f64_value(ws[10])?,
            lookback_window_weight: extract_f64_value(ws[11])?,
            precomputed_selections_weight: extract_f64_value(ws[12])?,
            recent_article_suppression_rate: extract_f64_value(ws[13])?,
            published_today_weight: extract_f64_value(ws[14])?,
            general_past_day_bonus_weight: extract_f64_value(ws[15])?,
            recently_active_past_day_bonus_weight: extract_f64_value(ws[16])?,
            recent_subforem_weight: extract_f64_value(ws[17])?,
            semantic_similarity_weight: extract_f64_value(ws[18])?,
            ai_disclosure_matching_weight: extract_f64_value(ws[19])?,
            autonomous_ai_penalty_weight: extract_f64_value(ws[20])?,
            featured_weight: extract_f64_value(ws[21])?,
            favorited_weight: extract_f64_value(ws[22])?,
            status_weight: extract_f64_value(ws[23])?,
            clickbait_score_weight: extract_f64_value(ws[24])?,
            compellingness_score_weight: extract_f64_value(ws[25])?,
            language_match_weight: extract_f64_value(ws[26])?,
            randomness_weight: extract_f64_value(ws[27])?,
            published_at_diversity_weight: extract_f64_value(ws[28])?,
        }
    };

    let cs: Vec<Value> = unsafe { ctx_arr.as_slice() }.to_vec();
    if cs.len() < 25 {
        return None;
    }

    let has_activity_store = cs[0].to_bool();
    let optimized_tags_query = cs[10].to_bool();
    let optimized_tags_limit = Integer::from_value(cs[11])?.to_usize().ok()?;
    let is_root_subforem = cs[12].to_bool();
    let ai_pref_code = Integer::from_value(cs[17])?.to_i64().ok()?;
    let random_seed = Integer::from_value(cs[19])?.to_u32().ok()?;
    let cutoff_24h_sec = Integer::from_value(cs[20])?.to_i64().ok()?;
    let cutoff_24h_nanos = Integer::from_value(cs[21])?.to_u32().ok()?;
    let default_second_pageview_sec = Integer::from_value(cs[22])?.to_i64().ok()?;
    let cutoff_30d_sec = Integer::from_value(cs[23])?.to_i64().ok()?;
    let published_at_diversity_half_lookback_hours = extract_f64_value(cs[24])?;

    // Analyze `recently_viewed_articles` in a single pass across all three consumers:
    // 1. `recent_pageviews_count` (for `recently_active_past_day_bonus_weight`)
    // 2. `second_latest_pageview_utc_sec` (for `lookback_window_weight`)
    // 3. `recent_article_ids` (for `recent_article_suppression_rate`)
    let mut recent_pageviews_count = 0_usize;
    let mut second_latest_pageview_utc_sec = default_second_pageview_sec;
    let mut recent_article_ids: Vec<i64> = Vec::new();

    let need_recent_views = w.recently_active_past_day_bonus_weight > 0.0
        || w.lookback_window_weight > 0.0
        || (w.recent_article_suppression_rate > 0.0 && has_activity_store);

    if need_recent_views && !cs[1].is_nil() {
        let views_arr = RArray::from_value(cs[1])?;
        let view_entries: Vec<Value> = unsafe { views_arr.as_slice() }.to_vec();
        if w.recent_article_suppression_rate > 0.0 && has_activity_store {
            recent_article_ids.reserve(view_entries.len());
        }

        for (idx, entry_val) in view_entries.into_iter().enumerate() {
            let tuple = RArray::from_value(entry_val)?;
            let (first_val, second_val) = {
                let slice = unsafe { tuple.as_slice() };
                (slice.first().copied(), slice.get(1).copied())
            };

            if w.recent_article_suppression_rate > 0.0 && has_activity_store {
                if let Some(id_val) = first_val {
                    if !id_val.is_nil() {
                        let int_id = Integer::from_value(id_val)?;
                        recent_article_ids.push(int_id.to_i64().ok()?);
                    }
                }
            }

            if w.recently_active_past_day_bonus_weight > 0.0
                || (w.lookback_window_weight > 0.0 && idx == 1)
            {
                let ts_val = second_val?;
                let parsed_ts = match classify_timestamp_value(ts_val) {
                    TimestampEntryOutcome::Parsed(ts) => ts,
                    _ => return None,
                };
                if w.recently_active_past_day_bonus_weight > 0.0
                    && parsed_ts.gt_instant(cutoff_24h_sec, cutoff_24h_nanos)
                {
                    recent_pageviews_count += 1;
                }
                if w.lookback_window_weight > 0.0 && idx == 1 {
                    second_latest_pageview_utc_sec = parsed_ts.utc_sec;
                }
            }
        }
    }

    let lookback_window_utc_sec = second_latest_pageview_utc_sec - 18 * 3600;

    let mut organization_follow_ids: Vec<i64> = Vec::new();
    if w.organization_follow_weight > 0.0 {
        let cap = Integer::from_value(cs[6])?.to_usize().ok()?;
        if !cs[5].is_nil() {
            append_compact_blank_ids(
                RArray::from_value(cs[5])?,
                cap,
                &mut organization_follow_ids,
            )?;
        }
        if !cs[7].is_nil() {
            append_compact_blank_ids(RArray::from_value(cs[7])?, 0, &mut organization_follow_ids)?;
        }
    }

    let mut user_follow_ids: Vec<i64> = Vec::new();
    if w.user_follow_weight > 0.0 || w.follow_status_weight > 0.0 {
        let cap = Integer::from_value(cs[3])?.to_usize().ok()?;
        if !cs[2].is_nil() {
            append_compact_blank_ids(RArray::from_value(cs[2])?, cap, &mut user_follow_ids)?;
        }
        if !cs[4].is_nil() {
            append_compact_blank_ids(RArray::from_value(cs[4])?, 0, &mut user_follow_ids)?;
        }
    }

    let mut subforem_follow_ids: Vec<i64> = Vec::new();
    if w.subforem_follow_weight > 0.0 && is_root_subforem && !cs[8].is_nil() {
        append_compact_blank_ids(RArray::from_value(cs[8])?, 0, &mut subforem_follow_ids)?;
    }

    let tag_names: Vec<String> = if w.tag_follow_weight > 0.0 && !cs[9].is_nil() {
        let max_tags = if optimized_tags_query {
            optimized_tags_limit
        } else {
            24
        };
        extract_string_vec(RArray::from_value(cs[9])?, max_tags)?
    } else {
        Vec::new()
    };

    let label_names: Vec<String> = if w.label_match_weight > 0.0 && !cs[13].is_nil() {
        extract_string_vec(RArray::from_value(cs[13])?, 0)?
    } else {
        Vec::new()
    };

    let mut precomputed_selection_ids: Vec<i64> = Vec::new();
    if w.precomputed_selections_weight > 0.0 && !cs[14].is_nil() {
        append_compact_blank_ids(
            RArray::from_value(cs[14])?,
            0,
            &mut precomputed_selection_ids,
        )?;
    }

    let mut recent_subforem_ids: Vec<i64> = Vec::new();
    if w.recent_subforem_weight > 0.0 && is_root_subforem && !cs[15].is_nil() {
        append_compact_blank_ids(RArray::from_value(cs[15])?, 0, &mut recent_subforem_ids)?;
    }

    let mut interest_embedding: Vec<f64> = Vec::new();
    if w.semantic_similarity_weight > 0.0 && !cs[16].is_nil() {
        let emb_arr = RArray::from_value(cs[16])?;
        let slice = unsafe { emb_arr.as_slice() };
        interest_embedding.reserve(slice.len());
        for &val in slice {
            interest_embedding.push(extract_f64_value(val)?);
        }
    }

    let languages: Vec<String> =
        if w.language_match_weight > 0.0 && w.score_weight > 0.0 && !cs[18].is_nil() {
            extract_string_vec(RArray::from_value(cs[18])?, 0)?
        } else {
            Vec::new()
        };

    let ai_preference = match ai_pref_code {
        1 => forem_core::feed::AiPreference::MinimizeAi,
        2 => forem_core::feed::AiPreference::HideFullyAutonomous,
        _ => forem_core::feed::AiPreference::ShowAll,
    };

    let ctx = forem_core::feed::FeedScoreContext {
        recent_pageviews_count,
        organization_follow_ids: &organization_follow_ids,
        user_follow_ids: &user_follow_ids,
        tag_names: &tag_names,
        optimized_tags_query,
        optimized_tags_limit,
        is_root_subforem,
        subforem_follow_ids: &subforem_follow_ids,
        label_names: &label_names,
        lookback_window_utc_sec,
        second_latest_pageview_utc_sec,
        precomputed_selection_ids: &precomputed_selection_ids,
        has_activity_store,
        recent_article_ids: &recent_article_ids,
        published_since_24h_utc_sec: cutoff_24h_sec,
        recent_subforem_ids: &recent_subforem_ids,
        interest_embedding: &interest_embedding,
        published_since_30d_utc_sec: cutoff_30d_sec,
        ai_preference,
        languages: &languages,
        random_seed,
        published_at_diversity_half_lookback_hours,
    };

    forem_core::feed::build_feed_config_score_sql(&w, &ctx)
}

fn extract_utf8_string_vec(arr: RArray) -> Option<Vec<String>> {
    let slice = unsafe { arr.as_slice() };
    let mut out = Vec::with_capacity(slice.len());
    for &val in slice {
        let rstr = RString::from_value(val)?;
        if !rstr.is_utf8_compatible_encoding() {
            return None;
        }
        out.push(unsafe { rstr.test_as_str() }?.to_owned());
    }
    Some(out)
}

fn extract_strict_i64_vec(arr: RArray) -> Option<Vec<i64>> {
    let slice = unsafe { arr.as_slice() };
    let mut out = Vec::with_capacity(slice.len());
    for &val in slice {
        out.push(Integer::from_value(val)?.to_i64().ok()?);
    }
    Some(out)
}

fn extract_f64_vec(arr: RArray) -> Option<Vec<f64>> {
    let slice = unsafe { arr.as_slice() };
    let mut out = Vec::with_capacity(slice.len());
    for &val in slice {
        out.push(extract_f64_value(val)?);
    }
    Some(out)
}

fn extract_optional_utf8_string(val: Value) -> Option<Option<String>> {
    if val.is_nil() {
        return Some(None);
    }
    let rstr = RString::from_value(val)?;
    rstr.is_utf8_compatible_encoding()
        .then(|| unsafe { rstr.test_as_str() }.map(str::to_owned))?
        .map(Some)
}

fn extract_optional_i64(val: Value) -> Option<Option<i64>> {
    if val.is_nil() {
        Some(None)
    } else {
        Some(Some(Integer::from_value(val)?.to_i64().ok()?))
    }
}

fn extract_experience_rating(val: Value) -> Option<(f64, bool, i64)> {
    if let Some(int) = Integer::from_value(val) {
        let i = int.to_i64().ok()?;
        return Some((i as f64, true, i));
    }
    Float::from_value(val).map(|fl| (fl.to_f64(), false, 0))
}

fn score_followed_tags(tags: RString, names: RArray, pts: RArray, w: f64, nf: f64) -> Option<f64> {
    if !tags.is_utf8_compatible_encoding() {
        return None;
    }
    let (n, p, s) = (
        extract_utf8_string_vec(names)?,
        extract_f64_vec(pts)?,
        unsafe { tags.test_as_str() }?,
    );
    forem_core::feed::score_followed_tags(s, &n, &p, w, nf)
}

fn score_experience_level(article_xp: Value, user_xp: Value, w: f64) -> Option<f64> {
    if let (Some(ai), Some(ui)) = (
        Integer::from_value(article_xp),
        Integer::from_value(user_xp),
    ) {
        return forem_core::feed::score_experience_level_int(
            ai.to_i64().ok()?,
            ui.to_i64().ok()?,
            w,
        );
    }
    forem_core::feed::score_experience_level(
        extract_f64_value(article_xp)?,
        extract_f64_value(user_xp)?,
        w,
    )
}

fn score_ai_disclosure(pref: Value, level: Value, some_p: f64, auto_p: f64) -> Option<f64> {
    let (p, l) = (
        extract_optional_utf8_string(pref)?,
        extract_optional_utf8_string(level)?,
    );
    forem_core::feed::score_ai_disclosure(p.as_deref(), l.as_deref(), some_p, auto_p)
}

struct OwnedUserArticleScoreContext {
    has_user: bool,
    following_user_ids: Vec<i64>,
    following_org_ids: Vec<i64>,
    followed_tag_names: Vec<String>,
    followed_tag_points: Vec<f64>,
    user_xp: (f64, bool, i64),
    ai_preference: Option<String>,
    weights: [f64; 11],
}

impl OwnedUserArticleScoreContext {
    fn from_rarray(user_ctx: RArray) -> Option<Self> {
        let cs = unsafe { user_ctx.as_slice() };
        if cs.len() < 18 {
            return None;
        }
        let mut weights = [0.0_f64; 11];
        for (idx, slot) in weights.iter_mut().enumerate() {
            *slot = extract_f64_value(cs[idx + 7])?;
        }
        let opt_i64 = |v: Value| {
            if v.is_nil() {
                Some(Vec::new())
            } else {
                extract_strict_i64_vec(RArray::from_value(v)?)
            }
        };
        Some(Self {
            has_user: cs[0].to_bool(),
            following_user_ids: opt_i64(cs[1])?,
            following_org_ids: opt_i64(cs[2])?,
            followed_tag_names: if cs[3].is_nil() {
                Vec::new()
            } else {
                extract_utf8_string_vec(RArray::from_value(cs[3])?)?
            },
            followed_tag_points: if cs[4].is_nil() {
                Vec::new()
            } else {
                extract_f64_vec(RArray::from_value(cs[4])?)?
            },
            user_xp: extract_experience_rating(cs[5])?,
            ai_preference: extract_optional_utf8_string(cs[6])?,
            weights,
        })
    }

    fn as_core(&self) -> forem_core::feed::UserArticleScoreContext<'_, String> {
        forem_core::feed::UserArticleScoreContext {
            has_user: self.has_user,
            following_user_ids: &self.following_user_ids,
            following_org_ids: &self.following_org_ids,
            followed_tag_names: &self.followed_tag_names,
            followed_tag_points: &self.followed_tag_points,
            user_xp: self.user_xp,
            ai_preference: self.ai_preference.as_deref(),
            weights: self.weights,
        }
    }
}

#[allow(clippy::too_many_arguments)]
fn score_article_for_user(
    user_ctx: RArray,
    user_id: Value,
    org_id: Value,
    tags_val: Value,
    xp_val: Value,
    comments_val: Value,
    ai_val: Value,
    base_pts: Value,
) -> Option<f64> {
    let owned_ctx = OwnedUserArticleScoreContext::from_rarray(user_ctx)?;
    let tags = extract_optional_utf8_string(tags_val)?.unwrap_or_default();
    let ai_level = extract_optional_utf8_string(ai_val)?;
    let article = forem_core::feed::ArticleScoreInput {
        user_id: extract_optional_i64(user_id)?,
        organization_id: extract_optional_i64(org_id)?,
        cached_tag_list: &tags,
        xp: extract_experience_rating(xp_val)?,
        comments_count: Integer::from_value(comments_val)?.to_i64().ok()?,
        ai_disclosure_level: ai_level.as_deref(),
        base_article_points: extract_f64_value(base_pts)?,
    };
    forem_core::feed::score_article_for_user(&owned_ctx.as_core(), &article)
}

fn rank_articles_for_basic_feed(
    ruby: &Ruby,
    articles: RArray,
    user_ctx: RArray,
    article_tuples: RArray,
) -> Option<RArray> {
    if articles.len() != article_tuples.len() {
        return None;
    }
    let owned_ctx = OwnedUserArticleScoreContext::from_rarray(user_ctx)?;
    let owned = {
        let slice = unsafe { article_tuples.as_slice() };
        let mut v = Vec::with_capacity(slice.len());
        for &val in slice {
            let tuple = RArray::from_value(val)?;
            let ts = unsafe { tuple.as_slice() };
            if ts.len() < 6 {
                return None;
            }
            v.push((
                extract_optional_i64(ts[0])?,
                extract_optional_i64(ts[1])?,
                extract_optional_utf8_string(ts[2])?.unwrap_or_default(),
                extract_optional_utf8_string(ts[5])?,
            ));
        }
        v
    };
    let core: Vec<forem_core::feed::ArticleScoreInput<'_>> = owned
        .iter()
        .map(|a| forem_core::feed::ArticleScoreInput {
            user_id: a.0,
            organization_id: a.1,
            cached_tag_list: &a.2,
            xp: (5.0, true, 5),
            comments_count: 0,
            ai_disclosure_level: a.3.as_deref(),
            base_article_points: 0.0,
        })
        .collect();
    let indices = forem_core::feed::rank_basic_feed_indices(&owned_ctx.as_core(), &core)?;
    let items: Vec<Value> = unsafe { articles.as_slice() }.to_vec();
    let out = ruby.ary_new_capa(items.len());
    for idx in indices {
        out.push(items[idx]).ok()?;
    }
    Some(out)
}

fn filter_tracked_article_ids(ruby: &Ruby, entries: RArray, min_sec: f64) -> Option<RArray> {
    let pairs: Vec<(i64, f64)> = {
        let slice = unsafe { entries.as_slice() };
        let mut out = Vec::with_capacity(slice.len());
        for &v in slice {
            let tuple = RArray::from_value(v)?;
            let ts = unsafe { tuple.as_slice() };
            if ts.len() < 2 {
                return None;
            }
            out.push((
                Integer::from_value(ts[0])?.to_i64().ok()?,
                extract_f64_value(if ts.len() >= 3 { ts[2] } else { ts[1] })?,
            ));
        }
        out
    };
    Some(
        ruby.ary_from_iter(forem_core::feed::filter_tracked_article_ids(
            &pairs, min_sec,
        )?),
    )
}

enum OwnedTagSource {
    CommaSeparated(String),
    PreSplit(Vec<String>),
}

fn aggregate_recent_activity_metadata(
    ruby: &Ruby,
    tag_lists: RArray,
    label_lists: RArray,
    org_ids: RArray,
    user_ids: RArray,
    subforem_ids: RArray,
    max_labels: usize,
) -> Option<RArray> {
    let owned_tags: Vec<OwnedTagSource> = {
        let slice = unsafe { tag_lists.as_slice() };
        let mut out = Vec::with_capacity(slice.len());
        for &val in slice {
            if val.is_nil() {
                out.push(OwnedTagSource::CommaSeparated(String::new()));
            } else if let Some(s) = extract_optional_utf8_string(val).flatten() {
                out.push(OwnedTagSource::CommaSeparated(s));
            } else {
                out.push(OwnedTagSource::PreSplit(extract_utf8_string_vec(
                    RArray::from_value(val)?,
                )?));
            }
        }
        out
    };
    let parsed_labels: Vec<Vec<String>> = {
        let slice = unsafe { label_lists.as_slice() };
        let mut out = Vec::with_capacity(slice.len());
        for &v in slice {
            out.push(if v.is_nil() {
                Vec::new()
            } else {
                extract_utf8_string_vec(RArray::from_value(v)?)?
            });
        }
        out
    };
    let opt_i64_vec = |arr: RArray| -> Option<Vec<Option<i64>>> {
        unsafe { arr.as_slice() }
            .iter()
            .map(|&v| extract_optional_i64(v))
            .collect()
    };
    let (orgs, users, subs) = (
        opt_i64_vec(org_ids)?,
        opt_i64_vec(user_ids)?,
        opt_i64_vec(subforem_ids)?,
    );
    let core_tags: Vec<forem_core::feed::ArticleTagSource<'_>> = owned_tags
        .iter()
        .map(|s| match s {
            OwnedTagSource::CommaSeparated(t) => {
                forem_core::feed::ArticleTagSource::CommaSeparated(t.as_str())
            }
            OwnedTagSource::PreSplit(l) => {
                forem_core::feed::ArticleTagSource::PreSplit(l.as_slice())
            }
        })
        .collect();
    let agg = forem_core::feed::aggregate_recent_activity_metadata(
        &core_tags,
        &parsed_labels,
        &orgs,
        &users,
        &subs,
        max_labels,
    );
    let out = ruby.ary_new_capa(5);
    out.push(ruby.ary_from_iter(agg.0)).ok()?;
    out.push(ruby.ary_from_iter(agg.1)).ok()?;
    out.push(ruby.ary_from_iter(agg.2)).ok()?;
    out.push(ruby.ary_from_iter(agg.3)).ok()?;
    out.push(ruby.ary_from_iter(agg.4)).ok()?;
    Some(out)
}

fn order_subforem_ids(ruby: &Ruby, r: RArray, f: RArray, d: RArray) -> Option<RArray> {
    let ordered = forem_core::feed::order_subforem_ids(
        &extract_strict_i64_vec(r)?,
        &extract_strict_i64_vec(f)?,
        &extract_strict_i64_vec(d)?,
    );
    Some(ruby.ary_from_iter(ordered))
}

fn parse_heatmap_date_key(key: Value) -> Option<i64> {
    if let Some(rstr) = RString::from_value(key) {
        return rstr
            .is_utf8_compatible_encoding()
            .then(|| forem_core::feed::parse_iso_date_days(unsafe { rstr.as_slice() }))?;
    }
    if key.respond_to("jd", false).unwrap_or(false)
        && !key.respond_to("hour", false).unwrap_or(true)
    {
        let jd: i64 = key.funcall("jd", ()).ok()?;
        return (jd >= 2_299_161).then_some(jd - 2_440_588);
    }
    None
}

fn extract_heatmap_counts(hash: RHash) -> Option<Vec<(i64, i64)>> {
    let mut raw: Vec<(Value, Value)> = Vec::with_capacity(hash.len());
    hash.foreach(|k: Value, v: Value| {
        raw.push((k, v));
        Ok(ForEach::Continue)
    })
    .ok()?;
    raw.into_iter()
        .map(|(k, v)| {
            Some((
                parse_heatmap_date_key(k)?,
                Integer::from_value(v)?.to_i64().ok()?,
            ))
        })
        .collect()
}

fn build_activity_heatmap_payload(
    ruby: &Ruby,
    start_iso: RString,
    end_iso: RString,
    articles_by_day: RHash,
    comments_by_day: RHash,
    reactions_by_day: RHash,
) -> Option<RHash> {
    if !start_iso.is_utf8_compatible_encoding() || !end_iso.is_utf8_compatible_encoding() {
        return None;
    }
    let start_days = forem_core::feed::parse_iso_date_days(unsafe { start_iso.as_slice() })?;
    let end_days = forem_core::feed::parse_iso_date_days(unsafe { end_iso.as_slice() })?;
    let (a, c, r) = (
        extract_heatmap_counts(articles_by_day)?,
        extract_heatmap_counts(comments_by_day)?,
        extract_heatmap_counts(reactions_by_day)?,
    );
    let p = forem_core::feed::build_activity_heatmap(start_days, end_days, &a, &c, &r)?;
    let (s_date, s_art, s_com, s_rea, s_tot) = (
        ruby.to_symbol("date"),
        ruby.to_symbol("articles"),
        ruby.to_symbol("comments"),
        ruby.to_symbol("reactions"),
        ruby.to_symbol("total"),
    );
    let days_ary = ruby.ary_new_capa(p.days.len());
    for (dt, da, dc, dr, dtot) in p.days {
        let h = ruby.hash_new_capa(5);
        h.aset(s_date, ruby.str_new(&dt)).ok()?;
        h.aset(s_art, da).ok()?;
        h.aset(s_com, dc).ok()?;
        h.aset(s_rea, dr).ok()?;
        h.aset(s_tot, dtot).ok()?;
        days_ary.push(h).ok()?;
    }
    let totals = ruby.hash_new_capa(4);
    for (sym, val) in [
        (s_art, p.totals[0]),
        (s_com, p.totals[1]),
        (s_rea, p.totals[2]),
        (s_tot, p.totals[3]),
    ] {
        totals.aset(sym, val).ok()?;
    }
    let root = ruby.hash_new_capa(5);
    root.aset(ruby.to_symbol("start_date"), ruby.str_new(&p.start_date))
        .ok()?;
    root.aset(ruby.to_symbol("end_date"), ruby.str_new(&p.end_date))
        .ok()?;
    root.aset(ruby.to_symbol("days"), days_ary).ok()?;
    root.aset(ruby.to_symbol("totals"), totals).ok()?;
    root.aset(ruby.to_symbol("max"), p.max).ok()?;
    Some(root)
}

fn link_heading_anchor_fragments(
    ruby: &Ruby,
    html: RString,
    ids_by_slug: RHash,
) -> Option<RString> {
    if !html.is_utf8_compatible_encoding() {
        return None;
    }
    if ids_by_slug.is_empty() {
        return Some(RString::new_shared(html));
    }
    let has_fragment_href = {
        let text = unsafe { html.test_as_str() }?;
        text.contains("href=\"#")
    };
    if !has_fragment_href {
        return Some(RString::new_shared(html));
    }

    let mut raw_pairs: Vec<(Value, Value)> = Vec::with_capacity(ids_by_slug.len());
    ids_by_slug
        .foreach(|k: Value, v: Value| {
            raw_pairs.push((k, v));
            Ok(ForEach::Continue)
        })
        .ok()?;

    let mut pairs: Vec<(String, String)> = Vec::with_capacity(raw_pairs.len());
    for (k, v) in raw_pairs {
        let ks = RString::from_value(k)?;
        let vs = RString::from_value(v)?;
        if !ks.is_utf8_compatible_encoding() || !vs.is_utf8_compatible_encoding() {
            return None;
        }
        let k_str = unsafe { ks.test_as_str() }?.to_owned();
        let v_str = unsafe { vs.test_as_str() }?.to_owned();
        pairs.push((k_str, v_str));
    }

    let linked = {
        let text = unsafe { html.test_as_str() }?;
        match forem_core::text::link_heading_anchor_fragments(text, &pairs)? {
            Cow::Borrowed(_) => None,
            Cow::Owned(s) => Some(s),
        }
    };
    Some(linked.map_or_else(|| RString::new_shared(html), |s| ruby.str_new(&s)))
}

fn scrub_sensitive_text(ruby: &Ruby, text: RString, tool_output: bool) -> Option<RString> {
    if !text.is_utf8_compatible_encoding() {
        return None;
    }
    let scrubbed = {
        let s = unsafe { text.test_as_str() }?;
        match forem_core::scrubber::scrub_sensitive_text(s, tool_output)? {
            Cow::Borrowed(_) => None,
            Cow::Owned(owned) => Some(owned),
        }
    };
    Some(scrubbed.map_or_else(|| RString::new_shared(text), |s| ruby.str_new(&s)))
}

fn scrub_sensitive_text_with_counts(
    ruby: &Ruby,
    text: RString,
    tool_output: bool,
) -> Option<RArray> {
    if !text.is_utf8_compatible_encoding() {
        return None;
    }
    let (scrubbed_opt, counts) = {
        let s = unsafe { text.test_as_str() }?;
        let (scrubbed, counts) =
            forem_core::scrubber::scrub_sensitive_text_with_counts(s, tool_output)?;
        let owned = match scrubbed {
            Cow::Borrowed(_) => None,
            Cow::Owned(o) => Some(o),
        };
        (owned, counts)
    };
    let r_str = scrubbed_opt.map_or_else(|| RString::new_shared(text), |s| ruby.str_new(&s));
    let r_counts = ruby.ary_new_capa(counts.len());
    for (name, count) in counts {
        let pair = ruby.ary_new_capa(2);
        pair.push(ruby.str_new(name)).ok()?;
        pair.push(count).ok()?;
        r_counts.push(pair).ok()?;
    }
    let out = ruby.ary_new_capa(2);
    out.push(r_str).ok()?;
    out.push(r_counts).ok()?;
    Some(out)
}

fn scrub_agent_session_messages(ruby: &Ruby, messages: RArray) -> Option<RArray> {
    let msg_vals: Vec<Value> = unsafe { messages.as_slice() }.to_vec();
    let k_content = ruby.str_new("content");
    let k_type = ruby.str_new("type");
    let k_text = ruby.str_new("text");
    let k_input = ruby.str_new("input");
    let k_output = ruby.str_new("output");

    let mut acc = forem_core::scrubber::RedactionAccumulator::new();
    let mut mutations: Vec<(RHash, RString, String)> = Vec::new();

    for msg_val in msg_vals {
        let msg_hash = RHash::from_value(msg_val)?;
        let Some(content_val) = msg_hash.lookup::<_, Option<Value>>(k_content).ok()? else {
            continue;
        };
        if !content_val.to_bool() {
            continue;
        }
        let content_ary = RArray::from_value(content_val)?;
        let block_vals: Vec<Value> = unsafe { content_ary.as_slice() }.to_vec();

        for block_val in block_vals {
            let block_hash = RHash::from_value(block_val)?;
            let type_val = block_hash.lookup::<_, Option<Value>>(k_type).ok()?;
            let is_tool_output = type_val
                .and_then(RString::from_value)
                .is_some_and(|rs| unsafe { rs.as_slice() } == b"tool_call");

            for (key_rstr, tool_out) in
                [(k_text, false), (k_input, is_tool_output), (k_output, true)]
            {
                let Some(field_val) = block_hash.lookup::<_, Option<Value>>(key_rstr).ok()? else {
                    continue;
                };
                if !field_val.to_bool() {
                    continue;
                }
                let field_rstr = RString::from_value(field_val)?;
                if !field_rstr.is_utf8_compatible_encoding() {
                    return None;
                }
                let scrubbed_opt = {
                    let s = unsafe { field_rstr.test_as_str() }?;
                    match forem_core::scrubber::scrub_sensitive_text_into_accumulator(
                        s, tool_out, &mut acc,
                    )? {
                        Cow::Borrowed(_) => None,
                        Cow::Owned(owned) => Some(owned),
                    }
                };
                if let Some(new_str) = scrubbed_opt {
                    mutations.push((block_hash, key_rstr, new_str));
                }
            }
        }
    }

    for (block_hash, key_rstr, new_str) in mutations {
        block_hash.aset(key_rstr, ruby.str_new(&new_str)).ok()?;
    }

    let counts = acc.into_counts();
    let result_ary = ruby.ary_new_capa(counts.len());
    for (name, count) in counts {
        let pair = ruby.ary_new_capa(2);
        pair.push(ruby.str_new(name)).ok()?;
        pair.push(count).ok()?;
        result_ary.push(pair).ok()?;
    }
    Some(result_ary)
}

fn add_control_class_to_codeblock(ruby: &Ruby, html: RString) -> Option<RString> {
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before we allocate any Ruby objects.
    let updated = {
        let text = unsafe { html.test_as_str() }?;
        match forem_core::html::add_control_class_to_codeblock(text)? {
            Cow::Borrowed(_) => None,
            Cow::Owned(updated) => Some(updated),
        }
    };
    Some(updated.map_or_else(|| RString::new_shared(html), |s| ruby.str_new(&s)))
}

fn add_control_panel_to_codeblock(ruby: &Ruby, html: RString) -> Option<RString> {
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before we allocate any Ruby objects.
    let updated = {
        let text = unsafe { html.test_as_str() }?;
        match forem_core::html::add_control_panel_to_codeblock(text)? {
            Cow::Borrowed(_) => None,
            Cow::Owned(updated) => Some(updated),
        }
    };
    Some(updated.map_or_else(|| RString::new_shared(html), |s| ruby.str_new(&s)))
}

/// Wraps untagged `<pre><code>` blocks in `<pre class="highlight"><code>`, returning `None`
/// when `html` is not valid UTF-8 or contains an unclosed code block.
fn wrap_untagged_codeblocks(ruby: &Ruby, html: RString) -> Option<RString> {
    // SAFETY: Only pure Rust inspects the borrowed string, and the borrow ends
    // before any Ruby allocation. Incomplete code blocks defer to the caller.
    let updated = {
        let text = unsafe { html.test_as_str() }?;
        match forem_core::transcript::wrap_untagged_codeblocks(text)? {
            Cow::Borrowed(_) => None,
            Cow::Owned(updated) => Some(updated),
        }
    };
    Some(updated.map_or_else(|| RString::new_shared(html), |s| ruby.str_new(&s)))
}

/// Replaces literal `[REDACTED]` markers with `<span class="agent-session-redacted">[REDACTED]</span>`.
fn style_redaction_markers(ruby: &Ruby, html: RString) -> Option<RString> {
    // SAFETY: The borrow is confined to pure Rust computation, before Ruby allocation.
    let updated = {
        let text = unsafe { html.test_as_str() }?;
        match forem_core::transcript::style_redaction_markers(text) {
            Cow::Borrowed(_) => None,
            Cow::Owned(updated) => Some(updated),
        }
    };
    Some(updated.map_or_else(|| RString::new_shared(html), |s| ruby.str_new(&s)))
}

/// Fuses untagged `<pre><code>` wrapping and optional `[REDACTED]` marker styling in a single pass.
fn postprocess_transcript_html(ruby: &Ruby, html: RString, redact: bool) -> Option<RString> {
    // SAFETY: The borrow is confined to pure Rust computation, before Ruby allocation.
    let updated = {
        let text = unsafe { html.test_as_str() }?;
        match forem_core::transcript::postprocess_transcript_html(text, redact)? {
            Cow::Borrowed(_) => None,
            Cow::Owned(updated) => Some(updated),
        }
    };
    Some(updated.map_or_else(|| RString::new_shared(html), |s| ruby.str_new(&s)))
}

fn wrap_all_tables(ruby: &Ruby, html: RString) -> Option<RString> {
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before we allocate any Ruby objects.
    let wrapped = {
        let text = unsafe { html.test_as_str() }?;
        match forem_core::html::wrap_all_tables(text)? {
            Cow::Borrowed(_) => None,
            Cow::Owned(wrapped) => Some(wrapped),
        }
    };
    Some(wrapped.map_or_else(|| RString::new_shared(html), |s| ruby.str_new(&s)))
}

fn remove_empty_paragraphs(ruby: &Ruby, html: RString) -> Option<RString> {
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before we allocate any Ruby objects.
    let cleaned = {
        let text = unsafe { html.test_as_str() }?;
        match forem_core::html::remove_empty_paragraphs(text)? {
            Cow::Borrowed(_) => None,
            Cow::Owned(cleaned) => Some(cleaned),
        }
    };
    Some(cleaned.map_or_else(|| RString::new_shared(html), |s| ruby.str_new(&s)))
}

fn wrap_all_images_in_links(ruby: &Ruby, html: RString) -> Option<RString> {
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before we allocate any Ruby objects.
    let wrapped = {
        let text = unsafe { html.test_as_str() }?;
        match forem_core::html::wrap_all_images_in_links(text)? {
            Cow::Borrowed(_) => None,
            Cow::Owned(wrapped) => Some(wrapped),
        }
    };
    Some(wrapped.map_or_else(|| RString::new_shared(html), |s| ruby.str_new(&s)))
}

fn unescape_raw_tag_in_codeblocks(ruby: &Ruby, html: RString) -> Option<RString> {
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before we allocate any Ruby objects.
    let unescaped = {
        let text = unsafe { html.test_as_str() }?;
        match forem_core::html::unescape_raw_tag_in_codeblocks(text)? {
            Cow::Borrowed(_) => None,
            Cow::Owned(unescaped) => Some(unescaped),
        }
    };
    Some(unescaped.map_or_else(|| RString::new_shared(html), |s| ruby.str_new(&s)))
}

fn extract_mention_usernames(ruby: &Ruby, html: RString) -> Option<RArray> {
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and all
    // Strings are owned before allocating the Ruby Array.
    let usernames = {
        let text = unsafe { html.test_as_str() }?;
        forem_core::html::extract_mention_usernames(text)?
    };
    let ary = ruby.ary_new_capa(usernames.len());
    for username in usernames {
        ary.push(ruby.str_new(&username)).ok()?;
    }
    Some(ary)
}

fn wrap_mentions_with_links(
    ruby: &Ruby,
    html: RString,
    existing_usernames: RArray,
    base_url: RString,
) -> Option<RString> {
    if !base_url.is_utf8_compatible_encoding() {
        return None;
    }
    // SAFETY: Borrow `existing_usernames`, `html`, and `base_url` in-place without calling into
    // the Ruby VM, and drop all borrows before allocating Ruby objects.
    let usernames_vec: Vec<String> = {
        let slice = unsafe { existing_usernames.as_slice() };
        let mut out = Vec::with_capacity(slice.len());
        for &val in slice {
            let rstr = RString::from_value(val)?;
            if !rstr.is_utf8_compatible_encoding() {
                return None;
            }
            out.push(unsafe { rstr.test_as_str() }?.to_ascii_lowercase());
        }
        out
    };
    let wrapped = {
        let text = unsafe { html.test_as_str() }?;
        let url_str = unsafe { base_url.test_as_str() }?;
        match forem_core::html::wrap_mentions_with_links(text, &usernames_vec, url_str)? {
            Cow::Borrowed(_) => None,
            Cow::Owned(wrapped) => Some(wrapped),
        }
    };
    Some(wrapped.map_or_else(|| RString::new_shared(html), |s| ruby.str_new(&s)))
}

#[allow(clippy::too_many_arguments)]
fn calendar_grid_days_html(
    grid_start_jd: Integer,
    grid_end_jd: Integer,
    display_month: Integer,
    event_day_jds: RArray,
    selected: bool,
    range_start_jd: Integer,
    range_end_jd: Integer,
    today_jd: Integer,
    base_path: RString,
    type_of: Option<RString>,
) -> Option<String> {
    let event_day_jds = extract_strict_i64_vec(event_day_jds)?;
    let selected_range = if selected {
        Some((range_start_jd.to_i64().ok()?, range_end_jd.to_i64().ok()?))
    } else {
        None
    };
    let (grid_start_jd, grid_end_jd) = (grid_start_jd.to_i64().ok()?, grid_end_jd.to_i64().ok()?);
    let display_month = u32::try_from(display_month.to_i64().ok()?).ok()?;
    let today_jd = today_jd.to_i64().ok()?;
    if !base_path.is_utf8_compatible_encoding()
        || type_of.is_some_and(|value| !value.is_utf8_compatible_encoding())
    {
        return None;
    }
    // SAFETY: Zero-copy `RString` borrows; `forem_core` never calls into Ruby, and the
    // borrows end before the owned `String` is returned.
    let grid = forem_core::calendar::CalendarGrid {
        grid_start_jd,
        grid_end_jd,
        display_month,
        event_day_jds: &event_day_jds,
        selected_range,
        today_jd,
        base_path: unsafe { base_path.as_slice() },
        type_of: type_of.as_ref().map(|value| unsafe { value.as_slice() }),
    };
    forem_core::calendar::build_calendar_grid_days_html(&grid)
}

fn extract_mentioned_usernames(ruby: &Ruby, html: RString) -> Option<RArray> {
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and all
    // Strings are owned before allocating the Ruby Array.
    let usernames = {
        let text = unsafe { html.test_as_str() }?;
        forem_core::html::extract_mentioned_usernames(text)?
    };
    let ary = ruby.ary_new_capa(usernames.len());
    for username in usernames {
        ary.push(ruby.str_new(&username)).ok()?;
    }
    Some(ary)
}

// Containers nested deeper than this are left to ActiveSupport (which recurses without limit).
const JSON_MAX_DEPTH: usize = 100;

fn json_quote(ruby: &Ruby, value: RString, escape_html: bool) -> Option<RString> {
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before the result String is allocated.
    let quoted = {
        let text = json_str(&value)?;
        forem_core::json::json_quote(text, escape_html)
    };
    Some(ruby.str_new(&quoted))
}

// Valid UTF-8 (or US-ASCII) contents of a `String`; anything else is left to Ruby.
fn json_str(value: &RString) -> Option<&str> {
    if !value.is_utf8_compatible_encoding() {
        return None;
    }
    // SAFETY: Callers only use the borrow while walking the value, without calling back into
    // Ruby code or allocating Ruby objects, so the String cannot be mutated or moved.
    std::str::from_utf8(unsafe { value.as_slice() }).ok()
}

// `rb_equal` short-circuits on identity, and `Class#==` is the C-level identity check.
fn is_instance_of(value: Value, class: magnus::RClass) -> bool {
    value.class().equal(class).unwrap_or(false)
}

/// Writes a supported Ruby hash key into `w`, rejecting non-string keys when `string_keys_only` is true.
fn write_json_key<W: forem_core::json::JsonOutput>(
    ruby: &Ruby,
    w: &mut forem_core::json::JsonWriter<W>,
    key: Value,
    string_keys_only: bool,
) -> Option<()> {
    if let Some(symbol) = Symbol::from_value(key) {
        // ActiveSupport can collapse symbol/string key collisions during as_json.
        // The counting fast path accepts JSON object keys only.
        if string_keys_only {
            return None;
        }
        w.key(&symbol.name().ok()?);
    } else if is_instance_of(key, ruby.class_string()) {
        w.key(json_str(&RString::from_value(key)?)?);
    } else {
        // Integer, nil, and object keys are stringified by ActiveSupport via `to_s`.
        return None;
    }
    Some(())
}

/// Recursively traverses a supported Ruby value and writes or counts its JSON representation in `w`.
fn write_json_value<W: forem_core::json::JsonOutput>(
    ruby: &Ruby,
    w: &mut forem_core::json::JsonWriter<W>,
    value: Value,
    string_keys_only: bool,
) -> Option<()> {
    if value.is_nil() {
        w.null();
    } else if Qtrue::from_value(value).is_some() {
        w.bool(true);
    } else if Qfalse::from_value(value).is_some() {
        w.bool(false);
    } else if let Some(integer) = Integer::from_value(value) {
        w.int(integer.to_i64().ok()?);
    } else if let Some(symbol) = Symbol::from_value(value) {
        w.string(&symbol.name().ok()?);
    } else {
        if w.depth() >= JSON_MAX_DEPTH {
            return None;
        }
        if is_instance_of(value, ruby.class_string()) {
            w.string(json_str(&RString::from_value(value)?)?);
        } else if is_instance_of(value, ruby.class_hash()) {
            let hash = RHash::from_value(value)?;
            let mut pairs: Vec<(Value, Value)> = Vec::with_capacity(hash.len());
            hash.foreach(|k: Value, v: Value| {
                pairs.push((k, v));
                Ok(ForEach::Continue)
            })
            .ok()?;
            w.begin_object();
            for (k, v) in pairs {
                write_json_key(ruby, w, k, string_keys_only)?;
                write_json_value(ruby, w, v, string_keys_only)?;
            }
            w.end_object();
        } else if is_instance_of(value, ruby.class_array()) {
            // SAFETY: Copy the element handles out so no slice borrow is held while recursing.
            let items: Vec<Value> = unsafe { RArray::from_value(value)?.as_slice() }.to_vec();
            w.begin_array();
            for item in items {
                write_json_value(ruby, w, item, string_keys_only)?;
            }
            w.end_array();
        } else {
            // Floats, Times, String/Hash subclasses, and other objects use Ruby's `as_json`.
            return None;
        }
    }
    Some(())
}

/// Encodes a supported Ruby value into a JSON `RString` matching ActiveSupport's `JSONGemEncoder`.
fn encode_json(ruby: &Ruby, value: Value, escape_html: bool) -> Option<RString> {
    // The walk only reads Strings, Symbols, and Integers in place (no Ruby allocations), so
    // nothing can run GC or mutate the tree until the finished buffer is copied out.
    let json = {
        let mut w = forem_core::json::JsonWriter::new(escape_html, 8192);
        write_json_value(ruby, &mut w, value, false)?;
        w.finish()
    };
    Some(ruby.str_new(&json))
}

/// Computes the exact encoded JSON byte size for a supported Ruby value without allocating a JSON buffer.
fn json_encoded_size(ruby: &Ruby, value: Value, escape_html: bool) -> Option<usize> {
    let mut w = forem_core::json::JsonWriter::counting(escape_html);
    write_json_value(ruby, &mut w, value, true)?;
    Some(w.finish().0)
}

fn truncate_feed_xml_items(ruby: &Ruby, xml: RString, max_items: usize) -> Option<RString> {
    if !xml.is_utf8_compatible_encoding() {
        return None;
    }
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before we allocate any Ruby objects.
    let truncated = {
        let text = unsafe { xml.test_as_str() }?;
        match forem_core::feed::truncate_feed_xml_items(text, max_items) {
            Cow::Borrowed(_) => None,
            Cow::Owned(truncated) => Some(truncated),
        }
    };
    Some(truncated.map_or(xml, |s| ruby.str_new(&s)))
}

fn feed_html_content(content: RString) -> Option<bool> {
    if !content.is_utf8_compatible_encoding() {
        return None;
    }
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby.
    let text = unsafe { content.test_as_str() }?;
    Some(forem_core::feed::feed_html_content(text))
}

fn postprocess_feed_markdown(ruby: &Ruby, content: RString) -> Option<RString> {
    if !content.is_utf8_compatible_encoding() {
        return None;
    }
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before we allocate any Ruby objects.
    let processed = {
        let text = unsafe { content.test_as_str() }?;
        match forem_core::feed::postprocess_feed_markdown(text) {
            Cow::Borrowed(_) => None,
            Cow::Owned(processed) => Some(processed),
        }
    };
    Some(processed.map_or_else(|| RString::new_shared(content), |s| ruby.str_new(&s)))
}

fn resolve_feed_markdown_images(
    ruby: &Ruby,
    content: RString,
    base_url: RString,
    feed_source_url: RString,
) -> Option<RString> {
    if !content.is_utf8_compatible_encoding()
        || !base_url.is_utf8_compatible_encoding()
        || !feed_source_url.is_utf8_compatible_encoding()
    {
        return None;
    }
    // SAFETY: Same zero-copy `RString` borrows; `forem_core` never calls into Ruby, and all
    // borrows end before we allocate any Ruby objects.
    let resolved = {
        let text = unsafe { content.test_as_str() }?;
        let base = unsafe { base_url.test_as_str() }?;
        let source = unsafe { feed_source_url.test_as_str() }?;
        match forem_core::feed::resolve_feed_markdown_images(text, base, source)? {
            Cow::Borrowed(_) => None,
            Cow::Owned(resolved) => Some(resolved),
        }
    };
    Some(resolved.map_or_else(|| RString::new_shared(content), |s| ruby.str_new(&s)))
}

fn format_feed_tags(categories: RArray) -> Option<String> {
    // SAFETY: Borrow `categories` slice in-place without calling into Ruby.
    let cats: Vec<String> = {
        let slice = unsafe { categories.as_slice() };
        let take = slice.len().min(4);
        let mut out = Vec::with_capacity(take);
        for &val in &slice[..take] {
            let rstr = RString::from_value(val)?;
            if !rstr.is_utf8_compatible_encoding() {
                return None;
            }
            out.push(unsafe { rstr.test_as_str() }?.to_owned());
        }
        out
    };
    forem_core::feed::format_feed_tags(&cats)
}

fn extract_feed_author(ruby: &Ruby, author_string: RString) -> Option<RArray> {
    if !author_string.is_utf8_compatible_encoding() {
        return None;
    }
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before allocating the Ruby Array.
    let (email, name) = {
        let text = unsafe { author_string.test_as_str() }?;
        forem_core::feed::extract_feed_author(text)?
    };
    let ary = ruby.ary_new_capa(2);
    match email {
        Some(e) => ary.push(ruby.str_new(&e)).ok()?,
        None => ary.push(ruby.qnil()).ok()?,
    }
    ary.push(ruby.str_new(&name)).ok()?;
    Some(ary)
}

fn sanitize_feed_error(message: RString) -> Option<String> {
    if !message.is_utf8_compatible_encoding() {
        return None;
    }
    // SAFETY: Same zero-copy `RString` borrow; `forem_core` never calls into Ruby.
    let text = unsafe { message.test_as_str() }?;
    Some(forem_core::feed::sanitize_feed_error(text))
}

fn verify_authenticity_token(
    ruby: &Ruby,
    encoded_masked: RString,
    encoded_real: RString,
    action_path: Option<RString>,
    request_method: Option<RString>,
) -> Option<bool> {
    if !is_ascii_compatible_host(ruby, encoded_masked)
        || !is_ascii_compatible_host(ruby, encoded_real)
    {
        return None;
    }
    if let Some(p) = action_path {
        if !is_ascii_compatible_host(ruby, p) {
            return None;
        }
    }
    if let Some(m) = request_method {
        if !is_ascii_compatible_host(ruby, m) {
            return None;
        }
    }
    // SAFETY: Zero-copy `RString` slice borrows; `forem_core` never calls into Ruby.
    unsafe {
        forem_core::metal::verify_authenticity_token(
            encoded_masked.as_slice(),
            encoded_real.as_slice(),
            action_path.as_ref().map(|p| p.as_slice()),
            request_method.as_ref().map(|m| m.as_slice()),
        )
    }
}

fn verify_hs256_jwt(ruby: &Ruby, token: RString, secret: RString, now_sec: i64) -> Value {
    if !is_ascii_compatible_host(ruby, token) || !is_ascii_compatible_host(ruby, secret) {
        return ruby.qnil().as_value();
    }
    // SAFETY: Zero-copy `RString` slice borrows; `forem_core` never calls into Ruby, and
    // the borrows end before allocating the Ruby Hash.
    let outcome = unsafe {
        forem_core::metal::verify_hs256_jwt(token.as_slice(), secret.as_slice(), now_sec)
    };
    match outcome {
        forem_core::metal::JwtVerifyOutcome::Invalid => ruby.qfalse().as_value(),
        forem_core::metal::JwtVerifyOutcome::DeferToRuby => ruby.qnil().as_value(),
        forem_core::metal::JwtVerifyOutcome::Valid(claims) => {
            let hash = ruby.hash_new_capa(claims.len());
            for (k, v) in claims {
                let key_val = ruby.str_new(&k);
                let val_obj = match v {
                    forem_core::metal::JwtClaimValue::Int(n) => ruby.integer_from_i64(n).as_value(),
                    forem_core::metal::JwtClaimValue::Str(s) => ruby.str_new(&s).as_value(),
                    forem_core::metal::JwtClaimValue::Bool(true) => ruby.qtrue().as_value(),
                    forem_core::metal::JwtClaimValue::Bool(false) => ruby.qfalse().as_value(),
                    forem_core::metal::JwtClaimValue::Null => ruby.qnil().as_value(),
                };
                if hash.aset(key_val, val_obj).is_err() {
                    return ruby.qnil().as_value();
                }
            }
            hash.as_value()
        }
    }
}

fn cast_ar_bigint_value(ruby: &Ruby, val: Value) -> forem_core::metal::ActiveRecordIntCast {
    use forem_core::metal::ActiveRecordIntCast;
    if val.is_nil() {
        return ActiveRecordIntCast::Null;
    }
    if let Some(int) = Integer::from_value(val) {
        return match int.to_i64() {
            Ok(n) => ActiveRecordIntCast::Value(n),
            Err(_) => ActiveRecordIntCast::DeferToRuby,
        };
    }
    if let Some(rstr) = RString::from_value(val) {
        if !is_ascii_compatible_host(ruby, rstr) {
            return ActiveRecordIntCast::DeferToRuby;
        }
        // SAFETY: Zero-copy `RString` slice borrow; `forem_core` never touches the Ruby VM.
        return forem_core::metal::cast_active_record_bigint_bytes(unsafe { rstr.as_slice() });
    }
    if let Some(fl) = Float::from_value(val) {
        let f = fl.to_f64();
        if f.is_finite() && f >= (i64::MIN as f64) && f < (i64::MAX as f64) {
            return ActiveRecordIntCast::Value(f as i64);
        }
        return ActiveRecordIntCast::DeferToRuby;
    }
    if Qtrue::from_value(val).is_some() {
        return ActiveRecordIntCast::Value(1);
    }
    if Qfalse::from_value(val).is_some() {
        return ActiveRecordIntCast::Value(0);
    }
    if RArray::from_value(val).is_some()
        || RHash::from_value(val).is_some()
        || Symbol::from_value(val).is_some()
    {
        return ActiveRecordIntCast::Null;
    }
    ActiveRecordIntCast::DeferToRuby
}

#[allow(clippy::too_many_arguments)]
fn billboard_event_update_sql(
    ruby: &Ruby,
    id: Value,
    user_id: Value,
    seconds: i64,
    now_sec: i64,
    now_usec: u32,
    cutoff_sec: i64,
    cutoff_usec: u32,
) -> Value {
    use forem_core::metal::ActiveRecordIntCast;
    let event_id = match cast_ar_bigint_value(ruby, id) {
        ActiveRecordIntCast::Null => return ruby.to_symbol("invalid").as_value(),
        ActiveRecordIntCast::DeferToRuby => return ruby.qnil().as_value(),
        ActiveRecordIntCast::Value(v) => v,
    };
    let uid = match cast_ar_bigint_value(ruby, user_id) {
        ActiveRecordIntCast::Null => None,
        ActiveRecordIntCast::DeferToRuby => return ruby.qnil().as_value(),
        ActiveRecordIntCast::Value(v) => Some(v),
    };
    match forem_core::metal::billboard_event_update_sql(
        event_id,
        uid,
        seconds,
        now_sec,
        now_usec,
        cutoff_sec,
        cutoff_usec,
    ) {
        Some(sql) => ruby.str_new(&sql).as_value(),
        None => ruby.qnil().as_value(),
    }
}

fn extract_optional_header_utf8_string(ruby: &Ruby, val: Value) -> Option<Option<String>> {
    if val.is_nil() {
        return Some(None);
    }
    let s = RString::from_value(val)?;
    if !is_ascii_compatible_host(ruby, s) {
        return None;
    }
    // SAFETY: Copy out short header bytes before any Ruby allocation.
    std::str::from_utf8(unsafe { s.as_slice() })
        .ok()
        .map(|t| Some(t.to_owned()))
}

fn billboard_event_insert_sql(ruby: &Ruby, args: RArray) -> Value {
    use forem_core::metal::{
        ActiveRecordIntCast, BillboardEventInsert, BillboardEventInsertOutcome,
    };
    let items: Vec<Value> = unsafe { args.as_slice() }.to_vec();
    if items.len() != 12 {
        return ruby.qnil().as_value();
    }

    let display_ad_id = match cast_ar_bigint_value(ruby, items[0]) {
        ActiveRecordIntCast::Null => return ruby.to_symbol("invalid").as_value(),
        ActiveRecordIntCast::DeferToRuby => return ruby.qnil().as_value(),
        ActiveRecordIntCast::Value(v) => v,
    };

    let category = match extract_optional_utf8_string(items[1]) {
        Some(Some(s)) => s,
        Some(None) => return ruby.to_symbol("invalid").as_value(),
        None => return ruby.qnil().as_value(),
    };
    let context_type = match extract_optional_utf8_string(items[2]) {
        Some(Some(s)) => s,
        Some(None) => return ruby.to_symbol("invalid").as_value(),
        None => return ruby.qnil().as_value(),
    };

    let user_id = match cast_ar_bigint_value(ruby, items[3]) {
        ActiveRecordIntCast::Null => None,
        ActiveRecordIntCast::DeferToRuby => return ruby.qnil().as_value(),
        ActiveRecordIntCast::Value(v) => Some(v),
    };
    let article_id = match cast_ar_bigint_value(ruby, items[4]) {
        ActiveRecordIntCast::Null => None,
        ActiveRecordIntCast::DeferToRuby => return ruby.qnil().as_value(),
        ActiveRecordIntCast::Value(v) => match i32::try_from(v) {
            Ok(i) => Some(i),
            Err(_) => return ruby.qnil().as_value(),
        },
    };

    let Some(geolocation) = extract_optional_header_utf8_string(ruby, items[5]) else {
        return ruby.qnil().as_value();
    };
    let Some(user_agent) = extract_optional_header_utf8_string(ruby, items[6]) else {
        return ruby.qnil().as_value();
    };

    let counts_for = match cast_ar_bigint_value(ruby, items[7]) {
        ActiveRecordIntCast::Null => 1,
        ActiveRecordIntCast::DeferToRuby => return ruby.qnil().as_value(),
        ActiveRecordIntCast::Value(v) => match i32::try_from(v) {
            Ok(i) => i,
            Err(_) => return ruby.qnil().as_value(),
        },
    };
    let seconds_visible = match cast_ar_bigint_value(ruby, items[8]) {
        ActiveRecordIntCast::Null => 10,
        ActiveRecordIntCast::DeferToRuby => return ruby.qnil().as_value(),
        ActiveRecordIntCast::Value(v) => match i32::try_from(v) {
            Ok(i) => i,
            Err(_) => return ruby.qnil().as_value(),
        },
    };

    let Some(now_sec) = Integer::from_value(items[9]).and_then(|i| i.to_i64().ok()) else {
        return ruby.qnil().as_value();
    };
    let Some(now_usec) = Integer::from_value(items[10]).and_then(|i| i.to_u32().ok()) else {
        return ruby.qnil().as_value();
    };
    let verify_billboard_exists = Qtrue::from_value(items[11]).is_some();

    let outcome = forem_core::metal::billboard_event_insert_sql(&BillboardEventInsert {
        display_ad_id,
        category: &category,
        context_type: &context_type,
        user_id,
        article_id,
        geolocation: geolocation.as_deref(),
        user_agent: user_agent.as_deref(),
        counts_for,
        seconds_visible,
        now_sec,
        now_usec,
        verify_billboard_exists,
    });

    match outcome {
        BillboardEventInsertOutcome::Sql(sql) => ruby.str_new(&sql).as_value(),
        BillboardEventInsertOutcome::Invalid => ruby.to_symbol("invalid").as_value(),
        BillboardEventInsertOutcome::DeferToRuby => ruby.qnil().as_value(),
    }
}

fn origin_in_comma_list(ruby: &Ruby, origin: RString, raw_list: RString) -> Option<bool> {
    if !is_ascii_compatible_host(ruby, origin) || !is_ascii_compatible_host(ruby, raw_list) {
        return None;
    }
    // SAFETY: Zero-copy `RString` slice borrows; `forem_core` never calls into Ruby.
    unsafe {
        Some(forem_core::metal::origin_in_comma_list(
            origin.as_slice(),
            raw_list.as_slice(),
        ))
    }
}

fn valid_uuid(ruby: &Ruby, value: RString) -> Option<bool> {
    if !is_ascii_compatible_host(ruby, value) {
        return None;
    }
    // SAFETY: Zero-copy `RString` slice borrow; `forem_core` never calls into Ruby.
    unsafe { Some(forem_core::metal::is_valid_uuid(value.as_slice())) }
}

fn feed_events_advisory_lock_key(user_id: i64) -> i64 {
    forem_core::metal::feed_events_advisory_lock_key(user_id)
}

fn valid_request_origin(
    ruby: &Ruby,
    referer: Value,
    origin: Value,
    base_url: Value,
    request_host: Value,
    request_port: Value,
) -> Value {
    use forem_core::metal::OriginValidation;

    let extract_ascii_bytes = |v: Value| -> Result<Option<Vec<u8>>, ()> {
        if v.is_nil() {
            return Ok(None);
        }
        let s = RString::from_value(v).ok_or(())?;
        if !is_ascii_compatible_host(ruby, s) {
            return Err(());
        }
        // SAFETY: Copy out short header bytes so no borrow spans across Ruby calls.
        Ok(Some(unsafe { s.as_slice().to_vec() }))
    };

    let ref_bytes = match extract_ascii_bytes(referer) {
        Ok(v) => v,
        Err(()) => return ruby.qnil().as_value(),
    };
    let orig_bytes = match extract_ascii_bytes(origin) {
        Ok(v) => v,
        Err(()) => return ruby.qnil().as_value(),
    };
    let base_bytes = match extract_ascii_bytes(base_url) {
        Ok(v) => v,
        Err(()) => return ruby.qnil().as_value(),
    };
    let host_bytes = match extract_ascii_bytes(request_host) {
        Ok(v) => v,
        Err(()) => return ruby.qnil().as_value(),
    };
    let Some(port_val) = extract_optional_i64(request_port) else {
        return ruby.qnil().as_value();
    };

    match forem_core::metal::valid_request_origin(
        ref_bytes.as_deref(),
        orig_bytes.as_deref(),
        base_bytes.as_deref(),
        host_bytes.as_deref(),
        port_val,
    ) {
        Some(OriginValidation::Valid) => ruby.qtrue().as_value(),
        Some(OriginValidation::Invalid) => ruby.qfalse().as_value(),
        Some(OriginValidation::NullOrigin) => ruby.to_symbol("null_origin").as_value(),
        None => ruby.qnil().as_value(),
    }
}

fn extract_referrer_domain_and_path(ruby: &Ruby, referrer: RString) -> Value {
    if !is_ascii_compatible_host(ruby, referrer) {
        return ruby.qnil().as_value();
    }
    // SAFETY: `referrer` is not mutated during `extract_referrer_domain_and_path`.
    let outcome =
        unsafe { forem_core::metal::extract_referrer_domain_and_path(referrer.as_slice()) };
    match outcome {
        Some((domain, path)) => {
            let arr = ruby.ary_new_capa(2);
            let dom_val = match domain {
                Some(d) => ruby.str_new(&d).as_value(),
                None => ruby.qnil().as_value(),
            };
            let _ = arr.push(dom_val);
            let _ = arr.push(ruby.str_new(&path));
            arr.as_value()
        }
        None => ruby.qnil().as_value(),
    }
}

fn match_metal_telemetry_route(ruby: &Ruby, method: RString, path: RString) -> Value {
    use forem_core::metal::MetalTelemetryRoute;

    if !is_ascii_compatible_host(ruby, method) || !is_ascii_compatible_host(ruby, path) {
        return ruby.qnil().as_value();
    }
    // SAFETY: Copy result before allocating Ruby symbols/strings.
    let matched = unsafe {
        forem_core::metal::match_metal_telemetry_route(method.as_slice(), path.as_slice()).map(
            |route| match route {
                MetalTelemetryRoute::BillboardUpdate(id) => (0u8, Some(id.to_owned())),
                MetalTelemetryRoute::BillboardCreate => (1u8, None),
                MetalTelemetryRoute::PageViewUpdate(id) => (2u8, Some(id.to_owned())),
                MetalTelemetryRoute::PageViewCreate => (3u8, None),
                MetalTelemetryRoute::GaEventCreate => (4u8, None),
                MetalTelemetryRoute::FeedEventsCreate => (5u8, None),
                MetalTelemetryRoute::FeedConfigVisitsCreate => (6u8, None),
            },
        )
    };
    match matched {
        Some((kind, id_opt)) => {
            let sym_name = match kind {
                0 => "billboard_update",
                1 => "billboard_create",
                2 => "page_view_update",
                3 => "page_view_create",
                4 => "ga_event_create",
                5 => "feed_events_create",
                _ => "feed_config_visits_create",
            };
            let arr = ruby.ary_new_capa(2);
            let _ = arr.push(ruby.to_symbol(sym_name));
            match id_opt {
                Some(id) => {
                    let _ = arr.push(ruby.str_new(&id));
                }
                None => {
                    let _ = arr.push(ruby.qnil());
                }
            }
            arr.as_value()
        }
        None => ruby.qnil().as_value(),
    }
}

fn extract_ga_event_params(
    ruby: &Ruby,
    json_body: RString,
    app_url_val: Value,
    user_id_val: Value,
) -> Value {
    use forem_core::metal::GaEventParseOutcome;

    if !is_ascii_compatible_host(ruby, json_body) {
        return ruby.qnil().as_value();
    }
    let Some(user_id) = extract_optional_i64(user_id_val) else {
        return ruby.qnil().as_value();
    };
    let Some(app_url) = extract_optional_header_utf8_string(ruby, app_url_val) else {
        return ruby.qnil().as_value();
    };

    // SAFETY: `json_body` is not mutated during `parse_ga_event_json`.
    let outcome =
        unsafe { forem_core::metal::parse_ga_event_json(json_body.as_slice(), app_url.as_deref()) };

    match outcome {
        GaEventParseOutcome::Parsed(fields) => {
            let hash = ruby.hash_new_capa(11);
            let set_opt_str = |k: &str, opt: Option<String>| {
                let v = match opt {
                    Some(s) => ruby.str_new(&s).as_value(),
                    None => ruby.qnil().as_value(),
                };
                let _ = hash.aset(ruby.str_new(k), v);
            };
            set_opt_str("page_title", fields.page_title);
            set_opt_str("page_location", fields.page_location);
            set_opt_str("page_path", fields.page_path);
            let uid_val = match user_id {
                Some(id) => ruby.into_value(id),
                None => ruby.qnil().as_value(),
            };
            let _ = hash.aset(ruby.str_new("user_id"), uid_val);
            set_opt_str("user_language", fields.user_language);
            set_opt_str("referrer", fields.referrer);
            set_opt_str("user_agent", fields.user_agent);
            set_opt_str("viewport_size", fields.viewport_size);
            set_opt_str("screen_resolution", fields.screen_resolution);
            set_opt_str("document_encoding", fields.document_encoding);
            let _ = hash.aset(ruby.str_new("data_source"), ruby.str_new("web"));
            hash.as_value()
        }
        GaEventParseOutcome::InvalidJson => ruby.to_symbol("invalid").as_value(),
        GaEventParseOutcome::DeferToRuby => ruby.qnil().as_value(),
    }
}

#[derive(Default)]
struct RawFeedEventEntry {
    article_id: Option<i64>,
    user_id: Option<i64>,
    article_position: Option<i64>,
    category: Option<Vec<u8>>,
    context_type: Option<Vec<u8>>,
    feed_config_id: Option<i64>,
    event_id: Option<Vec<u8>>,
    invalid: bool,
    defer: bool,
}

fn extract_hash_key_name(ruby: &Ruby, key: Value) -> Option<Vec<u8>> {
    if let Some(rstr) = RString::from_value(key) {
        if !is_ascii_compatible_host(ruby, rstr) {
            return None;
        }
        return Some(unsafe { rstr.as_slice().to_vec() });
    }
    if let Some(sym) = Symbol::from_value(key) {
        let name = sym.name().ok()?;
        return Some(name.as_bytes().to_vec());
    }
    None
}

fn extract_strict_i64_field(ruby: &Ruby, val: Value) -> Result<Option<i64>, bool> {
    if val.is_nil() {
        return Ok(None);
    }
    if let Some(int) = Integer::from_value(val) {
        return int.to_i64().map(Some).map_err(|_| true);
    }
    if let Some(rstr) = RString::from_value(val) {
        if !is_ascii_compatible_host(ruby, rstr) {
            return Err(true);
        }
        let parsed = unsafe { forem_core::metal::parse_strict_integer_i64(rstr.as_slice()) };
        return parsed.map(Some).ok_or(false);
    }
    if Float::from_value(val).is_some() {
        return Err(false);
    }
    Err(true)
}

fn extract_name_bytes(ruby: &Ruby, val: Value, allow_symbol: bool) -> Result<Option<Vec<u8>>, ()> {
    if val.is_nil() {
        return Ok(None);
    }
    if let Some(rstr) = RString::from_value(val) {
        if !is_ascii_compatible_host(ruby, rstr) {
            return Err(());
        }
        return Ok(Some(unsafe { rstr.as_slice().to_vec() }));
    }
    if allow_symbol {
        if let Some(sym) = Symbol::from_value(val) {
            let name = sym.name().map_err(|_| ())?;
            return Ok(Some(name.as_bytes().to_vec()));
        }
    }
    Err(())
}

fn validate_and_normalize_feed_events(ruby: &Ruby, events_arr: RArray) -> Option<RArray> {
    use forem_core::metal::{validate_feed_event_fields, ValidatedFeedEvent};
    use magnus::r_hash::ForEach;

    let items: Vec<Value> = unsafe { events_arr.as_slice() }.to_vec();
    let mut validated: Vec<ValidatedFeedEvent> = Vec::with_capacity(items.len());

    for item in items {
        let hash = RHash::from_value(item)?;
        let mut entry = RawFeedEventEntry::default();
        hash.foreach(|k: Value, v: Value| -> Result<ForEach, Error> {
            let Some(key_bytes) = extract_hash_key_name(ruby, k) else {
                entry.defer = true;
                return Ok(ForEach::Stop);
            };
            match key_bytes.as_slice() {
                b"article" | b"user" | b"feed_config" => {
                    entry.defer = true;
                    return Ok(ForEach::Stop);
                }
                b"article_id" => match extract_strict_i64_field(ruby, v) {
                    Ok(Some(n)) => entry.article_id = Some(n),
                    Ok(None) | Err(false) => {
                        entry.article_id = None;
                        entry.invalid = true;
                    }
                    Err(true) => {
                        entry.defer = true;
                        return Ok(ForEach::Stop);
                    }
                },
                b"user_id" => match extract_strict_i64_field(ruby, v) {
                    Ok(opt) => entry.user_id = opt,
                    Err(false) => entry.invalid = true,
                    Err(true) => {
                        entry.defer = true;
                        return Ok(ForEach::Stop);
                    }
                },
                b"article_position" => match extract_strict_i64_field(ruby, v) {
                    Ok(Some(n)) => entry.article_position = Some(n),
                    Ok(None) | Err(false) => {
                        entry.article_position = None;
                        entry.invalid = true;
                    }
                    Err(true) => {
                        entry.defer = true;
                        return Ok(ForEach::Stop);
                    }
                },
                b"feed_config_id" => match extract_strict_i64_field(ruby, v) {
                    Ok(opt) => entry.feed_config_id = opt,
                    Err(_) => {
                        entry.defer = true;
                        return Ok(ForEach::Stop);
                    }
                },
                b"category" => {
                    if let Some(int) = Integer::from_value(v) {
                        match int.to_i64() {
                            Ok(0) => entry.category = Some(b"impression".to_vec()),
                            Ok(1) => entry.category = Some(b"click".to_vec()),
                            Ok(2) => entry.category = Some(b"reaction".to_vec()),
                            Ok(3) => entry.category = Some(b"comment".to_vec()),
                            Ok(4) => entry.category = Some(b"extended_pageview".to_vec()),
                            _ => {
                                entry.category = None;
                                entry.invalid = true;
                            }
                        }
                    } else {
                        match extract_name_bytes(ruby, v, true) {
                            Ok(b) => entry.category = b,
                            Err(()) => {
                                entry.defer = true;
                                return Ok(ForEach::Stop);
                            }
                        }
                    }
                }
                b"context_type" => match extract_name_bytes(ruby, v, true) {
                    Ok(b) => entry.context_type = b,
                    Err(()) => {
                        entry.defer = true;
                        return Ok(ForEach::Stop);
                    }
                },
                b"event_id" => match extract_name_bytes(ruby, v, false) {
                    Ok(b) => entry.event_id = b,
                    Err(()) => {
                        entry.defer = true;
                        return Ok(ForEach::Stop);
                    }
                },
                _ => {}
            }
            Ok(ForEach::Continue)
        })
        .ok()?;

        if entry.defer {
            return None;
        }
        if entry.invalid {
            continue;
        }
        if let Some(v) = validate_feed_event_fields(
            entry.article_id,
            entry.user_id,
            entry.article_position,
            entry.category.as_deref(),
            entry.context_type.as_deref(),
            entry.feed_config_id,
            entry.event_id.as_deref(),
        ) {
            validated.push(v);
        }
    }

    let sym_article_id = ruby.to_symbol("article_id");
    let sym_user_id = ruby.to_symbol("user_id");
    let sym_article_position = ruby.to_symbol("article_position");
    let sym_category = ruby.to_symbol("category");
    let sym_context_type = ruby.to_symbol("context_type");
    let sym_feed_config_id = ruby.to_symbol("feed_config_id");
    let sym_event_id = ruby.to_symbol("event_id");

    let out = ruby.ary_new_capa(validated.len());
    for ev in validated {
        let h = ruby.hash_new_capa(7);
        h.aset(sym_article_id, ev.article_id).ok()?;
        match ev.user_id {
            Some(uid) => h.aset(sym_user_id, uid).ok()?,
            None => h.aset(sym_user_id, ruby.qnil()).ok()?,
        }
        h.aset(sym_article_position, ev.article_position).ok()?;
        h.aset(sym_category, ruby.str_new(ev.category)).ok()?;
        h.aset(sym_context_type, ruby.str_new(ev.context_type))
            .ok()?;
        match ev.feed_config_id {
            Some(fcid) => h.aset(sym_feed_config_id, fcid).ok()?,
            None => h.aset(sym_feed_config_id, ruby.qnil()).ok()?,
        }
        match ev.event_id {
            Some(ref eid) => h.aset(sym_event_id, ruby.str_new(eid)).ok()?,
            None => h.aset(sym_event_id, ruby.qnil()).ok()?,
        }
        out.push(h).ok()?;
    }
    Some(out)
}

#[allow(clippy::too_many_arguments)]
fn billboard_event_create_from_json_sql(
    ruby: &Ruby,
    json_body: RString,
    user_id_val: Value,
    geolocation_val: Value,
    header_ua_val: Value,
    is_embed: bool,
    now_sec: i64,
    now_usec: u32,
) -> Value {
    use forem_core::metal::BillboardJsonCreateOutcome;

    if !is_ascii_compatible_host(ruby, json_body) {
        return ruby.qnil().as_value();
    }
    let Some(user_id) = extract_optional_i64(user_id_val) else {
        return ruby.qnil().as_value();
    };
    let Some(geolocation) = extract_optional_header_utf8_string(ruby, geolocation_val) else {
        return ruby.qnil().as_value();
    };
    let Some(header_ua) = extract_optional_header_utf8_string(ruby, header_ua_val) else {
        return ruby.qnil().as_value();
    };

    // SAFETY: `json_body` is not mutated during `billboard_event_create_from_json_sql`.
    let outcome = unsafe {
        forem_core::metal::billboard_event_create_from_json_sql(
            json_body.as_slice(),
            user_id,
            geolocation.as_deref(),
            header_ua.as_deref(),
            is_embed,
            now_sec,
            now_usec,
        )
    };

    match outcome {
        Some(BillboardJsonCreateOutcome::BlankId) => ruby.to_symbol("blank_id").as_value(),
        Some(BillboardJsonCreateOutcome::Parsed {
            sql,
            raw_billboard_id,
        }) => {
            let arr = ruby.ary_new_capa(2);
            match sql {
                Some(s) => {
                    let _ = arr.push(ruby.str_new(&s));
                }
                None => {
                    let _ = arr.push(ruby.to_symbol("invalid"));
                }
            }
            let _ = arr.push(ruby.str_new(&raw_billboard_id));
            arr.as_value()
        }
        None => ruby.qnil().as_value(),
    }
}

fn encode_hs256_jwt(ruby: &Ruby, user_id: i64, exp: i64, secret: RString) -> Option<String> {
    if !is_ascii_compatible_host(ruby, secret) {
        return None;
    }
    // SAFETY: `secret` is not mutated during `encode_hs256_jwt`.
    Some(unsafe { forem_core::metal::encode_hs256_jwt(user_id, exp, secret.as_slice()) })
}

fn mask_authenticity_token(
    ruby: &Ruby,
    encoded_real_token: RString,
    one_time_pad: RString,
) -> Option<String> {
    if !is_ascii_compatible_host(ruby, encoded_real_token) {
        return None;
    }
    // SAFETY: Both Ruby Strings are borrowed read-only during pure Rust calculation.
    unsafe {
        forem_core::metal::mask_authenticity_token(
            encoded_real_token.as_slice(),
            one_time_pad.as_slice(),
        )
    }
}

fn parse_auth_pass_origin(ruby: &Ruby, raw_origin: RString) -> Option<RArray> {
    if !is_ascii_compatible_host(ruby, raw_origin) {
        return None;
    }
    // SAFETY: `raw_origin` is borrowed read-only and owned Strings are returned before Ruby allocations.
    let (host, csp_origin) =
        unsafe { forem_core::metal::parse_auth_pass_origin(raw_origin.as_slice()) }?;
    let ary = ruby.ary_new_capa(2);
    ary.push(ruby.str_new(&host)).ok()?;
    ary.push(ruby.str_new(&csp_origin)).ok()?;
    Some(ary)
}

#[allow(clippy::too_many_arguments)]
fn build_base_data_json(
    ruby: &Ruby,
    broadcast_val: Value,
    param: RString,
    token: RString,
    user_val: Value,
    geo_val: Value,
    optin_allowed: bool,
    creator: bool,
) -> Option<String> {
    if !param.is_utf8_compatible_encoding() || !token.is_utf8_compatible_encoding() {
        return None;
    }
    let broadcast = extract_optional_header_utf8_string(ruby, broadcast_val)?;
    let user_json = extract_optional_header_utf8_string(ruby, user_val)?;
    let client_geo = extract_optional_header_utf8_string(ruby, geo_val)?;

    // SAFETY: `param` and `token` are borrowed read-only during pure Rust formatting.
    let param_str = unsafe { param.test_as_str() }?;
    let token_str = unsafe { token.test_as_str() }?;

    let signed_in = user_json
        .as_deref()
        .map(|u| (u, client_geo.as_deref(), optin_allowed, creator));

    Some(forem_core::metal::build_base_data_json(
        broadcast.as_deref(),
        param_str,
        token_str,
        signed_in,
    ))
}

fn resolve_bulk_follow_json(
    viewer_id: i64,
    is_user_type: bool,
    ids_arr: RArray,
    forward_arr: RArray,
    reverse_arr: RArray,
) -> Option<String> {
    // SAFETY: Only immediate integers and booleans are inspected before calling pure Rust.
    let (ids, fwd, rev) = unsafe {
        let id_slice = ids_arr.as_slice();
        let fwd_slice = forward_arr.as_slice();
        let rev_slice = reverse_arr.as_slice();
        let mut ids_vec = Vec::with_capacity(id_slice.len());
        for &v in id_slice {
            ids_vec.push(Integer::from_value(v)?.to_i64().ok()?);
        }
        let fwd_vec: Vec<bool> = fwd_slice.iter().map(|v| v.to_bool()).collect();
        let rev_vec: Vec<bool> = rev_slice.iter().map(|v| v.to_bool()).collect();
        (ids_vec, fwd_vec, rev_vec)
    };
    forem_core::metal::resolve_bulk_follow_json(viewer_id, is_user_type, &ids, &fwd, &rev)
}

fn extract_liquid_embed_tags(ruby: &Ruby, content: RString) -> Option<RArray> {
    if !content.is_utf8_compatible_encoding() {
        return None;
    }
    // SAFETY: Zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before allocating the Ruby Arrays.
    let tags = {
        let text = unsafe { content.test_as_str() }?;
        forem_core::markdown::extract_liquid_embed_tags(text)
    };
    let ary = ruby.ary_new_capa(tags.len());
    for (tag_name, url, options) in tags {
        let tuple = ruby.ary_new_capa(3);
        tuple.push(ruby.str_new(&tag_name)).ok()?;
        tuple.push(ruby.str_new(&url)).ok()?;
        tuple.push(ruby.str_new(&options)).ok()?;
        ary.push(tuple).ok()?;
    }
    Some(ary)
}

fn extract_markdown_webpage_urls(ruby: &Ruby, content: RString) -> Option<RArray> {
    if !content.is_utf8_compatible_encoding() {
        return None;
    }
    // SAFETY: Zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before allocating the Ruby Array.
    let urls = {
        let text = unsafe { content.test_as_str() }?;
        forem_core::markdown::extract_markdown_webpage_urls(text)
    };
    let ary = ruby.ary_new_capa(urls.len());
    for url in urls {
        ary.push(ruby.str_new(&url)).ok()?;
    }
    Some(ary)
}

fn extract_markdown_and_html_image_urls(
    ruby: &Ruby,
    markdown: RString,
    excluded_substring: RString,
) -> Option<RArray> {
    if !markdown.is_utf8_compatible_encoding() || !excluded_substring.is_utf8_compatible_encoding()
    {
        return None;
    }
    // SAFETY: Zero-copy `RString` borrows; `forem_core` never calls into Ruby, and the
    // borrows end before allocating the Ruby Array.
    let urls = {
        let md = unsafe { markdown.test_as_str() }?;
        let excl = unsafe { excluded_substring.test_as_str() }?;
        forem_core::markdown::extract_markdown_and_html_image_urls(md, excl)
    };
    let ary = ruby.ary_new_capa(urls.len());
    for url in urls {
        ary.push(ruby.str_new(&url)).ok()?;
    }
    Some(ary)
}

fn clean_tag_list(ruby: &Ruby, input: RString) -> Option<RArray> {
    if !input.is_utf8_compatible_encoding() {
        return None;
    }
    // SAFETY: Zero-copy `RString` borrow; `forem_core` never calls into Ruby, and the
    // borrow ends before allocating the Ruby Array.
    let tags = {
        let text = unsafe { input.test_as_str() }?;
        forem_core::text::clean_tag_list(text)?
    };
    let ary = ruby.ary_new_capa(tags.len());
    for tag in tags {
        ary.push(ruby.str_new(&tag)).ok()?;
    }
    Some(ary)
}

fn extract_flare_allowed_tags(allowed_tags: Value) -> Option<Option<Vec<String>>> {
    if allowed_tags.is_nil() {
        return Some(None);
    }
    let arr = RArray::from_value(allowed_tags)?;
    // SAFETY: `arr.as_slice()` borrows the Ruby Array buffer in-place and copies UTF-8 strings
    // out before returning.
    let slice = unsafe { arr.as_slice() };
    let mut out = Vec::with_capacity(slice.len());
    for &val in slice {
        let rstr = RString::from_value(val)?;
        if !rstr.is_utf8_compatible_encoding() {
            return None;
        }
        let s = unsafe { rstr.test_as_str() }?;
        out.push(s.to_owned());
    }
    Some(Some(out))
}

fn match_first_flare_tag(ruby: &Ruby, cached_tag_list: Value, allowed_tags: Value) -> Value {
    let Some(allowed) = extract_flare_allowed_tags(allowed_tags) else {
        return ruby.qnil().as_value();
    };
    if cached_tag_list.is_nil() {
        return ruby.qfalse().as_value();
    }
    let Some(rstr) = RString::from_value(cached_tag_list) else {
        return ruby.qnil().as_value();
    };
    if !rstr.is_utf8_compatible_encoding() {
        return ruby.qnil().as_value();
    }
    // SAFETY: `test_as_str()` borrows the Ruby String buffer in-place during pure Rust scanning
    // and copies the matched tag slice before any Ruby allocation.
    let matched = {
        let Some(text) = (unsafe { rstr.test_as_str() }) else {
            return ruby.qnil().as_value();
        };
        forem_core::feed::match_first_flare_tag(text, allowed.as_deref()).map(str::to_owned)
    };
    match matched {
        Some(tag) => ruby.str_new(&tag).as_value(),
        None => ruby.qfalse().as_value(),
    }
}

fn match_articles_flare_tags(ruby: &Ruby, pairs: RArray, allowed_tags: Value) -> Option<RHash> {
    let allowed = extract_flare_allowed_tags(allowed_tags)?;
    // SAFETY: We only inspect immediate Integers, nil, and RString byte slices inside this scope,
    // copying owned group results before allocating the output Ruby Hash/Arrays.
    let groups: Vec<(String, Vec<i64>)> = {
        let outer_slice = unsafe { pairs.as_slice() };
        let mut group_vec: Vec<(String, Vec<i64>)> = Vec::new();
        for &pair_val in outer_slice {
            let pair_arr = RArray::from_value(pair_val)?;
            let pair_slice = unsafe { pair_arr.as_slice() };
            if pair_slice.len() != 2 {
                return None;
            }
            let article_id = Integer::from_value(pair_slice[0])?.to_i64().ok()?;
            let tags_val = pair_slice[1];
            if tags_val.is_nil() {
                continue;
            }
            let rstr = RString::from_value(tags_val)?;
            if !rstr.is_utf8_compatible_encoding() {
                return None;
            }
            let text = unsafe { rstr.test_as_str() }?;
            if let Some(flare_tag) =
                forem_core::feed::match_first_flare_tag(text, allowed.as_deref())
            {
                if let Some(entry) = group_vec.iter_mut().find(|(name, _)| name == flare_tag) {
                    entry.1.push(article_id);
                } else {
                    group_vec.push((flare_tag.to_owned(), vec![article_id]));
                }
            }
        }
        group_vec
    };

    let out = ruby.hash_new_capa(groups.len());
    for (tag_name, ids) in groups {
        let id_ary = ruby.ary_new_capa(ids.len());
        for id in ids {
            id_ary.push(id).ok()?;
        }
        out.aset(ruby.str_new(&tag_name), id_ary).ok()?;
    }
    Some(out)
}

#[inline]
fn extract_lever_case_i64(val: Value) -> Option<i64> {
    if let Some(int) = Integer::from_value(val) {
        return int.to_i64().ok();
    }
    if let Some(fl) = Float::from_value(val) {
        let f = fl.to_f64();
        if f.is_finite() && f.abs() < ((1_i64 << 53) as f64) {
            return Some(f as i64);
        }
    }
    None
}

#[inline]
fn extract_lever_exact_f64(val: Value) -> Option<f64> {
    if let Some(fl) = Float::from_value(val) {
        let f = fl.to_f64();
        return f.is_finite().then_some(f);
    }
    if let Some(int) = Integer::from_value(val) {
        let i = int.to_i64().ok()?;
        if i.abs() < (1_i64 << 53) {
            return Some(i as f64);
        }
    }
    None
}

fn extract_lever_cases(cases_arr: RArray) -> Option<Vec<(i64, f64)>> {
    // SAFETY: `cases_arr.as_slice()` and each inner `pair_arr.as_slice()` only inspect
    // immediate Integer/Float values without calling into the Ruby VM.
    let slice = unsafe { cases_arr.as_slice() };
    let mut out = Vec::with_capacity(slice.len());
    for &item in slice {
        let pair_arr = RArray::from_value(item)?;
        let pair_slice = unsafe { pair_arr.as_slice() };
        if pair_slice.len() != 2 {
            return None;
        }
        let v = extract_lever_case_i64(pair_slice[0])?;
        let factor = extract_lever_exact_f64(pair_slice[1])?;
        out.push((v, factor));
    }
    Some(out)
}

fn build_relevancy_lever_sql(
    select_fragment: RString,
    cases: RArray,
    fallback: Value,
) -> Option<String> {
    if !select_fragment.is_utf8_compatible_encoding() {
        return None;
    }
    let parsed_cases = extract_lever_cases(cases)?;
    let fallback_f64 = extract_lever_exact_f64(fallback)?;
    // SAFETY: Zero-copy `RString` borrow; `forem_core` is pure Rust.
    let frag_str = unsafe { select_fragment.test_as_str() }?;
    forem_core::feed::build_relevancy_lever_sql(frag_str, &parsed_cases, fallback_f64)
}

type ParsedLeverTuple = (bool, String, Vec<(i64, f64)>, f64);

fn build_variant_relevancy_score_sql(
    levers: RArray,
    has_user: bool,
    minimize_ai: bool,
) -> Option<String> {
    // Copy Value handles first so `levers.as_slice()` is dropped before any `RStruct::aref` call.
    let items: Vec<Value> = unsafe { levers.as_slice() }.to_vec();
    let mut parsed_levers: Vec<ParsedLeverTuple> = Vec::with_capacity(items.len());

    for item in items {
        let (user_required, frag_val, cases_val, fallback_val) =
            if let Some(rstruct) = RStruct::from_value(item) {
                if rstruct.size() != 8 {
                    return None;
                }
                let ur = rstruct.aref::<usize, Value>(1).ok()?.to_bool();
                if ur && !has_user {
                    continue;
                }
                let fv = rstruct.aref::<usize, Value>(2).ok()?;
                let cv = rstruct.aref::<usize, Value>(5).ok()?;
                let fbv = rstruct.aref::<usize, Value>(6).ok()?;
                (ur, fv, cv, fbv)
            } else {
                let arr = RArray::from_value(item)?;
                let slice = unsafe { arr.as_slice() };
                match slice.len() {
                    3 => (false, slice[0], slice[1], slice[2]),
                    4 => {
                        let ur = slice[0].to_bool();
                        if ur && !has_user {
                            continue;
                        }
                        (ur, slice[1], slice[2], slice[3])
                    }
                    _ => return None,
                }
            };

        let frag_rstr = RString::from_value(frag_val)?;
        if !frag_rstr.is_utf8_compatible_encoding() {
            return None;
        }
        let frag_owned = unsafe { frag_rstr.test_as_str() }?.to_owned();
        let cases_arr = RArray::from_value(cases_val)?;
        let parsed_cases = extract_lever_cases(cases_arr)?;
        let fallback_f64 = extract_lever_exact_f64(fallback_val)?;
        parsed_levers.push((user_required, frag_owned, parsed_cases, fallback_f64));
    }

    let core_inputs: Vec<forem_core::feed::RelevancyLeverInput<'_>> = parsed_levers
        .iter()
        .map(
            |(ur, frag, cases, fb)| forem_core::feed::RelevancyLeverInput {
                user_required: *ur,
                select_fragment: frag.as_str(),
                cases: cases.clone(),
                fallback: *fb,
            },
        )
        .collect();

    forem_core::feed::build_variant_relevancy_score_sql(&core_inputs, has_user, minimize_ai)
}

fn classify_billboard_browser_context(ruby: &Ruby, user_agent: RString) -> Option<Symbol> {
    if !user_agent.is_utf8_compatible_encoding() {
        return None;
    }
    // SAFETY: `user_agent.as_slice()` is only read within pure-Rust `classify_billboard_browser_context`.
    let ctx =
        forem_core::metal::classify_billboard_browser_context(unsafe { user_agent.as_slice() })
            .unwrap_or("unknown");
    Some(ruby.to_symbol(ctx))
}

fn geolocation_code_covered_by(code: Value, geo_codes: RArray) -> Option<bool> {
    let code_rstr = if code.is_nil() {
        None
    } else {
        let s = RString::from_value(code)?;
        if !s.is_utf8_compatible_encoding() {
            return None;
        }
        Some(s)
    };

    let items: Vec<Option<RString>> = {
        // SAFETY: Only inspects immediate `Value` handles and `RString` headers without Ruby VM calls.
        let slice = unsafe { geo_codes.as_slice() };
        let mut out = Vec::with_capacity(slice.len());
        for &val in slice {
            if val.is_nil() {
                out.push(None);
            } else {
                let s = RString::from_value(val)?;
                if !s.is_utf8_compatible_encoding() {
                    return None;
                }
                out.push(Some(s));
            }
        }
        out
    };

    // SAFETY: `code_rstr` and `items` are borrowed in-place while pure-Rust `geolocation_code_covered_by` runs.
    let code_bytes: &[u8] = match &code_rstr {
        Some(s) => unsafe { s.as_slice() },
        None => b"",
    };
    let entry_slices: Vec<Option<&[u8]>> = items
        .iter()
        .map(|opt| opt.as_ref().map(|s| unsafe { s.as_slice() }))
        .collect();

    forem_core::metal::geolocation_code_covered_by(code_bytes, &entry_slices)
}

fn extract_viewer_country(ruby: &Ruby, geo: Value) -> Option<Value> {
    if geo.is_nil() {
        return Some(ruby.qfalse().as_value());
    }
    let rstr = RString::from_value(geo)?;
    if !rstr.is_utf8_compatible_encoding() {
        return None;
    }
    // SAFETY: `rstr.as_slice()` is only read inside pure-Rust `extract_viewer_country`.
    let matched = forem_core::metal::extract_viewer_country(unsafe { rstr.as_slice() })
        .map(|s| s.as_bytes().to_vec());
    match matched {
        Some(bytes) => {
            let s = std::str::from_utf8(&bytes).ok()?;
            Some(ruby.str_new(s).as_value())
        }
        None => Some(ruby.qfalse().as_value()),
    }
}

fn build_billboard_tag_clause_sql(
    tags: RArray,
    include_untagged: bool,
    optimized_taggable: bool,
) -> Option<String> {
    let owned_tags = extract_utf8_string_vec(tags)?;
    let refs: Vec<&str> = owned_tags.iter().map(String::as_str).collect();
    forem_core::metal::build_billboard_tag_clause_sql(&refs, include_untagged, optimized_taggable)
}

fn build_billboard_role_filter_sql(role_names: RArray) -> Option<String> {
    let owned_roles = extract_utf8_string_vec(role_names)?;
    let refs: Vec<&str> = owned_roles.iter().map(String::as_str).collect();
    forem_core::metal::build_billboard_role_filter_sql(&refs)
}

fn build_billboard_weighted_random_sql(
    base_query: RString,
    target_article_id: Value,
    low_impressions: Value,
    random_val: f64,
) -> Option<String> {
    if !base_query.is_utf8_compatible_encoding() {
        return None;
    }
    let aid = extract_optional_i64(target_article_id)?;
    let low_imp = extract_optional_i64(low_impressions)?;
    // SAFETY: Zero-copy `RString` borrow; `forem_core` is pure Rust.
    let base_str = unsafe { base_query.test_as_str() }?;
    forem_core::metal::build_billboard_weighted_random_sql(base_str, aid, low_imp, random_val)
}

fn build_billboard_new_only_sql(
    base_query: RString,
    low_impressions: i64,
    fallback_limit: i64,
) -> Option<String> {
    if !base_query.is_utf8_compatible_encoding() {
        return None;
    }
    // SAFETY: Zero-copy `RString` borrow; `forem_core` is pure Rust.
    let base_str = unsafe { base_query.test_as_str() }?;
    forem_core::metal::build_billboard_new_only_sql(base_str, low_impressions, fallback_limit)
}

fn build_filtered_ads_where_sql(params_arr: RArray) -> Option<String> {
    // SAFETY: `params_arr.as_slice()` is copied into local handles/primitives without calling into Ruby.
    let ps: Vec<Value> = unsafe { params_arr.as_slice() }.to_vec();
    if ps.len() < 23 {
        return None;
    }

    let area_rstr = RString::from_value(ps[0])?;
    if !area_rstr.is_utf8_compatible_encoding() {
        return None;
    }
    let area = unsafe { area_rstr.test_as_str() }?.to_owned();
    let now_sec = Integer::from_value(ps[1])?.to_i64().ok()?;
    let now_usec = Integer::from_value(ps[2])?.to_u32().ok()?;
    let verified_event_ids = if ps[3].is_nil() {
        Vec::new()
    } else {
        extract_strict_i64_vec(RArray::from_value(ps[3])?)?
    };
    let subforem_id = extract_optional_i64(ps[4])?;
    let fully_cached = ps[5].to_bool();
    let user_agent_rstr = if ps[6].is_nil() {
        None
    } else {
        let s = RString::from_value(ps[6])?;
        if !s.is_utf8_compatible_encoding() {
            return None;
        }
        Some(unsafe { s.as_slice() }.to_vec())
    };
    let page_id = extract_optional_i64(ps[7])?;
    let cookies_allowed = ps[8].to_bool();
    let article_id = extract_optional_i64(ps[9])?;
    let article_tags = if ps[10].is_nil() {
        Vec::new()
    } else {
        extract_utf8_string_vec(RArray::from_value(ps[10])?)?
    };
    let user_tags = if ps[11].is_nil() {
        Vec::new()
    } else {
        extract_utf8_string_vec(RArray::from_value(ps[11])?)?
    };
    let has_user_tags = ps[12].to_bool();
    let optimized_taggable = ps[13].to_bool();
    let user_signed_in = ps[14].to_bool();
    let user_id = extract_optional_i64(ps[15])?;
    let role_names = if ps[16].is_nil() {
        Vec::new()
    } else {
        extract_utf8_string_vec(RArray::from_value(ps[16])?)?
    };
    let location_targeting_enabled = ps[17].to_bool();
    let location_sql_clause = extract_optional_utf8_string(ps[18])?;
    let include_post_type_of = ps[19].to_bool();
    let permit_adjacent_sponsors = ps[20].to_bool();
    let paused_org_ids = if ps[21].is_nil() {
        Vec::new()
    } else {
        extract_strict_i64_vec(RArray::from_value(ps[21])?)?
    };
    let skip_survey_filtering = ps[22].to_bool();

    let article_tag_refs: Vec<&str> = article_tags.iter().map(String::as_str).collect();
    let user_tag_refs: Vec<&str> = user_tags.iter().map(String::as_str).collect();
    let role_refs: Vec<&str> = role_names.iter().map(String::as_str).collect();

    let core_params = forem_core::metal::FilteredAdsWhereParams {
        area: &area,
        now_sec,
        now_usec,
        verified_event_ids: &verified_event_ids,
        subforem_id,
        fully_cached,
        user_agent: user_agent_rstr.as_deref(),
        page_id,
        cookies_allowed,
        article_id,
        article_tags: &article_tag_refs,
        user_tags: &user_tag_refs,
        has_user_tags,
        optimized_taggable,
        user_signed_in,
        user_id,
        role_names: &role_refs,
        location_targeting_enabled,
        location_sql_clause: location_sql_clause.as_deref(),
        include_post_type_of,
        permit_adjacent_sponsors,
        paused_org_ids: &paused_org_ids,
        skip_survey_filtering,
    };

    forem_core::metal::build_filtered_ads_where_sql(&core_params)
}

fn syntax_supported_language_tags(ruby: &Ruby) -> Option<RArray> {
    let tags = forem_core::syntax::supported_language_tags();
    let ary = ruby.ary_new_capa(tags.len());
    for &tag in tags {
        ary.push(ruby.str_new(tag)).ok()?;
    }
    Some(ary)
}

fn syntax_language_criteria(ruby: &Ruby) -> Option<RHash> {
    let hash = ruby.hash_new_capa(forem_core::syntax::supported_language_tags().len());
    for (tag, desc) in forem_core::syntax::language_criteria_entries() {
        hash.aset(ruby.str_new(tag), ruby.str_new(desc)).ok()?;
    }
    Some(hash)
}

fn syntax_lexer_tag(name: RString) -> Option<&'static str> {
    if !name.is_utf8_compatible_encoding() {
        return None;
    }
    let s = unsafe { name.test_as_str() }?;
    forem_core::syntax::find_lexer_tag(s)
}

fn syntax_normalize_language(language: RString) -> Option<&'static str> {
    if !language.is_utf8_compatible_encoding() {
        return None;
    }
    let s = unsafe { language.test_as_str() }?;
    Some(forem_core::syntax::normalize_language_tag(s))
}

fn syntax_find_fancy_tag(lang: Value, code: Value, rescue_ambiguous: bool) -> Option<&'static str> {
    let lang_str = extract_optional_utf8_string(lang)?;
    let code_str = extract_optional_utf8_string(code)?;
    forem_core::syntax::find_fancy_tag(lang_str.as_deref(), code_str.as_deref(), rescue_ambiguous)
}

fn syntax_language_from_path(path: RString) -> Option<&'static str> {
    if !path.is_utf8_compatible_encoding() {
        return None;
    }
    let s = unsafe { path.test_as_str() }?;
    forem_core::syntax::language_from_path(s)
}

fn syntax_highlight_html(code: RString, lang: Value) -> Option<String> {
    if !code.is_utf8_compatible_encoding() {
        return None;
    }
    let code_str = unsafe { code.test_as_str() }?;
    let lang_str = extract_optional_utf8_string(lang)?;
    Some(forem_core::syntax::highlight_html(
        code_str,
        lang_str.as_deref(),
    ))
}

fn syntax_highlight_code_block(code: RString, lang: Value) -> Option<String> {
    if !code.is_utf8_compatible_encoding() {
        return None;
    }
    let code_str = unsafe { code.test_as_str() }?;
    let lang_str = extract_optional_utf8_string(lang)?;
    Some(forem_core::syntax::highlight_code_block(
        code_str,
        lang_str.as_deref(),
    ))
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
    native_mod.define_singleton_method("color_accent", function!(color_accent, 2))?;
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
    native_mod.define_singleton_method(
        "fixer_convert_new_lines",
        function!(fixer_convert_new_lines, 1),
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
    native_mod.define_singleton_method("fixer_fix_all", function!(fixer_fix_all, 1))?;
    native_mod
        .define_singleton_method("fixer_fix_for_preview", function!(fixer_fix_for_preview, 1))?;
    native_mod
        .define_singleton_method("fixer_fix_for_comment", function!(fixer_fix_for_comment, 1))?;
    native_mod.define_singleton_method(
        "preprocess_markdown_for_finalize",
        function!(preprocess_markdown_for_finalize, 1),
    )?;
    native_mod.define_singleton_method(
        "contains_unlabeled_code_blocks",
        function!(contains_unlabeled_code_blocks, 1),
    )?;
    native_mod.define_singleton_method(
        "extract_unlabeled_code_blocks",
        function!(extract_unlabeled_code_blocks, 1),
    )?;
    native_mod.define_singleton_method(
        "apply_code_block_languages",
        function!(apply_code_block_languages, 2),
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
    native_mod.define_singleton_method("title_for_metadata", function!(title_for_metadata, 1))?;
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
    native_mod.define_singleton_method("full_sanitize", function!(full_sanitize, 1))?;
    native_mod.define_singleton_method(
        "slugify_heading_anchor",
        function!(slugify_heading_anchor, 1),
    )?;
    native_mod.define_singleton_method("beautified_url", function!(beautified_url, 1))?;
    native_mod.define_singleton_method("parse_emojis", function!(parse_emojis, 1))?;
    native_mod.define_singleton_method(
        "escape_colon_emojis_in_codeblock",
        function!(escape_colon_emojis_in_codeblock, 1),
    )?;
    native_mod.define_singleton_method("emoji_by_alias", function!(emoji_by_alias, 1))?;
    native_mod.define_singleton_method("strip_rgi_emoji", function!(strip_rgi_emoji, 1))?;
    native_mod.define_singleton_method("wcag_contrast_ratio", function!(wcag_contrast_ratio, 2))?;
    native_mod.define_singleton_method(
        "activity_distinct_days_since",
        function!(activity_distinct_days_since, 3),
    )?;
    native_mod.define_singleton_method(
        "activity_pageviews_since",
        function!(activity_pageviews_since, 3),
    )?;
    native_mod
        .define_singleton_method("dynamic_shuffle_count", function!(dynamic_shuffle_count, 4))?;
    native_mod.define_singleton_method("weighted_shuffle", function!(weighted_shuffle, 3))?;
    native_mod
        .define_singleton_method("format_video_duration", function!(format_video_duration, 1))?;
    native_mod.define_singleton_method("sql_int_list", function!(sql_int_list, 2))?;
    native_mod.define_singleton_method(
        "sql_string_array_literal",
        function!(sql_string_array_literal, 2),
    )?;
    native_mod.define_singleton_method("sql_vector_literal", function!(sql_vector_literal, 1))?;
    native_mod.define_singleton_method("sql_squish", function!(sql_squish, 1))?;
    native_mod
        .define_singleton_method("feed_config_score_sql", function!(feed_config_score_sql, 2))?;
    native_mod.define_singleton_method("score_followed_tags", function!(score_followed_tags, 5))?;
    native_mod.define_singleton_method(
        "score_experience_level",
        function!(score_experience_level, 3),
    )?;
    native_mod.define_singleton_method("score_ai_disclosure", function!(score_ai_disclosure, 4))?;
    native_mod.define_singleton_method(
        "score_article_for_user",
        function!(score_article_for_user, 8),
    )?;
    native_mod.define_singleton_method(
        "rank_articles_for_basic_feed",
        function!(rank_articles_for_basic_feed, 3),
    )?;
    native_mod.define_singleton_method(
        "filter_tracked_article_ids",
        function!(filter_tracked_article_ids, 2),
    )?;
    native_mod.define_singleton_method(
        "aggregate_recent_activity_metadata",
        function!(aggregate_recent_activity_metadata, 6),
    )?;
    native_mod.define_singleton_method("order_subforem_ids", function!(order_subforem_ids, 3))?;
    native_mod.define_singleton_method(
        "build_activity_heatmap_payload",
        function!(build_activity_heatmap_payload, 5),
    )?;
    native_mod.define_singleton_method(
        "link_heading_anchor_fragments",
        function!(link_heading_anchor_fragments, 2),
    )?;
    native_mod
        .define_singleton_method("scrub_sensitive_text", function!(scrub_sensitive_text, 2))?;
    native_mod.define_singleton_method(
        "scrub_sensitive_text_with_counts",
        function!(scrub_sensitive_text_with_counts, 2),
    )?;
    native_mod.define_singleton_method(
        "scrub_agent_session_messages",
        function!(scrub_agent_session_messages, 1),
    )?;
    native_mod.define_singleton_method(
        "add_control_class_to_codeblock",
        function!(add_control_class_to_codeblock, 1),
    )?;
    native_mod.define_singleton_method(
        "add_control_panel_to_codeblock",
        function!(add_control_panel_to_codeblock, 1),
    )?;
    native_mod.define_singleton_method(
        "wrap_untagged_codeblocks",
        function!(wrap_untagged_codeblocks, 1),
    )?;
    native_mod.define_singleton_method(
        "style_redaction_markers",
        function!(style_redaction_markers, 1),
    )?;
    native_mod.define_singleton_method(
        "postprocess_transcript_html",
        function!(postprocess_transcript_html, 2),
    )?;
    native_mod.define_singleton_method("wrap_all_tables", function!(wrap_all_tables, 1))?;
    native_mod.define_singleton_method(
        "remove_empty_paragraphs",
        function!(remove_empty_paragraphs, 1),
    )?;
    native_mod.define_singleton_method(
        "wrap_all_images_in_links",
        function!(wrap_all_images_in_links, 1),
    )?;
    native_mod.define_singleton_method(
        "unescape_raw_tag_in_codeblocks",
        function!(unescape_raw_tag_in_codeblocks, 1),
    )?;
    native_mod.define_singleton_method(
        "extract_mention_usernames",
        function!(extract_mention_usernames, 1),
    )?;
    native_mod.define_singleton_method(
        "wrap_mentions_with_links",
        function!(wrap_mentions_with_links, 3),
    )?;
    native_mod.define_singleton_method(
        "extract_mentioned_usernames",
        function!(extract_mentioned_usernames, 1),
    )?;
    native_mod.define_singleton_method(
        "calendar_grid_days_html",
        function!(calendar_grid_days_html, 10),
    )?;
    native_mod.define_singleton_method("json_quote", function!(json_quote, 2))?;
    native_mod.define_singleton_method("encode_json", function!(encode_json, 2))?;
    native_mod.define_singleton_method("json_encoded_size", function!(json_encoded_size, 2))?;
    native_mod.define_singleton_method(
        "truncate_feed_xml_items",
        function!(truncate_feed_xml_items, 2),
    )?;
    native_mod.define_singleton_method("feed_html_content", function!(feed_html_content, 1))?;
    native_mod.define_singleton_method(
        "postprocess_feed_markdown",
        function!(postprocess_feed_markdown, 1),
    )?;
    native_mod.define_singleton_method(
        "resolve_feed_markdown_images",
        function!(resolve_feed_markdown_images, 3),
    )?;
    native_mod.define_singleton_method("format_feed_tags", function!(format_feed_tags, 1))?;
    native_mod.define_singleton_method("extract_feed_author", function!(extract_feed_author, 1))?;
    native_mod.define_singleton_method("sanitize_feed_error", function!(sanitize_feed_error, 1))?;
    native_mod.define_singleton_method(
        "verify_authenticity_token",
        function!(verify_authenticity_token, 4),
    )?;
    native_mod.define_singleton_method("verify_hs256_jwt", function!(verify_hs256_jwt, 3))?;
    native_mod.define_singleton_method(
        "billboard_event_update_sql",
        function!(billboard_event_update_sql, 7),
    )?;
    native_mod.define_singleton_method(
        "billboard_event_insert_sql",
        function!(billboard_event_insert_sql, 1),
    )?;
    native_mod
        .define_singleton_method("origin_in_comma_list", function!(origin_in_comma_list, 2))?;
    native_mod.define_singleton_method("valid_uuid", function!(valid_uuid, 1))?;
    native_mod.define_singleton_method(
        "feed_events_advisory_lock_key",
        function!(feed_events_advisory_lock_key, 1),
    )?;
    native_mod
        .define_singleton_method("valid_request_origin", function!(valid_request_origin, 5))?;
    native_mod.define_singleton_method(
        "extract_referrer_domain_and_path",
        function!(extract_referrer_domain_and_path, 1),
    )?;
    native_mod.define_singleton_method(
        "match_metal_telemetry_route",
        function!(match_metal_telemetry_route, 2),
    )?;
    native_mod.define_singleton_method(
        "billboard_event_create_from_json_sql",
        function!(billboard_event_create_from_json_sql, 7),
    )?;
    native_mod.define_singleton_method(
        "extract_ga_event_params",
        function!(extract_ga_event_params, 3),
    )?;
    native_mod.define_singleton_method(
        "validate_and_normalize_feed_events",
        function!(validate_and_normalize_feed_events, 1),
    )?;
    native_mod.define_singleton_method("encode_hs256_jwt", function!(encode_hs256_jwt, 3))?;
    native_mod.define_singleton_method(
        "mask_authenticity_token",
        function!(mask_authenticity_token, 2),
    )?;
    native_mod.define_singleton_method(
        "parse_auth_pass_origin",
        function!(parse_auth_pass_origin, 1),
    )?;
    native_mod
        .define_singleton_method("build_base_data_json", function!(build_base_data_json, 7))?;
    native_mod.define_singleton_method(
        "resolve_bulk_follow_json",
        function!(resolve_bulk_follow_json, 5),
    )?;
    native_mod.define_singleton_method(
        "extract_liquid_embed_tags",
        function!(extract_liquid_embed_tags, 1),
    )?;
    native_mod.define_singleton_method(
        "extract_markdown_webpage_urls",
        function!(extract_markdown_webpage_urls, 1),
    )?;
    native_mod.define_singleton_method(
        "extract_markdown_and_html_image_urls",
        function!(extract_markdown_and_html_image_urls, 2),
    )?;
    native_mod.define_singleton_method("clean_tag_list", function!(clean_tag_list, 1))?;
    native_mod
        .define_singleton_method("match_first_flare_tag", function!(match_first_flare_tag, 2))?;
    native_mod.define_singleton_method(
        "match_articles_flare_tags",
        function!(match_articles_flare_tags, 2),
    )?;
    native_mod.define_singleton_method(
        "build_relevancy_lever_sql",
        function!(build_relevancy_lever_sql, 3),
    )?;
    native_mod.define_singleton_method(
        "build_variant_relevancy_score_sql",
        function!(build_variant_relevancy_score_sql, 3),
    )?;
    native_mod.define_singleton_method(
        "classify_billboard_browser_context",
        function!(classify_billboard_browser_context, 1),
    )?;
    native_mod.define_singleton_method(
        "geolocation_code_covered_by",
        function!(geolocation_code_covered_by, 2),
    )?;
    native_mod.define_singleton_method(
        "extract_viewer_country",
        function!(extract_viewer_country, 1),
    )?;
    native_mod.define_singleton_method(
        "build_billboard_tag_clause_sql",
        function!(build_billboard_tag_clause_sql, 3),
    )?;
    native_mod.define_singleton_method(
        "build_billboard_role_filter_sql",
        function!(build_billboard_role_filter_sql, 1),
    )?;
    native_mod.define_singleton_method(
        "build_billboard_weighted_random_sql",
        function!(build_billboard_weighted_random_sql, 4),
    )?;
    native_mod.define_singleton_method(
        "build_billboard_new_only_sql",
        function!(build_billboard_new_only_sql, 3),
    )?;
    native_mod.define_singleton_method(
        "build_filtered_ads_where_sql",
        function!(build_filtered_ads_where_sql, 1),
    )?;
    native_mod.define_singleton_method(
        "syntax_supported_language_tags",
        function!(syntax_supported_language_tags, 0),
    )?;
    native_mod.define_singleton_method(
        "syntax_language_criteria",
        function!(syntax_language_criteria, 0),
    )?;
    native_mod.define_singleton_method("syntax_lexer_tag", function!(syntax_lexer_tag, 1))?;
    native_mod.define_singleton_method(
        "syntax_normalize_language",
        function!(syntax_normalize_language, 1),
    )?;
    native_mod
        .define_singleton_method("syntax_find_fancy_tag", function!(syntax_find_fancy_tag, 3))?;
    native_mod.define_singleton_method(
        "syntax_language_from_path",
        function!(syntax_language_from_path, 1),
    )?;
    native_mod
        .define_singleton_method("syntax_highlight_html", function!(syntax_highlight_html, 2))?;
    native_mod.define_singleton_method(
        "syntax_highlight_code_block",
        function!(syntax_highlight_code_block, 2),
    )?;
    Ok(())
}
