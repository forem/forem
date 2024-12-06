# frozen_string_literal: true

module Anyway
  using Anyway::Ext::DeepDup

  module Utils
    def self.deep_merge!(source, other)
      other.each do |key, other_value|
        this_value = source[key]

        if this_value.is_a?(::Hash) && other_value.is_a?(::Hash)
          deep_merge!(this_value, other_value)
        else
          source[key] = other_value.deep_dup
        end
      end

      source
    end
  end
end
