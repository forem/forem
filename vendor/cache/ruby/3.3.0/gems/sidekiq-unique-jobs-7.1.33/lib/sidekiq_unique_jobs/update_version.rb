# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Class UpdateVersion sets the right version in redis
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  #
  class UpdateVersion
    #
    # Sets the right versions in redis
    #
    # @note the version isn't used yet but will be for automatic upgrades
    #
    # @return [true] when version changed
    #
    def self.call
      Script::Caller.call_script(
        :update_version,
        keys: [LIVE_VERSION, DEAD_VERSION],
        argv: [SidekiqUniqueJobs.version],
      )
    end
  end
end
