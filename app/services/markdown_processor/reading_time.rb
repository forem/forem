module MarkdownProcessor
  # Calculates estimated reading time (in minutes) for Markdown content.
  #
  # Uses `ForemNative.calculate_reading_time` (backed by the `forem_core` Rust crate
  # via `magnus`) when the native extension is loaded and the `:native_reading_time`
  # feature flag is enabled, falling back transparently to the pure-Ruby implementation
  # otherwise.
  module ReadingTime
    WORDS_READ_PER_MINUTE = 275.0
    FEATURE_FLAG = :native_reading_time

    def self.calculate(content)
      text = content.to_s
      if native_enabled?
        ForemNative.calculate_reading_time(text)
      else
        legacy_ruby_calculate(text)
      end
    end

    def self.native_enabled?
      ForemNative.available? && FeatureFlag.enabled?(FEATURE_FLAG)
    end

    def self.legacy_ruby_calculate(content)
      word_count = content.to_s.split(/\W+/).count
      (word_count / WORDS_READ_PER_MINUTE).ceil
    end
  end
end
