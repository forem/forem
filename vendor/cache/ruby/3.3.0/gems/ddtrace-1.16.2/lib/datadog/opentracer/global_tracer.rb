# frozen_string_literal: true

module Datadog
  module OpenTracer
    # Patch for OpenTracing module
    module GlobalTracer
      def global_tracer=(tracer)
        super.tap do
          if tracer.class <= Datadog::OpenTracer::Tracer
            # Update the Datadog global tracer, too.
            Datadog.configure { |c| c.tracing.instance = tracer.datadog_tracer }
          end
        end
      end
    end
  end
end
