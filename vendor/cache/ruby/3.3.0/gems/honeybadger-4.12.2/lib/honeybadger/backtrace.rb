require 'json'

module Honeybadger
  # @api private
  # Front end to parsing the backtrace for each notice.
  class Backtrace
    # Handles backtrace parsing line by line.
    class Line
      # Backtrace line regexp (optionally allowing leading X: for windows support).
      INPUT_FORMAT = %r{^((?:[a-zA-Z]:)?[^:]+):(\d+)(?::in `([^']+)')?$}.freeze

      # The file portion of the line (such as app/models/user.rb).
      attr_reader :file

      # The line number portion of the line.
      attr_reader :number

      # The method of the line (such as index).
      attr_reader :method

      # Filtered representations
      attr_reader :filtered_file, :filtered_number, :filtered_method

      # Parses a single line of a given backtrace
      #
      # @param [String] unparsed_line The raw line from +caller+ or some backtrace.
      #
      # @return The parsed backtrace line.
      def self.parse(unparsed_line, opts = {})
        filters = opts[:filters] || []
        filtered_line = filters.reduce(unparsed_line) do |line, proc|
          # TODO: Break if nil
          if proc.arity == 2
            proc.call(line, opts[:config])
          else
            proc.call(line)
          end
        end

        if filtered_line
          match = unparsed_line.match(INPUT_FORMAT) || [].freeze
          fmatch = filtered_line.match(INPUT_FORMAT) || [].freeze

          file, number, method = match[1], match[2], match[3]
          filtered_args = [fmatch[1], fmatch[2], fmatch[3]]
          new(file, number, method, *filtered_args, opts.fetch(:source_radius, 2))
        else
          nil
        end
      end

      def initialize(file, number, method, filtered_file = file,
                     filtered_number = number, filtered_method = method,
                     source_radius = 2)
        self.filtered_file   = filtered_file
        self.filtered_number = filtered_number
        self.filtered_method = filtered_method
        self.file            = file
        self.number          = number
        self.method          = method
        self.source_radius   = source_radius
      end

      # Reconstructs the line in a readable fashion.
      def to_s
        "#{filtered_file}:#{filtered_number}:in `#{filtered_method}'"
      end

      def ==(other)
        to_s == other.to_s
      end

      def inspect
        "<Line:#{to_s}>"
      end

      # Determines if this line is part of the application trace or not.
      def application?
        (filtered_file =~ /^\[PROJECT_ROOT\]/i) && !(filtered_file =~ /^\[PROJECT_ROOT\]\/vendor/i)
      end

      def source
        @source ||= get_source(file, number, source_radius)
      end

      private

      attr_writer :file, :number, :method, :filtered_file, :filtered_number, :filtered_method

      attr_accessor :source_radius

      # Open source file and read line(s).
      #
      # Returns an array of line(s) from source file.
      def get_source(file, number, radius = 2)
        if file && File.exist?(file)
          before = after = radius
          start = (number.to_i - 1) - before
          start = 0 and before = 1 if start <= 0
          duration = before + 1 + after

          l = 0
          File.open(file) do |f|
            start.times { f.gets ; l += 1 }
            return Hash[duration.times.map { (line = f.gets) ? [(l += 1), line] : nil }.compact]
          end
        else
          {}
        end
      end
    end

    # Holder for an Array of Backtrace::Line instances.
    attr_reader :lines, :application_lines

    def self.parse(ruby_backtrace, opts = {})
      ruby_lines = split_multiline_backtrace(ruby_backtrace.to_a)

      lines = ruby_lines.collect do |unparsed_line|
        Line.parse(unparsed_line.to_s, opts)
      end.compact

      instance = new(lines)
    end

    def initialize(lines)
      self.lines = lines
      self.application_lines = lines.select(&:application?)
    end

    # Convert Backtrace to arry.
    #
    # Returns array containing backtrace lines.
    def to_ary
      lines.take(1000).map { |l| { :number => l.filtered_number, :file => l.filtered_file, :method => l.filtered_method, :source => l.source } }
    end
    alias :to_a :to_ary

    # JSON support.
    #
    # Returns JSON representation of backtrace.
    def as_json(options = {})
      to_ary
    end

    # Creates JSON.
    #
    # Returns valid JSON representation of backtrace.
    def to_json(*a)
      as_json.to_json(*a)
    end

    def to_s
      lines.map(&:to_s).join("\n")
    end

    def inspect
      "<Backtrace: " + lines.collect { |line| line.inspect }.join(", ") + ">"
    end

    def ==(other)
      if other.respond_to?(:to_json)
        to_json == other.to_json
      else
        false
      end
    end

    private

    attr_writer :lines, :application_lines

    def self.split_multiline_backtrace(backtrace)
      if backtrace.size == 1
        backtrace.first.to_s.split(/\n\s*/)
      else
        backtrace
      end
    end
  end
end
