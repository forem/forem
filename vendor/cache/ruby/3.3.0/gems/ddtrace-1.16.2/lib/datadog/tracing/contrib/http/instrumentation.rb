require 'uri'

require_relative '../../metadata/ext'
require_relative '../analytics'
require_relative '../http_annotation_helper'
require_relative '../utils/quantization/http'

module Datadog
  module Tracing
    module Contrib
      module HTTP
        # Instrumentation for Net::HTTP
        module Instrumentation
          def self.included(base)
            base.prepend(InstanceMethods)
          end

          # Span hook invoked after request is completed.
          def self.after_request(&block)
            if block
              # Set hook
              @after_request = block
            else
              # Get hook
              @after_request ||= nil
            end
          end

          # InstanceMethods - implementing instrumentation
          module InstanceMethods
            include Contrib::HttpAnnotationHelper

            # :yield: +response+
            def request(req, body = nil, &block)
              host, = host_and_port(req)
              request_options = datadog_configuration(host)
              client_config = Datadog.configuration_for(self)

              return super(req, body, &block) if Contrib::HTTP.should_skip_tracing?(req)

              Tracing.trace(Ext::SPAN_REQUEST, on_error: method(:annotate_span_with_error!)) do |span, trace|
                begin
                  span.service = service_name(host, request_options, client_config)
                  span.span_type = Tracing::Metadata::Ext::HTTP::TYPE_OUTBOUND
                  span.resource = req.method

                  if Tracing.enabled? && !Contrib::HTTP.should_skip_distributed_tracing?(client_config)
                    Tracing::Propagation::HTTP.inject!(trace, req)
                  end

                  # Add additional request specific tags to the span.
                  annotate_span_with_request!(span, req, request_options)
                rescue StandardError => e
                  Datadog.logger.error("error preparing span for http request: #{e}")
                ensure
                  response = super(req, body, &block)
                end

                # Add additional response specific tags to the span.
                annotate_span_with_response!(span, response, request_options)

                # Invoke hook, if set.
                unless Contrib::HTTP::Instrumentation.after_request.nil?
                  Contrib::HTTP::Instrumentation.after_request.call(span, self, req, response)
                end

                response
              end
            end

            def annotate_span_with_request!(span, request, request_options)
              if request_options[:peer_service]
                span.set_tag(
                  Tracing::Metadata::Ext::TAG_PEER_SERVICE,
                  request_options[:peer_service]
                )
              end

              # Tag original global service name if not used
              if span.service != Datadog.configuration.service
                span.set_tag(Tracing::Contrib::Ext::Metadata::TAG_BASE_SERVICE, Datadog.configuration.service)
              end

              span.set_tag(Tracing::Metadata::Ext::TAG_KIND, Tracing::Metadata::Ext::SpanKind::TAG_CLIENT)

              span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
              span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_REQUEST)
              span.set_tag(
                Tracing::Metadata::Ext::HTTP::TAG_URL,
                Contrib::Utils::Quantization::HTTP.url(request.path, { query: { exclude: :all } })
              )
              span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_METHOD, request.method)

              host, port = host_and_port(request)
              span.set_tag(Tracing::Metadata::Ext::NET::TAG_TARGET_HOST, host)
              span.set_tag(Tracing::Metadata::Ext::NET::TAG_TARGET_PORT, port.to_s)

              span.set_tag(Tracing::Metadata::Ext::TAG_PEER_HOSTNAME, host)

              # Set analytics sample rate
              set_analytics_sample_rate(span, request_options)

              span.set_tags(
                Datadog.configuration.tracing.header_tags.request_tags(request)
              )

              Contrib::SpanAttributeSchema.set_peer_service!(span, Ext::PEER_SERVICE_SOURCES)
            end

            def annotate_span_with_response!(span, response, request_options)
              return unless response && response.code

              span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_STATUS_CODE, response.code)

              span.set_error(response) if request_options[:error_status_codes].include? response.code.to_i

              span.set_tags(
                Datadog.configuration.tracing.header_tags.response_tags(response)
              )
            end

            def annotate_span_with_error!(span, error)
              span.set_error(error)
            end

            def set_analytics_sample_rate(span, request_options)
              return unless analytics_enabled?(request_options)

              Contrib::Analytics.set_sample_rate(span, analytics_sample_rate(request_options))
            end

            private

            def host_and_port(request)
              if request.respond_to?(:uri) && request.uri
                [request.uri.host, request.uri.port]
              else
                [@address, @port]
              end
            end

            def datadog_configuration(host = :default)
              Datadog.configuration.tracing[:http, host]
            end

            def analytics_enabled?(request_options)
              Contrib::Analytics.enabled?(request_options[:analytics_enabled])
            end

            def analytics_sample_rate(request_options)
              request_options[:analytics_sample_rate]
            end
          end
        end
      end
    end
  end
end
