# frozen_string_literal: true

module KnapsackPro
  module Runners
    class MinitestRunner < BaseRunner
      def self.run(args)
        ENV['KNAPSACK_PRO_TEST_SUITE_TOKEN'] = KnapsackPro::Config::Env.test_suite_token_minitest
        ENV['KNAPSACK_PRO_RECORDING_ENABLED'] = 'true'

        adapter_class = KnapsackPro::Adapters::MinitestAdapter
        KnapsackPro::Config::Env.set_test_runner_adapter(adapter_class)
        runner = new(adapter_class)

        if runner.test_files_to_execute_exist?
          adapter_class.verify_bind_method_called

          KnapsackPro.tracker.set_prerun_tests(runner.test_file_paths)

          task_name = 'knapsack_pro:minitest_run'

          if Rake::Task.task_defined?(task_name)
            Rake::Task[task_name].clear
          end

          Rake::TestTask.new(task_name) do |t|
            t.warning = false
            t.libs << runner.test_dir
            t.test_files = runner.test_file_paths
            t.options = args
          end

          Rake::Task[task_name].invoke
        end
      end
    end
  end
end
