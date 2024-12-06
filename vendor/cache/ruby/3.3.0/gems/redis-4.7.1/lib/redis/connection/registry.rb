# frozen_string_literal: true

class Redis
  module Connection
    # Store a list of loaded connection drivers in the Connection module.
    # Redis::Client uses the last required driver by default, and will be aware
    # of the loaded connection drivers if the user chooses to override the
    # default connection driver.
    def self.drivers
      @drivers ||= []
    end
  end
end
