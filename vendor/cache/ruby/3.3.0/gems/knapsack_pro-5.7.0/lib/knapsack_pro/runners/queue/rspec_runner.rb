# frozen_string_literal: true

module KnapsackPro
  module Runners
    module Queue
      class RSpecRunner < BaseRunner
        @@used_seed = nil

        def self.run(args)
          require 'rspec/core'
          require_relative '../../formatters/rspec_queue_summary_formatter'
          require_relative '../../formatters/rspec_queue_profile_formatter_extension'

          ENV['KNAPSACK_PRO_TEST_SUITE_TOKEN'] = KnapsackPro::Config::Env.test_suite_token_rspec
          ENV['KNAPSACK_PRO_QUEUE_RECORDING_ENABLED'] = 'true'
          ENV['KNAPSACK_PRO_QUEUE_ID'] = KnapsackPro::Config::EnvGenerator.set_queue_id

          KnapsackPro::Config::Env.set_test_runner_adapter(adapter_class)
          runner = new(adapter_class)

          cli_args = (args || '').split
          adapter_class.ensure_no_tag_option_when_rspec_split_by_test_examples_enabled!(cli_args)

          # when format option is not defined by user then use progress formatter to show tests execution progress
          cli_args += ['--format', 'progress'] unless adapter_class.has_format_option?(cli_args)

          cli_args += [
            # shows summary of all tests executed in Queue Mode at the very end
            '--format', KnapsackPro::Formatters::RSpecQueueSummaryFormatter.to_s,
            '--default-path', runner.test_dir,
          ]

          accumulator = {
            status: :next,
            runner: runner,
            can_initialize_queue: true,
            args: cli_args,
            exitstatus: 0,
            all_test_file_paths: [],
          }
          while accumulator[:status] == :next
            handle_signal!
            accumulator = run_tests(accumulator)
          end

          Kernel.exit(accumulator[:exitstatus])
        end

        def self.run_tests(accumulator)
          runner = accumulator.fetch(:runner)
          can_initialize_queue = accumulator.fetch(:can_initialize_queue)
          args = accumulator.fetch(:args)
          exitstatus = accumulator.fetch(:exitstatus)
          all_test_file_paths = accumulator.fetch(:all_test_file_paths)

          test_file_paths = runner.test_file_paths(
            can_initialize_queue: can_initialize_queue,
            executed_test_files: all_test_file_paths
          )

          if test_file_paths.empty?
            unless all_test_file_paths.empty?
              KnapsackPro::Adapters::RSpecAdapter.verify_bind_method_called

              KnapsackPro::Formatters::RSpecQueueSummaryFormatter.print_summary
              KnapsackPro::Formatters::RSpecQueueProfileFormatterExtension.print_summary

              args += ['--seed', @@used_seed] if @@used_seed

              log_rspec_command(args, all_test_file_paths, :end_of_queue)
            end

            KnapsackPro::Hooks::Queue.call_after_queue

            KnapsackPro::Report.save_node_queue_to_api

            return {
              status: :completed,
              exitstatus: exitstatus,
            }
          else
            subset_queue_id = KnapsackPro::Config::EnvGenerator.set_subset_queue_id
            ENV['KNAPSACK_PRO_SUBSET_QUEUE_ID'] = subset_queue_id

            KnapsackPro.tracker.reset!
            KnapsackPro.tracker.set_prerun_tests(test_file_paths)

            KnapsackPro::Hooks::Queue.call_before_subset_queue

            all_test_file_paths += test_file_paths
            cli_args = args + test_file_paths

            ensure_spec_opts_have_rspec_queue_summary_formatter
            options = ::RSpec::Core::ConfigurationOptions.new(cli_args)
            rspec_runner = ::RSpec::Core::Runner.new(options)

            begin
              exit_code = rspec_runner.run($stderr, $stdout)
              exitstatus = exit_code if exit_code != 0
            rescue Exception => exception
              KnapsackPro.logger.error("Having exception when running RSpec: #{exception.inspect}")
              KnapsackPro::Formatters::RSpecQueueSummaryFormatter.print_exit_summary
              KnapsackPro::Hooks::Queue.call_after_subset_queue
              KnapsackPro::Hooks::Queue.call_after_queue
              Kernel.exit(1)
              raise
            else
              if rspec_runner.world.wants_to_quit
                KnapsackPro.logger.warn('RSpec wants to quit.')
                set_terminate_process
              end
              if rspec_runner.world.rspec_is_quitting
                KnapsackPro.logger.warn('RSpec is quitting.')
                set_terminate_process
              end

              printable_args = args_with_seed_option_added_when_viable(args, rspec_runner)
              log_rspec_command(printable_args, test_file_paths, :subset_queue)

              rspec_clear_examples

              KnapsackPro::Hooks::Queue.call_after_subset_queue

              KnapsackPro::Report.save_subset_queue_to_file

              return {
                status: :next,
                runner: runner,
                can_initialize_queue: false,
                args: args,
                exitstatus: exitstatus,
                all_test_file_paths: all_test_file_paths,
              }
            end
          end
        end

        def self.ensure_spec_opts_have_rspec_queue_summary_formatter
          spec_opts = ENV['SPEC_OPTS']

          return unless spec_opts
          return if spec_opts.include?(KnapsackPro::Formatters::RSpecQueueSummaryFormatter.to_s)

          ENV['SPEC_OPTS'] = "#{spec_opts} --format #{KnapsackPro::Formatters::RSpecQueueSummaryFormatter.to_s}"
        end

        private

        def self.adapter_class
          KnapsackPro::Adapters::RSpecAdapter
        end

        def self.log_rspec_command(cli_args, test_file_paths, type)
          case type
          when :subset_queue
            KnapsackPro.logger.info("To retry the last batch of tests fetched from the API Queue, please run the following command on your machine:")
          when :end_of_queue
            KnapsackPro.logger.info("To retry all the tests assigned to this CI node, please run the following command on your machine:")
          end

          stringified_cli_args = cli_args.join(' ').sub(" --format #{KnapsackPro::Formatters::RSpecQueueSummaryFormatter}", '')

          KnapsackPro.logger.info(
            "bundle exec rspec #{stringified_cli_args} " +
            KnapsackPro::TestFilePresenter.stringify_paths(test_file_paths)
          )
        end

        # Clear rspec examples without the shared examples:
        # https://github.com/rspec/rspec-core/pull/2379
        #
        # Keep formatters and report to accumulate info about failed/pending tests
        def self.rspec_clear_examples
          if ::RSpec::ExampleGroups.respond_to?(:remove_all_constants)
            ::RSpec::ExampleGroups.remove_all_constants
          else
            ::RSpec::ExampleGroups.constants.each do |constant|
              ::RSpec::ExampleGroups.__send__(:remove_const, constant)
            end
          end
          ::RSpec.world.example_groups.clear
          ::RSpec.configuration.start_time = ::RSpec::Core::Time.now

          if KnapsackPro::Config::Env.rspec_split_by_test_examples?
            # Reset example group counts to ensure scoped example ids in metadata
            # have correct index (not increased by each subsequent run).
            # Solves this problem: https://github.com/rspec/rspec-core/issues/2721
            ::RSpec.world.instance_variable_set(:@example_group_counts_by_spec_file, Hash.new(0))
          end

          # skip reset filters for old RSpec versions
          if ::RSpec.configuration.respond_to?(:reset_filters)
            ::RSpec.configuration.reset_filters
          end
        end

        def self.args_with_seed_option_added_when_viable(args, rspec_runner)
          order_option = adapter_class.order_option(args)

          if order_option
            # Don't add the seed option for order other than random, e.g. `defined`
            return args unless order_option.include?('rand')
            # Don't add the seed option if the seed is already set in args, e.g. `rand:12345`
            return args if order_option.to_s.split(':')[1]
          end

          # Don't add the seed option if the seed was not used (i.e. a different order is being used, e.g. `defined`)
          return args unless rspec_runner.configuration.seed_used?

          @@used_seed = rspec_runner.configuration.seed.to_s

          args + ['--seed', @@used_seed]
        end
      end
    end
  end
end
