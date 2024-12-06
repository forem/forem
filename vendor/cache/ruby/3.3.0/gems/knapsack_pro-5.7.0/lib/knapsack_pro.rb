# frozen_string_literal: true

require 'logger'
require 'singleton'
require 'net/http'
require 'json'
require 'uri'
require 'rake/testtask'
require 'digest'
require 'securerandom'
require 'timeout'
require_relative 'knapsack_pro/urls'
require_relative 'knapsack_pro/version'
require_relative 'knapsack_pro/extensions/time'
require_relative 'knapsack_pro/hooks/queue'
require_relative 'knapsack_pro/utils'
require_relative 'knapsack_pro/config/ci/base'
require_relative 'knapsack_pro/config/ci/app_veyor'
require_relative 'knapsack_pro/config/ci/circle'
require_relative 'knapsack_pro/config/ci/cirrus_ci'
require_relative 'knapsack_pro/config/ci/codefresh'
require_relative 'knapsack_pro/config/ci/gitlab_ci'
require_relative 'knapsack_pro/config/ci/semaphore'
require_relative 'knapsack_pro/config/ci/semaphore2'
require_relative 'knapsack_pro/config/ci/buildkite'
require_relative 'knapsack_pro/config/ci/travis'
require_relative 'knapsack_pro/config/ci/codeship'
require_relative 'knapsack_pro/config/ci/github_actions'
require_relative 'knapsack_pro/config/ci/heroku'
require_relative 'knapsack_pro/config/env'
require_relative 'knapsack_pro/config/env_generator'
require_relative 'knapsack_pro/config/temp_files'
require_relative 'knapsack_pro/logger_wrapper'
require_relative 'knapsack_pro/client/api/action'
require_relative 'knapsack_pro/client/api/v1/base'
require_relative 'knapsack_pro/client/api/v1/build_distributions'
require_relative 'knapsack_pro/client/api/v1/build_subsets'
require_relative 'knapsack_pro/client/api/v1/queues'
require_relative 'knapsack_pro/client/connection'
require_relative 'knapsack_pro/repository_adapters/base_adapter'
require_relative 'knapsack_pro/repository_adapters/env_adapter'
require_relative 'knapsack_pro/repository_adapters/git_adapter'
require_relative 'knapsack_pro/repository_adapter_initiator'
require_relative 'knapsack_pro/report'
require_relative 'knapsack_pro/presenter'
require_relative 'knapsack_pro/test_file_cleaner'
require_relative 'knapsack_pro/test_file_presenter'
require_relative 'knapsack_pro/test_file_finder'
require_relative 'knapsack_pro/test_file_pattern'
require_relative 'knapsack_pro/test_flat_distributor'
require_relative 'knapsack_pro/task_loader'
require_relative 'knapsack_pro/tracker'
require_relative 'knapsack_pro/adapters/base_adapter'
require_relative 'knapsack_pro/adapters/rspec_adapter'
require_relative 'knapsack_pro/adapters/cucumber_adapter'
require_relative 'knapsack_pro/adapters/minitest_adapter'
require_relative 'knapsack_pro/adapters/test_unit_adapter'
require_relative 'knapsack_pro/adapters/spinach_adapter'
require_relative 'knapsack_pro/allocator'
require_relative 'knapsack_pro/queue_allocator'
require_relative 'knapsack_pro/mask_string'
require_relative 'knapsack_pro/test_case_mergers/base_merger'
require_relative 'knapsack_pro/test_case_mergers/rspec_merger'
require_relative 'knapsack_pro/build_distribution_fetcher'
require_relative 'knapsack_pro/slow_test_file_determiner'
require_relative 'knapsack_pro/slow_test_file_finder'
require_relative 'knapsack_pro/test_files_with_test_cases_composer'
require_relative 'knapsack_pro/base_allocator_builder'
require_relative 'knapsack_pro/allocator_builder'
require_relative 'knapsack_pro/queue_allocator_builder'
require_relative 'knapsack_pro/runners/base_runner'
require_relative 'knapsack_pro/runners/rspec_runner'
require_relative 'knapsack_pro/runners/cucumber_runner'
require_relative 'knapsack_pro/runners/minitest_runner'
require_relative 'knapsack_pro/runners/test_unit_runner'
require_relative 'knapsack_pro/runners/spinach_runner'
require_relative 'knapsack_pro/runners/queue/base_runner'
require_relative 'knapsack_pro/runners/queue/rspec_runner'
require_relative 'knapsack_pro/runners/queue/cucumber_runner'
require_relative 'knapsack_pro/runners/queue/minitest_runner'
require_relative 'knapsack_pro/test_case_detectors/rspec_test_example_detector'
require_relative 'knapsack_pro/crypto/encryptor'
require_relative 'knapsack_pro/crypto/branch_encryptor'
require_relative 'knapsack_pro/crypto/decryptor'
require_relative 'knapsack_pro/crypto/digestor'

require 'knapsack_pro/railtie' if defined?(Rails::Railtie)

module KnapsackPro
  class << self
    def root
      File.expand_path('../..', __FILE__)
    end

    def logger
      if KnapsackPro::Config::Env.log_dir
        default_logger = Logger.new("#{KnapsackPro::Config::Env.log_dir}/knapsack_pro_node_#{KnapsackPro::Config::Env.ci_node_index}.log")
        default_logger.level = KnapsackPro::Config::Env.log_level
        self.logger = default_logger
      end

      unless @logger
        default_logger = ::Logger.new(STDOUT)
        default_logger.level = KnapsackPro::Config::Env.log_level
        self.logger = default_logger
      end
      @logger
    end

    def logger=(logger)
      @logger = KnapsackPro::LoggerWrapper.new(logger)
    end

    def reset_logger!
      @logger = nil
    end

    def tracker
      KnapsackPro::Tracker.instance
    end

    def load_tasks
      task_loader = KnapsackPro::TaskLoader.new
      task_loader.load_tasks
    end
  end
end
