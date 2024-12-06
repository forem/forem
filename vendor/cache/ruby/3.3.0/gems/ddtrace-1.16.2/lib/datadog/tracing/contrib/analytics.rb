# frozen_string_literal: true

require_relative '../analytics'

module Datadog
  module Tracing
    module Contrib
      # Defines analytics behavior for integrations
      # @public_api
      module Analytics
        module_function

        # Checks whether analytics should be enabled.
        # `flag` is a truthy/falsey value that represents a setting on the integration.
        def enabled?(flag = nil)
          (Datadog.configuration.tracing.analytics.enabled && flag != false) || flag == true
        end

        def set_sample_rate(span, sample_rate)
          Tracing::Analytics.set_sample_rate(span, sample_rate)
        end

        def set_measured(span, value = true)
          Tracing::Analytics.set_measured(span, value)
        end
      end
    end
  end
end
