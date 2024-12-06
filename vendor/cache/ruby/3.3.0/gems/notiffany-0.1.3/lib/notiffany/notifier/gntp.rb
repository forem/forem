require "notiffany/notifier/base"

module Notiffany
  class Notifier
    # System notifications using the
    # [ruby_gntp](https://github.com/snaka/ruby_gntp) gem.
    #
    # This gem is available for OS X, Linux and Windows and sends system
    # notifications to the following system notification frameworks through the
    #
    # [Growl Network Transport
    # Protocol](http://www.growlforwindows.com/gfw/help/gntp.aspx):
    #
    # * [Growl](http://growl.info)
    # * [Growl for Windows](http://www.growlforwindows.com)
    # * [Growl for Linux](http://mattn.github.com/growl-for-linux)
    # * [Snarl](https://sites.google.com/site/snarlapp)
    class GNTP < Base
      DEFAULTS = {
        sticky: false
      }

      # Default options for the ruby gtnp client.
      CLIENT_DEFAULTS = {
        host:     "127.0.0.1",
        password: "",
        port:     23_053
      }

      def _supported_hosts
        %w(darwin linux linux-gnu freebsd openbsd sunos solaris mswin mingw
           cygwin)
      end

      def _gem_name
        "ruby_gntp"
      end

      def _check_available(_opts)
      end

      # Shows a system notification.
      #
      # @param [String] message the notification message body
      # @param [Hash] opts additional notification library options
      # @option opts [String] type the notification type. Either 'success',
      #   'pending', 'failed' or 'notify'
      # @option opts [String] title the notification title
      # @option opts [String] image the path to the notification image
      # @option opts [String] host the hostname or IP address to which to send
      #   a remote notification
      # @option opts [String] password the password used for remote
      #   notifications
      # @option opts [Integer] port the port to send a remote notification
      # @option opts [Boolean] sticky make the notification sticky
      #
      def _perform_notify(message, opts = {})
        opts = {
          name: opts[:type].to_s,
          text: message,
          icon: opts[:image]
        }.merge(opts)

        _gntp_client(opts).notify(opts)
      end

      private

      def _gntp_client(opts = {})
        @_client ||= begin
          gntp = ::GNTP.new(
            "Notiffany",
            opts.fetch(:host) { CLIENT_DEFAULTS[:host] },
            opts.fetch(:password) { CLIENT_DEFAULTS[:password] },
            opts.fetch(:port) { CLIENT_DEFAULTS[:port] }
          )

          gntp.register(
            app_icon: _image_path(:guard),
            notifications: [
              { name: "notify", enabled: true },
              { name: "failed", enabled: true },
              { name: "pending", enabled: true },
              { name: "success", enabled: true }
            ]
          )
          gntp
        end
      end
    end
  end
end
