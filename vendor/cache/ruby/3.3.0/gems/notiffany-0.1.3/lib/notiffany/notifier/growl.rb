require "notiffany/notifier/base"

module Notiffany
  class Notifier
    # System notifications using the
    # [growl](https://github.com/visionmedia/growl) gem.
    #
    # This gem is available for OS X and sends system notifications to
    # [Growl](http://growl.info) through the
    # [GrowlNotify](http://growl.info/downloads) executable.
    #
    # The `growlnotify` executable must be installed manually or by using
    # [Homebrew](http://mxcl.github.com/homebrew/).
    #
    # Sending notifications with this notifier will not show the different
    # notifications in the Growl preferences. Use the :gntp notifier if you
    # want to customize each notification type in Growl.
    #
    # @example Install `growlnotify` with Homebrew
    #   brew install growlnotify
    #
    # @example Add the `growl` gem to your `Gemfile`
    #   group :development
    #     gem 'growl'
    #   end
    #
    # @example Add the `:growl` notifier to your `Guardfile`
    #   notification :growl
    #
    # @example Add the `:growl_notify` notifier with configuration options to
    # your `Guardfile` notification :growl, sticky: true, host: '192.168.1.5',
    # password: 'secret'
    #
    class Growl < Base
      INSTALL_GROWLNOTIFY = "Please install the 'growlnotify' executable'\
    ' (available by installing the 'growl' gem)."

      # Default options for the growl notifications.
      DEFAULTS = {
        sticky:   false,
        priority: 0
      }

      def _supported_hosts
        %w(darwin)
      end

      def _check_available(_opts = {})
        fail UnavailableError, INSTALL_GROWLNOTIFY unless ::Growl.installed?
      end

      # Shows a system notification.
      #
      # The documented options are for GrowlNotify 1.3, but the older options
      # are also supported. Please see `growlnotify --help`.
      #
      # Priority can be one of the following named keys: `Very Low`,
      # `Moderate`, `Normal`, `High`, `Emergency`. It can also be an integer
      # between -2 and 2.
      #
      # @param [String] message the notification message body
      # @param [Hash] opts additional notification library options
      # @option opts [String] type the notification type. Either 'success',
      #   'pending', 'failed' or 'notify'
      # @option opts [String] title the notification title
      # @option opts [String] image the path to the notification image
      # @option opts [Boolean] sticky make the notification sticky
      # @option opts [String, Integer] priority specify an int or named key
      #   (default is 0)
      # @option opts [String] host the hostname or IP address to which to
      #   send a remote notification
      # @option opts [String] password the password used for remote
      #   notifications
      #
      def _perform_notify(message, opts = {})
        opts = { name: "Notiffany" }.merge(opts)
        opts.select! { |k, _| ::Growl::Base.switches.include?(k) }
        ::Growl.notify(message, opts)
      end
    end
  end
end
