# frozen_string_literal: true

module KnapsackPro
  module TestCaseMergers
    class BaseMerger
      # values must be string to avoid circular dependency problem during loading files
      ADAPTER_TO_MERGER_MAP = {
        KnapsackPro::Adapters::RSpecAdapter => 'KnapsackPro::TestCaseMergers::RSpecMerger',
      }

      def self.call(adapter_class, test_files)
        merger_class =
          ADAPTER_TO_MERGER_MAP[adapter_class] ||
          raise("Test case merger does not exist for adapter_class: #{adapter_class}")
        Kernel.const_get(merger_class).new(test_files).call
      end

      def initialize(test_files)
        @test_files = test_files
      end

      def call
        raise NotImplementedError
      end

      private

      attr_reader :test_files
    end
  end
end
