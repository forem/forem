require 'notiffany/notifier/base'
require 'shellany/sheller'

require 'notiffany/notifier/emacs/client'

module Notiffany
  class Notifier
    # Send a notification to Emacs with emacsclient
    # (http://www.emacswiki.org/emacs/EmacsClient).
    #
    class Emacs < Base
      DEFAULTS = {
        client:    'emacsclient',
        success:   'ForestGreen',
        failed:    'Firebrick',
        default:   'Black',
        fontcolor: 'White'
      }.freeze

      DEFAULT_ELISP_ERB = <<EOF.freeze
(set-face-attribute 'mode-line nil
  :background "<%= bgcolor %>"
  :foreground "<%= color %>")
EOF

      private

      def _gem_name
        nil
      end

      def _check_available(options)
        return if Client.new(options.merge(elisp_erb: "'1'")).available?
        raise UnavailableError, 'Emacs client failed'
      end

      # Shows a system notification.
      #
      # @param [String] type the notification type. Either 'success',
      #   'pending', 'failed' or 'notify'
      # @param [String] title the notification title
      # @param [String] message the notification message body
      # @param [String] image the path to the notification image
      # @param [Hash] opts additional notification library options
      # @option opts [String] success the color to use for success
      #   notifications (default is 'ForestGreen')
      # @option opts [String] failed the color to use for failure
      #   notifications (default is 'Firebrick')
      # @option opts [String] pending the color to use for pending
      #   notifications
      # @option opts [String] default the default color to use (default is
      #   'Black')
      # @option opts [String] client the client to use for notification
      #   (default is 'emacsclient')
      # @option opts [String, Integer] priority specify an int or named key
      #   (default is 0)
      #
      def _perform_notify(message, opts = {})
        color     = _emacs_color(opts[:type], opts)
        fontcolor = _emacs_color(:fontcolor, opts)

        opts = opts.merge(elisp_erb: _erb_for(opts[:elisp_file]))
        Client.new(opts).notify(fontcolor, color, message)
      end

      # Get the Emacs color for the notification type.
      # You can configure your own color by overwrite the defaults.
      #
      # @param [String] type the notification type
      # @param [Hash] options aditional notification options
      #
      # @option options [String] success the color to use for success
      # notifications (default is 'ForestGreen')
      #
      # @option options [String] failed the color to use for failure
      # notifications (default is 'Firebrick')
      #
      # @option options [String] pending the color to use for pending
      # notifications
      #
      # @option options [String] default the default color to use (default is
      # 'Black')
      #
      # @return [String] the name of the emacs color
      #
      def _emacs_color(type, options = {})
        default = options.fetch(:default, DEFAULTS[:default])
        options.fetch(type.to_sym, default)
      end

      def _erb_for(filename)
        return DEFAULT_ELISP_ERB unless filename
        IO.read(::File.expand_path(filename))
      end
    end
  end
end
