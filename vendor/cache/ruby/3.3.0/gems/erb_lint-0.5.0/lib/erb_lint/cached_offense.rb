# frozen_string_literal: true

module ERBLint
  # A Cached version of an Offense with only essential information represented as strings
  class CachedOffense
    attr_reader(
      :message,
      :line_number,
      :severity,
      :column,
      :simple_name,
      :last_line,
      :last_column,
      :length,
    )

    def initialize(params)
      params = params.transform_keys(&:to_sym)

      @message = params[:message]
      @line_number = params[:line_number]
      @severity = params[:severity]&.to_sym
      @column = params[:column]
      @simple_name = params[:simple_name]
      @last_line = params[:last_line]
      @last_column = params[:last_column]
      @length = params[:length]
    end

    def self.new_from_offense(offense)
      new(
        {
          message: offense.message,
          line_number: offense.line_number,
          severity: offense.severity,
          column: offense.column,
          simple_name: offense.simple_name,
          last_line: offense.last_line,
          last_column: offense.last_column,
          length: offense.length,
        }
      )
    end

    def to_h
      {
        message: message,
        line_number: line_number,
        severity: severity,
        column: column,
        simple_name: simple_name,
        last_line: last_line,
        last_column: last_column,
        length: length,
      }
    end
  end
end
