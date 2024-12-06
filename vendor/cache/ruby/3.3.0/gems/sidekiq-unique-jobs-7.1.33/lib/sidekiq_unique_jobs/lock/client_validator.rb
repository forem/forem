# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    #
    # Validates the sidekiq options for the Sidekiq client process
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    class ClientValidator
      #
      # @return [Array<Symbol>] a collection of invalid conflict resolutions
      INVALID_ON_CONFLICTS = [:raise, :reject, :reschedule].freeze

      #
      # Validates the sidekiq options for the Sidekiq client process
      #
      #
      def self.validate(lock_config)
        on_conflict = lock_config.on_client_conflict
        return lock_config unless INVALID_ON_CONFLICTS.include?(on_conflict)

        lock_config.errors[:on_client_conflict] = "#{on_conflict} is incompatible with the client process"
        lock_config
      end
    end
  end
end
