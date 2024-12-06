# frozen_string_literal: true

require 'sd_notify'

module Puma
  class Systemd
    def initialize(events)
      @events = events
    end

    def hook_events
      @events.on_booted { SdNotify.ready }
      @events.on_stopped { SdNotify.stopping }
      @events.on_restart { SdNotify.reloading }
    end

    def start_watchdog
      return unless SdNotify.watchdog?

      ping_f = watchdog_sleep_time

      log "Pinging systemd watchdog every #{ping_f.round(1)} sec"
      Thread.new do
        loop do
          sleep ping_f
          SdNotify.watchdog
        end
      end
    end

    private

    def watchdog_sleep_time
      usec = Integer(ENV["WATCHDOG_USEC"])

      sec_f = usec / 1_000_000.0
      # "It is recommended that a daemon sends a keep-alive notification message
      # to the service manager every half of the time returned here."
      sec_f / 2
    end

    def log(str)
      @events.log str
    end
  end
end
