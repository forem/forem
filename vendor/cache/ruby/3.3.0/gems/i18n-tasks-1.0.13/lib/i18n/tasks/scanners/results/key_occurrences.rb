# frozen_string_literal: true

require 'i18n/tasks/scanners/results/occurrence'

module I18n::Tasks::Scanners::Results
  # A scanned key and all its occurrences.
  #
  # @note This is a value type. Equality and hash code are determined from the attributes.
  class KeyOccurrences
    # @return [String] the key.
    attr_reader :key

    # @return [Array<Occurrence>] the key's occurrences.
    attr_reader :occurrences

    def initialize(key:, occurrences:)
      @key         = key
      @occurrences = occurrences
    end

    def ==(other)
      other.key == @key && other.occurrences == @occurrences
    end

    def eql?(other)
      self == other
    end

    def hash
      [@key, @occurrences].hash
    end

    def inspect
      "KeyOccurrences(#{key.inspect}, [#{occurrences.map(&:inspect).join(', ')}])"
    end

    # Merge {KeyOccurrences} in an {Enumerable<KeyOccurrences>} so that in the resulting {Array<KeyOccurrences>}:
    # * Each key occurs only once.
    # * {Occurrence}s from multiple instances of the key are merged.
    # * The order of keys is preserved, occurrences are ordered by {Occurrence#path}.
    # @param keys_occurrences [Enumerable<KeyOccurrences>]
    # @return [Array<KeyOccurrences>] a new array.
    def self.merge_keys(keys_occurrences)
      keys_occurrences.each_with_object({}) do |key_occurrences, results_by_key|
        (results_by_key[key_occurrences.key] ||= []) << key_occurrences.occurrences
      end.map do |key, all_occurrences|
        occurrences = all_occurrences.flatten(1)
        occurrences.sort_by!(&:path)
        occurrences.uniq!
        new(key: key, occurrences: occurrences)
      end
    end
  end
end
