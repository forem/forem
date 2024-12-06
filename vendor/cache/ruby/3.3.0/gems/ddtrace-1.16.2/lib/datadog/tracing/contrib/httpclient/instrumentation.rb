require_relative '../../metadata/ext'
require_relative '../../propagation/http'
require_relative '../analytics'
require_relative '../http_annotation_helper'

module Datadog
  module Tracing
    module Contrib
      module Httpclient
        # Instrumentation for Httpclient
        module Instrumentation
          def self.included(base)
            base.prepend(InstanceMethods)
          end

          # Instance methods for configuration
          module InstanceMethods
            include Contrib::HttpAnnotationHelper

            def do_get_block(req, proxy, conn, &block)
              host = req.header.request_uri.host
              request_options = datadog_configuration(host)
              client_config = Datadog.configuration_for(self)

              Tracing.trace(Ext::SPAN_REQUEST, on_error: method(:annotate_span_with_error!)) do |span, trace|
                begin
                  span.service = service_name(host, request_options, client_config)
                  span.span_type = Tracing::Metadata::Ext::HTTP::TYPE_OUTBOUND

                  if Tracing.enabled? && !should_skip_distributed_tracing?(client_config)
                    Tracing::Propagation::HTTP.inject!(trace, req.header)
                  end

                  # Add additional request specific tags to the span.
                  annotate_span_with_request!(span, req, request_options)
                rescue StandardError => e
                  logger.error("error preparing span for httpclient request: #{e}, Source: #{e.backtrace}")
                ensure
                  res = super
                end

                # Add additional response specific tags to the span.
                annotate_span_with_response!(span, res, request_options)

                res
              end
            end

            private

            def annotate_span_with_request!(span, req, req_options)
              span.set_tag(Tracing::Metadata::Ext::TAG_KIND, Tracing::Metadata::Ext::SpanKind::TAG_CLIENT)

              if req_options[:peer_service]
                span.set_tag(
                  Tracing::Metadata::Ext::TAG_PEER_SERVICE,
                  req_options[:peer_service]
                )
              end

              # Tag original global service name if not used
              if span.service != Datadog.configuration.service
                span.set_tag(Tracing::Contrib::Ext::Metadata::TAG_BASE_SERVICE, Datadog.configuration.service)
              end

              span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
              span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_REQUEST)

              http_method = req.header.request_method.upcase
              uri = req.header.request_uri

              span.resource = http_method
              span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_METHOD, http_method)
              span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_URL, uri.path)
              span.set_tag(Tracing::Metadata::Ext::NET::TAG_TARGET_HOST, uri.host)
              span.set_tag(Tracing::Metadata::Ext::NET::TAG_TARGET_PORT, uri.port)

              span.set_tag(Tracing::Metadata::Ext::TAG_PEER_HOSTNAME, uri.host)

              set_analytics_sample_rate(span, req_options)

              span.set_tags(
                Datadog.configuration.tracing.header_tags.request_tags(req.http_header)
              )

              Contrib::SpanAttributeSchema.set_peer_service!(span, Ext::PEER_SERVICE_SOURCES)
            end

            def annotate_span_with_response!(span, response, request_options)
              return unless response && response.status

              span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_STATUS_CODE, response.status)

              if request_options[:error_status_codes].include? response.code.to_i
                span.set_error(["Error #{response.status}", response.body])
              end

              span.set_tags(
                Datadog.configuration.tracing.header_tags.response_tags(response.header)
              )
            end

            def annotate_span_with_error!(span, error)
              span.set_error(error)
            end

            def datadog_configuration(host = :default)
              Datadog.configuration.tracing[:httpclient, host]
            end

            def analytics_enabled?(request_options)
              Contrib::Analytics.enabled?(request_options[:analytics_enabled])
            end

            def logger
              Datadog.logger
            end

            def should_skip_distributed_tracing?(client_config)
              return !client_config[:distributed_tracing] if client_config && client_config.key?(:distributed_tracing)

              !Datadog.configuration.tracing[:httpclient][:distributed_tracing]
            end

            def set_analytics_sample_rate(span, request_options)
              return unless analytics_enabled?(request_options)

              Contrib::Analytics.set_sample_rate(span, request_options[:analytics_sample_rate])
            end
          end
        end
      end
    end
  end
end
