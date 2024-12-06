# frozen_string_literal: true

module KnapsackPro
  class BuildDistributionFetcher
    class BuildDistributionEntity
      def initialize(response)
        @response = response
      end

      def time_execution
        response.fetch('time_execution')
      end

      def test_files
        response.fetch('test_files')
      end

      private

      attr_reader :response
    end

    def self.call
      new.call
    end

    # get test files and time execution for last build distribution matching:
    # branch, node_total, node_index
    def call
      connection = KnapsackPro::Client::Connection.new(build_action)
      response = connection.call
      if connection.success?
        raise ArgumentError.new(response) if connection.errors?
        BuildDistributionEntity.new(response)
      else
        KnapsackPro.logger.warn("Slow test files fallback behaviour started. We could not connect with Knapsack Pro API to fetch last CI build test files that are needed to determine slow test files. No test files will be split by test cases. It means all test files will be split by the whole test files as if split by test cases would be disabled #{KnapsackPro::Urls::SPLIT_BY_TEST_EXAMPLES}")
        BuildDistributionEntity.new({
          'time_execution' => 0.0,
          'test_files' => [],
        })
      end
    end

    private

    def repository_adapter
      @repository_adapter ||= KnapsackPro::RepositoryAdapterInitiator.call
    end

    def build_action
      KnapsackPro::Client::API::V1::BuildDistributions.last(
        commit_hash: repository_adapter.commit_hash,
        branch: repository_adapter.branch,
        node_total: KnapsackPro::Config::Env.ci_node_total,
        node_index: KnapsackPro::Config::Env.ci_node_index,
      )
    end
  end
end
