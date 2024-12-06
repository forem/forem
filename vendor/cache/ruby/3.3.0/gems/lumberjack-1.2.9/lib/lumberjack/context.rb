# frozen_string_literal: true

module Lumberjack
  # A context is used to store tags that are then added to all log entries within a block.
  class Context
    attr_reader :tags

    # @param [Context] parent_context A parent context to inherit tags from.
    def initialize(parent_context = nil)
      @tags = {}
      @tags.merge!(parent_context.tags) if parent_context
    end

    # Set tags on the context.
    #
    # @param [Hash] tags The tags to set.
    # @return [void]
    def tag(tags)
      tags.each do |key, value|
        @tags[key.to_s] = value
      end
    end

    # Get a context tag.
    #
    # @param [String, Symbol] key The tag key.
    # @return [Object] The tag value.
    def [](key)
      @tags[key.to_s]
    end

    # Set a context tag.
    #
    # @param [String, Symbol] key The tag key.
    # @param [Object] value The tag value.
    # @return [void]
    def []=(key, value)
      @tags[key.to_s] = value
    end

    # Clear all the context data.
    #
    # @return [void]
    def reset
      @tags.clear
    end
  end
end
