# frozen_string_literal: true

module KnapsackPro
  class TestFilesWithTestCasesComposer
    # Args:
    #   All 3 arguments have structure: [{ 'path' => 'spec/a_spec.rb', 'time_execution' => 0.0 }]
    #   time_execution is not always present (but it's not relevant here)
    #
    #   test_files - list of test files that you want to run tests for
    #   slow_test_files - list of slow test files that should be split by test cases
    #   test_file_cases - list of paths to test cases (test examples) inside of all slow test files (slow_test_files)
    # Return:
    #   Test files and test cases paths (it excludes test files that should be split by test cases (test examples))
    def self.call(test_files, slow_test_files, test_file_cases)
      slow_test_file_paths = KnapsackPro::TestFilePresenter.paths(slow_test_files)

      test_files_without_slow_test_files = test_files.reject do |test_file|
        slow_test_file_paths.include?(test_file.fetch('path'))
      end

      test_files_without_slow_test_files + test_file_cases
    end
  end
end
