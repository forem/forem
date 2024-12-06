require_relative '../../metadata/ext'
require_relative '../analytics'
require_relative 'ext'
require_relative '../ext'
require_relative '../integration'
require_relative '../patcher'

module Datadog
  module Tracing
    module Contrib
      module Elasticsearch
        # Patcher enables patching of 'elasticsearch' module.
        module Patcher
          include Contrib::Patcher

          module_function

          def target_version
            Integration.version
          end

          def patch
            require 'uri'
            require 'json'
            require_relative 'quantize'

            transport_module::Client.prepend(Client)
          end

          SELF_DEPRECATION_ONLY_ONCE = Core::Utils::OnlyOnce.new

          # Patches Elasticsearch::Transport::Client module
          module Client
            # rubocop:disable Metrics/MethodLength
            # rubocop:disable Metrics/AbcSize
            def perform_request(*args)
              # DEV-2.0: Remove this access, as `Client#self` in this context is not exposed to the user
              # since `elasticsearch` v8.0.0. In contrast, `Client#transport` is always available across
              # all `elasticsearch` gem versions and should be used instead.
              service = Datadog.configuration_for(self, :service_name)

              if service
                SELF_DEPRECATION_ONLY_ONCE.run do
                  Datadog.logger.warn(
                    'Providing configuration though the Elasticsearch client object is deprecated.' \
                    'Configure the `client#transport` object instead: ' \
                    'Datadog.configure_onto(client.transport, service_name: service_name, ...)'
                  )
                end
              end

              # `Client#transport` is most convenient object both this integration and the library
              # user have shared access to across all `elasticsearch` versions.
              #
              # `Client#self` in this context is an internal object that the library user
              # does not have access to since `elasticsearch` v8.0.0.
              service ||= Datadog.configuration_for(transport, :service_name) || datadog_configuration[:service_name]

              method = args[0]
              path = args[1]
              params = args[2]
              body = args[3]
              full_url = URI.parse(path)
              url = full_url.path
              response = nil

              Tracing.trace(Datadog::Tracing::Contrib::Elasticsearch::Ext::SPAN_QUERY, service: service) do |span|
                begin
                  connection = transport.connections.first
                  host = connection.host[:host] if connection
                  port = connection.host[:port] if connection

                  if datadog_configuration[:peer_service]
                    span.set_tag(
                      Tracing::Metadata::Ext::TAG_PEER_SERVICE,
                      datadog_configuration[:peer_service]
                    )
                  end

                  # Tag original global service name if not used
                  if span.service != Datadog.configuration.service
                    span.set_tag(Tracing::Contrib::Ext::Metadata::TAG_BASE_SERVICE, Datadog.configuration.service)
                  end

                  span.span_type = Datadog::Tracing::Contrib::Elasticsearch::Ext::SPAN_TYPE_QUERY

                  span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
                  span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_QUERY)
                  span.set_tag(Tracing::Metadata::Ext::TAG_KIND, Tracing::Metadata::Ext::SpanKind::TAG_CLIENT)

                  span.set_tag(Contrib::Ext::DB::TAG_SYSTEM, Ext::TAG_SYSTEM)

                  span.set_tag(Tracing::Metadata::Ext::TAG_PEER_HOSTNAME, host) if host

                  # Set analytics sample rate
                  if Contrib::Analytics.enabled?(datadog_configuration[:analytics_enabled])
                    Contrib::Analytics.set_sample_rate(span, datadog_configuration[:analytics_sample_rate])
                  end

                  span.set_tag(Datadog::Tracing::Contrib::Elasticsearch::Ext::TAG_METHOD, method)
                  tag_params(params, span)
                  tag_body(body, span)
                  span.set_tag(Datadog::Tracing::Contrib::Elasticsearch::Ext::TAG_URL, url)
                  span.set_tag(Tracing::Metadata::Ext::NET::TAG_TARGET_HOST, host) if host
                  span.set_tag(Tracing::Metadata::Ext::NET::TAG_TARGET_PORT, port) if port

                  quantized_url = Datadog::Tracing::Contrib::Elasticsearch::Quantize.format_url(url)
                  span.resource = "#{method} #{quantized_url}"
                  Contrib::SpanAttributeSchema.set_peer_service!(span, Ext::PEER_SERVICE_SOURCES)
                rescue StandardError => e
                  Datadog.logger.error(e.message)
                ensure
                  # the call is still executed
                  response = super
                  span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_STATUS_CODE, response.status)
                end
              end
              response
            end

            def tag_params(params, span)
              return unless params

              params = JSON.generate(params) unless params.is_a?(String)
              span.set_tag(Datadog::Tracing::Contrib::Elasticsearch::Ext::TAG_PARAMS, params)
            end

            def tag_body(body, span)
              return unless body

              body = JSON.generate(body) unless body.is_a?(String)
              quantize_options = datadog_configuration[:quantize]
              quantized_body = Datadog::Tracing::Contrib::Elasticsearch::Quantize.format_body(
                body,
                quantize_options
              )
              span.set_tag(Datadog::Tracing::Contrib::Elasticsearch::Ext::TAG_BODY, quantized_body)
            end

            def datadog_configuration
              Datadog.configuration.tracing[:elasticsearch]
            end
          end
          # rubocop:enable Metrics/MethodLength
          # rubocop:enable Metrics/AbcSize

          # `Elasticsearch` namespace renamed to `Elastic` in version 8.0.0 of the transport gem:
          # @see https://github.com/elastic/elastic-transport-ruby/commit/ef804cbbd284f2a82d825221f87124f8b5ff823c
          def transport_module
            if Integration.version >= Gem::Version.new('8.0.0')
              ::Elastic::Transport
            else
              ::Elasticsearch::Transport
            end
          end
        end
      end
    end
  end
end
