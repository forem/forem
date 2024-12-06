# frozen_string_literal: true

module KnapsackPro
  class TestFileFinder
    def self.call(test_file_pattern, test_file_list_enabled: true)
      new(test_file_pattern, test_file_list_enabled).call
    end

    # finds slow test files on disk based on ENV patterns
    # returns example: [{ 'path' => 'a_spec.rb' }]
    def self.slow_test_files_by_pattern(adapter_class)
      raise 'KNAPSACK_PRO_SLOW_TEST_FILE_PATTERN is not defined' unless KnapsackPro::Config::Env.slow_test_file_pattern

      test_file_pattern = KnapsackPro::TestFilePattern.call(adapter_class)
      test_file_entities = call(test_file_pattern)

      slow_test_file_entities = call(KnapsackPro::Config::Env.slow_test_file_pattern, test_file_list_enabled: false)

      # slow test files (KNAPSACK_PRO_SLOW_TEST_FILE_PATTERN)
      # should be subset of test file pattern (KNAPSACK_PRO_TEST_FILE_PATTERN)
      slow_test_file_entities & test_file_entities
    end

    # Args:
    #   test_file_entities_to_run - it can be list of slow test files that you want to run
    # Return:
    #   subset of test_file_entities_to_run that are present on disk and it is subset of tests matching pattern KNAPSACK_PRO_TEST_FILE_PATTERN
    #   Thanks to that we can select only slow test files that are within list of test file pattern we want to run tests for
    def self.select_test_files_that_can_be_run(adapter_class, test_file_entities_to_run)
      test_file_pattern = KnapsackPro::TestFilePattern.call(adapter_class)
      test_file_entities = call(test_file_pattern)

      test_file_paths_existing_on_disk = KnapsackPro::TestFilePresenter.paths(test_file_entities)

      selected_test_files = []

      test_file_entities_to_run.each do |test_file_entity|
        if test_file_paths_existing_on_disk.include?(test_file_entity.fetch('path'))
          selected_test_files << test_file_entity
        end
      end

      selected_test_files
    end

    def initialize(test_file_pattern, test_file_list_enabled)
      @test_file_pattern = test_file_pattern
      @test_file_list_enabled = test_file_list_enabled
    end

    def call
      test_file_hashes = []
      test_files.each do |test_file_path|
        test_file_hashes << test_file_hash_for(test_file_path)
      end
      test_file_hashes
    end

    private

    attr_reader :test_file_pattern, :test_file_list_enabled

    def test_files
      if test_file_list_enabled && KnapsackPro::Config::Env.test_file_list
        return KnapsackPro::Config::Env.test_file_list.split(',').map(&:strip)
      end

      if test_file_list_enabled && KnapsackPro::Config::Env.test_file_list_source_file
        return File.read(KnapsackPro::Config::Env.test_file_list_source_file).split(/\n/)
      end

      test_file_paths = Dir.glob(test_file_pattern).uniq

      excluded_test_file_paths =
        if KnapsackPro::Config::Env.test_file_exclude_pattern
          Dir.glob(KnapsackPro::Config::Env.test_file_exclude_pattern).uniq
        else
          []
        end

      (test_file_paths - excluded_test_file_paths).sort
    end

    def test_file_hash_for(test_file_path)
      {
        'path' => TestFileCleaner.clean(test_file_path)
      }
    end
  end
end
