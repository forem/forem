module Languages
  class Detection
    attr_reader :text

    PROBABILITY_THRESHOLD = 0.5

    def self.call(...)
      new(...).call
    end

    def initialize(text)
      @text = text
    end

    def call(identifier: CLD3::NNetLanguageIdentifier.new(0, 1000))
      language_outcome = identifier.find_language(text)
      return unless language_outcome.probability > PROBABILITY_THRESHOLD && language_outcome.reliable?

      language_outcome.language
    end
  end
end
