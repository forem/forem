# frozen_string_literal: true

module KnapsackPro
  class SlowTestFileFinder
    # Get recorded test files from API.
    # Find slow tests among them that are still present on the disk.
    # Save slow test files in json file on the disk.
    # Returns slow test files.
    def self.call(adapter_class)
      if KnapsackPro::Config::Env.test_files_encrypted?
        raise "Split by test cases is not possible when you have enabled test file names encryption ( #{KnapsackPro::Urls::ENCRYPTION} ). You need to disable encryption with KNAPSACK_PRO_TEST_FILES_ENCRYPTED=false in order to use split by test cases #{KnapsackPro::Urls::SPLIT_BY_TEST_EXAMPLES}"
      end

      # get list of recorded test files for last CI Build
      build_distribution_entity = KnapsackPro::BuildDistributionFetcher.call
      test_files_from_api = build_distribution_entity.test_files

      merged_test_files_from_api = KnapsackPro::TestCaseMergers::BaseMerger.call(adapter_class, test_files_from_api)

      test_files_existing_on_disk = KnapsackPro::TestFileFinder.select_test_files_that_can_be_run(adapter_class, merged_test_files_from_api)

      slow_test_files = KnapsackPro::SlowTestFileDeterminer.call(test_files_existing_on_disk, build_distribution_entity.time_execution)

      KnapsackPro::SlowTestFileDeterminer.save_to_json_report(slow_test_files)

      slow_test_files
    end
  end
end
