# frozen_string_literal: true

module KnapsackPro
  module Adapters
    class SpinachAdapter < BaseAdapter
      TEST_DIR_PATTERN = 'features/**{,/*/**}/*.feature'

      def self.test_path(scenario)
        scenario.feature.filename
      end

      def bind_time_tracker
        ::Spinach.hooks.before_scenario do |scenario_data, step_definitions|
          KnapsackPro.tracker.current_test_path = KnapsackPro::Adapters::SpinachAdapter.test_path(scenario_data)
          KnapsackPro.tracker.start_timer
        end

        ::Spinach.hooks.after_scenario do
          KnapsackPro.tracker.stop_timer
        end

        ::Spinach.hooks.after_run do
          KnapsackPro.logger.debug(KnapsackPro::Presenter.global_time)
        end
      end

      def bind_save_report(latest_error = nil)
        ::Spinach.hooks.after_run do
          KnapsackPro::Report.save
        end
      end
    end
  end
end
