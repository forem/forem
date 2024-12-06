require "yaml"
require "rbconfig"
require "pathname"
require "nenv"

require "notiffany/notifier/detected"
require "notiffany/notifier/config"

module Notiffany
  # The notifier handles sending messages to different notifiers. Currently the
  # following libraries are supported:
  #
  # * Ruby GNTP
  # * Growl
  # * Libnotify
  # * rb-notifu
  # * emacs
  # * Terminal Notifier
  # * Terminal Title
  # * Tmux
  #
  # Please see the documentation of each notifier for more information about
  # the requirements
  # and configuration possibilities.
  #
  # Notiffany knows four different notification types:
  #
  # * success
  # * pending
  # * failed
  # * notify
  #
  # The notification type selection is based on the image option that is
  # sent to {#notify}. Each image type has its own notification type, and
  # notifications with custom images goes all sent as type `notify`. The
  # `gntp` notifier is able to register these types
  # at Growl and allows customization of each notification type.
  #
  # Notiffany can be configured to make use of more than one notifier at once.
  #
  def self.connect(options = {})
    Notifier.new(options)
  end

  class Notifier
    NOTIFICATIONS_DISABLED = "Notifications disabled by GUARD_NOTIFY" \
      " environment variable"

    USING_NOTIFIER = "Notiffany is using %s to send notifications."

    ONLY_NOTIFY = "Only notify() is available from a child process"

    # List of available notifiers, grouped by functionality
    SUPPORTED = [
      {
        gntp: GNTP,
        growl: Growl,
        terminal_notifier: TerminalNotifier,
        libnotify: Libnotify,
        notifysend: NotifySend,
        notifu: Notifu
      },
      { emacs: Emacs },
      { tmux: Tmux },
      { terminal_title: TerminalTitle },
      { file: File }
    ]

    Env = Nenv::Builder.build do
      create_method(:notify?) { |data| data != "false" }
      create_method(:notify_pid) { |data| data && Integer(data) }
      create_method(:notify_pid=)
      create_method(:notify_active?)
      create_method(:notify_active=)
    end

    class NotServer < RuntimeError
    end

    attr_reader :config

    def initialize(opts)
      @config = Config.new(opts)
      @detected = Detected.new(SUPPORTED, config.env_namespace, config.logger)
      return if _client?

      _activate
    rescue Detected::NoneAvailableError => e
      config.logger.info e.to_s
    end

    def disconnect
      if _client?
        @detected = nil
        return
      end

      turn_off if active?
      @detected.reset unless @detected.nil?
      _env.notify_pid = nil
      @detected = nil
    end

    # Turn notifications on.
    #
    # @param [Hash] options the turn_on options
    # @option options [Boolean] silent disable any logging
    #
    def turn_on(options = {})
      _check_server!
      return unless enabled?

      fail "Already active!" if active?

      _turn_on_notifiers(options)
      _env.notify_active = true
    end

    # Turn notifications off.
    def turn_off
      _check_server!

      fail "Not active!" unless active?

      @detected.available.each do |obj|
        obj.turn_off if obj.respond_to?(:turn_off)
      end

      _env.notify_active = false
    end

    # Test if the notifications can be enabled based on ENV['GUARD_NOTIFY']
    def enabled?
      _env.notify?
    end

    # Test if notifiers are currently turned on
    def active?
      _env.notify_active?
    end

    # Show a system notification with all configured notifiers.
    #
    # @param [String] message the message to show
    # @option opts [Symbol, String] image the image symbol or path to an image
    # @option opts [String] title the notification title
    #
    def notify(message, message_opts = {})
      if _client?
        return unless enabled?
      else
        return unless active?
      end

      @detected.available.each do |notifier|
        notifier.notify(message, message_opts.dup)
      end
    end

    def available
      @detected.available
    end

    private

    def _env
      @environment ||= Env.new(config.env_namespace)
    end

    def _check_server!
      _client? && fail(NotServer, ONLY_NOTIFY)
    end

    def _client?
      (pid = _env.notify_pid) && (pid != $$)
    end

    def _detect_or_add_notifiers
      notifiers = config.notifiers
      return @detected.detect if notifiers.empty?

      notifiers.each do |name, notifier_options|
        @detected.add(name, notifier_options)
      end
    end

    def _notification_wanted?
      enabled? && config.notify?
    end

    def _activate
      _env.notify_pid = $$

      fail "Already connected" if active?

      return unless _notification_wanted?

      _detect_or_add_notifiers
      turn_on
    end

    def _turn_on_notifiers(options)
      silent = options[:silent]
      @detected.available.each do |obj|
        config.logger.debug(format(USING_NOTIFIER, obj.title)) unless silent
        obj.turn_on if obj.respond_to?(:turn_on)
      end
    end
  end
end
