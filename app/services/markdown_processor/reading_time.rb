module MarkdownProcessor
  # Calculates estimated reading time (in minutes) for Markdown content
  # using `ForemNative.calculate_reading_time` (backed by the `forem_core`
  # Rust crate via `magnus`).
  module ReadingTime
    WORDS_READ_PER_MINUTE = 275.0

    def self.calculate(content)
      ForemNative.calculate_reading_time(content.to_s)
    end
  end
end
