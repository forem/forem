module PgQuery
  class ParseError < ArgumentError
    attr_reader :location
    def initialize(message, source_file, source_line, location)
      super("#{message} (#{source_file}:#{source_line})")
      @location = location
    end
  end
end
