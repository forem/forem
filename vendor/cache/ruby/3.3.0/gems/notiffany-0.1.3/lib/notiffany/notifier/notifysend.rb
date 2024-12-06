require "notiffany/notifier/base"

require "shellany/sheller"

module Notiffany
  class Notifier
    # System notifications using notify-send, a binary that ships with
    # the libnotify-bin package on many Debian-based distributions.
    #
    # @example Add the `:notifysend` notifier to your `Guardfile`
    #   notification :notifysend
    #
    class NotifySend < Base
      # Default options for the notify-send notifications.
      DEFAULTS = {
        t: 3000, # Default timeout is 3000ms
        h: "int:transient:1" # Automatically close the notification
      }

      # Full list of options supported by notify-send.
      SUPPORTED = [:u, :t, :i, :c, :h]

      private

      # notify-send has no gem, just a binary to shell out
      def _gem_name
        nil
      end

      def _supported_hosts
        %w(linux linux-gnu freebsd openbsd sunos solaris)
      end

      def _check_available(_opts = {})
        which = Shellany::Sheller.stdout("which notify-send")

        return true unless which.nil? || which.empty?

        fail UnavailableError, "libnotify-bin package is not installed"
      end

      # Shows a system notification.
      #
      # @param [String] message the notification message body
      # @param [Hash] opts additional notification library options
      # @option opts [String] type the notification type. Either 'success',
      #   'pending', 'failed' or 'notify'
      # @option opts [String] title the notification title
      # @option opts [String] image the path to the notification image
      # @option opts [String] c the notification category
      # @option opts [Number] t the number of milliseconds to display (1000,
      #   3000)
      #
      def _perform_notify(message, opts = {})
        command = [opts[:title], message]
        opts = opts.merge(
          i: opts[:i] || opts[:image],
          u: opts[:u] || _notifysend_urgency(opts[:type])
        )

        Shellany::Sheller.
          run("notify-send", *_to_arguments(command, SUPPORTED, opts))
      end

      # Converts Guards notification type to the best matching
      # notify-send urgency.
      #
      # @param [String] type the Guard notification type
      # @return [String] the notify-send urgency
      #
      def _notifysend_urgency(type)
        { failed: "normal", pending: "low" }.fetch(type, "low")
      end

      # Builds a shell command out of a command string and option hash.
      #
      # @param [String] command the command execute
      # @param [Array] supported list of supported option flags
      # @param [Hash] opts additional command options
      #
      # @return [Array<String>] the command and its options converted to a
      # shell command.
      #
      def _to_arguments(command, supported, opts = {})
        opts.inject(command) do |cmd, (flag, value)|
          supported.include?(flag) ? (cmd << "-#{flag}" << value.to_s) : cmd
        end
      end
    end
  end
end
