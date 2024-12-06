# frozen_string_literal: true

module SidekiqUniqueJobs
  # Utility module for reducing the number of uses of logger.
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  module Logging
    def self.included(base)
      base.send(:extend, self)
    end

    #
    # A convenience method for using the configured gem logger
    #
    # @see SidekiqUniqueJobs#.logger
    #
    # @return [Logger]
    #
    def logger
      SidekiqUniqueJobs.logger
    end

    #
    # Logs a message at debug level
    #
    # @param [String, Exception] message_or_exception the message or exception to log
    #
    # @return [void]
    #
    # @yield [String, Exception] the message or exception to use for log message
    #
    def log_debug(message_or_exception = nil, item = nil, &block)
      return unless logging?

      message = build_message(message_or_exception, item)
      logger.debug(message, &block)
      nil
    end

    #
    # Logs a message at info level
    #
    # @param [String, Exception] message_or_exception the message or exception to log
    #
    # @return [void]
    #
    # @yield [String, Exception] the message or exception to use for log message
    #
    def log_info(message_or_exception = nil, item = nil, &block)
      return unless logging?

      message = build_message(message_or_exception, item)
      logger.info(message, &block)
      nil
    end

    #
    # Logs a message at warn level
    #
    # @param [String, Exception] message_or_exception the message or exception to log
    #
    # @return [void]
    #
    # @yield [String, Exception] the message or exception to use for log message
    #
    def log_warn(message_or_exception = nil, item = nil, &block)
      return unless logging?

      message = build_message(message_or_exception, item)
      logger.warn(message, &block)
      nil
    end

    #
    # Logs a message at error level
    #
    # @param [String, Exception] message_or_exception the message or exception to log
    #
    # @return [void]
    #
    # @yield [String, Exception] the message or exception to use for log message
    #
    def log_error(message_or_exception = nil, item = nil, &block)
      return unless logging?

      message = build_message(message_or_exception, item)
      logger.error(message, &block)
      nil
    end

    #
    # Logs a message at fatal level
    #
    # @param [String, Exception] message_or_exception the message or exception to log
    #
    # @return [void]
    #
    # @yield [String, Exception] the message or exception to use for log message
    #
    def log_fatal(message_or_exception = nil, item = nil, &block)
      return unless logging?

      message = build_message(message_or_exception, item)
      logger.fatal(message, &block)

      nil
    end

    #
    # Build a log message
    #
    # @param [String, Exception] message_or_exception an entry to log
    # @param [Hash] item the sidekiq job hash
    #
    # @return [String] a complete log entry
    #
    def build_message(message_or_exception, item = nil)
      return nil if message_or_exception.nil?
      return message_or_exception if item.nil?

      message = message_or_exception.dup
      details = item.slice(LOCK, QUEUE, CLASS, JID, LOCK_DIGEST).each_with_object([]) do |(key, value), memo|
        memo << "#{key}=#{value}"
      end
      message << " ("
      message << details.join(" ")
      message << ")"

      message
    end

    #
    # Wraps the middleware logic with context aware logging
    #
    #
    # @return [void]
    #
    # @yieldreturn [void] yield to the middleware instance
    #
    def with_logging_context
      with_configured_loggers_context do
        return yield
      end

      nil # Need to make sure we don't return anything here
    end

    #
    # Attempt to setup context aware logging for the given logger
    #
    #
    # @return [void]
    #
    # @yield
    #
    def with_configured_loggers_context(&block)
      logger_method.call(logging_context, &block)
    end

    #
    # Setup some variables to add to each log line
    #
    #
    # @return [Hash] the context to use for each log line
    #
    def logging_context
      raise NotImplementedError, "#{__method__} needs to be implemented in #{self.class}"
    end

    private

    #
    # A memoized method to use for setting up a logging context
    #
    #
    # @return [proc] the method to call
    #
    def logger_method
      @logger_method ||= sidekiq_context_method
      @logger_method ||= sidekiq_logger_context_method
      @logger_method ||= sidekiq_logging_context_method
      @logger_method ||= no_sidekiq_context_method
    end

    #
    # Checks if the logger respond to `with_context`.
    #
    # @note only used to remove the need for explicitly ignoring manual dispatch in other places.
    #
    #
    # @return [true,false]
    #
    def logger_respond_to_with_context?
      logger.respond_to?(:with_context)
    end

    #
    # Checks if the logger context takes a hash argument
    #
    # @note only used to remove the need for explicitly ignoring manual dispatch in other places.
    #
    #
    # @return [true,false]
    #
    def logger_context_hash?
      defined?(Sidekiq::Context) || logger_respond_to_with_context?
    end

    def sidekiq_context_method
      Sidekiq::Context.method(:with) if defined?(Sidekiq::Context)
    end

    def sidekiq_logger_context_method
      logger.method(:with_context) if logger_respond_to_with_context?
    end

    def sidekiq_logging_context_method
      Sidekiq::Logging.method(:with_context) if defined?(Sidekiq::Logging)
    end

    def no_sidekiq_context_method
      method(:fake_logger_context)
    end

    def fake_logger_context(_context)
      logger.warn "Don't know how to setup the logging context. Please open a feature request:" \
                  " https://github.com/mhenrixon/sidekiq-unique-jobs/issues/new?template=feature_request.md"

      yield
    end

    def logging?
      SidekiqUniqueJobs.logging?
    end
  end
end
