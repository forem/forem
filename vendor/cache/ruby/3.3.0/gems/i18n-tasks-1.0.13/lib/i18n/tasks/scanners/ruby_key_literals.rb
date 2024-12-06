# frozen_string_literal: true

module I18n::Tasks::Scanners
  module RubyKeyLiterals
    LITERAL_RE = /:?".+?"|:?'.+?'|:\w+/.freeze

    # Match literals:
    # * String: '', "#{}"
    # * Symbol: :sym, :'', :"#{}"
    def literal_re
      LITERAL_RE
    end

    # remove the leading colon and unwrap quotes from the key match
    # @param literal [String] e.g: "key", 'key', or :key.
    # @return [String] key
    def strip_literal(literal)
      literal = literal[1..] if literal[0] == ':'
      literal = literal[1..-2] if literal[0] == "'" || literal[0] == '"'
      literal
    end

    VALID_KEY_CHARS = %r{(?:[[:word:]]|[-.?!:;À-ž/])}.freeze
    VALID_KEY_RE    = /^#{VALID_KEY_CHARS}+$/.freeze

    def valid_key?(key)
      key =~ VALID_KEY_RE && !key.end_with?('.')
    end
  end
end
