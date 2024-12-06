# frozen_string_literal: true

module Brpoplpush
  module RedisScript
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
      # @see RedisScript#.logger
      #
      # @return [Logger]
      #
      def logger
        Brpoplpush::RedisScript.logger
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
      def log_debug(message_or_exception = nil, &block)
        logger.debug(message_or_exception, &block)
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
      def log_info(message_or_exception = nil, &block)
        logger.info(message_or_exception, &block)
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
      def log_warn(message_or_exception = nil, &block)
        logger.warn(message_or_exception, &block)
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
      def log_error(message_or_exception = nil, &block)
        logger.error(message_or_exception, &block)
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
      def log_fatal(message_or_exception = nil, &block)
        logger.fatal(message_or_exception, &block)
        nil
      end
    end
  end
end
