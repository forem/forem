require 'faraday'

require_relative '../../metadata/ext'
require_relative '../../propagation/http'
require_relative '../analytics'
require_relative 'ext'
require_relative '../http_annotation_helper'

module Datadog
  module Tracing
    module Contrib
      module Faraday
        # Middleware implements a faraday-middleware for ddtrace instrumentation
        class Middleware < ::Faraday::Middleware
          include Contrib::HttpAnnotationHelper

          def initialize(app, options = {})
            super(app)
            @options = options
          end

          def call(env)
            # Resolve configuration settings to use for this request.
            # Do this once to reduce expensive regex calls.
            request_options = build_request_options!(env)

            Tracing.trace(Ext::SPAN_REQUEST) do |span, trace|
              annotate!(span, env, request_options)
              propagate!(trace, span, env) if request_options[:distributed_tracing] && Tracing.enabled?
              app.call(env).on_complete { |resp| handle_response(span, resp, request_options) }
            end
          end

          private

          attr_reader :app

          def annotate!(span, env, options)
            span.resource = resource_name(env)
            span.service = service_name(env[:url].host, options)
            span.span_type = Tracing::Metadata::Ext::HTTP::TYPE_OUTBOUND

            if options[:peer_service]
              span.set_tag(
                Tracing::Metadata::Ext::TAG_PEER_SERVICE,
                options[:peer_service]
              )
            end

            # Tag original global service name if not used
            if span.service != Datadog.configuration.service
              span.set_tag(Tracing::Contrib::Ext::Metadata::TAG_BASE_SERVICE, Datadog.configuration.service)
            end

            span.set_tag(Tracing::Metadata::Ext::TAG_KIND, Tracing::Metadata::Ext::SpanKind::TAG_CLIENT)

            span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
            span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_REQUEST)

            span.set_tag(Tracing::Metadata::Ext::TAG_PEER_HOSTNAME, env[:url].host)

            # Set analytics sample rate
            if Contrib::Analytics.enabled?(options[:analytics_enabled])
              Contrib::Analytics.set_sample_rate(span, options[:analytics_sample_rate])
            end

            span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_URL, env[:url].path)
            span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_METHOD, env[:method].to_s.upcase)
            span.set_tag(Tracing::Metadata::Ext::NET::TAG_TARGET_HOST, env[:url].host)
            span.set_tag(Tracing::Metadata::Ext::NET::TAG_TARGET_PORT, env[:url].port)
            span.set_tags(
              Datadog.configuration.tracing.header_tags.request_tags(env[:request_headers])
            )

            Contrib::SpanAttributeSchema.set_peer_service!(span, Ext::PEER_SERVICE_SOURCES)
          end

          def handle_response(span, env, options)
            span.set_error(["Error #{env[:status]}", env[:body]]) if options.fetch(:error_handler).call(env)

            span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_STATUS_CODE, env[:status])

            span.set_tags(
              Datadog.configuration.tracing.header_tags.response_tags(env[:response_headers])
            )
          end

          def propagate!(trace, span, env)
            Tracing::Propagation::HTTP.inject!(trace, env[:request_headers])
          end

          def resource_name(env)
            env[:method].to_s.upcase
          end

          def build_request_options!(env)
            datadog_configuration
              .options_hash # integration level settings
              .merge(datadog_configuration(env[:url].host).options_hash) # per-host override
              .merge(@options) # middleware instance override
          end

          def datadog_configuration(host = :default)
            Datadog.configuration.tracing[:faraday, host]
          end
        end
      end
    end
  end
end
