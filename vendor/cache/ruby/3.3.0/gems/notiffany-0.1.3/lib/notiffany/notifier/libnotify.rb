require "notiffany/notifier/base"

module Notiffany
  class Notifier
    # System notifications using the
    # [libnotify](https://github.com/splattael/libnotify) gem.
    #
    # This gem is available for Linux, FreeBSD, OpenBSD and Solaris and sends
    # system notifications to
    # Gnome [libnotify](http://developer.gnome.org/libnotify):
    #
    class Libnotify < Base
      DEFAULTS = {
        transient: false,
        append:    true,
        timeout:   3
      }

      private

      def _supported_hosts
        %w(linux linux-gnu freebsd openbsd sunos solaris)
      end

      def _check_available(_opts = {})
      end

      # Shows a system notification.
      #
      # @param [String] message the notification message body
      # @param [Hash] opts additional notification library options
      # @option opts [String] type the notification type. Either 'success',
      #   'pending', 'failed' or 'notify'
      # @option opts [String] title the notification title
      # @option opts [String] image the path to the notification image
      # @option opts [Boolean] transient keep the notifications around after
      #   display
      # @option opts [Boolean] append append onto existing notification
      # @option opts [Number, Boolean] timeout the number of seconds to display
      #   (1.5 (s), 1000 (ms), false)
      #
      def _perform_notify(message, opts = {})
        opts = opts.merge(
          summary: opts[:title],
          icon_path: opts[:image],
          body: message,
          urgency: opts[:urgency] || (opts[:type] == "failed" ? :normal : :low)
        )

        ::Libnotify.show(opts)
      end
    end
  end
end
