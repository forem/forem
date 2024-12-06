# frozen_string_literals: true

module Lumberjack
  class Device
    # This logging device writes log entries as strings to an IO stream. By default, messages will be buffered
    # and written to the stream in a batch when the buffer is full or when +flush+ is called.
    #
    # Subclasses can implement a +before_flush+ method if they have logic to execute before flushing the log.
    # If it is implemented, it will be called before every flush inside a mutex lock.
    class Writer < Device
      DEFAULT_FIRST_LINE_TEMPLATE = "[:time :severity :progname(:pid) #:unit_of_work_id] :message :tags"
      DEFAULT_ADDITIONAL_LINES_TEMPLATE = "#{Lumberjack::LINE_SEPARATOR}> [#:unit_of_work_id] :message"

      # The size of the internal buffer. Defaults to 32K.
      attr_reader :buffer_size

      # Internal buffer to batch writes to the stream.
      class Buffer # :nodoc:
        attr_reader :size

        def initialize
          @values = []
          @size = 0
        end

        def <<(string)
          @values << string
          @size += string.size
        end

        def empty?
          @values.empty?
        end

        def pop!
          return nil if @values.empty?
          popped = @values
          clear
          popped
        end

        def clear
          @values = []
          @size = 0
        end
      end

      # Create a new device to write log entries to a stream. Entries are converted to strings
      # using a Template. The template can be specified using the :template option. This can
      # either be a Proc or a string that will compile into a Template object.
      #
      # If the template is a Proc, it should accept an LogEntry as its only argument and output a string.
      #
      # If the template is a template string, it will be used to create a Template. The
      # :additional_lines and :time_format options will be passed through to the
      # Template constuctor.
      #
      # The default template is "[:time :severity :progname(:pid) #:unit_of_work_id] :message"
      # with additional lines formatted as "\n [#:unit_of_work_id] :message". The unit of
      # work id will only appear if it is present.
      #
      # The size of the internal buffer in bytes can be set by providing :buffer_size (defaults to 32K).
      #
      # @param [IO] stream The stream to write log entries to.
      # @param [Hash] options The options for the device.
      def initialize(stream, options = {})
        @lock = Mutex.new
        @stream = stream
        @stream.sync = true if @stream.respond_to?(:sync=)
        @buffer = Buffer.new
        @buffer_size = (options[:buffer_size] || 0)
        template = (options[:template] || DEFAULT_FIRST_LINE_TEMPLATE)
        if template.respond_to?(:call)
          @template = template
        else
          additional_lines = (options[:additional_lines] || DEFAULT_ADDITIONAL_LINES_TEMPLATE)
          @template = Template.new(template, additional_lines: additional_lines, time_format: options[:time_format])
        end
      end

      # Set the buffer size in bytes. The device will only be physically written to when the buffer size
      # is exceeded.
      #
      # @param [Integer] value The size of the buffer in bytes.
      # @return [void]
      def buffer_size=(value)
        @buffer_size = value
        flush
      end

      # Write an entry to the stream. The entry will be converted into a string using the defined template.
      #
      # @param [LogEntry, String] entry The entry to write to the stream.
      # @return [void]
      def write(entry)
        string = (entry.is_a?(LogEntry) ? @template.call(entry) : entry)
        return if string.nil?
        string = string.strip
        return if string.length == 0

        unless string.encoding == Encoding::UTF_8
          string = string.encode("UTF-8", invalid: :replace, undef: :replace)
        end

        if buffer_size > 1
          @lock.synchronize do
            @buffer << string
          end
          flush if @buffer.size >= buffer_size
        else
          flush if respond_to?(:before_flush, true)
          write_to_stream(string)
        end
      end

      # Close the underlying stream.
      #
      # @return [void]
      def close
        flush
        stream.close
      end

      # Flush the underlying stream.
      #
      # @return [void]
      def flush
        lines = nil
        @lock.synchronize do
          before_flush if respond_to?(:before_flush, true)
          lines = @buffer.pop!
        end
        write_to_stream(lines) if lines
      end

      # Get the datetime format.
      #
      # @return [String] The datetime format.
      def datetime_format
        @template.datetime_format if @template.respond_to?(:datetime_format)
      end

      # Set the datetime format.
      #
      # @param [String] format The datetime format.
      # @return [void]
      def datetime_format=(format)
        if @template.respond_to?(:datetime_format=)
          @template.datetime_format = format
        end
      end

      protected

      # Set the underlying stream.
      attr_writer :stream

      # Get the underlying stream.
      attr_reader :stream

      private

      def write_to_stream(lines)
        return if lines.empty?
        lines = lines.first if lines.is_a?(Array) && lines.size == 1

        out = nil
        out = if lines.is_a?(Array)
          "#{lines.join(Lumberjack::LINE_SEPARATOR)}#{Lumberjack::LINE_SEPARATOR}"
        else
          "#{lines}#{Lumberjack::LINE_SEPARATOR}"
        end

        begin
          begin
            stream.write(out)
          rescue IOError => e
            # This condition can happen if another thread closed the stream in the `before_flush` call.
            # Synchronizing will handle the race condition, but since it's an exceptional case we don't
            # want to lock the thread on every stream write call.
            @lock.synchronize do
              if stream.closed?
                raise e
              else
                stream.write(out)
              end
            end
          end
          begin
            stream.flush
          rescue
            nil
          end
        rescue => e
          $stderr.write("#{e.class.name}: #{e.message}#{" at " + e.backtrace.first if e.backtrace}")
          $stderr.write(out)
          $stderr.flush
        end
      end
    end
  end
end
