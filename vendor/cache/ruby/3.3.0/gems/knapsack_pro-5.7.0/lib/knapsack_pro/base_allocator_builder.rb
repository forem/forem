# frozen_string_literal: true

module KnapsackPro
  class BaseAllocatorBuilder
    TEST_RUNNER_MAP = {
      KnapsackPro::Adapters::RSpecAdapter => 'rspec',
      KnapsackPro::Adapters::CucumberAdapter => 'cucumber',
      KnapsackPro::Adapters::MinitestAdapter => 'minitest',
      KnapsackPro::Adapters::SpinachAdapter => 'spinach',
      KnapsackPro::Adapters::TestUnitAdapter => 'test-unit',
    }

    def initialize(adapter_class)
      @adapter_class = adapter_class
      ENV['KNAPSACK_PRO_TEST_RUNNER'] = TEST_RUNNER_MAP[adapter_class]
    end

    def allocator
      raise NotImplementedError
    end

    def test_dir
      KnapsackPro::Config::Env.test_dir || TestFilePattern.test_dir(adapter_class)
    end

    # in fallback mode we always want to run the whole test files
    # (not split by test cases) to guarantee that each test will be executed
    # at least once across parallel CI nodes
    def fallback_mode_test_files
      all_test_files_to_run
    end

    # detect test files present on the disk that should be run
    # this may include some fast test files + slow test files split by test cases
    def fast_and_slow_test_files_to_run
      test_files_to_run = all_test_files_to_run

      if adapter_class.split_by_test_cases_enabled?
        slow_test_files = get_slow_test_files
        return test_files_to_run if slow_test_files.empty?

        test_file_cases = adapter_class.test_file_cases_for(slow_test_files)

        return KnapsackPro::TestFilesWithTestCasesComposer.call(test_files_to_run, slow_test_files, test_file_cases)
      end

      test_files_to_run
    end

    private

    attr_reader :adapter_class

    def env
      KnapsackPro::Config::Env
    end

    def repository_adapter
      KnapsackPro::RepositoryAdapterInitiator.call
    end

    def test_file_pattern
      TestFilePattern.call(adapter_class)
    end

    def all_test_files_to_run
      KnapsackPro::TestFileFinder.call(test_file_pattern)
    end

    def slow_test_file_pattern
      KnapsackPro::Config::Env.slow_test_file_pattern
    end

    def get_slow_test_files
      slow_test_files =
        if slow_test_file_pattern
          KnapsackPro::TestFileFinder.slow_test_files_by_pattern(adapter_class)
        else
          # get slow test files from API and ensure they exist on disk
          KnapsackPro::SlowTestFileFinder.call(adapter_class)
        end
      KnapsackPro.logger.debug("Detected #{slow_test_files.size} slow test files: #{slow_test_files.inspect}")
      slow_test_files
    end
  end
end
