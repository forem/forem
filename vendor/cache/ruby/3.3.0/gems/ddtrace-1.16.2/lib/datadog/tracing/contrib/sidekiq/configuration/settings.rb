# frozen_string_literal: true

require_relative '../../../span_operation'
require_relative '../../configuration/settings'
require_relative '../ext'

module Datadog
  module Tracing
    module Contrib
      module Sidekiq
        module Configuration
          # Custom settings for the Sidekiq integration
          # @public_api
          class Settings < Contrib::Configuration::Settings
            option :enabled do |o|
              o.type :bool
              o.env Ext::ENV_ENABLED
              o.default true
            end

            option :analytics_enabled do |o|
              o.type :bool
              o.env Ext::ENV_ANALYTICS_ENABLED
              o.default false
            end

            option :analytics_sample_rate do |o|
              o.type :float
              o.env Ext::ENV_ANALYTICS_SAMPLE_RATE
              o.default 1.0
            end

            option :tag_args do |o|
              o.type :bool
              o.env Ext::ENV_TAG_JOB_ARGS
              o.default false
            end

            option :service_name
            option :client_service_name
            option :error_handler do |o|
              o.type :proc
              o.default_proc(&Tracing::SpanOperation::Events::DEFAULT_ON_ERROR)
            end
            option :quantize, default: {}, type: :hash
            option :distributed_tracing, default: false, type: :bool
          end
        end
      end
    end
  end
end
