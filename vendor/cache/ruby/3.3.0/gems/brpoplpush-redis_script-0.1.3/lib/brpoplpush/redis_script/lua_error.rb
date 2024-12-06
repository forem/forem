# frozen_string_literal: true

module Brpoplpush
  module RedisScript
    #
    # Misconfiguration is raised when gem is misconfigured
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    #
    class Misconfiguration < RuntimeError
    end

    # LuaError raised on errors in Lua scripts
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class LuaError < RuntimeError
      # Reformats errors raised by redis representing failures while executing
      # a lua script. The default errors have confusing messages and backtraces,
      # and a type of +RuntimeError+. This class improves the message and
      # modifies the backtrace to include the lua script itself in a reasonable
      # way.

      PATTERN  = /ERR Error (compiling|running) script \(.*?\): .*?:(\d+): (.*)/.freeze
      LIB_PATH = File.expand_path("..", __dir__).freeze
      CONTEXT_LINE_NUMBER = 2

      attr_reader :error, :file, :content

      # Is this error one that should be reformatted?
      #
      # @param error [StandardError] the original error raised by redis
      # @return [Boolean] is this an error that should be reformatted?
      def self.intercepts?(error)
        PATTERN.match?(error.message)
      end

      # Initialize a new {LuaError} from an existing redis error, adjusting
      # the message and backtrace in the process.
      #
      # @param error [StandardError] the original error raised by redis
      # @param script [Script] a DTO with information about the script
      #
      def initialize(error, script)
        @error        = error
        @file         = script.path
        @content      = script.source
        @backtrace    = @error.backtrace

        @error.message.match(PATTERN) do |regexp_match|
          line_number   = regexp_match[2].to_i
          message       = regexp_match[3]
          error_context = generate_error_context(content, line_number)

          super("#{message}\n\n#{error_context}\n\n")
          set_backtrace(generate_backtrace(file, line_number))
        end
      end

      private

      # :nocov:
      def generate_error_context(content, line_number)
        lines                 = content.lines.to_a
        beginning_line_number = [1, line_number - CONTEXT_LINE_NUMBER].max
        ending_line_number    = [lines.count, line_number + CONTEXT_LINE_NUMBER].min
        line_number_width     = ending_line_number.to_s.length

        (beginning_line_number..ending_line_number).map do |number|
          indicator = (number == line_number) ? "=>" : "  "
          formatted_number = format("%#{line_number_width}d", number)
          " #{indicator} #{formatted_number}: #{lines[number - 1]}"
        end.join.chomp
      end

      # :nocov:
      def generate_backtrace(file, line_number)
        pre_gem                 = backtrace_before_entering_gem(@backtrace)
        index_of_first_gem_line = (@backtrace.size - pre_gem.size - 1)

        pre_gem.unshift(@backtrace[index_of_first_gem_line])
        pre_gem.unshift("#{file}:#{line_number}")
        pre_gem
      end

      # :nocov:
      def backtrace_before_entering_gem(backtrace)
        backtrace.reverse.take_while { |line| !line_from_gem(line) }.reverse
      end

      # :nocov:
      def line_from_gem(line)
        line.split(":").first.include?(LIB_PATH)
      end
    end
  end
end
