require "logger"

module Notiffany
  class Notifier
    # Configuration class for Notifier
    class Config
      DEFAULTS = { notify: true }.freeze

      attr_reader :env_namespace
      attr_reader :logger
      attr_reader :notifiers

      def initialize(opts)
        options = DEFAULTS.merge(opts)
        @env_namespace = opts.fetch(:namespace, "notiffany")
        @logger = _setup_logger(options)
        @notify = options[:notify]
        @notifiers = opts.fetch(:notifiers, {})
      end

      def notify?
        @notify
      end

      private

      def _setup_logger(opts)
        opts.fetch(:logger) do
          Logger.new($stderr).tap { |l| l.level = Logger::WARN }
        end
      end
    end
  end
end
