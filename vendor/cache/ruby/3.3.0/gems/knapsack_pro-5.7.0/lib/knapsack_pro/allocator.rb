# frozen_string_literal: true

module KnapsackPro
  class Allocator
    def initialize(args)
      @fast_and_slow_test_files_to_run = args.fetch(:fast_and_slow_test_files_to_run)
      @fallback_mode_test_files = args.fetch(:fallback_mode_test_files)
      @ci_node_total = args.fetch(:ci_node_total)
      @ci_node_index = args.fetch(:ci_node_index)
      @repository_adapter = args.fetch(:repository_adapter)
    end

    def test_file_paths
      action = build_action(cache_read_attempt: true)
      connection = KnapsackPro::Client::Connection.new(action)
      response = connection.call

      # when a cache miss because the test suite split was not cached yet
      if connection.success? && connection.api_code == KnapsackPro::Client::API::V1::BuildDistributions::TEST_SUITE_SPLIT_CACHE_MISS_CODE
        # make an attempt to initalize a new test suite split on the API side
        action = build_action(cache_read_attempt: false)
        connection = KnapsackPro::Client::Connection.new(action)
        response = connection.call
      end

      if connection.success?
        raise ArgumentError.new(response) if connection.errors?
        prepare_test_files(response)
      elsif !KnapsackPro::Config::Env.fallback_mode_enabled?
        message = "Fallback Mode was disabled with KNAPSACK_PRO_FALLBACK_MODE_ENABLED=false. Please restart this CI node to retry tests. Most likely Fallback Mode was disabled due to #{KnapsackPro::Urls::REGULAR_MODE__CONNECTION_ERROR_WITH_FALLBACK_ENABLED_FALSE}"
        KnapsackPro.logger.error(message)
        raise message
      elsif KnapsackPro::Config::Env.ci_node_retry_count > 0
        message = "knapsack_pro gem could not connect to Knapsack Pro API and the Fallback Mode cannot be used this time. Running tests in Fallback Mode are not allowed for retried parallel CI node to avoid running the wrong set of tests. Please manually retry this parallel job on your CI server then knapsack_pro gem will try to connect to Knapsack Pro API again and will run a correct set of tests for this CI node. Learn more #{KnapsackPro::Urls::REGULAR_MODE__CONNECTION_ERROR_WITH_FALLBACK_ENABLED_TRUE_AND_POSITIVE_RETRY_COUNT}"
        unless KnapsackPro::Config::Env.fixed_test_suite_split?
          message += " Please ensure you have set KNAPSACK_PRO_FIXED_TEST_SUITE_SPLIT=true to allow Knapsack Pro API remember the recorded CI node tests so when you retry failed tests on the CI node then the same set of tests will be executed. See more #{KnapsackPro::Urls::FIXED_TEST_SUITE_SPLIT}"
        end
        KnapsackPro.logger.error(message)
        raise message
      else
        KnapsackPro.logger.warn("Fallback mode started. We could not connect with Knapsack Pro API. Your tests will be executed based on directory names. Read more about fallback mode at #{KnapsackPro::Urls::FALLBACK_MODE}")
        fallback_test_files
      end
    end

    private

    attr_reader :fast_and_slow_test_files_to_run,
      :fallback_mode_test_files,
      :ci_node_total,
      :ci_node_index,
      :repository_adapter

    def encrypted_test_files
      KnapsackPro::Crypto::Encryptor.call(fast_and_slow_test_files_to_run)
    end

    def encrypted_branch
      KnapsackPro::Crypto::BranchEncryptor.call(repository_adapter.branch)
    end

    def build_action(cache_read_attempt:)
      test_files =
        unless cache_read_attempt
          encrypted_test_files
        end

      KnapsackPro::Client::API::V1::BuildDistributions.subset(
        cache_read_attempt: cache_read_attempt,
        commit_hash: repository_adapter.commit_hash,
        branch: encrypted_branch,
        node_total: ci_node_total,
        node_index: ci_node_index,
        test_files: test_files,
      )
    end

    def prepare_test_files(response)
      decrypted_test_files = KnapsackPro::Crypto::Decryptor.call(fast_and_slow_test_files_to_run, response['test_files'])
      KnapsackPro::TestFilePresenter.paths(decrypted_test_files)
    end

    def fallback_test_files
      test_flat_distributor = KnapsackPro::TestFlatDistributor.new(fallback_mode_test_files, ci_node_total)
      test_files_for_node_index = test_flat_distributor.test_files_for_node(ci_node_index)
      KnapsackPro::TestFilePresenter.paths(test_files_for_node_index)
    end
  end
end
