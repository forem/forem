# See https://github.com/heroku/rails_stdout_logging
# I have no idea why this library was created, but most Heroku / Rails apps use it.
# This library completely obliterates any logger configuration you set.
# So this patch fixes that.

begin
  require "rails_stdout_logging"

  module RailsStdoutLogging
    class Rails2 < Rails
      def self.set_logger
      end
    end

    class Rails3 < Rails
      def self.set_logger(config)
      end
    end
  end
rescue Exception
end