# frozen_string_literal: true

require "delegate"
require "forwardable"

module Lumberjack
  # Methods to make Lumberjack::Logger API compatible with ActiveSupport::TaggedLogger.
  module TaggedLoggerSupport
    class Formatter < DelegateClass(Lumberjack::Formatter)
      extend Forwardable
      def_delegators :@logger, :tagged, :push_tags, :pop_tags, :clear_tags!

      def initialize(formatter:, logger:)
        @logger = logger
        @formatter = formatter
        super(formatter)
      end

      def current_tags
        tags = @logger.instance_variable_get(:@tags)
        if tags.is_a?(Hash)
          Array(tags["tagged"])
        else
          []
        end
      end

      def tags_text
        tags = current_tags
        if tags.any?
          tags.collect { |tag| "[#{tag}] " }.join
        end
      end

      def __formatter
        @formatter
      end
    end

    # Compatibility with ActiveSupport::TaggedLogging which only supports adding tags as strings.
    # If a tag looks like "key:value"  or "key=value", it will be added as a key value pair.
    # Otherwise it will be appended to a list named "tagged".
    def tagged(*tags, &block)
      tag_hash = {}
      tags.flatten.each do |tag|
        tagged_values = Array(tag_hash["tagged"] || self.tags["tagged"])
        tag_hash["tagged"] = tagged_values + [tag]
      end
      tag(tag_hash, &block)
    end

    def push_tags(*tags)
      tagged(*tags)
    end

    def pop_tags(size = 1)
      tagged_values = Array(@tags["tagged"])
      tagged_values = ((tagged_values.size > size) ? tagged_values[0, tagged_values.size - size] : nil)
      tag("tagged" => tagged_values)
    end

    def clear_tags!
      tag("tagged" => nil)
    end
  end
end
