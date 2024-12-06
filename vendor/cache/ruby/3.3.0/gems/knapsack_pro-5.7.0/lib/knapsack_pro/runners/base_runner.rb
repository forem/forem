# frozen_string_literal: true

module KnapsackPro
  module Runners
    class BaseRunner
      def self.run(args)
        raise NotImplementedError
      end

      def initialize(adapter_class)
        @allocator_builder = KnapsackPro::AllocatorBuilder.new(adapter_class)
        @allocator = allocator_builder.allocator
      end

      def test_file_paths
        @test_file_paths ||= allocator.test_file_paths
      end

      def stringify_test_file_paths
        KnapsackPro::TestFilePresenter.stringify_paths(test_file_paths)
      end

      def test_dir
        allocator_builder.test_dir
      end

      def test_files_to_execute_exist?
        if test_file_paths.empty?
          KnapsackPro.logger.info("Knapsack Pro API returned no test files to execute for the node this time. The reason might be that you changed recently a number of total nodes or you removed some test files. Please create a new commit to get a better test suite split next time.")
          false
        else
          true
        end
      end

      private

      attr_reader :allocator_builder,
        :allocator

      def self.child_status
        $?
      end
    end
  end
end
