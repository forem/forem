# frozen_string_literal: true

module Datadog
  module Core
    module Telemetry
      module Ext
        ENV_ENABLED = 'DD_INSTRUMENTATION_TELEMETRY_ENABLED'
        ENV_HEARTBEAT_INTERVAL = 'DD_TELEMETRY_HEARTBEAT_INTERVAL'
      end
    end
  end
end
