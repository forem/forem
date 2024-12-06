# frozen_string_literals: true

module Lumberjack
  class Formatter
    # Truncate a string object to a specific length. This is useful
    # for formatting messages when there is a limit on the number of
    # characters that can be logged per message. This formatter should
    # only be used when necessary since it is a lossy formatter.
    #
    # When a string is truncated, it will have a unicode ellipsis
    # character (U+2026) appended to the end of the string.
    class TruncateFormatter
      # @param [Integer] length The maximum length of the string (defaults to 32K)
      def initialize(length = 32768)
        @length = length
      end

      def call(obj)
        if obj.is_a?(String) && obj.length > @length
          "#{obj[0, @length - 1]}…"
        else
          obj
        end
      end
    end
  end
end
