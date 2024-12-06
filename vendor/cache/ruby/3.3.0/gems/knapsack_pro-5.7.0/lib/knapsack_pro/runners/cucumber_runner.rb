# frozen_string_literal: true

module KnapsackPro
  module Runners
    class CucumberRunner < BaseRunner
      def self.run(args)
        ENV['KNAPSACK_PRO_TEST_SUITE_TOKEN'] = KnapsackPro::Config::Env.test_suite_token_cucumber
        ENV['KNAPSACK_PRO_RECORDING_ENABLED'] = 'true'

        adapter_class = KnapsackPro::Adapters::CucumberAdapter
        KnapsackPro::Config::Env.set_test_runner_adapter(adapter_class)
        runner = new(adapter_class)

        if runner.test_files_to_execute_exist?
          adapter_class.verify_bind_method_called

          KnapsackPro.tracker.set_prerun_tests(runner.test_file_paths)

          require 'cucumber/rake/task'

          task_name = 'knapsack_pro:cucumber_run'
          if Rake::Task.task_defined?(task_name)
            Rake::Task[task_name].clear
          end

          ::Cucumber::Rake::Task.new(task_name) do |t|
            t.cucumber_opts = "#{args} --require #{runner.test_dir} -- #{runner.stringify_test_file_paths}"
          end
          Rake::Task[task_name].invoke
        end
      end
    end
  end
end
