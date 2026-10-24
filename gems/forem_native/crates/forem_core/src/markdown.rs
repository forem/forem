/// Words read per minute constant matching `MarkdownProcessor::Parser::WORDS_READ_PER_MINUTE`.
pub const WORDS_READ_PER_MINUTE: usize = 275;

#[inline]
const fn is_ascii_word_byte(byte: u8) -> bool {
    byte.is_ascii_alphanumeric() || byte == b'_'
}

/// Counts tokens produced by Ruby's `content.split(/\W+/).count` in a single zero-allocation pass.
///
/// ### Behavioral Equivalence Notes
/// In Ruby, `/\W+/` (without the `/u` flag) defines word characters strictly as ASCII `[a-zA-Z0-9_]`.
/// Furthermore, `String#split(pattern)` with default `limit = 0`:
/// - Returns `[]` (`0` tokens) when the string is empty or contains only non-word bytes.
/// - Strips all trailing empty fields when the string ends with `/\W+/`.
/// - Preserves a single leading `""` token when the string starts with a non-word byte (`/\W+/`)
///   and contains at least one ASCII word run after it.
#[inline]
pub fn split_word_count_bytes(bytes: &[u8]) -> usize {
    let mut word_runs = 0usize;
    let mut in_word = false;

    for &byte in bytes {
        if is_ascii_word_byte(byte) {
            if !in_word {
                word_runs += 1;
                in_word = true;
            }
        } else {
            in_word = false;
        }
    }

    if word_runs == 0 {
        return 0;
    }

    let starts_with_non_word = !is_ascii_word_byte(bytes[0]);
    word_runs + usize::from(starts_with_non_word)
}

/// Convenience wrapper around [`split_word_count_bytes`] for UTF-8 `&str` slices.
#[inline]
pub fn split_word_count(text: &str) -> usize {
    split_word_count_bytes(text.as_bytes())
}

/// Calculates estimated reading time in minutes, matching
/// `(content.split(/\W+/).count / 275.0).ceil` in `MarkdownProcessor::Parser#calculate_reading_time`.
#[inline]
pub fn calculate_reading_time_bytes(bytes: &[u8]) -> usize {
    let word_count = split_word_count_bytes(bytes);
    word_count.div_ceil(WORDS_READ_PER_MINUTE)
}

/// Convenience wrapper around [`calculate_reading_time_bytes`] for UTF-8 `&str` slices.
#[inline]
pub fn calculate_reading_time(text: &str) -> usize {
    calculate_reading_time_bytes(text.as_bytes())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_and_non_word_only_strings_return_zero() {
        assert_eq!(split_word_count(""), 0);
        assert_eq!(calculate_reading_time(""), 0);

        assert_eq!(split_word_count("   \n\t\r  "), 0);
        assert_eq!(calculate_reading_time("   \n\t\r  "), 0);

        assert_eq!(split_word_count("... --- !!! ???"), 0);
        assert_eq!(calculate_reading_time("... --- !!! ???"), 0);

        assert_eq!(split_word_count("🚀 🌟 🎉"), 0);
        assert_eq!(calculate_reading_time("🚀 🌟 🎉"), 0);
    }

    #[test]
    fn basic_word_counting_and_reading_time() {
        assert_eq!(split_word_count("hello"), 1);
        assert_eq!(calculate_reading_time("hello"), 1);

        assert_eq!(split_word_count("hello world"), 2);
        assert_eq!(calculate_reading_time("hello world"), 1);

        assert_eq!(split_word_count("foo_bar_123 baz"), 2);
        assert_eq!(calculate_reading_time("foo_bar_123 baz"), 1);
    }

    #[test]
    fn preserves_ruby_split_leading_delimiter_semantics() {
        // In Ruby: "  hello world  ".split(/\W+/) => ["", "hello", "world"] (count = 3)
        assert_eq!(split_word_count("  hello world  "), 3);
        assert_eq!(split_word_count("...hello...world..."), 3);
        assert_eq!(split_word_count("\n\thello\n"), 2);
        assert_eq!(split_word_count("🚀 hello 🌟"), 2);
        assert_eq!(split_word_count("café résumé"), 3);
    }

    #[test]
    fn reading_time_boundaries_match_ceil_division() {
        let words_275 = (0..275).map(|_| "word").collect::<Vec<_>>().join(" ");
        assert_eq!(split_word_count(&words_275), 275);
        assert_eq!(calculate_reading_time(&words_275), 1);

        let words_276 = (0..276).map(|_| "word").collect::<Vec<_>>().join(" ");
        assert_eq!(split_word_count(&words_276), 276);
        assert_eq!(calculate_reading_time(&words_276), 2);

        // Leading non-word char pushes 275 words to 276 tokens in Ruby's `split(/\W+/)`
        let leading_space_275 = format!(" {words_275}");
        assert_eq!(split_word_count(&leading_space_275), 276);
        assert_eq!(calculate_reading_time(&leading_space_275), 2);

        let words_550 = (0..550).map(|_| "word").collect::<Vec<_>>().join(" ");
        assert_eq!(calculate_reading_time(&words_550), 2);

        let words_551 = (0..551).map(|_| "word").collect::<Vec<_>>().join(" ");
        assert_eq!(calculate_reading_time(&words_551), 3);
    }
}
