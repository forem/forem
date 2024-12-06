# frozen_string_literal: true

module I18n::Tasks
  module Scanners
    module Results
      # The occurrence of some key in a file.
      #
      # @note This is a value type. Equality and hash code are determined from the attributes.
      class Occurrence
        # @return [String] source path relative to the current working directory.
        attr_reader :path

        # @return [Integer] count of characters in the file before the occurrence.
        attr_reader :pos

        # @return [Integer] line number of the occurrence, counting from 1.
        attr_reader :line_num

        # @return [Integer] position of the start of the occurrence in the line, counting from 1.
        attr_reader :line_pos

        # @return [String] the line of the occurrence, excluding the last LF or CRLF.
        attr_reader :line

        # @return [String, nil] the value of the `default:` argument of the translate call.
        attr_reader :default_arg

        # @return [String, nil] the raw key (for relative keys and references)
        attr_accessor :raw_key

        # @param path        [String]
        # @param pos         [Integer]
        # @param line_num    [Integer]
        # @param line_pos    [Integer]
        # @param line        [String]
        # @param raw_key     [String, nil]
        # @param default_arg [String, nil]
        # rubocop:disable Metrics/ParameterLists
        def initialize(path:, pos:, line_num:, line_pos:, line:, raw_key: nil, default_arg: nil)
          @path        = path
          @pos         = pos
          @line_num    = line_num
          @line_pos    = line_pos
          @line        = line
          @raw_key     = raw_key
          @default_arg = default_arg
        end
        # rubocop:enable Metrics/ParameterLists

        def inspect
          "Occurrence(#{@path}:#{@line_num}, line_pos: #{@line_pos}, pos: #{@pos}, raw_key: #{@raw_key}, default_arg: #{@default_arg}, line: #{@line})" # rubocop:disable Layout/LineLength
        end

        def ==(other)
          other.path == @path && other.pos == @pos && other.line_num == @line_num && other.line == @line &&
            other.raw_key == @raw_key && other.default_arg == @default_arg
        end

        def eql?(other)
          self == other
        end

        def hash
          [@path, @pos, @line_num, @line_pos, @line, @default_arg].hash
        end

        # @param raw_key [String]
        # @param range [Parser::Source::Range]
        # @param default_arg [String, nil]
        # @return [Results::Occurrence]
        def self.from_range(raw_key:, range:, default_arg: nil)
          Occurrence.new(
            path: range.source_buffer.name,
            pos: range.begin_pos,
            line_num: range.line,
            line_pos: range.column,
            line: range.source_line,
            raw_key: raw_key,
            default_arg: default_arg
          )
        end
      end
    end
  end
end
