# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Gathers all configuration for a lock
  #   which helps reduce the amount of instance variables
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  #
  class LockConfig
    #
    # @!attribute [r] type
    #   @return [Symbol] the type of lock
    attr_reader :type
    #
    # @!attribute [r] job
    #   @return [Symbol] the job class
    attr_reader :job
    #
    # @!attribute [r] limit
    #   @return [Integer] the number of simultaneous locks
    attr_reader :limit
    #
    # @!attribute [r] timeout
    #   @return [Integer, nil] the time to wait for a lock
    attr_reader :timeout
    #
    # @!attribute [r] ttl
    #   @return [Integer, nil] the time (in seconds) to live after successful
    attr_reader :ttl
    #
    # @!attribute [r] ttl
    #   @return [Integer, nil] the time (in milliseconds) to live after successful
    attr_reader :pttl
    #
    # @!attribute [r] lock_info
    #   @return [Boolean] indicate wether to use lock_info or not
    attr_reader :lock_info
    #
    # @!attribute [r] on_conflict
    #   @return [Symbol, Hash<Symbol, Symbol>] the strategies to use as conflict resolution
    attr_reader :on_conflict
    #
    # @!attribute [r] errors
    #   @return [Array<Hash<Symbol, Array<String>] a collection of configuration errors
    attr_reader :errors

    #
    # Instantiate a new lock_config based on sidekiq options in worker
    #
    # @param [Hash] options sidekiq_options for worker
    #
    # @return [LockConfig]
    #
    def self.from_worker(options)
      new(options.deep_stringify_keys)
    end

    def initialize(job_hash = {})
      @type        = job_hash[LOCK]&.to_sym
      @job         = SidekiqUniqueJobs.safe_constantize(job_hash[CLASS])
      @limit       = job_hash.fetch(LOCK_LIMIT, 1)&.to_i
      @timeout     = job_hash.fetch(LOCK_TIMEOUT, 0)&.to_i
      @ttl         = job_hash.fetch(LOCK_TTL) { job_hash.fetch(LOCK_EXPIRATION, nil) }.to_i
      @pttl        = ttl * 1_000
      @lock_info   = job_hash.fetch(LOCK_INFO) { SidekiqUniqueJobs.config.lock_info }
      @on_conflict = job_hash.fetch(ON_CONFLICT, nil)
      @errors      = job_hash.fetch(ERRORS) { {} }

      @on_client_conflict = job_hash[ON_CLIENT_CONFLICT]
      @on_server_conflict = job_hash[ON_SERVER_CONFLICT]
    end

    def lock_info?
      lock_info
    end

    #
    # Indicate if timeout was set
    #
    #
    # @return [true,false]
    #
    def wait_for_lock?
      timeout.nil? || timeout.positive?
    end

    #
    # Is the configuration valid?
    #
    #
    # @return [true,false]
    #
    def valid?
      errors.empty?
    end

    #
    # Return a nice descriptive message with all validation errors
    #
    #
    # @return [String]
    #
    def errors_as_string
      return if valid?

      @errors_as_string ||= begin
        error_msg = +"\t"
        error_msg << errors.map { |key, val| "#{key}: :#{val}" }.join("\n\t")
        error_msg
      end
    end

    # the strategy to use as conflict resolution from sidekiq client
    def on_client_conflict
      @on_client_conflict ||= on_conflict["client"] || on_conflict[:client] if on_conflict.is_a?(Hash)
      @on_client_conflict ||= on_conflict
    end

    # the strategy to use as conflict resolution from sidekiq server
    def on_server_conflict
      @on_server_conflict ||= on_conflict["server"] || on_conflict[:server] if on_conflict.is_a?(Hash)
      @on_server_conflict ||= on_conflict
    end
  end
end
