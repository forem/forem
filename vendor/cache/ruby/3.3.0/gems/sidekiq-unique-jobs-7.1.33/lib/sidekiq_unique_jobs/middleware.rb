# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Provides the sidekiq middleware that makes the gem work
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  #
  module Middleware
    include SidekiqUniqueJobs::Logging::Middleware
    include SidekiqUniqueJobs::OptionsWithFallback
    include SidekiqUniqueJobs::JSON

    # The sidekiq job hash
    # @return [Hash] the Sidekiq job hash
    attr_reader :item

    #
    # This method runs before (prepended) the actual middleware implementation.
    #   This is done to reduce duplication
    #
    # @param [Sidekiq::Worker] worker_class
    # @param [Hash] item a sidekiq job hash
    # @param [String] queue name of the queue
    # @param [ConnectionPool] redis_pool only used for compatility reasons
    #
    # @return [yield<super>] <description>
    #
    # @yieldparam [<type>] if <description>
    # @yieldreturn [<type>] <describe what yield should return>
    def call(worker_class, item, queue, redis_pool = nil)
      @item       = item
      @queue      = queue
      @redis_pool = redis_pool
      self.job_class = worker_class
      return yield if unique_disabled?

      SidekiqUniqueJobs::Job.prepare(item) unless item[LOCK_DIGEST]

      with_logging_context do
        super
      end
    end
  end
end
