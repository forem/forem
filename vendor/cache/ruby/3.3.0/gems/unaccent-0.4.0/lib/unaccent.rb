# frozen_string_literal: true

require 'unaccent/version'

# Replace accented characters with unaccented characters in a string.
module Unaccent
  autoload :ACCENTMAP, 'unaccent/accentmap'

  class << self
    # Replace a string's accented characters with unaccented characters.
    #
    # @example
    #   str = 'Å Ç ß'
    #   Unaccent.unaccent(str) = > 'AA C ss'
    #
    # @return [String] a string that has no accents

    def unaccent(str)
      return str if str.ascii_only?

      str.gsub(/[^[:ascii:]]/) { |char| ACCENTMAP.fetch(char, char) }
    end
  end
end
