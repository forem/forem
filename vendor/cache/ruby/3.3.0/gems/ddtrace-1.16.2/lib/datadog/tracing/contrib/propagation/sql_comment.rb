require_relative 'sql_comment/comment'
require_relative 'sql_comment/ext'

require_relative '../../distributed/trace_context'

module Datadog
  module Tracing
    module Contrib
      module Propagation
        # Implements sql comment propagation related contracts.
        module SqlComment
          def self.annotate!(span_op, mode)
            return unless mode.enabled?

            span_op.set_tag(Ext::TAG_DBM_TRACE_INJECTED, true) if mode.full?
          end

          # Inject span_op and trace_op instead of TraceDigest to improve memory usage
          # for `disabled` and `service` mode
          def self.prepend_comment(sql, span_op, trace_op, mode)
            return sql unless mode.enabled?

            tags = {
              Ext::KEY_DATABASE_SERVICE => span_op.get_tag(Tracing::Metadata::Ext::TAG_PEER_SERVICE) || span_op.service,
              Ext::KEY_ENVIRONMENT => datadog_configuration.env,
              Ext::KEY_PARENT_SERVICE => datadog_configuration.service,
              Ext::KEY_VERSION => datadog_configuration.version
            }

            if mode.full?
              # When tracing is disabled, trace_operation is a dummy object that does not contain data to build traceparent
              if datadog_configuration.tracing.enabled
                tags[Ext::KEY_TRACEPARENT] =
                  Tracing::Distributed::TraceContext.new(fetcher: nil).send(:build_traceparent, trace_op.to_digest)
              else
                Datadog.logger.warn(
                  'Sql comment propagation with `full` mode is aborted, because tracing is disabled. '\
                  'Please set `Datadog.configuration.tracing.enabled = true` to continue.'
                )
              end
            end

            "#{Comment.new(tags)} #{sql}"
          end

          def self.datadog_configuration
            Datadog.configuration
          end
        end
      end
    end
  end
end
