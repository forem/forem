# frozen_string_literals: true

module Lumberjack
  class Formatter
    # No-op formatter that just returns the object itself.
    class ObjectFormatter
      def call(obj)
        obj
      end
    end
  end
end
