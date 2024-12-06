require "notiffany/notifier/base"

module Notiffany
  class Notifier
    # Shows system notifications in the terminal title bar.
    #
    class TerminalTitle < Base
      DEFAULTS = {}

      # Clears the terminal title
      def turn_off
        STDOUT.puts "\e]2;\a"
      end

      private

      def _gem_name
        nil
      end

      def _check_available(_options)
      end

      # Shows a system notification.
      #
      # @param [Hash] opts additional notification library options
      # @option opts [String] message the notification message body
      # @option opts [String] type the notification type. Either 'success',
      #   'pending', 'failed' or 'notify'
      # @option opts [String] title the notification title
      #
      def _perform_notify(message, opts = {})
        first_line = message.sub(/^\n/, "").sub(/\n.*/m, "")

        STDOUT.puts "\e]2;[#{opts[:title]}] #{first_line}\a"
      end
    end
  end
end
