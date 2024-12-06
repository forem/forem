# frozen_string_literals: true

module Lumberjack
  # A template converts entries to strings. Templates can contain the following place holders to
  # reference log entry values:
  #
  # * :time
  # * :severity
  # * :progname
  # * :tags
  # * :message
  #
  # Any other words prefixed with a colon will be substituted with the value of the tag with that name.
  # If your tag name contains characters other than alpha numerics and the underscore, you must surround it
  # with curly brackets: `:{http.request-id}`.
  class Template
    TEMPLATE_ARGUMENT_ORDER = %w[:time :severity :progname :pid :message :tags].freeze
    MILLISECOND_TIME_FORMAT = "%Y-%m-%dT%H:%M:%S.%3N"
    MICROSECOND_TIME_FORMAT = "%Y-%m-%dT%H:%M:%S.%6N"
    PLACEHOLDER_PATTERN = /:(([a-z0-9_]+)|({[^}]+}))/i.freeze

    # Create a new template from the markup. The +first_line+ argument is used to format only the first
    # line of a message. Additional lines will be added to the message unformatted. If you wish to format
    # the additional lines, use the :additional_lines options to specify a template. Note that you'll need
    # to provide the line separator character in this template if you want to keep the message on multiple lines.
    #
    # The time will be formatted as YYYY-MM-DDTHH:MM:SSS.SSS by default. If you wish to change the format, you
    # can specify the :time_format option which can be either a time format template as documented in
    # +Time#strftime+ or the values +:milliseconds+ or +:microseconds+ to use the standard format with the
    # specified precision.
    #
    # Messages will have white space stripped from both ends.
    #
    # @param [String] first_line The template to use to format the first line of a message.
    # @param [Hash] options The options for the template.
    def initialize(first_line, options = {})
      @first_line_template, @first_line_tags = compile(first_line)
      additional_lines = options[:additional_lines] || "#{Lumberjack::LINE_SEPARATOR}:message"
      @additional_line_template, @additional_line_tags = compile(additional_lines)
      # Formatting the time is relatively expensive, so only do it if it will be used
      @template_include_time = first_line.include?(":time") || additional_lines.include?(":time")
      self.datetime_format = (options[:time_format] || :milliseconds)
    end

    # Set the format used to format the time.
    #
    # @param [String] format The format to use to format the time.
    def datetime_format=(format)
      if format == :milliseconds
        format = MILLISECOND_TIME_FORMAT
      elsif format == :microseconds
        format = MICROSECOND_TIME_FORMAT
      end
      @time_formatter = Formatter::DateTimeFormatter.new(format)
    end

    # Get the format used to format the time.
    #
    # @return [String]
    def datetime_format
      @time_formatter.format
    end

    # Convert an entry into a string using the template.
    #
    # @param [Lumberjack::LogEntry] entry The entry to convert to a string.
    # @return [String] The entry converted to a string.
    def call(entry)
      return entry unless entry.is_a?(LogEntry)

      first_line = entry.message.to_s
      additional_lines = nil
      if first_line.include?(Lumberjack::LINE_SEPARATOR)
        additional_lines = first_line.split(Lumberjack::LINE_SEPARATOR)
        first_line = additional_lines.shift
      end

      formatted_time = @time_formatter.call(entry.time) if @template_include_time
      format_args = [formatted_time, entry.severity_label, entry.progname, entry.pid, first_line]
      tag_arguments = tag_args(entry.tags, @first_line_tags)
      message = (@first_line_template % (format_args + tag_arguments))
      message.rstrip! if message.end_with?(" ")

      if additional_lines && !additional_lines.empty?
        tag_arguments = tag_args(entry.tags, @additional_line_tags) unless @additional_line_tags == @first_line_tags
        additional_lines.each do |line|
          format_args[format_args.size - 1] = line
          line_message = (@additional_line_template % (format_args + tag_arguments)).rstrip
          line_message.rstrip! if line_message.end_with?(" ")
          message << line_message
        end
      end
      message
    end

    private

    def tag_args(tags, tag_vars)
      return [nil] * (tag_vars.size + 1) if tags.nil? || tags.size == 0

      tags_string = ""
      tags.each do |name, value|
        unless value.nil? || tag_vars.include?(name)
          value = value.to_s
          value = value.gsub(Lumberjack::LINE_SEPARATOR, " ") if value.include?(Lumberjack::LINE_SEPARATOR)
          tags_string << "[#{name}:#{value}] "
        end
      end

      args = [tags_string.chop]
      tag_vars.each do |name|
        args << tags[name]
      end
      args
    end

    # Compile the template string into a value that can be used with sprintf.
    def compile(template) # :nodoc:
      tag_vars = []
      template = template.gsub(PLACEHOLDER_PATTERN) do |match|
        var_name = match.sub("{", "").sub("}", "")
        position = TEMPLATE_ARGUMENT_ORDER.index(var_name)
        if position
          "%#{position + 1}$s"
        else
          tag_vars << var_name[1, var_name.length]
          "%#{TEMPLATE_ARGUMENT_ORDER.size + tag_vars.size}$s"
        end
      end
      [template, tag_vars]
    end
  end
end
