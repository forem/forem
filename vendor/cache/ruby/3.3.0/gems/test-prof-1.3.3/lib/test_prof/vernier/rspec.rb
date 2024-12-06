# frozen_string_literal: true

require "test_prof/utils/rspec"

module TestProf
  module Vernier
    # Reporter for RSpec to profile specific examples with Vernier
    class Listener # :nodoc:
      class << self
        attr_accessor :report_name_generator
      end

      self.report_name_generator = Utils::RSpec.method(:example_to_filename)

      NOTIFICATIONS = %i[
        example_started
        example_finished
      ].freeze

      def example_started(notification)
        return unless profile?(notification.example)
        notification.example.metadata[:vernier_collector] = TestProf::Vernier.profile
      end

      def example_finished(notification)
        return unless profile?(notification.example)
        return unless notification.example.metadata[:vernier_collector]

        TestProf::Vernier.dump(
          notification.example.metadata[:vernier_collector],
          self.class.report_name_generator.call(notification.example)
        )
      end

      private

      def profile?(example)
        example.metadata.key?(:vernier)
      end
    end
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    listener = TestProf::Vernier::Listener.new

    config.reporter.register_listener(
      listener, *TestProf::Vernier::Listener::NOTIFICATIONS
    )
  end
end

# Handle boot profiling
RSpec.configure do |config|
  config.append_before(:suite) do
    TestProf::Vernier.dump(TestProf::Vernier.default_collector, "boot") if TestProf::Vernier.config.boot?
  end
end
