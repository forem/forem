module ForemNative
  # Pure-Ruby reference implementation used automatically whenever the native
  # Rust extension (`ForemNative::Native`) is not compiled for the current host
  # platform or when fallback mode is explicitly requested in tests.
  module RubyFallback
    WORDS_READ_PER_MINUTE = 275.0
    NON_WORD_REGEXP = /\W+/

    def self.split_word_count(content)
      content.to_s.split(NON_WORD_REGEXP).count
    end

    def self.calculate_reading_time(content)
      word_count = split_word_count(content)
      (word_count / WORDS_READ_PER_MINUTE).ceil
    end
  end
end
