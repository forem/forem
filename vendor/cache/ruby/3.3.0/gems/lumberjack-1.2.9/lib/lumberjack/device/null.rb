# frozen_string_literals: true

module Lumberjack
  class Device
    # This is a logging device that produces no output. It can be useful in
    # testing environments when log file output is not useful.
    class Null < Device
      def initialize(*args)
      end

      def write(entry)
      end
    end
  end
end
