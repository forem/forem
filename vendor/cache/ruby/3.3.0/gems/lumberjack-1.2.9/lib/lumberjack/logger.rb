# frozen_string_literals: true

module Lumberjack
  # Logger is a thread safe logging object. It has a compatible API with the Ruby
  # standard library Logger class, the Log4r gem, and ActiveSupport::BufferedLogger.
  #
  # === Example
  #
  #   logger = Lumberjack::Logger.new
  #   logger.info("Starting processing")
  #   logger.debug("Processing options #{options.inspect}")
  #   logger.fatal("OMG the application is on fire!")
  #
  # Log entries are written to a logging Device if their severity meets or exceeds the log level.
  #
  # Devices may use buffers internally and the log entries are not guaranteed to be written until you call
  # the +flush+ method. Sometimes this can result in problems when trying to track down extraordinarily
  # long running sections of code since it is likely that none of the messages logged before the long
  # running code will appear in the log until the entire process finishes. You can set the +:flush_seconds+
  # option on the constructor to force the device to be flushed periodically. This will create a new
  # monitoring thread, but its use is highly recommended.
  #
  # Each log entry records the log message and severity along with the time it was logged, the
  # program name, process id, and unit of work id. The message will be converted to a string, but
  # otherwise, it is up to the device how these values are recorded. Messages are converted to strings
  # using a Formatter associated with the logger.
  class Logger
    include Severity

    # The time that the device was last flushed.
    attr_reader :last_flushed_at

    # Set +silencer+ to false to disable silencing the log.
    attr_accessor :silencer

    # Set the name of the program to attach to log entries.
    attr_writer :progname

    # The device being written to
    attr_accessor :device

    # The TagFormatter used for formatting tags for output
    attr_accessor :tag_formatter

    # Create a new logger to log to a Device.
    #
    # The +device+ argument can be in any one of several formats.
    #
    # If it is a Device object, that object will be used.
    # If it has a +write+ method, it will be wrapped in a Device::Writer class.
    # If it is :null, it will be a Null device that won't record any output.
    # Otherwise, it will be assumed to be file path and wrapped in a Device::LogFile class.
    #
    # This method can take the following options:
    #
    # * :level - The logging level below which messages will be ignored.
    # * :formatter - The formatter to use for outputting messages to the log.
    # * :datetime_format - The format to use for log timestamps.
    # * :tag_formatter - The TagFormatter to use for formatting tags.
    # * :progname - The name of the program that will be recorded with each log entry.
    # * :flush_seconds - The maximum number of seconds between flush calls.
    # * :roll - If the log device is a file path, it will be a Device::DateRollingLogFile if this is set.
    # * :max_size - If the log device is a file path, it will be a Device::SizeRollingLogFile if this is set.
    #
    # All other options are passed to the device constuctor.
    #
    # @param [Lumberjack::Device, Object, Symbol, String] device The device to log to.
    # @param [Hash] options The options for the logger.
    def initialize(device = $stdout, options = {})
      options = options.dup
      self.level = options.delete(:level) || INFO
      self.progname = options.delete(:progname)
      max_flush_seconds = options.delete(:flush_seconds).to_f

      @device = open_device(device, options) if device
      self.formatter = (options[:formatter] || Formatter.new)
      @tag_formatter = (options[:tag_formatter] || TagFormatter.new)
      time_format = (options[:datetime_format] || options[:time_format])
      self.datetime_format = time_format if time_format
      @last_flushed_at = Time.now
      @silencer = true
      @tags = {}
      @closed = false

      create_flusher_thread(max_flush_seconds) if max_flush_seconds > 0
    end

    # Get the timestamp format on the device if it has one.
    #
    # @return [String, nil] The timestamp format or nil if the device doesn't support it.
    def datetime_format
      device.datetime_format if device.respond_to?(:datetime_format)
    end

    # Set the timestamp format on the device if it is supported.
    #
    # @param [String] format The timestamp format.
    # @return [void]
    def datetime_format=(format)
      if device.respond_to?(:datetime_format=)
        device.datetime_format = format
      end
    end

    # Get the level of severity of entries that are logged. Entries with a lower
    # severity level will be ignored.
    #
    # @return [Integer] The severity level.
    def level
      thread_local_value(:lumberjack_logger_level) || @level
    end

    alias_method :sev_threshold, :level

    # Set the log level using either an integer level like Logger::INFO or a label like
    # :info or "info"
    #
    # @param [Integer, Symbol, String] value The severity level.
    # @return [void]
    def level=(value)
      @level = if value.is_a?(Integer)
        value
      else
        Severity.label_to_level(value)
      end
    end

    alias_method :sev_threshold=, :level=

    # Set the Lumberjack::Formatter used to format objects for logging as messages.
    #
    # @param [Lumberjack::Formatter, Object] value The formatter to use.
    # @return [void]
    def formatter=(value)
      @_formatter = (value.is_a?(TaggedLoggerSupport::Formatter) ? value.__formatter : value)
    end

    # Get the Lumberjack::Formatter used to format objects for logging as messages.
    #
    # @return [Lumberjack::Formatter] The formatter.
    def formatter
      if respond_to?(:tagged)
        # Wrap in an object that supports ActiveSupport::TaggedLogger API
        TaggedLoggerSupport::Formatter.new(logger: self, formatter: @_formatter)
      else
        @_formatter
      end
    end

    # Enable this logger to function like an ActiveSupport::TaggedLogger. This will make the logger
    # API compatible with ActiveSupport::TaggedLogger and is provided as a means of compatibility
    # with other libraries that assume they can call the `tagged` method on a logger to add tags.
    #
    # The tags added with this method are just strings so they are stored in the logger tags
    # in an array under the "tagged" tag. So calling `logger.tagged("foo", "bar")` will result
    # in tags `{"tagged" => ["foo", "bar"]}`.
    #
    # @return [Lumberjack::Logger] self.
    def tagged_logger!
      extend(TaggedLoggerSupport)
      self
    end

    # Add a message to the log with a given severity. The message can be either
    # passed in the +message+ argument or supplied with a block. This method
    # is not normally called. Instead call one of the helper functions
    # +fatal+, +error+, +warn+, +info+, or +debug+.
    #
    # The severity can be passed in either as one of the Severity constants,
    # or as a Severity label.
    #
    # @param [Integer, Symbol, String] severity The severity of the message.
    # @param [Object] message The message to log.
    # @param [String] progname The name of the program that is logging the message.
    # @param [Hash] tags The tags to add to the log entry.
    # @return [void]
    #
    # @example
    #
    #   logger.add_entry(Logger::ERROR, exception)
    #   logger.add_entry(Logger::INFO, "Request completed")
    #   logger.add_entry(:warn, "Request took a long time")
    #   logger.add_entry(Logger::DEBUG){"Start processing with options #{options.inspect}"}
    def add_entry(severity, message, progname = nil, tags = nil)
      begin
        severity = Severity.label_to_level(severity) unless severity.is_a?(Integer)
        return true unless device && severity && severity >= level

        return true if Thread.current[:lumberjack_logging]
        Thread.current[:lumberjack_logging] = true

        time = Time.now
        message = message.call if message.is_a?(Proc)
        message = formatter.format(message)
        progname ||= self.progname

        current_tags = self.tags
        tags = nil unless tags.is_a?(Hash)
        if current_tags.empty?
          tags = Tags.stringify_keys(tags) unless tags.nil?
        else
          tags = if tags.nil?
            current_tags.dup
          else
            current_tags.merge(Tags.stringify_keys(tags))
          end
        end
        tags = Tags.expand_runtime_values(tags)
        tags = tag_formatter.format(tags) if tag_formatter

        entry = LogEntry.new(time, severity, message, progname, $$, tags)
        write_to_device(entry)
      ensure
        Thread.current[:lumberjack_logging] = nil
      end
      true
    end

    # ::Logger compatible method to add a log entry.
    #
    # @param [Integer, Symbol, String] severity The severity of the message.
    # @param [Object] message The message to log.
    # @param [String] progname The name of the program that is logging the message.
    # @return [void]
    def add(severity, message = nil, progname = nil, &block)
      if message.nil?
        if block
          message = block
        else
          message = progname
          progname = nil
        end
      end
      add_entry(severity, message, progname)
    end

    alias_method :log, :add

    # Flush the logging device. Messages are not guaranteed to be written until this method is called.
    #
    # @return [void]
    def flush
      device.flush
      @last_flushed_at = Time.now
      nil
    end

    # Close the logging device.
    #
    # @return [void]
    def close
      flush
      device.close if device.respond_to?(:close)
      @closed = true
    end

    # Returns +true+ if the logging device is closed.
    #
    # @return [Boolean] +true+ if the logging device is closed.
    def closed?
      @closed
    end

    # Reopen the logging device.
    #
    # @param [Object] logdev passed through to the logging device.
    def reopen(logdev = nil)
      @closed = false
      device.reopen(logdev) if device.respond_to?(:reopen)
    end

    # Log a +FATAL+ message. The message can be passed in either the +message+ argument or in a block.
    #
    # @param [Object] message_or_progname_or_tags The message to log or progname
    #   if the message is passed in a block.
    # @param [String, Hash] progname_or_tags The name of the program that is logging the message or tags
    #   if the message is passed in a block.
    # @return [void]
    def fatal(message_or_progname_or_tags = nil, progname_or_tags = nil, &block)
      call_add_entry(FATAL, message_or_progname_or_tags, progname_or_tags, &block)
    end

    # Return +true+ if +FATAL+ messages are being logged.
    #
    # @return [Boolean]
    def fatal?
      level <= FATAL
    end

    # Set the log level to fatal.
    #
    # @return [void]
    def fatal!
      self.level = FATAL
    end

    # Log an +ERROR+ message. The message can be passed in either the +message+ argument or in a block.
    #
    # @param [Object] message_or_progname_or_tags The message to log or progname
    #   if the message is passed in a block.
    # @param [String, Hash] progname_or_tags The name of the program that is logging the message or tags
    #   if the message is passed in a block.
    # @return [void]
    def error(message_or_progname_or_tags = nil, progname_or_tags = nil, &block)
      call_add_entry(ERROR, message_or_progname_or_tags, progname_or_tags, &block)
    end

    # Return +true+ if +ERROR+ messages are being logged.
    #
    # @return [Boolean]
    def error?
      level <= ERROR
    end

    # Set the log level to error.
    #
    # @return [void]
    def error!
      self.level = ERROR
    end

    # Log a +WARN+ message. The message can be passed in either the +message+ argument or in a block.
    #
    # @param [Object] message_or_progname_or_tags The message to log or progname
    #   if the message is passed in a block.
    # @param [String, Hash] progname_or_tags The name of the program that is logging the message or tags
    #   if the message is passed in a block.
    # @return [void]
    def warn(message_or_progname_or_tags = nil, progname_or_tags = nil, &block)
      call_add_entry(WARN, message_or_progname_or_tags, progname_or_tags, &block)
    end

    # Return +true+ if +WARN+ messages are being logged.
    #
    # @return [Boolean]
    def warn?
      level <= WARN
    end

    # Set the log level to warn.
    #
    # @return [void]
    def warn!
      self.level = WARN
    end

    # Log an +INFO+ message. The message can be passed in either the +message+ argument or in a block.
    #
    # @param [Object] message_or_progname_or_tags The message to log or progname
    #   if the message is passed in a block.
    # @param [String] progname_or_tags The name of the program that is logging the message or tags
    #   if the message is passed in a block.
    # @return [void]
    def info(message_or_progname_or_tags = nil, progname_or_tags = nil, &block)
      call_add_entry(INFO, message_or_progname_or_tags, progname_or_tags, &block)
    end

    # Return +true+ if +INFO+ messages are being logged.
    #

    def info?
      level <= INFO
    end

    # Set the log level to info.
    #
    # @return [void]
    def info!
      self.level = INFO
    end

    # Log a +DEBUG+ message. The message can be passed in either the +message+ argument or in a block.
    #
    # @param [Object] message_or_progname_or_tags The message to log or progname
    #   if the message is passed in a block.
    # @param [String, Hash] progname_or_tags The name of the program that is logging the message or tags
    #   if the message is passed in a block.
    # @return [void]
    def debug(message_or_progname_or_tags = nil, progname_or_tags = nil, &block)
      call_add_entry(DEBUG, message_or_progname_or_tags, progname_or_tags, &block)
    end

    # Return +true+ if +DEBUG+ messages are being logged.
    #
    # @return [Boolean]
    def debug?
      level <= DEBUG
    end

    # Set the log level to debug.
    #
    # @return [void]
    def debug!
      self.level = DEBUG
    end

    # Log a message when the severity is not known. Unknown messages will always appear in the log.
    # The message can be passed in either the +message+ argument or in a block.
    #
    # @param [Object] message_or_progname_or_tags The message to log or progname
    #   if the message is passed in a block.
    # @param [String, Hash] progname_or_tags The name of the program that is logging the message or tags
    #   if the message is passed in a block.
    # @return [void]
    def unknown(message_or_progname_or_tags = nil, progname_or_tags = nil, &block)
      call_add_entry(UNKNOWN, message_or_progname_or_tags, progname_or_tags, &block)
    end

    # Add a message when the severity is not known.
    #
    # @param [Object] msg The message to log.
    # @return [void]
    def <<(msg)
      add_entry(UNKNOWN, msg)
    end

    # Silence the logger by setting a new log level inside a block. By default, only +ERROR+ or +FATAL+
    # messages will be logged.
    #
    # @param [Integer, String, Symbol] temporary_level The log level to use inside the block.
    # @return [Object] The result of the block.
    #
    # @example
    #
    #   logger.level = Logger::INFO
    #   logger.silence do
    #     do_something   # Log level inside the block is +ERROR+
    #   end
    def silence(temporary_level = ERROR, &block)
      if silencer
        unless temporary_level.is_a?(Integer)
          temporary_level = Severity.label_to_level(temporary_level)
        end
        push_thread_local_value(:lumberjack_logger_level, temporary_level, &block)
      else
        yield
      end
    end

    # Set the program name that is associated with log messages. If a block
    # is given, the program name will be valid only within the block.
    #
    # @param [String] value The program name to use.
    # @return [void]
    def set_progname(value, &block)
      if block
        push_thread_local_value(:lumberjack_logger_progname, value, &block)
      else
        self.progname = value
      end
    end

    # Get the program name associated with log messages.
    #
    # @return [String]
    def progname
      thread_local_value(:lumberjack_logger_progname) || @progname
    end

    # Set a hash of tags on logger. If a block is given, the tags will only be set
    # for the duration of the block. If this method is called inside such a block,
    # the tags will only be defined on the tags in that block. When the parent block
    # exits, all the tags will be reverted. If there is no block, then the tags will
    # be defined as global and apply to all log statements.
    #
    # @param [Hash] tags The tags to set.
    # @return [void]
    def tag(tags, &block)
      tags = Tags.stringify_keys(tags)
      thread_tags = thread_local_value(:lumberjack_logger_tags)
      if block
        merged_tags = (thread_tags ? thread_tags.merge(tags) : tags.dup)
        push_thread_local_value(:lumberjack_logger_tags, merged_tags, &block)
      elsif thread_tags
        thread_tags.merge!(tags)
        nil
      else
        @tags.merge!(tags)
        nil
      end
    end

    # Remove a tag from the current tag context. If this is called inside a block to a
    # call to `tag`, the tags will only be removed for the duration of that block. Otherwise
    # they will be removed from the global tags.
    #
    # @param [Array<String, Symbol>] tag_names The tags to remove.
    # @return [void]
    def remove_tag(*tag_names)
      thread_tags = thread_local_value(:lumberjack_logger_tags)
      if thread_tags
        tag_names.each { |name| thread_tags.delete(name.to_s) }
      else
        tag_names.each { |name| @tags.delete(name.to_s) }
      end
    end

    # Return all tags in scope on the logger including global tags set on the Lumberjack
    # context, tags set on the logger, and tags set on the current block for the logger.
    #
    # @return [Hash]
    def tags
      tags = {}
      context_tags = Lumberjack.context_tags
      tags.merge!(context_tags) if context_tags && !context_tags.empty?
      tags.merge!(@tags) if !@tags.empty? && !thread_local_value(:lumberjack_logger_untagged)
      scope_tags = thread_local_value(:lumberjack_logger_tags)
      tags.merge!(scope_tags) if scope_tags && !scope_tags.empty?
      tags
    end

    # Remove all tags on the current logger and logging context within a block.
    # You can still set new block scoped tags within theuntagged block and provide
    # tags on individual log methods.
    #
    # @return [void]
    def untagged(&block)
      Lumberjack.use_context(nil) do
        scope_tags = thread_local_value(:lumberjack_logger_tags)
        untagged = thread_local_value(:lumberjack_logger_untagged)
        begin
          set_thread_local_value(:lumberjack_logger_untagged, true)
          set_thread_local_value(:lumberjack_logger_tags, nil)
          tag({}, &block)
        ensure
          set_thread_local_value(:lumberjack_logger_untagged, untagged)
          set_thread_local_value(:lumberjack_logger_tags, scope_tags)
        end
      end
    end

    private

    # Dereference arguments to log calls so we can have methods with compatibility with ::Logger
    def call_add_entry(severity, message_or_progname_or_tags, progname_or_tags, &block) # :nodoc:
      message = nil
      progname = nil
      tags = nil
      if block
        message = block
        if message_or_progname_or_tags.is_a?(Hash)
          tags = message_or_progname_or_tags
          progname = progname_or_tags
        else
          progname = message_or_progname_or_tags
          tags = progname_or_tags if progname_or_tags.is_a?(Hash)
        end
      else
        message = message_or_progname_or_tags
        if progname_or_tags.is_a?(Hash)
          tags = progname_or_tags
        else
          progname = progname_or_tags
        end
      end
      add_entry(severity, message, progname, tags)
    end

    # Set a local value for a thread tied to this object.
    def set_thread_local_value(name, value) # :nodoc:
      values = Thread.current[name]
      unless values
        values = {}
        Thread.current[name] = values
      end
      if value.nil?
        values.delete(self)
        Thread.current[name] = nil if values.empty?
      else
        values[self] = value
      end
    end

    # Get a local value for a thread tied to this object.
    def thread_local_value(name) # :nodoc:
      values = Thread.current[name]
      values[self] if values
    end

    # Set a local value for a thread tied to this object within a block.
    def push_thread_local_value(name, value) # :nodoc:
      save_val = thread_local_value(name)
      set_thread_local_value(name, value)
      begin
        yield
      ensure
        set_thread_local_value(name, save_val)
      end
    end

    # Open a logging device.
    def open_device(device, options) # :nodoc:
      if device.nil?
        nil
      elsif device.is_a?(Device)
        device
      elsif device.respond_to?(:write) && device.respond_to?(:flush)
        Device::Writer.new(device, options)
      elsif device == :null
        Device::Null.new
      else
        device = device.to_s
        if options[:roll]
          Device::DateRollingLogFile.new(device, options)
        elsif options[:max_size]
          Device::SizeRollingLogFile.new(device, options)
        else
          Device::LogFile.new(device, options)
        end
      end
    end

    def write_to_device(entry) # :nodoc:
      device.write(entry)
    rescue => e
      # rubocop:disable Style/StderrPuts
      $stderr.puts("#{e.class.name}: #{e.message}#{" at " + e.backtrace.first if e.backtrace}")
      $stderr.puts(entry.to_s)
      # rubocop:enable Style/StderrPuts
    end

    # Create a thread that will periodically call flush.
    def create_flusher_thread(flush_seconds) # :nodoc:
      if flush_seconds > 0
        begin
          logger = self
          Thread.new do
            until closed?
              begin
                sleep(flush_seconds)
                logger.flush if Time.now - logger.last_flushed_at >= flush_seconds
              rescue => e
                warn("Error flushing log: #{e.inspect}")
              end
            end
          end
        end
      end
    end
  end
end
