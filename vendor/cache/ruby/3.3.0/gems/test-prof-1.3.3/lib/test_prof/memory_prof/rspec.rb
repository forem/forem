# frozen_string_literal: true

module TestProf
  module MemoryProf
    class RSpecListener
      NOTIFICATIONS = %i[
        example_started
        example_finished
        example_group_started
        example_group_finished
      ].freeze

      attr_reader :tracker, :printer

      def initialize
        @tracker = MemoryProf.tracker
        @printer = MemoryProf.printer(tracker)

        @current_group = nil
        @current_example = nil

        @tracker.start
      end

      def example_started(notification)
        tracker.example_started(notification.example, example(notification))
      end

      def example_finished(notification)
        tracker.example_finished(notification.example)
      end

      def example_group_started(notification)
        tracker.group_started(notification.group, group(notification))
      end

      def example_group_finished(notification)
        tracker.group_finished(notification.group)
      end

      def report
        tracker.finish
        printer.print
      end

      private

      def example(notification)
        {
          name: notification.example.description,
          location: notification.example.metadata[:location]
        }
      end

      def group(notification)
        {
          name: notification.group.description,
          location: notification.group.metadata[:location]
        }
      end
    end
  end
end

TestProf.activate("TEST_MEM_PROF") do
  RSpec.configure do |config|
    listener = nil

    config.before(:suite) do
      listener = TestProf::MemoryProf::RSpecListener.new

      config.reporter.register_listener(
        listener, *TestProf::MemoryProf::RSpecListener::NOTIFICATIONS
      )
    end

    config.after(:suite) { listener&.report }
  end
end
