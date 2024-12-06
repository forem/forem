# frozen_string_literal: true

RSpec::Support.require_rspec_core('formatters/base_formatter')
RSpec::Support.require_rspec_core('formatters/base_text_formatter')

module KnapsackPro
  module Formatters
    module RSpecHideFailuresAndPendingExtension
      def dump_failures(notification); end
      def dump_pending(notification); end
      def dump_summary(summary); end
    end

    class RSpecQueueSummaryFormatter < ::RSpec::Core::Formatters::BaseFormatter
      ::RSpec::Core::Formatters.register self, :dump_summary, :dump_failures, :dump_pending

      def self.registered_output=(output)
        @registered_output = {
          ENV['KNAPSACK_PRO_QUEUE_ID'] => output
        }
      end

      def self.registered_output
        @registered_output[ENV['KNAPSACK_PRO_QUEUE_ID']]
      end

      def self.most_recent_failures_summary=(fully_formatted_failed_examples)
        @most_recent_failures_summary = {
          ENV['KNAPSACK_PRO_QUEUE_ID'] => fully_formatted_failed_examples
        }
      end

      def self.most_recent_failures_summary
        @most_recent_failures_summary ||= {}
        @most_recent_failures_summary[ENV['KNAPSACK_PRO_QUEUE_ID']] || []
      end

      def self.most_recent_pending=(fully_formatted_pending_examples)
        @most_recent_pending = {
          ENV['KNAPSACK_PRO_QUEUE_ID'] => fully_formatted_pending_examples
        }
      end

      def self.most_recent_pending
        @most_recent_pending ||= {}
        @most_recent_pending[ENV['KNAPSACK_PRO_QUEUE_ID']] || []
      end

      def self.most_recent_summary=(fully_formatted)
        @most_recent_summary = {
          ENV['KNAPSACK_PRO_QUEUE_ID'] => fully_formatted
        }
      end

      def self.most_recent_summary
        @most_recent_summary ||= {}
        @most_recent_summary[ENV['KNAPSACK_PRO_QUEUE_ID']] || []
      end

      def self.print_summary
        registered_output.puts('Knapsack Pro Queue finished!')
        registered_output.puts('')

        unless most_recent_pending.empty?
          registered_output.puts('All pending tests on this CI node:')
          registered_output.puts(most_recent_pending)
          registered_output.puts('')
        end

        unless most_recent_failures_summary.empty?
          registered_output.puts('All failed tests on this CI node:')
          registered_output.puts(most_recent_failures_summary)
          registered_output.puts('')
        end

        registered_output.puts(most_recent_summary)
      end

      def self.print_exit_summary
        registered_output.puts('Knapsack Pro Queue exited/aborted!')
        registered_output.puts('')

        unexecuted_test_files = KnapsackPro.tracker.unexecuted_test_files
        unless unexecuted_test_files.empty?
          registered_output.puts('Unexecuted tests on this CI node:')
          registered_output.puts(unexecuted_test_files)
          registered_output.puts('')
        end

        unless most_recent_pending.empty?
          registered_output.puts('All pending tests on this CI node:')
          registered_output.puts(most_recent_pending)
          registered_output.puts('')
        end

        unless most_recent_failures_summary.empty?
          registered_output.puts('All failed tests on this CI node:')
          registered_output.puts(most_recent_failures_summary)
          registered_output.puts('')
        end

        registered_output.puts(most_recent_summary)
      end

      def initialize(output)
        super
        self.class.registered_output = output
      end

      def dump_failures(notification)
        return if notification.failure_notifications.empty?
        self.class.most_recent_failures_summary = notification.fully_formatted_failed_examples
      end

      def dump_pending(notification)
        return if notification.pending_examples.empty?
        self.class.most_recent_pending = notification.fully_formatted_pending_examples
      end

      def dump_summary(summary)
        colorizer = ::RSpec::Core::Formatters::ConsoleCodes
        duration = KnapsackPro.tracker.global_time_since_beginning
        formatted_duration = ::RSpec::Core::Formatters::Helpers.format_duration(duration)

        formatted = "\nFinished in #{formatted_duration}\n" \
          "#{summary.colorized_totals_line(colorizer)}\n"

        unless summary.failed_examples.empty?
          formatted += (summary.colorized_rerun_commands(colorizer) + "\n")
        end

        self.class.most_recent_summary = formatted
      end
    end
  end
end

if KnapsackPro::Config::Env.modify_default_rspec_formatters?
  class RSpec::Core::Formatters::BaseTextFormatter
    prepend KnapsackPro::Formatters::RSpecHideFailuresAndPendingExtension
  end
end
