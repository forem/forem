# frozen_string_literal: true

require "parser/source/buffer"
require "parser/source/range"

module BetterHtml
  module Tokenizer
    class Location < ::Parser::Source::Range
      def initialize(buffer, begin_pos, end_pos)
        raise ArgumentError,
          "first argument must be Parser::Source::Buffer" unless buffer.is_a?(::Parser::Source::Buffer)

        if begin_pos > buffer.source.size
          raise ArgumentError,
            "begin_pos location #{begin_pos} is out of range for document of size #{buffer.source.size}"
        end

        if (end_pos - 1) > buffer.source.size
          raise ArgumentError,
            "end_pos location #{end_pos} is out of range for document of size #{buffer.source.size}"
        end

        super(buffer, begin_pos, end_pos)
      end

      def range
        Range.new(begin_pos, end_pos, true)
      end

      def line_range
        Range.new(start_line, stop_line)
      end

      alias_method :start_line, :line
      alias_method :stop_line, :last_line
      alias_method :start_column, :column
      alias_method :stop_column, :last_column

      def line_source_with_underline
        spaces = source_line.scan(/\A\s*/).first
        column_without_spaces = [column - spaces.length, 0].max
        underscore_length = [[end_pos - begin_pos, source_line.length - column_without_spaces].min, 1].max
        "#{source_line.gsub(/\A\s*/, "")}\n#{" " * column_without_spaces}#{"^" * underscore_length}"
      end

      def with(begin_pos: @begin_pos, end_pos: @end_pos)
        self.class.new(@source_buffer, begin_pos, end_pos)
      end

      def adjust(begin_pos: 0, end_pos: 0)
        self.class.new(@source_buffer, @begin_pos + begin_pos, @end_pos + end_pos)
      end

      def resize(new_size)
        with(end_pos: @begin_pos + new_size)
      end

      def offset(offset)
        with(begin_pos: offset + @begin_pos, end_pos: offset + @end_pos)
      end

      def begin
        with(end_pos: @begin_pos)
      end

      def end
        with(begin_pos: @end_pos)
      end
    end
  end
end
