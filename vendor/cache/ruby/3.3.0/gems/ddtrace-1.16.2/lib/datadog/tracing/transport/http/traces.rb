# frozen_string_literal: true

require 'json'

require_relative '../traces'
require_relative 'client'
require_relative '../../../core/transport/http/response'
require_relative '../../../core/transport/http/api/endpoint'
require_relative 'api/instance'

module Datadog
  module Tracing
    module Transport
      module HTTP
        # HTTP transport behavior for traces
        module Traces
          # Response from HTTP transport for traces
          class Response
            include Datadog::Core::Transport::HTTP::Response
            include Datadog::Tracing::Transport::Traces::Response

            def initialize(http_response, options = {})
              super(http_response)
              @service_rates = options.fetch(:service_rates, nil)
              @trace_count = options.fetch(:trace_count, 0)
            end
          end

          # Extensions for HTTP client
          module Client
            def send_traces_payload(request)
              send_request(request) do |api, env|
                api.send_traces(env)
              end
            end
          end

          module API
            # Extensions for HTTP API Spec
            module Spec
              attr_reader :traces

              def traces=(endpoint)
                @traces = endpoint
              end

              def send_traces(env, &block)
                raise NoTraceEndpointDefinedError, self if traces.nil?

                traces.call(env, &block)
              end

              def encoder
                traces.encoder
              end

              # Raised when traces sent but no traces endpoint is defined
              class NoTraceEndpointDefinedError < StandardError
                attr_reader :spec

                def initialize(spec)
                  super

                  @spec = spec
                end

                def message
                  'No trace endpoint is defined for API specification!'
                end
              end
            end

            # Extensions for HTTP API Instance
            module Instance
              def send_traces(env)
                raise TracesNotSupportedError, spec unless spec.is_a?(Traces::API::Spec)

                spec.send_traces(env) do |request_env|
                  call(request_env)
                end
              end

              # Raised when traces sent to API that does not support traces
              class TracesNotSupportedError < StandardError
                attr_reader :spec

                def initialize(spec)
                  super

                  @spec = spec
                end

                def message
                  'Traces not supported for this API!'
                end
              end
            end

            # Endpoint for submitting trace data
            class Endpoint < Datadog::Core::Transport::HTTP::API::Endpoint
              HEADER_CONTENT_TYPE = 'Content-Type'
              HEADER_TRACE_COUNT = 'X-Datadog-Trace-Count'
              SERVICE_RATE_KEY = 'rate_by_service'

              attr_reader \
                :encoder

              def initialize(path, encoder, options = {})
                super(:post, path)
                @encoder = encoder
                @service_rates = options.fetch(:service_rates, false)
              end

              def service_rates?
                @service_rates == true
              end

              def call(env, &block)
                # Add trace count header
                env.headers[HEADER_TRACE_COUNT] = env.request.parcel.trace_count.to_s

                # Encode body & type
                env.headers[HEADER_CONTENT_TYPE] = encoder.content_type
                env.body = env.request.parcel.data

                # Query for response
                http_response = super(env, &block)

                # Process the response
                response_options = { trace_count: env.request.parcel.trace_count }.tap do |options|
                  # Parse service rates, if configured to do so.
                  if service_rates? && !http_response.payload.to_s.empty?
                    body = JSON.parse(http_response.payload)
                    options[:service_rates] = body[SERVICE_RATE_KEY] if body.is_a?(Hash) && body.key?(SERVICE_RATE_KEY)
                  end
                end

                # Build and return a trace response
                Traces::Response.new(http_response, response_options)
              end
            end
          end

          # Add traces behavior to transport components
          HTTP::Client.include(Traces::Client)
          HTTP::API::Spec.include(Traces::API::Spec)
          HTTP::API::Instance.include(Traces::API::Instance)
        end
      end
    end
  end
end
