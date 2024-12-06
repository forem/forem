module Datadog
  module Profiling
    # Stores stack samples in a native libdatadog data structure and expose Ruby-level serialization APIs
    # Note that `record_sample` is only accessible from native code.
    # Methods prefixed with _native_ are implemented in `stack_recorder.c`
    class StackRecorder
      def initialize(cpu_time_enabled:, alloc_samples_enabled:)
        # This mutex works in addition to the fancy C-level mutexes we have in the native side (see the docs there).
        # It prevents multiple Ruby threads calling serialize at the same time -- something like
        # `10.times { Thread.new { stack_recorder.serialize } }`.
        # This isn't something we expect to happen normally, but because it would break the assumptions of the
        # C-level mutexes (that there is a single serializer thread), we add it here as an extra safeguard against it
        # accidentally happening.
        @no_concurrent_synchronize_mutex = Mutex.new

        self.class._native_initialize(self, cpu_time_enabled, alloc_samples_enabled)
      end

      def serialize
        status, result = @no_concurrent_synchronize_mutex.synchronize { self.class._native_serialize(self) }

        if status == :ok
          start, finish, encoded_pprof = result

          Datadog.logger.debug { "Encoded profile covering #{start.iso8601} to #{finish.iso8601}" }

          [start, finish, encoded_pprof]
        else
          error_message = result

          Datadog.logger.error("Failed to serialize profiling data: #{error_message}")

          nil
        end
      end

      def serialize!
        status, result = @no_concurrent_synchronize_mutex.synchronize { self.class._native_serialize(self) }

        if status == :ok
          _start, _finish, encoded_pprof = result

          encoded_pprof
        else
          error_message = result

          raise("Failed to serialize profiling data: #{error_message}")
        end
      end

      def reset_after_fork
        self.class._native_reset_after_fork(self)
      end
    end
  end
end
