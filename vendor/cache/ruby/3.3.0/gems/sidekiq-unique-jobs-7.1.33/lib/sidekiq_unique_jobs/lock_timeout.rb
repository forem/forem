# frozen_string_literal: true

module SidekiqUniqueJobs
  # Calculates timeout and expiration
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  class LockTimeout
    # includes "SidekiqUniqueJobs::SidekiqWorkerMethods"
    # @!parse include SidekiqUniqueJobs::SidekiqWorkerMethods
    include SidekiqUniqueJobs::SidekiqWorkerMethods

    #
    # Calculates the timeout for a Sidekiq job
    #
    # @param [Hash] item sidekiq job hash
    #
    # @return [Integer] timeout in seconds
    #
    def self.calculate(item)
      new(item).calculate
    end

    # @!attribute [r] item
    #   @return [Hash] the Sidekiq job hash
    attr_reader :item

    # @param [Hash] item the Sidekiq job hash
    # @option item [Integer, nil] :lock_ttl the configured lock expiration
    # @option item [Integer, nil] :lock_timeout the configured lock timeout
    # @option item [String] :class the class of the sidekiq worker
    # @option item [Float] :at the unix time the job is scheduled at
    def initialize(item)
      @item = item
      self.job_class = item[CLASS]
    end

    #
    # Finds a lock timeout in either of
    #  default worker options, {default_lock_timeout} or provided worker_options
    #
    #
    # @return [Integer, nil]
    #
    def calculate
      timeout = default_job_options[LOCK_TIMEOUT]
      timeout = default_lock_timeout if default_lock_timeout
      timeout = job_options[LOCK_TIMEOUT] if job_options.key?(LOCK_TIMEOUT)
      timeout
    end

    #
    # The configured default_lock_timeout
    # @see SidekiqUniqueJobs::Config#lock_timeout
    #
    #
    # @return [Integer, nil]
    #
    def default_lock_timeout
      SidekiqUniqueJobs.config.lock_timeout
    end
  end
end
