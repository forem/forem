# frozen_string_literal: true

require 'json'

module Datadog
  module Profiling
    # Entity class used to represent metadata for a given profile
    class Flush
      attr_reader \
        :start,
        :finish,
        :pprof_file_name,
        :pprof_data, # gzipped pprof bytes
        :code_provenance_file_name,
        :code_provenance_data, # gzipped json bytes
        :tags_as_array,
        :internal_metadata_json

      def initialize(
        start:,
        finish:,
        pprof_file_name:,
        pprof_data:,
        code_provenance_file_name:,
        code_provenance_data:,
        tags_as_array:,
        internal_metadata:
      )
        @start = start
        @finish = finish
        @pprof_file_name = pprof_file_name
        @pprof_data = pprof_data
        @code_provenance_file_name = code_provenance_file_name
        @code_provenance_data = code_provenance_data
        @tags_as_array = tags_as_array
        @internal_metadata_json = JSON.fast_generate(internal_metadata.map { |k, v| [k, v.to_s] }.to_h)
      end
    end
  end
end
