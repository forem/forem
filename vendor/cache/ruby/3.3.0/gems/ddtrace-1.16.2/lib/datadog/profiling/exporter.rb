require_relative 'ext'
require_relative 'tag_builder'

module Datadog
  module Profiling
    # Exports profiling data gathered by the multiple recorders in a `Flush`.
    #
    # @ivoanjo: Note that the recorder that gathers pprof data is special, since we use its start/finish/empty? to
    # decide if there's data to flush, as well as the timestamp for that data.
    # I could've made the whole design more generic, but I'm unsure if we'll ever have more than a handful of
    # recorders, so I've decided to make it specific until we actually need to support more recorders.
    #
    class Exporter
      # Profiles with duration less than this will not be reported
      PROFILE_DURATION_THRESHOLD_SECONDS = 1

      private

      attr_reader \
        :pprof_recorder,
        :code_provenance_collector, # The code provenance collector acts both as collector and as a recorder
        :minimum_duration_seconds,
        :time_provider,
        :last_flush_finish_at,
        :created_at,
        :internal_metadata

      public

      def initialize(
        pprof_recorder:,
        code_provenance_collector:,
        internal_metadata:,
        minimum_duration_seconds: PROFILE_DURATION_THRESHOLD_SECONDS,
        time_provider: Time
      )
        @pprof_recorder = pprof_recorder
        @code_provenance_collector = code_provenance_collector
        @minimum_duration_seconds = minimum_duration_seconds
        @time_provider = time_provider
        @last_flush_finish_at = nil
        @created_at = time_provider.now.utc
        @internal_metadata = internal_metadata
      end

      def flush
        start, finish, uncompressed_pprof = pprof_recorder.serialize
        @last_flush_finish_at = finish

        return if uncompressed_pprof.nil? # We don't want to report empty profiles

        if duration_below_threshold?(start, finish)
          Datadog.logger.debug('Skipped exporting profiling events as profile duration is below minimum')
          return
        end

        uncompressed_code_provenance = code_provenance_collector.refresh.generate_json if code_provenance_collector

        Flush.new(
          start: start,
          finish: finish,
          pprof_file_name: Datadog::Profiling::Ext::Transport::HTTP::PPROF_DEFAULT_FILENAME,
          pprof_data: uncompressed_pprof.to_s,
          code_provenance_file_name: Datadog::Profiling::Ext::Transport::HTTP::CODE_PROVENANCE_FILENAME,
          code_provenance_data: uncompressed_code_provenance,
          tags_as_array: Datadog::Profiling::TagBuilder.call(settings: Datadog.configuration).to_a,
          internal_metadata: internal_metadata,
        )
      end

      def can_flush?
        !duration_below_threshold?(last_flush_finish_at || created_at, time_provider.now.utc)
      end

      def reset_after_fork
        @last_flush_finish_at = time_provider.now.utc
        nil
      end

      private

      def duration_below_threshold?(start, finish)
        (finish - start) < minimum_duration_seconds
      end
    end
  end
end
