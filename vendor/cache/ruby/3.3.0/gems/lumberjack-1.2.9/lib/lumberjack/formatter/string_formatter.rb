# frozen_string_literals: true

module Lumberjack
  class Formatter
    # Format an object by calling `to_s` on it.
    class StringFormatter
      def call(obj)
        obj.to_s
      end
    end
  end
end
