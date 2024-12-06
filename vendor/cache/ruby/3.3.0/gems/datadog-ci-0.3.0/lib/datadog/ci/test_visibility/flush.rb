# frozen_string_literal: true

require "datadog/tracing/metadata/ext"
require "datadog/tracing/flush"

module Datadog
  module CI
    module TestVisibility
      module Flush
        # Common behavior for CI flushing
        module Tagging
          # Decorate a trace with CI tags
          def get_trace(trace_op)
            trace = trace_op.flush!

            # Origin tag is required on every span
            trace.spans.each do |span|
              span.set_tag(
                Tracing::Metadata::Ext::Distributed::TAG_ORIGIN,
                trace.origin
              )
            end

            trace
          end
        end

        # Consumes only completed traces (where all spans have finished)
        class Finished < Tracing::Flush::Finished
          prepend Tagging
        end

        # Performs partial trace flushing to avoid large traces residing in memory for too long
        class Partial < Tracing::Flush::Partial
          prepend Tagging
        end
      end
    end
  end
end
