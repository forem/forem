# frozen_string_literal: true

module Capybara
  module Selenium
    module ChromeLogs
      LOG_MSG = <<~MSG
        Chromedriver 75+ defaults to W3C mode. Please upgrade to chromedriver >= \
        75.0.3770.90 if you need to access logs while in W3C compliant mode.
      MSG

      COMMANDS = {
        get_available_log_types: [:get, 'session/:session_id/se/log/types'],
        get_log: [:post, 'session/:session_id/se/log'],
        get_log_legacy: [:post, 'session/:session_id/log']
      }.freeze

      def commands(command)
        COMMANDS[command] || super
      end

      def available_log_types
        types = execute :get_available_log_types
        Array(types).map(&:to_sym)
      rescue ::Selenium::WebDriver::Error::UnknownCommandError
        raise NotImplementedError, LOG_MSG
      end

      def log(type)
        data = begin
          execute :get_log, {}, type: type.to_s
        rescue ::Selenium::WebDriver::Error::UnknownCommandError
          execute :get_log_legacy, {}, type: type.to_s
        end

        Array(data).map do |l|
          ::Selenium::WebDriver::LogEntry.new l.fetch('level', 'UNKNOWN'), l.fetch('timestamp'), l.fetch('message')
        rescue KeyError
          next
        end
      rescue ::Selenium::WebDriver::Error::UnknownCommandError
        raise NotImplementedError, LOG_MSG
      end
    end
  end
end
