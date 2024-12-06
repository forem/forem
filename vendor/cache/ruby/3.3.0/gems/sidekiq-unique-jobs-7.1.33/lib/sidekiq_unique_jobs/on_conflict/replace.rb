# frozen_string_literal: true

module SidekiqUniqueJobs
  module OnConflict
    # Strategy to replace the job on conflict
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class Replace < OnConflict::Strategy
      #
      # @!attribute [r] queue
      #   @return [String] rthe sidekiq queue this job belongs to
      attr_reader :queue
      #
      # @!attribute [r] lock_digest
      #   @return [String] the unique digest to use for locking
      attr_reader :lock_digest

      #
      # Initialize a new Replace strategy
      #
      # @param [Hash] item sidekiq job hash
      #
      def initialize(item, redis_pool = nil)
        super(item, redis_pool)
        @queue       = item[QUEUE]
        @lock_digest = item[LOCK_DIGEST]
      end

      #
      # Replace the old job in the queue
      #
      #
      # @return [void] <description>
      #
      # @yield to retry the lock after deleting the old one
      #
      def call(&block)
        return unless (deleted_job = delete_job_by_digest)

        log_info("Deleted job: #{deleted_job}")
        if (del_count = delete_lock)
          log_info("Deleted `#{del_count}` keys for #{lock_digest}")
        end

        block&.call
      end

      #
      # Delete the job from either schedule, retry or the queue
      #
      #
      # @return [String] the deleted job hash
      # @return [nil] when deleting nothing
      #
      def delete_job_by_digest
        call_script(:delete_job_by_digest,
                    keys: ["#{QUEUE}:#{queue}", SCHEDULE, RETRY],
                    argv: [lock_digest])
      end

      #
      # Delete the keys belonging to the job
      #
      #
      # @return [Integer] the number of keys deleted
      #
      def delete_lock
        digests.delete_by_digest(lock_digest)
      end

      #
      # Access to the {Digests}
      #
      #
      # @return [Digests] and instance with digests
      #
      def digests
        @digests ||= SidekiqUniqueJobs::Digests.new
      end
    end
  end
end
