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
    Ok(())
}
