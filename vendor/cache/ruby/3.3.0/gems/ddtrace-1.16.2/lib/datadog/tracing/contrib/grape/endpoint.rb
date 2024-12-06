require_relative '../../../core'
require_relative '../../metadata/ext'
require_relative '../analytics'
require_relative '../rack/ext'

module Datadog
  module Tracing
    module Contrib
      module Grape
        # Endpoint module includes a list of subscribers to create
        # traces when a Grape endpoint is hit
        module Endpoint
          KEY_RUN = 'datadog_grape_endpoint_run'.freeze
          KEY_RENDER = 'datadog_grape_endpoint_render'.freeze

          class << self
            def subscribe
              # subscribe when a Grape endpoint is hit
              ::ActiveSupport::Notifications.subscribe('endpoint_run.grape.start_process') do |*args|
                endpoint_start_process(*args)
              end
              ::ActiveSupport::Notifications.subscribe('endpoint_run.grape') do |*args|
                endpoint_run(*args)
              end
              ::ActiveSupport::Notifications.subscribe('endpoint_render.grape.start_render') do |*args|
                endpoint_start_render(*args)
              end
              ::ActiveSupport::Notifications.subscribe('endpoint_render.grape') do |*args|
                endpoint_render(*args)
              end
              ::ActiveSupport::Notifications.subscribe('endpoint_run_filters.grape') do |*args|
                endpoint_run_filters(*args)
              end
            end

            def endpoint_start_process(_name, _start, _finish, _id, payload)
              return if Thread.current[KEY_RUN]
              return unless enabled?

              # collect endpoint details
              endpoint = payload.fetch(:endpoint)
              api_view = api_view(endpoint.options[:for])
              request_method = endpoint.options.fetch(:method).first
              path = endpoint_expand_path(endpoint)
              resource = "#{api_view} #{request_method} #{path}"

              # Store the beginning of a trace
              span = Tracing.trace(
                Ext::SPAN_ENDPOINT_RUN,
                service: service_name,
                span_type: Tracing::Metadata::Ext::HTTP::TYPE_INBOUND,
                resource: resource
              )
              trace = Tracing.active_trace

              # Set the trace resource
              trace.resource = span.resource

              span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
              span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_ENDPOINT_RUN)

              Thread.current[KEY_RUN] = true
            rescue StandardError => e
              Datadog.logger.error(e.message)
            end

            def endpoint_run(name, start, finish, id, payload)
              return unless Thread.current[KEY_RUN]

              Thread.current[KEY_RUN] = false

              return unless enabled?

              trace = Tracing.active_trace
              span = Tracing.active_span
              return unless trace && span

              begin
                # collect endpoint details
                endpoint = payload.fetch(:endpoint)
                api_view = api_view(endpoint.options[:for])
                request_method = endpoint.options.fetch(:method).first
                path = endpoint_expand_path(endpoint)

                trace.resource = span.resource

                # Set analytics sample rate
                Contrib::Analytics.set_sample_rate(span, analytics_sample_rate) if analytics_enabled?

                # Measure service stats
                Contrib::Analytics.set_measured(span)

                # catch thrown exceptions

                span.set_error(payload[:exception_object]) if exception_is_error?(payload[:exception_object])

                # override the current span with this notification values
                span.set_tag(Ext::TAG_ROUTE_ENDPOINT, api_view) unless api_view.nil?
                span.set_tag(Ext::TAG_ROUTE_PATH, path)
                span.set_tag(Ext::TAG_ROUTE_METHOD, request_method)

                span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_METHOD, request_method)
                span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_URL, path)
              ensure
                span.start(start)
                span.finish(finish)
              end
            rescue StandardError => e
              Datadog.logger.error(e.message)
            end

            def endpoint_start_render(*)
              return if Thread.current[KEY_RENDER]
              return unless enabled?

              # Store the beginning of a trace
              span = Tracing.trace(
                Ext::SPAN_ENDPOINT_RENDER,
                service: service_name,
                span_type: Tracing::Metadata::Ext::HTTP::TYPE_TEMPLATE
              )

              span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
              span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_ENDPOINT_RENDER)

              Thread.current[KEY_RENDER] = true
            rescue StandardError => e
              Datadog.logger.error(e.message)
            end

            def endpoint_render(name, start, finish, id, payload)
              return unless Thread.current[KEY_RENDER]

              Thread.current[KEY_RENDER] = false

              return unless enabled?

              span = Tracing.active_span
              return unless span

              # catch thrown exceptions
              begin
                # Measure service stats
                Contrib::Analytics.set_measured(span)

                span.set_error(payload[:exception_object]) if exception_is_error?(payload[:exception_object])
              ensure
                span.start(start)
                span.finish(finish)
              end
            rescue StandardError => e
              Datadog.logger.error(e.message)
            end

            def endpoint_run_filters(name, start, finish, id, payload)
              return unless enabled?

              # safe-guard to prevent submitting empty filters
              zero_length = (finish - start).zero?
              filters = payload[:filters]
              type = payload[:type]
              return if (!filters || filters.empty?) || !type || zero_length

              span = Tracing.trace(
                Ext::SPAN_ENDPOINT_RUN_FILTERS,
                service: service_name,
                span_type: Tracing::Metadata::Ext::HTTP::TYPE_INBOUND,
                start_time: start
              )

              begin
                span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
                span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_ENDPOINT_RUN_FILTERS)

                # Set analytics sample rate
                Contrib::Analytics.set_sample_rate(span, analytics_sample_rate) if analytics_enabled?

                # Measure service stats
                Contrib::Analytics.set_measured(span)

                # catch thrown exceptions
                span.set_error(payload[:exception_object]) if exception_is_error?(payload[:exception_object])

                span.set_tag(Ext::TAG_FILTER_TYPE, type.to_s)
              ensure
                span.start(start)
                span.finish(finish)
              end
            rescue StandardError => e
              Datadog.logger.error(e.message)
            end

            private

            def api_view(api)
              # If the API inherits from Grape::API in version >= 1.2.0
              # then the API will be an instance and the name must be derived from the base.
              # See https://github.com/ruby-grape/grape/issues/1825
              if defined?(::Grape::API::Instance) && api <= ::Grape::API::Instance
                api.base.to_s
              else
                api.to_s
              end
            end

            def endpoint_expand_path(endpoint)
              route_path = endpoint.options[:path]
              namespace = endpoint.routes.first && endpoint.routes.first.namespace || ''

              parts = (namespace.split('/') + route_path).reject { |p| p.blank? || p.eql?('/') }
              parts.join('/').prepend('/')
            end

            def service_name
              datadog_configuration[:service_name]
            end

            def analytics_enabled?
              Contrib::Analytics.enabled?(datadog_configuration[:analytics_enabled])
            end

            def analytics_sample_rate
              datadog_configuration[:analytics_sample_rate]
            end

            def exception_is_error?(exception)
              matcher = datadog_configuration[:error_statuses]
              return false unless exception
              return true unless matcher
              return true unless exception.respond_to?('status')

              matcher.include?(exception.status)
            end

            def enabled?
              Datadog.configuration.tracing.enabled && \
                datadog_configuration[:enabled] == true
            end

            def datadog_configuration
              Datadog.configuration.tracing[:grape]
            end
          end
        end
      end
    end
  end
end
