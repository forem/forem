# frozen_string_literal: true

module Listen
  @logger = nil

  # Listen.logger will always be present.
  # If you don't want logging, set Listen.logger = ::Logger.new('/dev/null', level: ::Logger::UNKNOWN)

  @adapter_warn_behavior = :warn

  class << self
    attr_writer :logger
    attr_accessor :adapter_warn_behavior

    def logger
      @logger ||= default_logger
    end

    def adapter_warn(message)
      case ENV['LISTEN_GEM_ADAPTER_WARN_BEHAVIOR']&.to_sym || adapter_warn_behavior_callback(message)
      when :log
        logger.warn(message)
      when :silent, nil, false
        # do nothing
      else # :warn
        warn(message)
      end
    end

    private

    def default_logger
      level =
        case ENV['LISTEN_GEM_DEBUGGING'].to_s
        when /debug|2/i
          ::Logger::DEBUG
        when /info|true|yes|1/i
          ::Logger::INFO
        when /warn/i
          ::Logger::WARN
        when /fatal/i
          ::Logger::FATAL
        else
          ::Logger::ERROR
        end

      ::Logger.new(STDERR, level: level)
    end
    
    def adapter_warn_behavior_callback(message)
      if adapter_warn_behavior.respond_to?(:call)
        case behavior = adapter_warn_behavior.call(message)
        when Symbol
          behavior
        when false, nil
          :silent
        else
          :warn
        end
      else
        adapter_warn_behavior
      end
    end
  end
end
