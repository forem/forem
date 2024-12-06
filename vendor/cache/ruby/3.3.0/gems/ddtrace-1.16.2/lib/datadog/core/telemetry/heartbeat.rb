# frozen_string_literal: true

require_relative '../worker'
require_relative '../workers/polling'

module Datadog
  module Core
    module Telemetry
      # Periodically (every DEFAULT_INTERVAL_SECONDS) sends a heartbeat event to the telemetry API.
      class Heartbeat < Core::Worker
        include Core::Workers::Polling

        def initialize(heartbeat_interval_seconds:, enabled: true, &block)
          # Workers::Polling settings
          self.enabled = enabled
          # Workers::IntervalLoop settings
          self.loop_base_interval = heartbeat_interval_seconds
          self.fork_policy = Core::Workers::Async::Thread::FORK_POLICY_STOP
          super(&block)
          start
        end

        def loop_wait_before_first_iteration?
          true
        end

        private

        def start
          perform
        end
      end
    end
  end
end
