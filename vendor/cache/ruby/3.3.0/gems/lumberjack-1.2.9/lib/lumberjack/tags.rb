# frozen_string_literal: true

module Lumberjack
  class Tags
    class << self
      # Transform hash keys to strings. This method exists for optimization and backward compatibility.
      # If a hash already has string keys, it will be returned as is.
      #
      # @param [Hash] hash The hash to transform.
      # @return [Hash] The hash with string keys.
      def stringify_keys(hash)
        return nil if hash.nil?
        if hash.keys.all? { |key| key.is_a?(String) }
          hash
        elsif hash.respond_to?(:transform_keys)
          hash.transform_keys(&:to_s)
        else
          copy = {}
          hash.each do |key, value|
            copy[key.to_s] = value
          end
          copy
        end
      end

      # Ensure keys are strings and expand any values in a hash that are Proc's by calling them and replacing
      # the value with the result. This allows setting global tags with runtime values.
      #
      # @param [Hash] hash The hash to transform.
      # @return [Hash] The hash with string keys and expanded values.
      def expand_runtime_values(hash)
        return nil if hash.nil?
        if hash.all? { |key, value| key.is_a?(String) && !value.is_a?(Proc) }
          return hash
        end

        copy = {}
        hash.each do |key, value|
          if value.is_a?(Proc) && (value.arity == 0 || value.arity == -1)
            value = value.call
          end
          copy[key.to_s] = value
        end
        copy
      end
    end
  end
end
