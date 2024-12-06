require "notiffany/notifier"
require "guard/ui"

module Guard
  class Notifier
    def self.connect(options = {})
      @notifier ||= nil
      fail "Already connected!" if @notifier
      begin
        opts = options.merge(namespace: "guard", logger: UI)
        @notifier = Notiffany.connect(opts)
      rescue Notiffany::Notifier::Detected::UnknownNotifier => e
        UI.error "Failed to setup notification: #{e.message}"
        fail
      end
    end

    def self.disconnect
      @notifier && @notifier.disconnect
      @notifier = nil
    end

    DEPRECATED_IMPLICIT_CONNECT = "Calling Notiffany::Notifier.notify()"\
                                  " without a prior Notifier.connect() is"\
                                  " deprecated"

    def self.notify(message, options = {})
      unless @notifier
        # TODO: reenable again?
        # UI.deprecation(DEPRECTED_IMPLICIT_CONNECT)
        connect(notify: true)
      end

      @notifier.notify(message, options)
    rescue RuntimeError => e
      UI.error "Notification failed for #{@notifier.class.name}: #{e.message}"
      UI.debug e.backtrace.join("\n")
    end

    def self.turn_on
      @notifier.turn_on
    end

    def self.toggle
      unless @notifier.enabled?
        UI.error NOTIFICATIONS_DISABLED
        return
      end

      if @notifier.active?
        UI.info "Turn off notifications"
        @notifier.turn_off
        return
      end

      @notifier.turn_on
    end

    # Used by dsl describer
    def self.supported
      Notiffany::Notifier::SUPPORTED.inject(:merge)
    end

    # Used by dsl describer
    def self.detected
      @notifier.available.map do |mod|
        { name: mod.name.to_sym, options: mod.options }
      end
    end
  end
end
