# frozen_string_literal: true

module SidekiqUniqueJobs
  # The unique sidekiq middleware for the server processor
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  class Server
    DEATH_HANDLER = (lambda do |job, _ex|
      return unless (digest = job["lock_digest"])

      SidekiqUniqueJobs::Digests.new.delete_by_digest(digest)
    end).freeze
    #
    # Configure the server middleware
    #
    #
    # @return [Sidekiq] the sidekiq configuration
    #
    def self.configure(config)
      config.on(:startup)  { start }
      config.on(:shutdown) { stop }

      return unless config.respond_to?(:death_handlers)

      config.death_handlers << death_handler
    end

    #
    # Start the sidekiq unique jobs server process
    #
    #
    # @return [void]
    #
    def self.start
      SidekiqUniqueJobs::UpdateVersion.call
      SidekiqUniqueJobs::UpgradeLocks.call
      SidekiqUniqueJobs::Orphans::Manager.start
      SidekiqUniqueJobs::Orphans::ReaperResurrector.start
    end

    #
    # Stop the sidekiq unique jobs server process
    #
    #
    # @return [void]
    #
    def self.stop
      SidekiqUniqueJobs::Orphans::Manager.stop
    end

    #
    # A death handler for dead jobs
    #
    #
    # @return [lambda]
    #
    def self.death_handler
      DEATH_HANDLER
    end
  end
end
