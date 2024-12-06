require 'honeybadger/plugin'
require 'honeybadger/ruby'

module Honeybadger
  module Plugins
    module Thor
      def self.included(base)
        base.class_eval do
          no_commands do
            alias_method :invoke_command_without_honeybadger, :invoke_command
            alias_method :invoke_command, :invoke_command_with_honeybadger
          end
        end
      end

      def invoke_command_with_honeybadger(*args)
        invoke_command_without_honeybadger(*args)
      rescue Exception => e
        Honeybadger.notify(e)
        raise
      end
    end

    Plugin.register do
      requirement { defined?(::Thor.no_commands) }

      execution do
        ::Thor.send(:include, Thor)
      end
    end
  end
end
