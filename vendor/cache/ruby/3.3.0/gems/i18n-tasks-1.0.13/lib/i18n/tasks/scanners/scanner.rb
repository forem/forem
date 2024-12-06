# frozen_string_literal: true

require 'i18n/tasks/scanners/results/key_occurrences'

module I18n::Tasks::Scanners
  # Describes the API of a scanner.
  #
  # @abstract
  # @since 0.9.0
  class Scanner
    # @abstract
    # @return [Array<Results::KeyOccurrences>] the keys found by this scanner and their occurrences.
    def keys
      fail 'Unimplemented'
    end
  end
end
