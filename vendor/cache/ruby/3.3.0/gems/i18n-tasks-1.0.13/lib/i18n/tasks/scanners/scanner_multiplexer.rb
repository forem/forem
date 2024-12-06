# frozen_string_literal: true

require 'i18n/tasks/scanners/scanner'

module I18n::Tasks::Scanners
  # Run multiple {Scanner Scanners} and merge their results.
  # @note The scanners are run concurrently. A thread is spawned per each scanner.
  # @since 0.9.0
  class ScannerMultiplexer < Scanner
    # @param scanners [Array<Scanner>]
    def initialize(scanners:)
      super()
      @scanners = scanners
    end

    # Collect the results of all the scanners. Occurrences of a key from multiple scanners are merged.
    #
    # @note The scanners are run concurrently. A thread is spawned per each scanner.
    # @return (see Scanner#keys)
    def keys
      Results::KeyOccurrences.merge_keys collect_results.flatten(1)
    end

    private

    # @return [Array<Array<Results::KeyOccurrences>>]
    def collect_results
      return [@scanners[0].keys] if @scanners.length == 1

      Array.new(@scanners.length).tap do |results|
        results_mutex = Mutex.new
        @scanners.map.with_index do |scanner, i|
          Thread.start do
            scanner_results = scanner.keys
            results_mutex.synchronize do
              results[i] = scanner_results
            end
          end
        end.each(&:join)
      end
    end
  end
end
