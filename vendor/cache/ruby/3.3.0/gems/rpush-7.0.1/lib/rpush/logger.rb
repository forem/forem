module Rpush
  class Logger
    attr_reader :internal_logger

    def initialize
      @internal_logger = Rpush.config.logger || setup_logger(open_logfile)
      @internal_logger.level = Rpush.config.log_level
    rescue SystemCallError => e
      @internal_logger = nil
      error(e)
      error('Logging disabled.')
    end

    def debug(msg, inline = false)
      log(:debug, msg, inline)
    end

    def info(msg, inline = false)
      log(:info, msg, inline)
    end

    def error(msg, inline = false)
      log(:error, msg, inline, 'ERROR', STDERR)
    end

    def warn(msg, inline = false)
      log(:warn, msg, inline, 'WARNING', STDERR)
    end

    def reopen
      if Rpush.config.logger
        Rpush.config.logger.reopen if Rpush.config.logger.respond_to?(:reopen)
      else
        @internal_logger.close
        @internal_logger = setup_logger(open_logfile)
      end
    end

    private

    def open_logfile
      FileUtils.mkdir_p(File.dirname(Rpush.config.log_file))
      log = File.open(Rpush.config.log_file, 'a')
      log.sync = true
      log
    end

    def setup_logger(log)
      if ActiveSupport.const_defined?('BufferedLogger')
        logger = ActiveSupport::BufferedLogger.new(log)
        logger.auto_flushing = auto_flushing
        logger
      else
        ActiveSupport::Logger.new(log)
      end
    end

    def auto_flushing
      if defined?(Rails) && Rails.logger.respond_to?(:auto_flushing)
        Rails.logger.auto_flushing
      else
        true
      end
    end

    def log(where, msg, inline = false, prefix = nil, io = STDOUT)
      if msg.is_a?(Exception)
        formatted_backtrace = msg.backtrace&.join("\n")
        msg = "#{msg.class.name}, #{msg.message}\n#{formatted_backtrace}"
      end

      formatted_msg = "[#{Time.now.to_formatted_s(:db)}]"
      formatted_msg << '[rpush] ' if Rpush.config.embedded
      formatted_msg << "[#{prefix}] " if prefix
      formatted_msg << msg

      log_foreground(io, formatted_msg, inline)
      @internal_logger.send(where, formatted_msg) if @internal_logger
    end

    def log_foreground(io, formatted_msg, inline)
      return unless Rpush.config.foreground_logging
      return unless io == STDERR || Rpush.config.foreground

      if inline
        io.write(formatted_msg)
        io.flush
      else
        io.puts(formatted_msg)
      end
    end
  end
end
