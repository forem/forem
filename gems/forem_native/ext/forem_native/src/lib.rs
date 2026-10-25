use std::borrow::Cow;

use magnus::{function, prelude::*, Error, RString, Ruby};

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
    Ok(())
}
