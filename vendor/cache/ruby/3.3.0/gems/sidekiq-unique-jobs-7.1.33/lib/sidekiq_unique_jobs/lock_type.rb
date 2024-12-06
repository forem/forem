# frozen_string_literal: true

module SidekiqUniqueJobs
  # Calculates the lock type
  #
  class LockType
    # includes "SidekiqUniqueJobs::SidekiqWorkerMethods"
    # @!parse include SidekiqUniqueJobs::SidekiqWorkerMethods
    include SidekiqUniqueJobs::SidekiqWorkerMethods

    #
    # Computes lock type from job arguments, sidekiq_options.
    #
    # @return [Symbol] the lock type
    # @return [NilClass] if no lock type is found.
    #
    def self.call(item)
      new(item).call
    end

    # @!attribute [r] item
    #   @return [Hash] the Sidekiq job hash
    attr_reader :item

    # @param [Hash] item the Sidekiq job hash
    # @option item [Symbol, nil] :lock the type of lock to use.
    # @option item [String] :class the class of the sidekiq worker
    def initialize(item)
      @item = item
      self.job_class = item[CLASS]
    end

    def call
      item[LOCK] || job_options[LOCK] || default_job_options[LOCK]
    end
  end
end
