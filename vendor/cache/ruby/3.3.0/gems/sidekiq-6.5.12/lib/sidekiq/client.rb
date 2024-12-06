# frozen_string_literal: true

require "securerandom"
require "sidekiq/middleware/chain"
require "sidekiq/job_util"

module Sidekiq
  class Client
    include Sidekiq::JobUtil

    ##
    # Define client-side middleware:
    #
    #   client = Sidekiq::Client.new
    #   client.middleware do |chain|
    #     chain.use MyClientMiddleware
    #   end
    #   client.push('class' => 'SomeJob', 'args' => [1,2,3])
    #
    # All client instances default to the globally-defined
    # Sidekiq.client_middleware but you can change as necessary.
    #
    def middleware(&block)
      @chain ||= Sidekiq.client_middleware
      if block
        @chain = @chain.dup
        yield @chain
      end
      @chain
    end

    attr_accessor :redis_pool

    # Sidekiq::Client normally uses the default Redis pool but you may
    # pass a custom ConnectionPool if you want to shard your
    # Sidekiq jobs across several Redis instances (for scalability
    # reasons, e.g.)
    #
    #   Sidekiq::Client.new(ConnectionPool.new { Redis.new })
    #
    # Generally this is only needed for very large Sidekiq installs processing
    # thousands of jobs per second.  I don't recommend sharding unless you
    # cannot scale any other way (e.g. splitting your app into smaller apps).
    def initialize(redis_pool = nil)
      @redis_pool = redis_pool || Thread.current[:sidekiq_via_pool] || Sidekiq.redis_pool
    end

    ##
    # The main method used to push a job to Redis.  Accepts a number of options:
    #
    #   queue - the named queue to use, default 'default'
    #   class - the job class to call, required
    #   args - an array of simple arguments to the perform method, must be JSON-serializable
    #   at - timestamp to schedule the job (optional), must be Numeric (e.g. Time.now.to_f)
    #   retry - whether to retry this job if it fails, default true or an integer number of retries
    #   backtrace - whether to save any error backtrace, default false
    #
    # If class is set to the class name, the jobs' options will be based on Sidekiq's default
    # job options. Otherwise, they will be based on the job class's options.
    #
    # Any options valid for a job class's sidekiq_options are also available here.
    #
    # All options must be strings, not symbols.  NB: because we are serializing to JSON, all
    # symbols in 'args' will be converted to strings.  Note that +backtrace: true+ can take quite a bit of
    # space in Redis; a large volume of failing jobs can start Redis swapping if you aren't careful.
    #
    # Returns a unique Job ID.  If middleware stops the job, nil will be returned instead.
    #
    # Example:
    #   push('queue' => 'my_queue', 'class' => MyJob, 'args' => ['foo', 1, :bat => 'bar'])
    #
    def push(item)
      normed = normalize_item(item)
      payload = middleware.invoke(item["class"], normed, normed["queue"], @redis_pool) do
        normed
      end
      if payload
        verify_json(payload)
        raw_push([payload])
        payload["jid"]
      end
    end

    ##
    # Push a large number of jobs to Redis. This method cuts out the redis
    # network round trip latency.  I wouldn't recommend pushing more than
    # 1000 per call but YMMV based on network quality, size of job args, etc.
    # A large number of jobs can cause a bit of Redis command processing latency.
    #
    # Takes the same arguments as #push except that args is expected to be
    # an Array of Arrays.  All other keys are duplicated for each job.  Each job
    # is run through the client middleware pipeline and each job gets its own Job ID
    # as normal.
    #
    # Returns an array of the of pushed jobs' jids.  The number of jobs pushed can be less
    # than the number given if the middleware stopped processing for one or more jobs.
    def push_bulk(items)
      args = items["args"]
      raise ArgumentError, "Bulk arguments must be an Array of Arrays: [[1], [2]]" unless args.is_a?(Array) && args.all?(Array)
      return [] if args.empty? # no jobs to push

      at = items.delete("at")
      raise ArgumentError, "Job 'at' must be a Numeric or an Array of Numeric timestamps" if at && (Array(at).empty? || !Array(at).all? { |entry| entry.is_a?(Numeric) })
      raise ArgumentError, "Job 'at' Array must have same size as 'args' Array" if at.is_a?(Array) && at.size != args.size

      jid = items.delete("jid")
      raise ArgumentError, "Explicitly passing 'jid' when pushing more than one job is not supported" if jid && args.size > 1

      normed = normalize_item(items)
      payloads = args.map.with_index { |job_args, index|
        copy = normed.merge("args" => job_args, "jid" => SecureRandom.hex(12))
        copy["at"] = (at.is_a?(Array) ? at[index] : at) if at
        result = middleware.invoke(items["class"], copy, copy["queue"], @redis_pool) do
          verify_json(copy)
          copy
        end
        result || nil
      }.compact

      raw_push(payloads) unless payloads.empty?
      payloads.collect { |payload| payload["jid"] }
    end

    # Allows sharding of jobs across any number of Redis instances.  All jobs
    # defined within the block will use the given Redis connection pool.
    #
    #   pool = ConnectionPool.new { Redis.new }
    #   Sidekiq::Client.via(pool) do
    #     SomeJob.perform_async(1,2,3)
    #     SomeOtherJob.perform_async(1,2,3)
    #   end
    #
    # Generally this is only needed for very large Sidekiq installs processing
    # thousands of jobs per second.  I do not recommend sharding unless
    # you cannot scale any other way (e.g. splitting your app into smaller apps).
    def self.via(pool)
      raise ArgumentError, "No pool given" if pool.nil?
      current_sidekiq_pool = Thread.current[:sidekiq_via_pool]
      Thread.current[:sidekiq_via_pool] = pool
      yield
    ensure
      Thread.current[:sidekiq_via_pool] = current_sidekiq_pool
    end

    class << self
      def push(item)
        new.push(item)
      end

      def push_bulk(items)
        new.push_bulk(items)
      end

      # Resque compatibility helpers.  Note all helpers
      # should go through Sidekiq::Job#client_push.
      #
      # Example usage:
      #   Sidekiq::Client.enqueue(MyJob, 'foo', 1, :bat => 'bar')
      #
      # Messages are enqueued to the 'default' queue.
      #
      def enqueue(klass, *args)
        klass.client_push("class" => klass, "args" => args)
      end

      # Example usage:
      #   Sidekiq::Client.enqueue_to(:queue_name, MyJob, 'foo', 1, :bat => 'bar')
      #
      def enqueue_to(queue, klass, *args)
        klass.client_push("queue" => queue, "class" => klass, "args" => args)
      end

      # Example usage:
      #   Sidekiq::Client.enqueue_to_in(:queue_name, 3.minutes, MyJob, 'foo', 1, :bat => 'bar')
      #
      def enqueue_to_in(queue, interval, klass, *args)
        int = interval.to_f
        now = Time.now.to_f
        ts = ((int < 1_000_000_000) ? now + int : int)

        item = {"class" => klass, "args" => args, "at" => ts, "queue" => queue}
        item.delete("at") if ts <= now

        klass.client_push(item)
      end

      # Example usage:
      #   Sidekiq::Client.enqueue_in(3.minutes, MyJob, 'foo', 1, :bat => 'bar')
      #
      def enqueue_in(interval, klass, *args)
        klass.perform_in(interval, *args)
      end
    end

    private

    def raw_push(payloads)
      @redis_pool.with do |conn|
        retryable = true
        begin
          conn.pipelined do |pipeline|
            atomic_push(pipeline, payloads)
          end
        rescue RedisConnection.adapter::BaseError => ex
          # 2550 Failover can cause the server to become a replica, need
          # to disconnect and reopen the socket to get back to the primary.
          # 4495 Use the same logic if we have a "Not enough replicas" error from the primary
          # 4985 Use the same logic when a blocking command is force-unblocked
          # The retry logic is copied from sidekiq.rb
          if retryable && ex.message =~ /READONLY|NOREPLICAS|UNBLOCKED/
            conn.disconnect!
            retryable = false
            retry
          end
          raise
        end
      end
      true
    end

    def atomic_push(conn, payloads)
      if payloads.first.key?("at")
        conn.zadd("schedule", payloads.flat_map { |hash|
          at = hash.delete("at").to_s
          [at, Sidekiq.dump_json(hash)]
        })
      else
        queue = payloads.first["queue"]
        now = Time.now.to_f
        to_push = payloads.map { |entry|
          entry["enqueued_at"] = now
          Sidekiq.dump_json(entry)
        }
        conn.sadd("queues", [queue])
        conn.lpush("queue:#{queue}", to_push)
      end
    end
  end
end
