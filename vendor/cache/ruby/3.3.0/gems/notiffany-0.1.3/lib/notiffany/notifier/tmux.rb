require "notiffany/notifier/base"

require "notiffany/notifier/tmux/client"
require "notiffany/notifier/tmux/session"
require "notiffany/notifier/tmux/notification"

# TODO: this probably deserves a gem of it's own
module Notiffany
  class Notifier
    # Changes the color of the Tmux status bar and optionally
    # shows messages in the status bar.
    class Tmux < Base
      @session = nil

      DEFAULTS = {
        tmux_environment:       "TMUX",
        success:                "green",
        failed:                 "red",
        pending:                "yellow",
        default:                "green",
        timeout:                5,
        display_message:        false,
        default_message_format: "%s - %s",
        default_message_color:  "white",
        display_on_all_clients: false,
        display_title:          false,
        default_title_format:   "%s - %s",
        line_separator:         " - ",
        change_color:           true,
        color_location:         "status-left-bg"
      }

      class Error < RuntimeError
      end

      ERROR_NOT_INSIDE_TMUX = ":tmux notifier is only available inside a "\
        "TMux session."

      ERROR_ANCIENT_TMUX = "Your tmux version is way too old (%s)!"

      # Notification starting, save the current Tmux settings
      # and quiet the Tmux output.
      #
      def turn_on
        self.class._start_session
      end

      # Notification stopping. Restore the previous Tmux state
      # if available (existing options are restored, new options
      # are unset) and unquiet the Tmux output.
      #
      def turn_off
        self.class._end_session
      end

      private

      def _gem_name
        nil
      end

      def _check_available(opts = {})
        @session ||= nil # to avoid unitialized error
        fail "PREVIOUS TMUX SESSION NOT CLEARED!" if @session

        var_name = opts[:tmux_environment]
        fail Error, ERROR_NOT_INSIDE_TMUX unless ENV.key?(var_name)

        version = Client.version
        fail Error, format(ERROR_ANCIENT_TMUX, version) if version < 1.7

        true
      rescue Error => e
        fail UnavailableError, e.message
      end

      # Shows a system notification.
      #
      # By default, the Tmux notifier only makes
      # use of a color based notification, changing the background color of the
      # `color_location` to the color defined in either the `success`,
      # `failed`, `pending` or `default`, depending on the notification type.
      #
      # You may enable an extra explicit message by setting `display_message`
      # to true, and may further disable the colorization by setting
      # `change_color` to false.
      #
      # @param [String] message the notification message
      # @param [Hash] options additional notification library options
      # @option options [String] type the notification type. Either 'success',
      #   'pending', 'failed' or 'notify'
      # @option options [String] message the notification message body
      # @option options [String] image the path to the notification image
      # @option options [Boolean] change_color whether to show a color
      #   notification
      # @option options [String,Array] color_location the location where to draw
      #   the color notification
      # @option options [Boolean] display_message whether to display a message
      #   or not
      # @option options [Boolean] display_on_all_clients whether to display a
      #   message on all tmux clients or not
      #
      def _perform_notify(message, options = {})
        locations = Array(options[:color_location])
        type  = options[:type].to_s
        title = options[:title]

        tmux = Notification.new(type, options)
        tmux.colorize(locations) if options[:change_color]
        tmux.display_title(title, message) if options[:display_title]
        tmux.display_message(title, message) if options[:display_message]
      end

      class << self
        def _start_session
          fail "Already turned on!" if @session
          @session = Session.new
        end

        def _end_session
          fail "Already turned off!" unless @session
          @session.close
          @session = nil
        end

        def _session
          @session
        end
      end
    end
  end
end
