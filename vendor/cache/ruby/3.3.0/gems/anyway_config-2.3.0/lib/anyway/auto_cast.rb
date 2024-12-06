# frozen_string_literal: true

module Anyway
  module AutoCast
    # Regexp to detect array values
    # Array value is a values that contains at least one comma
    # and doesn't start/end with quote or curly braces
    ARRAY_RXP = /\A[^'"{].*\s*,\s*.*[^'"}]\z/

    class << self
      def call(val)
        return val unless val.is_a?(::Hash) || val.is_a?(::String)

        case val
        when Hash
          val.transform_values { call(_1) }
        when ARRAY_RXP
          val.split(/\s*,\s*/).map { call(_1) }
        when /\A(true|t|yes|y)\z/i
          true
        when /\A(false|f|no|n)\z/i
          false
        when /\A(nil|null)\z/i
          nil
        when /\A\d+\z/
          val.to_i
        when /\A\d*\.\d+\z/
          val.to_f
        when /\A['"].*['"]\z/
          val.gsub(/(\A['"]|['"]\z)/, "")
        else
          val
        end
      end

      def cast_hash(obj)
        obj.transform_values do |val|
          val.is_a?(::Hash) ? cast_hash(val) : call(val)
        end
      end

      def coerce(_key, val)
        call(val)
      end
    end
  end

  module NoCast
    def self.call(val) = val

    def self.coerce(_key, val) = val
  end
end
