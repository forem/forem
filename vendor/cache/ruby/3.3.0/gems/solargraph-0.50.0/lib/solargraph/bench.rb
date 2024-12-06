# frozen_string_literal: true

require 'set'

module Solargraph
  # A container of source maps and workspace data to be cataloged in an ApiMap.
  #
  class Bench
    # @return [Set<SourceMap>]
    attr_reader :source_maps

    # @return [Workspace]
    attr_reader :workspace

    # @return [Set<String>]
    attr_reader :external_requires

    # @param source_maps [Array<SourceMap>, Set<SourceMap>]
    # @param workspace [Workspace]
    # @param external_requires [Array<String>, Set<String>]
    def initialize source_maps: [], workspace: Workspace.new, external_requires: []
      @source_maps = source_maps.to_set
      @workspace = workspace
      @external_requires = external_requires.to_set
    end
  end
end
