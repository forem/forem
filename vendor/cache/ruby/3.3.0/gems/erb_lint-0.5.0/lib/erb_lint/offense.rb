# frozen_string_literal: true

module ERBLint
  # Defines common functionality available to all linters.
  class Offense
    attr_reader :linter, :source_range, :message, :context, :severity

    def initialize(linter, source_range, message, context = nil, severity = nil)
      unless source_range.is_a?(Parser::Source::Range)
        raise ArgumentError, "expected Parser::Source::Range for arg 2"
      end

      @linter = linter
      @source_range = source_range
      @message = message
      @context = context
      @severity = severity
      @disabled = false
    end

    def to_cached_offense_hash
      ERBLint::CachedOffense.new_from_offense(self).to_h
    end

    def inspect
      "#<#{self.class.name} linter=#{linter.class.name} "\
        "source_range=#{source_range.begin_pos}...#{source_range.end_pos} "\
        "message=#{message}> "\
        "severity=#{severity}"
    end

    def ==(other)
      other.class <= ERBLint::Offense &&
        other.linter == linter &&
        other.source_range == source_range &&
        other.message == message &&
        other.severity == severity
    end

    def line_range
      Range.new(source_range.line, source_range.last_line)
    end

    def line_number
      line_range.begin
    end

    attr_writer :disabled

    def disabled?
      @disabled
    end

    def column
      source_range.column
    end

    def simple_name
      linter.class.simple_name
    end

    def last_line
      source_range.last_line
    end

    def last_column
      source_range.last_column
    end

    def length
      source_range.length
    end
  end
end
