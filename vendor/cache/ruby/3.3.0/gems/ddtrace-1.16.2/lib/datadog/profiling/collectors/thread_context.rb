# frozen_string_literal: true

module Datadog
  module Profiling
    module Collectors
      # Used to trigger sampling of threads, based on external "events", such as:
      # * periodic timer for cpu-time and wall-time
      # * VM garbage collection events
      # * VM object allocation events
      # Triggering of this component (e.g. watching for the above "events") is implemented by
      # Collectors::CpuAndWallTimeWorker.
      # The stack collection itself is handled using the Datadog::Profiling::Collectors::Stack.
      # Almost all of this class is implemented as native code.
      #
      # Methods prefixed with _native_ are implemented in `collectors_thread_context.c`
      class ThreadContext
        def initialize(
          recorder:,
          max_frames:,
          tracer:,
          endpoint_collection_enabled:,
          timeline_enabled:,
          allocation_type_enabled: true
        )
          tracer_context_key = safely_extract_context_key_from(tracer)
          self.class._native_initialize(
            self,
            recorder,
            max_frames,
            tracer_context_key,
            endpoint_collection_enabled,
            timeline_enabled,
            allocation_type_enabled,
          )
        end

        def inspect
          # Compose Ruby's default inspect with our custom inspect for the native parts
          result = super()
          result[-1] = "#{self.class._native_inspect(self)}>"
          result
        end

        def reset_after_fork
          self.class._native_reset_after_fork(self)
        end

        private

        def safely_extract_context_key_from(tracer)
          provider = tracer && tracer.respond_to?(:provider) && tracer.provider

          return unless provider

          context = provider.instance_variable_get(:@context)
          context && context.instance_variable_get(:@key)
        end
      end
    end
  end
end
