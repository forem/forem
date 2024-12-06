# frozen_string_literal: true

require 'json'

require_relative '../negotiation'
require_relative 'client'
require_relative '../../../transport/http/response'
require_relative '../../../transport/http/api/endpoint'

# TODO: Decouple standard transport/http/api/instance
#
# Separate classes are needed because transport/http/trace includes
# Trace::API::Instance which closes over and uses a single spec, which is
# negotiated as either /v3 or /v4 for the whole API at the spec level, but we
# need an independent toplevel path at the endpoint level.
#
# Separate classes are needed because of `include Trace::API::Instance`.
#
# Below should be:
# require_relative '../../../../ddtrace/transport/http/api/instance'
require_relative 'api/instance'
# Below should be:
# require_relative '../../../../ddtrace/transport/http/api/spec'
require_relative 'api/spec'

module Datadog
  module Core
    module Remote
      module Transport
        module HTTP
          # HTTP transport behavior for agent feature negotiation
          module Negotiation
            # Response from HTTP transport for agent feature negotiation
            class Response
              include Datadog::Core::Transport::HTTP::Response
              include Core::Remote::Transport::Negotiation::Response

              def initialize(http_response, options = {})
                super(http_response)

                # TODO: transform endpoint hash in a better object for negotiation
                # TODO: transform config in a better object, notably config has max_request_bytes
                @version = options[:version]
                @endpoints = options[:endpoints]
                @config = options[:config]
              end
            end

            # Extensions for HTTP client
            module Client
              def send_info_payload(request)
                send_request(request) do |api, env|
                  api.send_info(env)
                end
              end
            end

            module API
              # Extensions for HTTP API Spec
              module Spec
                attr_reader :info

                def info=(endpoint)
                  @info = endpoint
                end

                def send_info(env, &block)
                  raise NoNegotiationEndpointDefinedError, self if info.nil?

                  info.call(env, &block)
                end

                # Raised when traces sent but no traces endpoint is defined
                class NoNegotiationEndpointDefinedError < StandardError
                  attr_reader :spec

                  def initialize(spec)
                    super()

                    @spec = spec
                  end

                  def message
                    'No info endpoint is defined for API specification!'
                  end
                end
              end

              # Extensions for HTTP API Instance
              module Instance
                def send_info(env)
                  raise NegotiationNotSupportedError, spec unless spec.is_a?(Negotiation::API::Spec)

                  spec.send_info(env) do |request_env|
                    call(request_env)
                  end
                end

                # Raised when traces sent to API that does not support traces
                class NegotiationNotSupportedError < StandardError
                  attr_reader :spec

                  def initialize(spec)
                    super()

                    @spec = spec
                  end

                  def message
                    'Info not supported for this API!'
                  end
                end
              end

              # Endpoint for negotiation
              class Endpoint < Datadog::Core::Transport::HTTP::API::Endpoint
                def initialize(path)
                  super(:get, path)
                end

                def call(env, &block)
                  # Query for response
                  http_response = super(env, &block)

                  # Process the response
                  body = JSON.parse(http_response.payload, symbolize_names: true) if http_response.ok?

                  # TODO: there should be more processing here to ensure a proper response_options
                  response_options = body.is_a?(Hash) ? body : {}

                  # Build and return a trace response
                  Negotiation::Response.new(http_response, response_options)
                end
              end
            end

            # Add negotiation behavior to transport components
            HTTP::Client.include(Negotiation::Client)
            HTTP::API::Spec.include(Negotiation::API::Spec)
            HTTP::API::Instance.include(Negotiation::API::Instance)
          end
        end
      end
    end
  end
end
