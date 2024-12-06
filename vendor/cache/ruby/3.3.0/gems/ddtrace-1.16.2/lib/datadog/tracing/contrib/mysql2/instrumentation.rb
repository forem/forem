# frozen_string_literal: true

require_relative '../../metadata/ext'
require_relative '../analytics'
require_relative 'ext'
require_relative '../ext'
require_relative '../propagation/sql_comment'
require_relative '../propagation/sql_comment/mode'

module Datadog
  module Tracing
    module Contrib
      module Mysql2
        # Mysql2::Client patch module
        module Instrumentation
          def self.included(base)
            base.prepend(InstanceMethods)
          end

          # Mysql2::Client patch instance methods
          module InstanceMethods
            def query(sql, options = {})
              service = Datadog.configuration_for(self, :service_name) || datadog_configuration[:service_name]

              Tracing.trace(Ext::SPAN_QUERY, service: service) do |span, trace_op|
                span.resource = sql
                span.span_type = Tracing::Metadata::Ext::SQL::TYPE

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

                span.set_tag(Contrib::Ext::DB::TAG_SYSTEM, Ext::TAG_SYSTEM)
                span.set_tag(Tracing::Metadata::Ext::TAG_KIND, Tracing::Metadata::Ext::SpanKind::TAG_CLIENT)

                span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
                span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_QUERY)

                span.set_tag(Tracing::Metadata::Ext::TAG_PEER_HOSTNAME, query_options[:host])

                # Set analytics sample rate
                Contrib::Analytics.set_sample_rate(span, analytics_sample_rate) if analytics_enabled?

                span.set_tag(Ext::TAG_DB_NAME, query_options[:database])
                span.set_tag(Tracing::Metadata::Ext::NET::TAG_TARGET_HOST, query_options[:host])
                span.set_tag(Tracing::Metadata::Ext::NET::TAG_TARGET_PORT, query_options[:port])

                Contrib::SpanAttributeSchema.set_peer_service!(span, Ext::PEER_SERVICE_SOURCES)

                propagation_mode = Contrib::Propagation::SqlComment::Mode.new(comment_propagation)

                Contrib::Propagation::SqlComment.annotate!(span, propagation_mode)
                sql = Contrib::Propagation::SqlComment.prepend_comment(
                  sql,
                  span,
                  trace_op,
                  propagation_mode
                )

                super(sql, options)
              end
            end

            private

            def datadog_configuration
              Datadog.configuration.tracing[:mysql2]
            end

            def analytics_enabled?
              datadog_configuration[:analytics_enabled]
            end

            def analytics_sample_rate
              datadog_configuration[:analytics_sample_rate]
            end

            def comment_propagation
              datadog_configuration[:comment_propagation]
            end
          end
        end
      end
    end
  end
end
