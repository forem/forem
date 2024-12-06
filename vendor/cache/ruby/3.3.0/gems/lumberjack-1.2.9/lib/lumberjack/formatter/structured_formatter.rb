# frozen_string_literals: true

require "set"

module Lumberjack
  class Formatter
    # Dereference arrays and hashes and recursively call formatters on each element.
    class StructuredFormatter
      class RecusiveReferenceError < StandardError
      end

      # @param [Formatter] formatter The formatter to call on each element
      #   in the structure.
      def initialize(formatter = nil)
        @formatter = formatter
      end

      def call(obj)
        call_with_references(obj, Set.new)
      end

      private

      def call_with_references(obj, references)
        if obj.is_a?(Hash)
          with_object_reference(obj, references) do
            hash = {}
            obj.each do |name, value|
              value = call_with_references(value, references)
              hash[name.to_s] = value unless value.is_a?(RecusiveReferenceError)
            end
            hash
          end
        elsif obj.is_a?(Enumerable) && obj.respond_to?(:size) && obj.size != Float::INFINITY
          with_object_reference(obj, references) do
            array = []
            obj.each do |value|
              value = call_with_references(value, references)
              array << value unless value.is_a?(RecusiveReferenceError)
            end
            array
          end
        elsif @formatter
          @formatter.format(obj)
        else
          obj
        end
      end

      def with_object_reference(obj, references)
        if obj.is_a?(Enumerable)
          return RecusiveReferenceError.new if references.include?(obj.object_id)
          references << obj.object_id
          begin
            yield
          ensure
            references.delete(obj.object_id)
          end
        else
          yield
        end
      end
    end
  end
end
