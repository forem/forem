# frozen_string_literal: true

#
# Contains configuration and utility methods that belongs top level
#
# @author Mikael Henriksson <mikael@mhenrixon.com>
module SidekiqUniqueJobs # rubocop:disable Metrics/ModuleLength
  include SidekiqUniqueJobs::Connection
  extend SidekiqUniqueJobs::JSON

  module_function

  #
  # The current configuration (See: {.configure} on how to configure)
  #
  #
  # @return [SidekiqUniqueJobs::Config] the gem configuration
  #
  def config
    @config ||= reset! # rubocop:disable ThreadSafety/InstanceVariableInClassMethod
  end

  #
  # The current strategies
  #
  #
  # @return [Hash<Symbol, SidekiqUniqueJobs::Strategy>] the configured locks
  #
  def strategies
    config.strategies
  end

  #
  # The current locks
  #
  #
  # @return [Hash<Symbol, SidekiqUniqueJobs::BaseLock>] the configured locks
  #
  def locks
    config.locks
  end

  #
  # The current logger
  #
  #
  # @return [Logger] the configured logger
  #
  def logger
    config.logger
  end

  #
  # The current gem version
  #
  #
  # @return [String] the current gem version
  #
  def version
    VERSION
  end

  #
  # Set a new logger
  #
  # @param [Logger] other another logger
  #
  # @return [Logger] the new logger
  #
  def logger=(other)
    config.logger = other
  end

  #
  # Check if logging is enabled
  #
  #
  # @return [true, false]
  #
  def logging?
    config.logger_enabled
  end

  #
  # Temporarily use another configuration and reset to the old config after yielding
  #
  # @param [Hash] tmp_config the temporary configuration to use
  #
  # @return [void]
  #
  # @yield control to the caller
  def use_config(tmp_config = {})
    raise ::ArgumentError, "#{name}.#{__method__} needs a block" unless block_given?

    old_config = config.to_h
    reset!
    configure(tmp_config)
    yield
  ensure
    reset!
    configure(old_config.to_h)
  end

  #
  # Resets configuration to deafult
  #
  #
  # @return [SidekiqUniqueJobs::Config] a default gem configuration
  #
  def reset!
    @config = SidekiqUniqueJobs::Config.default # rubocop:disable ThreadSafety/InstanceVariableInClassMethod
  end

  #
  # Enable SidekiqUniuqeJobs either temporarily in a block or for good
  #
  #
  # @return [true] when not given a block
  # @return [true, false] the previous value of enable when given a block
  #
  # @yieldreturn [void] temporarily enable sidekiq unique jobs while executing a block of code
  def enable!(&block)
    toggle(true, &block)
  end

  #
  # Disable SidekiqUniuqeJobs either temporarily in a block or for good
  #
  #
  # @return [false] when not given a block
  # @return [true, false] the previous value of enable when given a block
  #
  # @yieldreturn [void] temporarily disable sidekiq unique jobs while executing a block of code
  def disable!(&block)
    toggle(false, &block)
  end

  #
  # Checks if the gem has been disabled
  #
  # @return [true] when config.enabled is true
  # @return [false] when config.enabled is false
  #
  def enabled?
    config.enabled
  end

  #
  # Checks if the gem has been disabled
  #
  # @return [true] when config.enabled is false
  # @return [false] when config.enabled is true
  #
  def disabled?
    !enabled?
  end

  #
  # Toggles enabled on or off
  #
  # @api private
  # :nodoc:
  def toggle(enabled)
    if block_given?
      enabled_was = config.enabled
      config.enabled = enabled
      yield
      config.enabled = enabled_was
    else
      config.enabled = enabled
    end
  end

  # Configure the gem
  #
  # This is usually called once at startup of an application
  # @param [Hash] options global gem options
  # @option options [Integer] :lock_timeout (default is 0)
  # @option options [Integer] :lock_ttl (default is 0)
  # @option options [true,false] :enabled (default is true)
  # @option options [String] :lock_prefix (default is 'uniquejobs')
  # @option options [Logger] :logger (default is Sidekiq.logger)
  # @yield control to the caller when given block
  def configure(options = {})
    if block_given?
      yield config
    else
      options.each do |key, val|
        config.send(:"#{key}=", val)
      end
    end
  end

  #
  # Returns the current redis version
  #
  #
  # @return [String] a string like `5.0.2`
  #
  def fetch_redis_version
    Sidekiq.redis_info["redis_version"]
  end

  #
  # Current time as float
  #
  #
  # @return [Float]
  #
  def now_f
    now.to_f
  end

  #
  # Current time
  #
  #
  # @return [Time]
  #
  def now
    Time.now
  end

  #
  # Checks that the worker is valid with the given options
  #
  # @param [Hash] options the `sidekiq_options` to validate
  #
  # @return [Boolean]
  #
  def validate_worker(options)
    raise NotUniqueWorker, options unless (lock_type = options[LOCK])

    lock_class = locks[lock_type]
    lock_class.validate_options(options)
  end

  #
  # Checks that the worker is valid with the given options
  #
  # @param [Hash] options the `sidekiq_options` to validate
  #
  # @raise [InvalidWorker] when {#validate_worker} returns false or nil
  #
  def validate_worker!(options)
    lock_config = validate_worker(options)
    raise InvalidWorker, lock_config unless lock_config.errors.empty?
  end

  # Attempt to constantize a string worker_class argument, always
  # failing back to the original argument when the constant can't be found
  #
  # @return [Sidekiq::Worker]
  def constantize(str)
    return str.class             if str.is_a?(Sidekiq::Worker) # sidekiq v6.x
    return str                   unless str.is_a?(String)
    return Object.const_get(str) unless str.include?("::")

    names = str.split("::")
    names.shift if names.empty? || names.first.empty?

    names.inject(Object) do |constant, name|
      # the false flag limits search for name to under the constant namespace
      #   which mimics Rails' behaviour
      constant.const_get(name, false)
    end
  end

  # Attempt to constantize a string worker_class argument, always
  # failing back to the original argument when the constant can't be found
  #
  # @return [Sidekiq::Worker, String]
  def safe_constantize(str)
    constantize(str)
  rescue NameError => ex
    case ex.message
    when /uninitialized constant/
      str
    else
      raise
    end
  end

  #
  # Collection with notifications
  #
  #
  # @return [Reflections]
  #
  def reflections
    @reflections ||= Reflections.new # rubocop:disable ThreadSafety/InstanceVariableInClassMethod
  end

  #
  # Yields notification stack for sidekiq unique jobs to configure notifications
  #
  #
  # @return [void] <description>
  #
  # @yieldparam [Reflections] x used to configure notifications
  def reflect
    yield reflections if block_given?
  end
end
