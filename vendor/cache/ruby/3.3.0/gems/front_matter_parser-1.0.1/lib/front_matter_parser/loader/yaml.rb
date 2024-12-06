# frozen_string_literal: true

require 'yaml'

module FrontMatterParser
  module Loader
    # {Loader} that uses YAML library
    class Yaml
      # @!attribute [r] allowlist_classes
      # Classes that may be parsed by #call.
      attr_reader :allowlist_classes

      def initialize(allowlist_classes: [])
        @allowlist_classes = allowlist_classes
      end

      # Loads a hash front matter from a string
      #
      # @param string [String] front matter string representation
      # @return [Hash] front matter hash representation
      def call(string)
        YAML.safe_load(string, permitted_classes: allowlist_classes)
      end
    end
  end
end
