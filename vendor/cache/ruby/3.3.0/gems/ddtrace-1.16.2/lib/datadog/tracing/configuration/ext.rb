# frozen_string_literal: true

require_relative '../../core/configuration/ext'

module Datadog
  module Tracing
    module Configuration
      # Constants for configuration settings
      # e.g. Env vars, default values, enums, etc...
      module Ext
        ENV_ENABLED = 'DD_TRACE_ENABLED'
        ENV_HEADER_TAGS = 'DD_TRACE_HEADER_TAGS'
        ENV_TRACE_ID_128_BIT_GENERATION_ENABLED = 'DD_TRACE_128_BIT_TRACEID_GENERATION_ENABLED'

        # @public_api
        module SpanAttributeSchema
          ENV_GLOBAL_DEFAULT_SERVICE_NAME_ENABLED = 'DD_TRACE_REMOVE_INTEGRATION_SERVICE_NAMES_ENABLED'
          ENV_PEER_SERVICE_MAPPING = 'DD_TRACE_PEER_SERVICE_MAPPING'
        end

        # @public_api
        module Analytics
          ENV_TRACE_ANALYTICS_ENABLED = 'DD_TRACE_ANALYTICS_ENABLED'
        end

        # @public_api
        module Correlation
          ENV_LOGS_INJECTION_ENABLED = 'DD_LOGS_INJECTION'
          ENV_TRACE_ID_128_BIT_LOGGING_ENABLED = 'DD_TRACE_128_BIT_TRACEID_LOGGING_ENABLED'
        end

        # @public_api
        module Distributed
          # Custom Datadog format
          PROPAGATION_STYLE_DATADOG = 'Datadog'

          PROPAGATION_STYLE_B3_MULTI_HEADER = 'b3multi'
          # @deprecated Use `b3multi` instead.
          PROPAGATION_STYLE_B3 = 'B3'

          PROPAGATION_STYLE_B3_SINGLE_HEADER = 'b3'
          # @deprecated Use `b3` instead.
          PROPAGATION_STYLE_B3_SINGLE_HEADER_OLD = 'B3 single header'

          # W3C Trace Context
          PROPAGATION_STYLE_TRACE_CONTEXT = 'tracecontext'

          # Sets both extract and inject propagation style tho the provided value.
          # Has lower precedence than `DD_TRACE_PROPAGATION_STYLE_INJECT` or
          # `DD_TRACE_PROPAGATION_STYLE_EXTRACT`.
          ENV_PROPAGATION_STYLE = 'DD_TRACE_PROPAGATION_STYLE'

          ENV_PROPAGATION_STYLE_INJECT = 'DD_TRACE_PROPAGATION_STYLE_INJECT'
          # @deprecated Use `DD_TRACE_PROPAGATION_STYLE_INJECT` instead.
          ENV_PROPAGATION_STYLE_INJECT_OLD = 'DD_PROPAGATION_STYLE_INJECT'

          ENV_PROPAGATION_STYLE_EXTRACT = 'DD_TRACE_PROPAGATION_STYLE_EXTRACT'
          # @deprecated Use `DD_TRACE_PROPAGATION_STYLE_EXTRACT` instead.
          ENV_PROPAGATION_STYLE_EXTRACT_OLD = 'DD_PROPAGATION_STYLE_EXTRACT'

          # A no-op propagator. Compatible with OpenTelemetry's `none` propagator.
          # @see https://opentelemetry.io/docs/concepts/sdk-configuration/general-sdk-configuration/#get_otel__propagators
          PROPAGATION_STYLE_NONE = 'none'

          ENV_X_DATADOG_TAGS_MAX_LENGTH = 'DD_TRACE_X_DATADOG_TAGS_MAX_LENGTH'
        end

        # @public_api
        module NET
          ENV_REPORT_HOSTNAME = 'DD_TRACE_REPORT_HOSTNAME'
        end

        # @public_api
        module Sampling
          ENV_SAMPLE_RATE = 'DD_TRACE_SAMPLE_RATE'
          ENV_RATE_LIMIT = 'DD_TRACE_RATE_LIMIT'
          ENV_RULES = 'DD_TRACE_SAMPLING_RULES'

          # @public_api
          module Span
            ENV_SPAN_SAMPLING_RULES = 'DD_SPAN_SAMPLING_RULES'
            ENV_SPAN_SAMPLING_RULES_FILE = 'DD_SPAN_SAMPLING_RULES_FILE'
          end
        end

        # @public_api
        module Test
          ENV_MODE_ENABLED = 'DD_TRACE_TEST_MODE_ENABLED'
        end

        # @public_api
        module Transport
          ENV_DEFAULT_PORT = Datadog::Core::Configuration::Ext::Agent::ENV_DEFAULT_PORT
          ENV_DEFAULT_URL = Datadog::Core::Configuration::Ext::Agent::ENV_DEFAULT_URL
        end

        # @public_api
        module ClientIp
          ENV_ENABLED = 'DD_TRACE_CLIENT_IP_ENABLED'
          ENV_DISABLED = 'DD_TRACE_CLIENT_IP_HEADER_DISABLED' # TODO: deprecated, remove later
          ENV_HEADER_NAME = 'DD_TRACE_CLIENT_IP_HEADER'
        end
      end
    end
  end
end
