# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    #
    # Validates the sidekiq options for the Sidekiq server process
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    class ServerValidator
      #
      # @return [Array<Symbol>] a collection of invalid conflict resolutions
      INVALID_ON_CONFLICTS = [:replace].freeze

      #
      # Validates the sidekiq options for the Sidekiq server process
      #
      #
      def self.validate(lock_config)
        on_conflict = lock_config.on_server_conflict
        return lock_config unless INVALID_ON_CONFLICTS.include?(on_conflict)

        lock_config.errors[:on_server_conflict] = "#{on_conflict} is incompatible with the server process"
      end
    end
  end
end
