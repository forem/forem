# frozen_string_literal: true

require "sidekiq/version"
fail "Sidekiq #{Sidekiq::VERSION} does not support Ruby versions below 2.5.0." if RUBY_PLATFORM != "java" && Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.5.0")

require "sidekiq/logger"
require "sidekiq/client"
require "sidekiq/transaction_aware_client"
require "sidekiq/worker"
require "sidekiq/job"
require "sidekiq/redis_connection"
require "sidekiq/delay"

require "json"

module Sidekiq
  NAME = "Sidekiq"
  LICENSE = "See LICENSE and the LGPL-3.0 for licensing details."

  DEFAULTS = {
    queues: [],
    labels: [],
    concurrency: 10,
    require: ".",
    strict: true,
    environment: nil,
    timeout: 25,
    poll_interval_average: nil,
    average_scheduled_poll_interval: 5,
    on_complex_arguments: :warn,
    error_handlers: [],
    death_handlers: [],
    lifecycle_events: {
      startup: [],
      quiet: [],
      shutdown: [],
      # triggers when we fire the first heartbeat on startup OR repairing a network partition
      heartbeat: [],
      # triggers on EVERY heartbeat call, every 10 seconds
      beat: []
    },
    dead_max_jobs: 10_000,
    dead_timeout_in_seconds: 180 * 24 * 60 * 60, # 6 months
    reloader: proc { |&block| block.call }
  }

  FAKE_INFO = {
    "redis_version" => "9.9.9",
    "uptime_in_days" => "9999",
    "connected_clients" => "9999",
    "used_memory_human" => "9P",
    "used_memory_peak_human" => "9P"
  }

  def self.❨╯°□°❩╯︵┻━┻
    puts "Calm down, yo."
  end

  # config.concurrency = 5
  def self.concurrency=(val)
    self[:concurrency] = Integer(val)
  end

  # config.queues = %w( high default low )                 # strict
  # config.queues = %w( high,3 default,2 low,1 )           # weighted
  # config.queues = %w( feature1,1 feature2,1 feature3,1 ) # random
  #
  # With weighted priority, queue will be checked first (weight / total) of the time.
  # high will be checked first (3/6) or 50% of the time.
  # I'd recommend setting weights between 1-10. Weights in the hundreds or thousands
  # are ridiculous and unnecessarily expensive. You can get random queue ordering
  # by explicitly setting all weights to 1.
  def self.queues=(val)
    self[:queues] = Array(val).each_with_object([]) do |qstr, memo|
      name, weight = qstr.split(",")
      self[:strict] = false if weight.to_i > 0
      [weight.to_i, 1].max.times do
        memo << name
      end
    end
  end

  ### Private APIs
  def self.default_error_handler(ex, ctx)
    logger.warn(dump_json(ctx)) unless ctx.empty?
    logger.warn("#{ex.class.name}: #{ex.message}")
    logger.warn(ex.backtrace.join("\n")) unless ex.backtrace.nil?
  end

  # DEFAULT_ERROR_HANDLER is a constant that allows the default error handler to
  # be referenced. It must be defined here, after the default_error_handler
  # method is defined.
  DEFAULT_ERROR_HANDLER = method(:default_error_handler)

  @config = DEFAULTS.dup
  def self.options
    logger.warn "`config.options[:key] = value` is deprecated, use `config[:key] = value`: #{caller(1..2)}"
    @config
  end

  def self.options=(opts)
    logger.warn "config.options = hash` is deprecated, use `config.merge!(hash)`: #{caller(1..2)}"
    @config = opts
  end

  def self.[](key)
    @config[key]
  end

  def self.[]=(key, val)
    @config[key] = val
  end

  def self.merge!(hash)
    @config.merge!(hash)
  end

  def self.fetch(*args, &block)
    @config.fetch(*args, &block)
  end

  def self.handle_exception(ex, ctx = {})
    self[:error_handlers].each do |handler|
      handler.call(ex, ctx)
    rescue => ex
      logger.error "!!! ERROR HANDLER THREW AN ERROR !!!"
      logger.error ex
      logger.error ex.backtrace.join("\n") unless ex.backtrace.nil?
    end
  end
  ###

  ##
  # Configuration for Sidekiq server, use like:
  #
  #   Sidekiq.configure_server do |config|
  #     config.server_middleware do |chain|
  #       chain.add MyServerHook
  #     end
  #   end
  def self.configure_server
    yield self if server?
  end

  ##
  # Configuration for Sidekiq client, use like:
  #
  #   Sidekiq.configure_client do |config|
  #     config.redis = { size: 1, url: 'redis://myhost:8877/0' }
  #   end
  def self.configure_client
    yield self unless server?
  end

  def self.server?
    defined?(Sidekiq::CLI)
  end

  def self.redis
    raise ArgumentError, "requires a block" unless block_given?
    redis_pool.with do |conn|
      retryable = true
      begin
        yield conn
      rescue RedisConnection.adapter::BaseError => ex
        # 2550 Failover can cause the server to become a replica, need
        # to disconnect and reopen the socket to get back to the primary.
        # 4495 Use the same logic if we have a "Not enough replicas" error from the primary
        # 4985 Use the same logic when a blocking command is force-unblocked
        # The same retry logic is also used in client.rb
        if retryable && ex.message =~ /READONLY|NOREPLICAS|UNBLOCKED/
          conn.disconnect!
          retryable = false
          retry
        end
        raise
      end
    end
  end

  def self.redis_info
    redis do |conn|
      # admin commands can't go through redis-namespace starting
      # in redis-namespace 2.0
      if conn.respond_to?(:namespace)
        conn.redis.info
      else
        conn.info
      end
    rescue RedisConnection.adapter::CommandError => ex
      # 2850 return fake version when INFO command has (probably) been renamed
      raise unless /unknown command/.match?(ex.message)
      FAKE_INFO
    end
  end

  def self.redis_pool
    @redis ||= RedisConnection.create
  end

  def self.redis=(hash)
    @redis = if hash.is_a?(ConnectionPool)
      hash
    else
      RedisConnection.create(hash)
    end
  end

  def self.client_middleware
    @client_chain ||= Middleware::Chain.new(self)
    yield @client_chain if block_given?
    @client_chain
  end

  def self.server_middleware
    @server_chain ||= default_server_middleware
    yield @server_chain if block_given?
    @server_chain
  end

  def self.default_server_middleware
    Middleware::Chain.new(self)
  end

  def self.default_worker_options=(hash) # deprecated
    @default_job_options = default_job_options.merge(hash.transform_keys(&:to_s))
  end

  def self.default_job_options=(hash)
    @default_job_options = default_job_options.merge(hash.transform_keys(&:to_s))
  end

  def self.default_worker_options # deprecated
    @default_job_options ||= {"retry" => true, "queue" => "default"}
  end

  def self.default_job_options
    @default_job_options ||= {"retry" => true, "queue" => "default"}
  end

  ##
  # Death handlers are called when all retries for a job have been exhausted and
  # the job dies.  It's the notification to your application
  # that this job will not succeed without manual intervention.
  #
  # Sidekiq.configure_server do |config|
  #   config.death_handlers << ->(job, ex) do
  #   end
  # end
  def self.death_handlers
    self[:death_handlers]
  end

  def self.load_json(string)
    JSON.parse(string)
  end

  def self.dump_json(object)
    JSON.generate(object)
  end

  def self.log_formatter
    @log_formatter ||= if ENV["DYNO"]
      Sidekiq::Logger::Formatters::WithoutTimestamp.new
    else
      Sidekiq::Logger::Formatters::Pretty.new
    end
  end

  def self.log_formatter=(log_formatter)
    @log_formatter = log_formatter
    logger.formatter = log_formatter
  end

  def self.logger
    @logger ||= Sidekiq::Logger.new($stdout, level: :info)
  end

  def self.logger=(logger)
    if logger.nil?
      self.logger.level = Logger::FATAL
      return self.logger
    end

    logger.extend(Sidekiq::LoggingUtils)

    @logger = logger
  end

  def self.pro?
    defined?(Sidekiq::Pro)
  end

  def self.ent?
    defined?(Sidekiq::Enterprise)
  end

  # How frequently Redis should be checked by a random Sidekiq process for
  # scheduled and retriable jobs. Each individual process will take turns by
  # waiting some multiple of this value.
  #
  # See sidekiq/scheduled.rb for an in-depth explanation of this value
  def self.average_scheduled_poll_interval=(interval)
    self[:average_scheduled_poll_interval] = interval
  end

  # Register a proc to handle any error which occurs within the Sidekiq process.
  #
  #   Sidekiq.configure_server do |config|
  #     config.error_handlers << proc {|ex,ctx_hash| MyErrorService.notify(ex, ctx_hash) }
  #   end
  #
  # The default error handler logs errors to Sidekiq.logger.
  def self.error_handlers
    self[:error_handlers]
  end

  # Register a block to run at a point in the Sidekiq lifecycle.
  # :startup, :quiet or :shutdown are valid events.
  #
  #   Sidekiq.configure_server do |config|
  #     config.on(:shutdown) do
  #       puts "Goodbye cruel world!"
  #     end
  #   end
  def self.on(event, &block)
    raise ArgumentError, "Symbols only please: #{event}" unless event.is_a?(Symbol)
    raise ArgumentError, "Invalid event name: #{event}" unless self[:lifecycle_events].key?(event)
    self[:lifecycle_events][event] << block
  end

  def self.strict_args!(mode = :raise)
    self[:on_complex_arguments] = mode
  end

  # We are shutting down Sidekiq but what about threads that
  # are working on some long job?  This error is
  # raised in jobs that have not finished within the hard
  # timeout limit.  This is needed to rollback db transactions,
  # otherwise Ruby's Thread#kill will commit.  See #377.
  # DO NOT RESCUE THIS ERROR IN YOUR JOBS
  class Shutdown < Interrupt; end
end

require "sidekiq/rails" if defined?(::Rails::Engine)
