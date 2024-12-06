# frozen_string_literals: true

module Lumberjack
  class Formatter
    # Format a Date, Time, or DateTime object. If you don't specify a format in the constructor,
    # it will use the ISO-8601 format.
    class DateTimeFormatter
      attr_reader :format

      # @param [String] format The format to use when formatting the date/time object.
      def initialize(format = nil)
        @format = format.dup.to_s.freeze unless format.nil?
      end

      def call(obj)
        if @format && obj.respond_to?(:strftime)
          obj.strftime(@format)
        elsif obj.respond_to?(:iso8601)
          obj.iso8601
        else
          obj.to_s
        end
      end
    end
  end
end
