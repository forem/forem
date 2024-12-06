# frozen_string_literal: true

require 'json'
require 'base64'

require_relative '../config'
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
# require_relative '../../../core/transport/http/api/instance'
require_relative 'api/instance'
# Below should be:
# require_relative '../../../core/transport/http/api/spec'
require_relative 'api/spec'

module Datadog
  module Core
    module Remote
      module Transport
        module HTTP
          # HTTP transport behavior for remote configuration
          module Config
            # Response from HTTP transport for remote configuration
            class Response
              include Datadog::Core::Transport::HTTP::Response
              include Core::Remote::Transport::Config::Response

              def initialize(http_response, options = {}) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
                super(http_response)

                begin
                  payload = JSON.parse(http_response.payload, symbolize_names: true)
                rescue JSON::ParserError => e
                  raise ParseError.new(:roots, e)
                end

                raise TypeError.new(Hash, payload) unless payload.is_a?(Hash)

                @empty = true if payload.empty?

                # TODO: these fallbacks should be improved
                roots = payload[:roots] || []
                targets = payload[:targets] || Base64.encode64('{}').chomp
                target_files = payload[:target_files] || []
                client_configs = payload[:client_configs] || []

                raise TypeError.new(Array, roots) unless roots.is_a?(Array)

                @roots = roots.map do |root|
                  raise TypeError.new(String, root) unless root.is_a?(String)

                  decoded = begin
                    Base64.strict_decode64(root) # TODO: unprocessed, don't symbolize_names
                  rescue ArgumentError
                    raise DecodeError.new(:roots, root)
                  end

                  parsed = begin
                    JSON.parse(decoded)
                  rescue JSON::ParserError
                    raise ParseError.new(:roots, decoded)
                  end

                  # TODO: perform more processing to validate content. til then, no freeze

                  parsed
                end

                raise TypeError.new(String, targets) unless targets.is_a?(String)

                @targets = begin
                  decoded = begin
                    Base64.strict_decode64(targets)
                  rescue ArgumentError
                    raise DecodeError.new(:targets, targets)
                  end

                  parsed = begin
                    JSON.parse(decoded) # TODO: unprocessed, don't symbolize_names
                  rescue JSON::ParserError
                    raise ParseError.new(:targets, decoded)
                  end

                  # TODO: perform more processing to validate content. til then, no freeze

                  parsed
                end

                raise TypeError.new(Array, target_files) unless target_files.is_a?(Array)

                @target_files = target_files.map do |h|
                  raise TypeError.new(Hash, h) unless h.is_a?(Hash)
                  raise KeyError.new(:raw) unless h.key?(:raw) # rubocop:disable Style/RaiseArgs
                  raise KeyError.new(:path) unless h.key?(:path) # rubocop:disable Style/RaiseArgs

                  raw = h[:raw]

                  raise TypeError.new(String, raw) unless raw.is_a?(String)

                  content = begin
                    Base64.strict_decode64(raw)
                  rescue ArgumentError
                    raise DecodeError.new(:target_files, raw)
                  end

                  {
                    path: h[:path].freeze,
                    content: StringIO.new(content.freeze),
                  }
                end.freeze

                @client_configs = client_configs.map do |s|
                  raise TypeError.new(String, s) unless s.is_a?(String)

                  s.freeze
                end.freeze
              end

              def inspect
                "#{super}, #{
                  {
                    roots: @roots,
                    targets: @targets,
                    target_files: @target_files,
                    client_configs: @client_configs,
                  }}"
              end

              # When an expected key is missing
              class KeyError < StandardError
                def initialize(key)
                  message = "key not found: #{key.inspect}"

                  super(message)
                end
              end

              # When an expected value type is incorrect
              class TypeError < StandardError
                def initialize(type, value)
                  message = "not a #{type}: #{value.inspect}"

                  super(message)
                end
              end

              # When value decoding fails
              class DecodeError < StandardError
                def initialize(key, value)
                  message = "could not decode key #{key.inspect}: #{value.inspect}"

                  super(message)
                end
              end

              # When value parsing fails
              class ParseError < StandardError
                def initialize(key, value)
                  message = "could not parse key #{key.inspect}: #{value.inspect}"

                  super(message)
                end
              end
            end

            # Extensions for HTTP client
            module Client
              def send_config_payload(request)
                send_request(request) do |api, env|
                  api.send_config(env)
                end
              end
            end

            module API
              # Extensions for HTTP API Spec
              module Spec
                attr_reader :config

                def config=(endpoint)
                  @config = endpoint
                end

                def send_config(env, &block)
                  raise NoConfigEndpointDefinedError, self if config.nil?

                  config.call(env, &block)
                end

                # Raised when traces sent but no traces endpoint is defined
                class NoConfigEndpointDefinedError < StandardError
                  attr_reader :spec

                  def initialize(spec)
                    super()

                    @spec = spec
                  end

                  def message
                    'No config endpoint is defined for API specification!'
                  end
                end
              end

              # Extensions for HTTP API Instance
              module Instance
                def send_config(env)
                  raise ConfigNotSupportedError, spec unless spec.is_a?(Config::API::Spec)

                  spec.send_config(env) do |request_env|
                    call(request_env)
                  end
                end

                # Raised when traces sent to API that does not support traces
                class ConfigNotSupportedError < StandardError
                  attr_reader :spec

                  def initialize(spec)
                    super()

                    @spec = spec
                  end

                  def message
                    'Config not supported for this API!'
                  end
                end
              end

              # Endpoint for remote configuration
              class Endpoint < Datadog::Core::Transport::HTTP::API::Endpoint
                HEADER_CONTENT_TYPE = 'Content-Type'

                attr_reader :encoder

                def initialize(path, encoder)
                  super(:post, path)
                  @encoder = encoder
                end

                def call(env, &block)
                  # Encode body & type
                  env.headers[HEADER_CONTENT_TYPE] = encoder.content_type
                  env.body = env.request.parcel.data

                  # Query for response
                  http_response = super(env, &block)

                  response_options = {}

                  # Build and return a response
                  Config::Response.new(http_response, response_options)
                end
              end
            end

            # Add remote configuration behavior to transport components
            ###### overrides send_payload! which calls send_<endpoint>! kills any other possible endpoint!
            HTTP::Client.include(Config::Client)
            HTTP::API::Spec.include(Config::API::Spec)
            HTTP::API::Instance.include(Config::API::Instance)
          end
        end
      end
    end
  end
end
