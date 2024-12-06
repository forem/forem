# frozen_string_literals: true

require "pp"
require "stringio"

module Lumberjack
  class Formatter
    # Format an object with it's pretty print method.
    class PrettyPrintFormatter
      attr_accessor :width

      # Create a new formatter. The maximum width of the message can be specified with the width
      # parameter (defaults to 79 characters).
      #
      # @param [Integer] width The maximum width of the message.
      def initialize(width = 79)
        @width = width
      end

      def call(obj)
        s = StringIO.new
        PP.pp(obj, s)
        s.string.chomp
      end
    end
  end
end
