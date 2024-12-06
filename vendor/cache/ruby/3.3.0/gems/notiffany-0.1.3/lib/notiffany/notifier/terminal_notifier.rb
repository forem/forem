require "notiffany/notifier/base"

module Notiffany
  class Notifier
    # System notifications using the
    #
    # [terminal-notifier](https://github.com/Springest/terminal-notifier-guard)
    #
    # gem.
    #
    # This gem is available for OS X 10.8 Mountain Lion and sends notifications
    # to the OS X notification center.
    class TerminalNotifier < Base
      DEFAULTS = { app_name: "Notiffany" }

      ERROR_ONLY_OSX10 = "The :terminal_notifier only runs"\
        " on Mac OS X 10.8 and later."

      def _supported_hosts
        %w(darwin)
      end

      def _gem_name
        "terminal-notifier-guard"
      end

      def _check_available(_opts = {})
        return if ::TerminalNotifier::Guard.available?
        fail UnavailableError, ERROR_ONLY_OSX10
      end

      # Shows a system notification.
      #
      # @param [String] message the notification message body
      # @param [Hash] opts additional notification library options
      # @option opts [String] type the notification type. Either 'success',
      #   'pending', 'failed' or 'notify'
      # @option opts [String] title the notification title
      # @option opts [String] image the path to the notification image (ignored)
      # @option opts [String] app_name name of your app
      # @option opts [String] execute a command
      # @option opts [String] activate an app bundle
      # @option opts [String] open some url or file
      #
      def _perform_notify(message, opts = {})
        title = [opts[:app_name], opts[:type].downcase.capitalize].join(" ")
        opts = {
          title: title
        }.merge(opts)
        opts[:message] = message
        opts[:title] ||= title
        opts.delete(:image)
        opts.delete(:app_name)

        ::TerminalNotifier::Guard.execute(false, opts)
      end
    end
  end
end
