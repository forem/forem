# frozen_string_literal: true

module Solargraph
  module Diagnostics
    # RequireNotFound reports required paths that could not be resolved to
    # either a file in the workspace or a gem.
    #
    class RequireNotFound < Base
      def diagnose source, api_map
        return [] unless source.parsed? && source.synchronized?
        result = []
        refs = {}
        map = api_map.source_map(source.filename)
        map.requires.each { |ref| refs[ref.name] = ref }
        api_map.missing_docs.each do |r|
          next unless refs.key?(r)
          result.push docs_error(r, refs[r].location)
        end
        api_map.unresolved_requires.each do |r|
          next unless refs.key?(r)
          result.push require_error(r, refs[r].location)
        end
        result
      end

      private

      # @param path [String]
      # @param location [Location]
      # @return [Hash]
      def docs_error path, location
        {
          range: location.range.to_hash,
          severity: Diagnostics::Severities::WARNING,
          source: 'RequireNotFound',
          message: "YARD docs not found for #{path}"
        }
      end

      # @param path [String]
      # @param location [Location]
      # @return [Hash]
      def require_error path, location
        {
          range: location.range.to_hash,
          severity: Diagnostics::Severities::WARNING,
          source: 'RequireNotFound',
          message: "Required path #{path} could not be resolved."
        }
      end
    end
  end
end
