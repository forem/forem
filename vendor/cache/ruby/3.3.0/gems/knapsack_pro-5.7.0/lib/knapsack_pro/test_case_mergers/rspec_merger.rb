# frozen_string_literal: true

module KnapsackPro
  module TestCaseMergers
    class RSpecMerger < BaseMerger
      def call
        merged_test_files_hash = {}
        test_files.each do |test_file|
          test_file_path = extract_test_file_path(test_file.fetch('path'))

          # must be float (default type for time execution from API)
          merged_test_files_hash[test_file_path] ||= 0.0
          merged_test_files_hash[test_file_path] += test_file.fetch('time_execution')
        end

        merged_test_files = []
        merged_test_files_hash.each do |path, time_execution|
          merged_test_files << {
            'path' => path,
            'time_execution' => time_execution
          }
        end
        merged_test_files
      end

      private

      # path - can be:
      # test file path: spec/a_spec.rb
      # or test example path: spec/a_spec.rb[1:1]
      def extract_test_file_path(path)
        path.gsub(/\.rb\[.+\]$/, '.rb')
      end
    end
  end
end
