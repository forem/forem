module BetterErrors
  # @private
  class CodeFormatter
    require "better_errors/code_formatter/html"
    require "better_errors/code_formatter/text"

    attr_reader :filename, :line, :context

    def initialize(filename, line, context = 5)
      @filename = filename
      @line     = line
      @context  = context
    end

    def output
      formatted_code
    rescue Errno::ENOENT, Errno::EINVAL
      source_unavailable
    end

    def line_range
      min = [line - context, 1].max
      max = [line + context, source_lines.count].min
      min..max
    end

    def context_lines
      range = line_range
      source_lines[(range.begin - 1)..(range.end - 1)] or raise Errno::EINVAL
    end

    private

    def formatted_code
      formatted_lines.join
    end

    def each_line_of(lines, &blk)
      line_range.zip(lines).map { |current_line, str|
        yield (current_line == line), current_line, str
      }
    end

    def source
      @source ||= File.read(filename)
    end

    def source_lines
      @source_lines ||= source.lines
    end
  end
end
