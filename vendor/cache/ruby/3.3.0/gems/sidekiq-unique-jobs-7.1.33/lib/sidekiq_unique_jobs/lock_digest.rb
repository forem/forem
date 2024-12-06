# frozen_string_literal: true

require "openssl"

module SidekiqUniqueJobs
  # Handles uniqueness of sidekiq arguments
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  class LockDigest
    include SidekiqUniqueJobs::Logging
    include SidekiqUniqueJobs::JSON
    include SidekiqUniqueJobs::SidekiqWorkerMethods

    #
    # Generates a new digest
    #
    # @param [Hash] item a sidekiq job hash
    #
    # @return [String] a unique digest for the given arguments
    #
    def self.call(item)
      new(item).lock_digest
    end

    # The sidekiq job hash
    # @return [Hash] the Sidekiq job hash
    attr_reader :item
    #
    # @!attribute [r] args
    #   @return [Array<Objet>] the arguments passed to `perform_async`
    attr_reader :lock_args
    #
    # @!attribute [r] args
    #   @return [String] the prefix for the unique key
    attr_reader :lock_prefix

    # @param [Hash] item a Sidekiq job hash
    def initialize(item)
      @item        = item
      @lock_args   = item[LOCK_ARGS] || item[UNIQUE_ARGS] # TODO: Deprecate UNIQUE_ARGS
      @lock_prefix = item[LOCK_PREFIX] || item[UNIQUE_PREFIX] # TODO: Deprecate UNIQUE_PREFIX
      self.job_class = item[CLASS]
    end

    # Memoized lock_digest
    # @return [String] a unique digest
    def lock_digest
      @lock_digest ||= create_digest
    end

    # Creates a namespaced unique digest based on the {#digestable_hash} and the {#lock_prefix}
    # @return [String] a unique digest
    def create_digest
      digest = OpenSSL::Digest::MD5.hexdigest(dump_json(digestable_hash.sort))
      "#{lock_prefix}:#{digest}"
    end

    # Filter a hash to use for digest
    # @return [Hash] to use for digest
    def digestable_hash
      @item.slice(CLASS, QUEUE, LOCK_ARGS, APARTMENT).tap do |hash|
        hash.delete(QUEUE) if unique_across_queues?
        hash.delete(CLASS) if unique_across_workers?
      end
    end

    # Checks if we should disregard the queue when creating the unique digest
    # @return [true, false]
    def unique_across_queues?
      item[UNIQUE_ACROSS_QUEUES] || job_options[UNIQUE_ACROSS_QUEUES]
    end

    # Checks if we should disregard the worker when creating the unique digest
    # @return [true, false]
    def unique_across_workers?
      item[UNIQUE_ACROSS_WORKERS] || job_options[UNIQUE_ACROSS_WORKERS]
    end
  end
end
