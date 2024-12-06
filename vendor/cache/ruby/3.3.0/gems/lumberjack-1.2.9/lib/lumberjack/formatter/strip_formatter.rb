# frozen_string_literals: true

module Lumberjack
  class Formatter
    # Format an object by calling `to_s` on it and stripping leading and trailing whitespace.
    class StripFormatter
      def call(obj)
        obj.to_s.strip
      end
    end
  end
end
