# frozen_string_literal: true

require_relative '../../../span_operation'
require_relative '../../configuration/settings'
require_relative '../ext'

module Datadog
  module Tracing
    module Contrib
      module GRPC
        module Configuration
          # Custom settings for the gRPC integration
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

            option :distributed_tracing, default: true, type: :bool

            option :service_name do |o|
              o.default do
                Contrib::SpanAttributeSchema.fetch_service_name(
                  Ext::ENV_SERVICE_NAME,
                  Ext::DEFAULT_PEER_SERVICE_NAME
                )
              end
            end

            option :peer_service do |o|
              o.type :string, nilable: true
              o.env Ext::ENV_PEER_SERVICE
            end

            option :error_handler do |o|
              o.type :proc
              o.default_proc(&Tracing::SpanOperation::Events::DEFAULT_ON_ERROR)
              o.after_set do |value|
                if value != Tracing::SpanOperation::Events::DEFAULT_ON_ERROR
                  Datadog.logger.warn(
                    'The gRPC `error_handler` setting has been deprecated for removal. Please replace ' \
                    'it with `server_error_handler` which is explicit about only handling errors from ' \
                    'server interceptors. Alternatively, to handle errors from client interceptors use ' \
                    'the `client_error_handler` setting instead.'
                  )
                end
              end
            end

            option :server_error_handler do |o|
              o.type :proc
              o.default_proc(&Tracing::SpanOperation::Events::DEFAULT_ON_ERROR)
            end

            option :client_error_handler do |o|
              o.type :proc
              o.default_proc(&Tracing::SpanOperation::Events::DEFAULT_ON_ERROR)
            end
          end
        end
      end
    end
  end
end
