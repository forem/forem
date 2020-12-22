# frozen_string_literal: true

module ERBLint
  # Defines common functionality available to all linters.
  class Offense
    attr_reader :linter, :source_range, :message, :context

    def initialize(linter, source_range, message, context = nil)
      unless source_range.is_a?(Parser::Source::Range)
        raise ArgumentError, "expected Parser::Source::Range for arg 2"
      end
      @linter = linter
      @source_range = source_range
      @message = message
      @context = context
    end

    def inspect
      "#<#{self.class.name} linter=#{linter.class.name} "\
        "source_range=#{source_range.begin_pos}...#{source_range.end_pos} "\
        "message=#{message}>"
    end

    def ==(other)
      other.class <= ERBLint::Offense &&
        other.linter == linter &&
        other.source_range == source_range &&
        other.message == message
    end

    def line_range
      Range.new(source_range.line, source_range.last_line)
    end

    def line_number
      line_range.begin
    end

    def column
      source_range.column
    end
  end
end
