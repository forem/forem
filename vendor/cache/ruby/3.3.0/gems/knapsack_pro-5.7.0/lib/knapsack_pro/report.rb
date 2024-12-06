# frozen_string_literal: true

module KnapsackPro
  class Report
    def self.save
      test_files = KnapsackPro.tracker.to_a

      if test_files.empty?
        KnapsackPro.logger.warn("No test files were executed on this CI node.")
        KnapsackPro.logger.debug("When you use knapsack_pro Regular Mode, the reason for no tests executing might be a very narrow tests list. Most likely, you run only tests with a specified tag, and there were fewer test files with the tag than parallel CI nodes.")
      end

      create_build_subset(test_files)
    end

    def self.save_subset_queue_to_file
      test_files = KnapsackPro.tracker.to_a

      subset_queue_id = KnapsackPro::Config::Env.subset_queue_id

      KnapsackPro::Config::TempFiles.ensure_temp_directory_exists!
      FileUtils.mkdir_p(queue_path)

      subset_queue_file_name = "#{subset_queue_id}.json"
      report_path = File.join(queue_path, subset_queue_file_name)
      report_json = JSON.pretty_generate(test_files)

      File.open(report_path, 'w+') do |f|
        f.write(report_json)
      end
    end

    def self.save_node_queue_to_api
      test_files = []
      Dir.glob("#{queue_path}/*.json").each do |file|
        report = JSON.parse(File.read(file))
        test_files += report
      end

      if test_files.empty?
        KnapsackPro.logger.warn("No test files were executed on this CI node.")
        KnapsackPro.logger.debug("This CI node likely started work late after the test files were already executed by other CI nodes consuming the queue.")
      end

      measured_test_files = test_files
        .map { |t| t['time_execution'] }
        .select { |time_execution| time_execution != KnapsackPro::Tracker::DEFAULT_TEST_FILE_TIME }

      if test_files.size > 0 && measured_test_files.size == 0
        KnapsackPro.logger.warn("#{test_files.size} test files were executed on this CI node but the recorded time was lost due to:")
        KnapsackPro.logger.warn("1. Please ensure you do not remove the contents of the .knapsack_pro directory between tests run.")
        KnapsackPro.logger.warn("2. Ensure you've added Knapsack::Adapters::RSpecAdapter.bind in your rails_helper.rb or spec_helper.rb. Please follow the installation guide again: #{KnapsackPro::Urls::INSTALLATION_GUIDE}")
        KnapsackPro.logger.warn("3. Another potential reason for this warning is that all your tests are empty test files, pending tests, or they have syntax errors, and the time execution was not recorded for them.")
      end

      create_build_subset(test_files)
    end

    def self.create_build_subset(test_files)
      repository_adapter = KnapsackPro::RepositoryAdapterInitiator.call
      test_files = KnapsackPro::Utils.unsymbolize(test_files)
      encrypted_test_files = KnapsackPro::Crypto::Encryptor.call(test_files)
      encrypted_branch = KnapsackPro::Crypto::BranchEncryptor.call(repository_adapter.branch)
      action = KnapsackPro::Client::API::V1::BuildSubsets.create(
        commit_hash: repository_adapter.commit_hash,
        branch: encrypted_branch,
        node_total: KnapsackPro::Config::Env.ci_node_total,
        node_index: KnapsackPro::Config::Env.ci_node_index,
        test_files: encrypted_test_files,
      )
      connection = KnapsackPro::Client::Connection.new(action)
      response = connection.call
      if connection.success?
        raise ArgumentError.new(response) if connection.errors?
        KnapsackPro.logger.debug('Saved time execution report on Knapsack Pro API server.')
      else
        KnapsackPro.logger.warn('Time execution report was not saved on Knapsack Pro API server due to connection problem.')
      end
    end

    private

    def self.queue_path
      "#{KnapsackPro::Config::TempFiles::TEMP_DIRECTORY_PATH}/queue/#{KnapsackPro::Config::Env.queue_id}"
    end
  end
end
