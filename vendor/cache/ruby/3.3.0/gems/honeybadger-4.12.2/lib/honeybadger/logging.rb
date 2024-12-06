require 'logger'
require 'singleton'
require 'delegate'
require 'forwardable'

module Honeybadger
  # @api private
  module Logging
    PREFIX = '** [Honeybadger] '.freeze
    LOGGER_PROG = "honeybadger".freeze

    # Logging helper methods. Requires a Honeybadger::Config @config instance
    # variable to exist and/or #logger to be defined. Each method is
    # defined/block captured in this module rather than delegating to the
    # logger directly to avoid extra object allocation.
    module Helper
      private
      def debug(msg = nil)
        return true unless logger.debug?
        msg = yield if block_given?
        logger.debug(msg)
      end
      alias :d :debug

      def info(msg = nil)
        return true unless logger.info?
        msg = yield if block_given?
        logger.info(msg)
      end

      def warn(msg = nil)
        return true unless logger.warn?
        msg = yield if block_given?
        logger.warn(msg)
      end

      def error(msg = nil)
        return true unless logger.error?
        msg = yield if block_given?
        logger.error(msg)
      end

      def logger
        @config.logger
      end
    end

    class Base
      Logger::Severity.constants.each do |severity|
        define_method severity.downcase do |msg|
          add(Logger::Severity.const_get(severity), msg)
        end

        define_method :"#{severity.downcase}?" do
          true
        end
      end

      def add(severity, msg)
        raise NotImplementedError, 'must define #add on subclass.'
      end

      def level
        Logger::Severity::DEBUG
      end
    end

    class BootLogger < Base
      include Singleton

      def initialize
        @messages = []
      end

      def add(severity, msg)
        @messages << [severity, msg]
      end

      def flush(logger)
        @messages.each do |msg|
          logger.add(*msg)
        end
        @messages.clear
      end
    end

    class StandardLogger < Base
      extend Forwardable

      def initialize(logger = Logger.new(nil))
        raise ArgumentError, 'logger not specified' unless logger
        raise ArgumentError, 'logger must be a logger' unless logger.respond_to?(:add)

        @logger = logger
      end

      def add(severity, msg, progname=LOGGER_PROG)
        @logger.add(severity, msg, progname)
      end

      def_delegators :@logger, :level, :debug?, :info?, :warn?, :error?
    end

    class FormattedLogger < StandardLogger
      def add(severity, msg, progname=LOGGER_PROG)
        super(severity, format_message(msg), progname)
      end

      private

      def format_message(msg)
        return msg unless msg.kind_of?(String)
        PREFIX + msg
      end
    end

    class ConfigLogger < StandardLogger
      LOCATE_CALLER_LOCATION = Regexp.new("#{Regexp.escape(__FILE__)}").freeze
      CALLER_LOCATION = Regexp.new("#{Regexp.escape(File.expand_path('../../../', __FILE__))}/(.*)").freeze

      INFO_SUPPLEMENT = ' level=%s pid=%s'.freeze
      DEBUG_SUPPLEMENT = ' at=%s'.freeze

      def initialize(config, logger = Logger.new(nil))
        @config = config
        @tty = STDOUT.tty?
        @tty_level = @config.log_level(:'logging.tty_level')
        super(logger)
      end

      def add(severity, msg)
        return true if suppress_tty?(severity)

        # There is no debug level in Honeybadger. Debug logs will be logged at
        # the info level if the debug config option is on.
        if severity == Logger::Severity::DEBUG
          return true if suppress_debug?
          super(Logger::Severity::INFO, supplement(msg, Logger::Severity::DEBUG))
        else
          super(severity, supplement(msg, severity))
        end
      end

      def debug?
        @config.log_debug?
      end

      private

      def suppress_debug?
        !debug?
      end

      def suppress_tty?(severity)
        @tty && severity < @tty_level
      end

      def supplement(msg, severity)
        return msg unless msg.kind_of?(String)

        r = msg.dup
        r << sprintf(INFO_SUPPLEMENT, severity, Process.pid)
        if severity == Logger::Severity::DEBUG && l = caller_location
          r << sprintf(DEBUG_SUPPLEMENT, l.dump)
        end

        r
      end

      def caller_location
        if caller && caller.find {|l| l !~ LOCATE_CALLER_LOCATION && l =~ CALLER_LOCATION }
          Regexp.last_match(1)
        end
      end
    end
  end
end
