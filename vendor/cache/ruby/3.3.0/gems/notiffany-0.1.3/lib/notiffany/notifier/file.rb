require "notiffany/notifier/base"

module Notiffany
  class Notifier
    # Writes notifications to a file.
    #
    class File < Base
      DEFAULTS = { format: "%s\n%s\n%s\n" }

      private

      # @param [Hash] opts some options
      # @option opts [Boolean] path the path to a file where notification
      #   message will be written
      #
      def _check_available(opts = {})
        fail UnavailableError, "No :path option given" unless opts[:path]
      end

      # Writes the notification to a file. By default it writes type, title,
      # and message separated by newlines.
      #
      # @param [String] message the notification message body
      # @param [Hash] opts additional notification library options
      # @option opts [String] type the notification type. Either 'success',
      #   'pending', 'failed' or 'notify'
      # @option opts [String] title the notification title
      # @option opts [String] image the path to the notification image
      # @option opts [String] format printf style format for file contents
      # @option opts [String] path the path of where to write the file
      #
      def _perform_notify(message, opts = {})
        fail UnavailableError, "No :path option given" unless opts[:path]

        str = format(opts[:format], opts[:type], opts[:title], message)
        ::File.write(opts[:path], str)
      end

      def _gem_name
        nil
      end
    end
  end
end
