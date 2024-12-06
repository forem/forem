# frozen_string_literal: true

module Datadog
  module Core
    module Configuration
      # Constants for configuration settings
      # e.g. Env vars, default values, enums, etc...
      module Ext
        # @public_api
        module Diagnostics
          ENV_DEBUG_ENABLED = 'DD_TRACE_DEBUG'
          ENV_HEALTH_METRICS_ENABLED = 'DD_HEALTH_METRICS_ENABLED'
          ENV_STARTUP_LOGS_ENABLED = 'DD_TRACE_STARTUP_LOGS'
        end

        module Metrics
          ENV_DEFAULT_PORT = 'DD_METRIC_AGENT_PORT'
        end

        # DEV-2.0: This module only exists for backwards compatibility with the public API.
        # It should be consolidated into the Agent module below.
        module Transport
          ENV_DEFAULT_HOST = 'DD_AGENT_HOST'
        end

        module Agent
          # env var has "trace" in it, but it really applies to all products
          ENV_DEFAULT_PORT = 'DD_TRACE_AGENT_PORT'
          ENV_DEFAULT_URL = 'DD_TRACE_AGENT_URL'

          module HTTP
            ADAPTER = :net_http # DEV: Rename to simply `:http`, as Net::HTTP is an implementation detail.
            DEFAULT_HOST = '127.0.0.1'
            DEFAULT_PORT = 8126
          end

          # @public_api
          module UnixSocket
            ADAPTER = :unix
            DEFAULT_PATH = '/var/run/datadog/apm.socket'
            DEFAULT_TIMEOUT_SECONDS = 1
          end
        end
      end
    end
  end
end
