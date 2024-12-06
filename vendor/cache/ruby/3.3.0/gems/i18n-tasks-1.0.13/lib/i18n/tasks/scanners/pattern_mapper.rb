# frozen_string_literal: true

require 'i18n/tasks/scanners/file_scanner'
require 'i18n/tasks/scanners/relative_keys'
require 'i18n/tasks/scanners/occurrence_from_position'
require 'i18n/tasks/scanners/ruby_key_literals'

module I18n::Tasks::Scanners
  # Maps the provided patterns to keys.
  class PatternMapper < FileScanner
    include I18n::Tasks::Scanners::RelativeKeys
    include I18n::Tasks::Scanners::OccurrenceFromPosition
    include I18n::Tasks::Scanners::RubyKeyLiterals

    # @param patterns [Array<[String, String]> the list of pattern-key pairs
    #   the patterns follow the regular expression syntax, with a syntax addition for matching
    #   string/symbol literals: you can include %{key} in the pattern, and it will be converted to
    #   a named capture group, capturing ruby strings and symbols, that can then be used in the key:
    #
    #       patterns: [['Spree\.t[( ]\s*%{key}', 'spree.%{key}']]
    #
    #   All of the named capture groups are interpolated into the key with %{group_name} interpolations.
    #
    def initialize(config:, **args)
      super
      @patterns = configure_patterns(config[:patterns] || [])
    end

    protected

    # @return [Array<[absolute key, Results::Occurrence]>]
    def scan_file(path)
      text = read_file(path)
      @patterns.flat_map do |pattern, key|
        result = []
        text.scan(pattern) do |_|
          match    = Regexp.last_match
          matches  = match.names.map(&:to_sym).zip(match.captures).to_h
          if matches.key?(:key)
            matches[:key] = strip_literal(matches[:key])
            next unless valid_key?(matches[:key])
          end
          result << [absolute_key(format(key, matches), path),
                     occurrence_from_position(path, text, match.offset(0).first)]
        end
        result
      end
    end

    private

    KEY_GROUP = "(?<key>#{LITERAL_RE})"

    def configure_patterns(patterns)
      patterns.map do |(pattern, key)|
        [pattern.is_a?(Regexp) ? pattern : Regexp.new(format(pattern, key: KEY_GROUP)), key]
      end
    end
  end
end
