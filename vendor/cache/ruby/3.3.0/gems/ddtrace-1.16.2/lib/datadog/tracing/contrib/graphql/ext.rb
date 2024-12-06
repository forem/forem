# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module GraphQL
        # GraphQL integration constants
        # @public_api Changing resource names, tag names, or environment variables creates breaking changes.
        module Ext
          ENV_ENABLED = 'DD_TRACE_GRAPHQL_ENABLED'
          ENV_ANALYTICS_ENABLED = 'DD_TRACE_GRAPHQL_ANALYTICS_ENABLED'
          ENV_ANALYTICS_SAMPLE_RATE = 'DD_TRACE_GRAPHQL_ANALYTICS_SAMPLE_RATE'
          SERVICE_NAME = 'graphql'
          TAG_COMPONENT = 'graphql'
        end
      end
    end
  end
end
