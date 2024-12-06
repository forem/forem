# frozen_string_literal: true

module KnapsackPro
  module Adapters
    class CucumberAdapter < BaseAdapter
      TEST_DIR_PATTERN = 'features/**{,/*/**}/*.feature'

      def self.test_path(object)
        if ::Cucumber::VERSION.to_i >= 2
          test_case = object
          test_case.location.file
        else
          if object.respond_to?(:scenario_outline)
            if object.scenario_outline.respond_to?(:feature)
              # Cucumber < 1.3
              object.scenario_outline.feature.file
            else
              # Cucumber >= 1.3
              object.scenario_outline.file
            end
          else
            if object.respond_to?(:feature)
              # Cucumber < 1.3
              object.feature.file
            else
              # Cucumber >= 1.3
              object.file
            end
          end
        end
      end

      def bind_time_tracker
        Around do |object, block|
          KnapsackPro.tracker.current_test_path = KnapsackPro::Adapters::CucumberAdapter.test_path(object)
          KnapsackPro.tracker.start_timer
          block.call
          KnapsackPro.tracker.stop_timer
        end

        ::Kernel.at_exit do
          KnapsackPro.logger.debug(KnapsackPro::Presenter.global_time)
        end
      end

      def bind_save_report(latest_error = nil)
        ::Kernel.at_exit do
          # $! is latest error message
          latest_error = (latest_error || $!)
          exit_status = latest_error.status if latest_error.is_a?(SystemExit)
          # saving report makes API call which changes exit status
          # from cucumber so we need to preserve cucumber exit status
          KnapsackPro::Report.save
          ::Kernel.exit exit_status if exit_status
        end
      end

      def bind_before_queue_hook
        Around do |object, block|
          unless ENV['KNAPSACK_PRO_BEFORE_QUEUE_HOOK_CALLED']
            KnapsackPro::Hooks::Queue.call_before_queue
            ENV['KNAPSACK_PRO_BEFORE_QUEUE_HOOK_CALLED'] = 'true'
          end
          block.call
        end
      end

      def bind_queue_mode
        super

        ::Kernel.at_exit do
          KnapsackPro::Hooks::Queue.call_after_subset_queue
          KnapsackPro::Report.save_subset_queue_to_file
        end
      end

      private

      def Around(*tag_expressions, &proc)
        if ::Cucumber::VERSION.to_i >= 3
          ::Cucumber::Glue::Dsl.register_rb_hook('around', tag_expressions, proc)
        else
          ::Cucumber::RbSupport::RbDsl.register_rb_hook('around', tag_expressions, proc)
        end
      end
    end
  end
end
