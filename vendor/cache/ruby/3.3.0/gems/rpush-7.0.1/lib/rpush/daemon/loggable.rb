module Rpush
  module Daemon
    module Loggable
      def log_debug(msg)
        Rpush.logger.debug(app_prefix(msg))
      end

      def log_info(msg)
        Rpush.logger.info(app_prefix(msg))
      end

      def log_warn(msg)
        Rpush.logger.warn(app_prefix(msg))
      end

      def log_error(e)
        if e.is_a?(Exception)
          Rpush.logger.error(e)
        else
          Rpush.logger.error(app_prefix(e))
        end
      end

      private

      def app_prefix(msg)
        app = instance_variable_get('@app')
        msg = "[#{app.name}] #{msg}" if app
        msg
      end
    end
  end
end
