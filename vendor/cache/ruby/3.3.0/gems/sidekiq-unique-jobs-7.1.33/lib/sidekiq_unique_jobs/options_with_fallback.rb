# frozen_string_literal: true

module SidekiqUniqueJobs
  # Module containing methods shared between client and server middleware
  #
  # Requires the following methods to be defined in the including class
  #   1. item (required)
  #   2. options (can be nil)
  #   3. job_class (required, can be anything)
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  module OptionsWithFallback
    def self.included(base)
      base.send(:include, SidekiqUniqueJobs::SidekiqWorkerMethods)
    end

    # A convenience method for using the configured locks
    def locks
      SidekiqUniqueJobs.locks
    end

    # Check if unique has been enabled
    # @return [true, false] indicate if the gem has been enabled
    def unique_enabled?
      SidekiqUniqueJobs.enabled? && lock_type
    end

    # Check if unique has been disabled
    def unique_disabled?
      !unique_enabled?
    end

    #
    # A new lock for this Sidekiq Job
    #
    #
    # @return [Lock::BaseLock] an instance of a lock implementation
    #
    def lock_instance
      @lock_instance ||= lock_class.new(item, after_unlock_hook, @redis_pool)
    end

    #
    # Returns the corresponding class for the lock_type
    #
    #
    # @return [Class]
    #
    def lock_class
      @lock_class ||= locks.fetch(lock_type.to_sym) do
        raise UnknownLock, "No implementation for `lock: :#{lock_type}`"
      end
    end

    #
    # The type of lock for this worker
    #
    #
    # @return [Symbol, NilClass]
    #
    def lock_type
      @lock_type ||= options[LOCK] || item[LOCK]
    end

    #
    # The default options with any matching keys overridden from worker options
    #
    #
    # @return [Hash<String, Object>]
    #
    def options
      @options ||= begin
        opts = default_job_options.dup
        opts.merge!(job_options) if sidekiq_job_class?
        (opts || {}).stringify_keys
      end
    end
  end
end
