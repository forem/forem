# frozen_string_literal: true

module Honeycomb
  ##
  # Functionality for including 'rollup_fields'. Which are fields that can be
  # tracked numerically and will also be propogated up to an existing trace.
  #
  module RollupFields
    def rollup_fields
      @rollup_fields ||= Hash.new(0)
    end

    def add_rollup_field(key, value)
      return unless value.is_a? Numeric

      respond_to?(:trace) && trace.add_rollup_field(key, value)
      rollup_fields[key] += value
    end
  end
end
