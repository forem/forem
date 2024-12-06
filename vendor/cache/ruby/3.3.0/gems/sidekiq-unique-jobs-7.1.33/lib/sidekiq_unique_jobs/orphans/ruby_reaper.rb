# frozen_string_literal: true

module SidekiqUniqueJobs
  module Orphans
    #
    # Class DeleteOrphans provides deletion of orphaned digests
    #
    # @note this is a much slower version of the lua script but does not crash redis
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    # rubocop:disable Metrics/ClassLength
    class RubyReaper < Reaper
      include SidekiqUniqueJobs::Timing

      #
      # @return [String] the suffix for :RUN locks
      RUN_SUFFIX = ":RUN"
      #
      # @return [Integer] the maximum combined length of sidekiq queues for running the reaper
      MAX_QUEUE_LENGTH = 1000
      #
      # @!attribute [r] digests
      #   @return [SidekiqUniqueJobs::Digests] digest collection
      attr_reader :digests
      #
      # @!attribute [r] scheduled
      #   @return [Redis::SortedSet] the Sidekiq ScheduleSet
      attr_reader :scheduled
      #
      # @!attribute [r] retried
      #   @return [Redis::SortedSet] the Sidekiq RetrySet
      attr_reader :retried

      #
      # @!attribute [r] start_time
      #   @return [Integer] The timestamp this execution started represented as Time (used for locks)
      attr_reader :start_time

      #
      # @!attribute [r] start_time
      #   @return [Integer] The clock stamp this execution started represented as integer
      #      (used for redis compatibility as it is more accurate than time)
      attr_reader :start_source

      #
      # @!attribute [r] timeout_ms
      #   @return [Integer] The allowed ms before timeout
      attr_reader :timeout_ms

      #
      # Initialize a new instance of DeleteOrphans
      #
      # @param [Redis] conn a connection to redis
      #
      def initialize(conn)
        super(conn)
        @digests      = SidekiqUniqueJobs::Digests.new
        @scheduled    = Redis::SortedSet.new(SCHEDULE)
        @retried      = Redis::SortedSet.new(RETRY)
        @start_time   = Time.now
        @start_source = time_source.call
        @timeout_ms   = SidekiqUniqueJobs.config.reaper_timeout * 1000
      end

      #
      # Delete orphaned digests
      #
      #
      # @return [Integer] the number of reaped locks
      #
      def call
        return if queues_very_full?

        BatchDelete.call(expired_digests, conn)
        BatchDelete.call(orphans, conn)
      end

      def expired_digests
        max_score = (start_time - reaper_timeout).to_f

        if VersionCheck.satisfied?(redis_version, ">= 6.2.0") && VersionCheck.satisfied?(::Redis::VERSION, ">= 4.6.0")
          conn.zrange(EXPIRING_DIGESTS, 0, max_score, byscore: true)
        else
          conn.zrangebyscore(EXPIRING_DIGESTS, 0, max_score)
        end
      end

      #
      # Find orphaned digests
      #
      #
      # @return [Array<String>] an array of orphaned digests
      #
      def orphans # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity
        page = 0
        per = reaper_count * 2
        orphans = []
        results = conn.zrange(digests.key, page * per, (page + 1) * per)

        while results.size.positive?
          results.each do |digest|
            break if timeout?
            next if belongs_to_job?(digest)

            orphans << digest
            break if orphans.size >= reaper_count
          end

          break if timeout?
          break if orphans.size >= reaper_count

          page += 1
          results = conn.zrange(digests.key, page * per, (page + 1) * per)
        end

        orphans
      end

      def timeout?
        elapsed_ms >= timeout_ms
      end

      def elapsed_ms
        time_source.call - start_source
      end

      #
      # Checks if the digest has a matching job.
      #   1. It checks the scheduled set
      #   2. It checks the retry set
      #   3. It goes through all queues
      #
      #
      # @param [String] digest the digest to search for
      #
      # @return [true] when either of the checks return true
      # @return [false] when no job was found for this digest
      #
      def belongs_to_job?(digest)
        scheduled?(digest) || retried?(digest) || enqueued?(digest) || active?(digest)
      end

      #
      # Checks if the digest exists in the Sidekiq::ScheduledSet
      #
      # @param [String] digest the current digest
      #
      # @return [true] when digest exists in scheduled set
      #
      def scheduled?(digest)
        in_sorted_set?(SCHEDULE, digest)
      end

      #
      # Checks if the digest exists in the Sidekiq::RetrySet
      #
      # @param [String] digest the current digest
      #
      # @return [true] when digest exists in retry set
      #
      def retried?(digest)
        in_sorted_set?(RETRY, digest)
      end

      #
      # Checks if the digest exists in a Sidekiq::Queue
      #
      # @param [String] digest the current digest
      #
      # @return [true] when digest exists in any queue
      #
      def enqueued?(digest)
        Sidekiq.redis do |conn|
          queues(conn) do |queue|
            entries(conn, queue) do |entry|
              return true if entry.include?(digest)
            end
          end

          false
        end
      end

      def active?(digest) # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        Sidekiq.redis do |conn|
          procs = conn.sscan_each("processes").to_a
          return false if procs.empty?

          procs.sort.each do |key|
            valid, workers = conn.pipelined do |pipeline|
              # TODO: Remove the if statement in the future
              if pipeline.respond_to?(:exists?)
                pipeline.exists?(key)
              else
                pipeline.exists(key)
              end
              pipeline.hgetall("#{key}:work")
            end

            next unless valid
            next unless workers.any?

            workers.each_pair do |_tid, job|
              next unless (item = safe_load_json(job))

              payload = safe_load_json(item[PAYLOAD])

              return true if match?(digest, payload[LOCK_DIGEST])
              return true if considered_active?(payload[CREATED_AT])
            end
          end

          false
        end
      end

      def match?(key_one, key_two)
        return false if key_one.nil? || key_two.nil?

        key_one.delete_suffix(RUN_SUFFIX) == key_two.delete_suffix(RUN_SUFFIX)
      end

      def considered_active?(time_f)
        (Time.now - reaper_timeout).to_f < time_f
      end

      #
      # Loops through all the redis queues and yields them one by one
      #
      # @param [Redis] conn the connection to use for fetching queues
      #
      # @return [void]
      #
      # @yield queues one at a time
      #
      def queues(conn, &block)
        conn.sscan_each("queues", &block)
      end

      def entries(conn, queue, &block) # rubocop:disable Metrics/MethodLength
        queue_key    = "queue:#{queue}"
        initial_size = conn.llen(queue_key)
        deleted_size = 0
        page         = 0
        page_size    = 50

        loop do
          range_start = (page * page_size) - deleted_size

          range_end   = range_start + page_size - 1
          entries     = conn.lrange(queue_key, range_start, range_end)
          page       += 1

          break if entries.empty?

          entries.each(&block)

          deleted_size = initial_size - conn.llen(queue_key)

          # The queue is growing, not shrinking, just keep looping
          deleted_size = 0 if deleted_size.negative?
        end
      end

      # If sidekiq queues are very full, it becomes highly inefficient for the reaper
      # because it must check every queued job to verify a digest is safe to delete
      # The reaper checks queued jobs in batches of 50, adding 2 reads per digest
      # With a queue length of 1,000 jobs, that's over 20 extra reads per digest.
      def queues_very_full?
        total_queue_size = 0
        Sidekiq.redis do |conn|
          queues(conn) do |queue|
            total_queue_size += conn.llen("queue:#{queue}")

            return true if total_queue_size > MAX_QUEUE_LENGTH
          end
        end
        false
      end

      #
      # Checks a sorted set for the existance of this digest
      #
      #
      # @param [String] key the key for the sorted set
      # @param [String] digest the digest to scan for
      #
      # @return [true] when found
      # @return [false] when missing
      #
      def in_sorted_set?(key, digest)
        conn.zscan_each(key, match: "*#{digest}*", count: 1).to_a.any?
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
