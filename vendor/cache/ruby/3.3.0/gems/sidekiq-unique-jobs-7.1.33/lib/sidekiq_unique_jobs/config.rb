# frozen_string_literal: true

module SidekiqUniqueJobs
  # ThreadSafe config exists to be able to document the config class without errors
  ThreadSafeConfig = Concurrent::MutableStruct.new("ThreadSafeConfig",
                                                   :lock_timeout,
                                                   :lock_ttl,
                                                   :enabled,
                                                   :lock_prefix,
                                                   :logger,
                                                   :logger_enabled,
                                                   :locks,
                                                   :strategies,
                                                   :debug_lua,
                                                   :max_history,
                                                   :reaper,
                                                   :reaper_count,
                                                   :reaper_interval,
                                                   :reaper_timeout,
                                                   :reaper_resurrector_interval,
                                                   :reaper_resurrector_enabled,
                                                   :lock_info,
                                                   :raise_on_config_error,
                                                   :current_redis_version)

  #
  # Shared class for dealing with gem configuration
  #
  # @author Mauro Berlanda <mauro.berlanda@gmail.com>
  # rubocop:disable Metrics/ClassLength
  class Config < ThreadSafeConfig
    #
    # @return [Hash<Symbol, SidekiqUniqueJobs::Lock::BaseLock] all available queued locks
    LOCKS_WHILE_ENQUEUED = {
      until_executing: SidekiqUniqueJobs::Lock::UntilExecuting,
      while_enqueued: SidekiqUniqueJobs::Lock::UntilExecuting,
    }.freeze

    #
    # @return [Hash<Symbol, SidekiqUniqueJobs::Lock::BaseLock] all available fulltime locks
    LOCKS_FROM_PUSH_TO_PROCESSED = {
      until_completed: SidekiqUniqueJobs::Lock::UntilExecuted,
      until_executed: SidekiqUniqueJobs::Lock::UntilExecuted,
      until_performed: SidekiqUniqueJobs::Lock::UntilExecuted,
      until_processed: SidekiqUniqueJobs::Lock::UntilExecuted,
      until_and_while_executing: SidekiqUniqueJobs::Lock::UntilAndWhileExecuting,
      until_successfully_completed: SidekiqUniqueJobs::Lock::UntilExecuted,
    }.freeze

    #
    # @return [Hash<Symbol, SidekiqUniqueJobs::Lock::BaseLock] all available locks without unlock
    LOCKS_WITHOUT_UNLOCK = {
      until_expired: SidekiqUniqueJobs::Lock::UntilExpired,
    }.freeze

    #
    # @return [Hash<Symbol, SidekiqUniqueJobs::Lock::BaseLock] all available runtime/client locks
    LOCKS_WHEN_BUSY = {
      around_perform: SidekiqUniqueJobs::Lock::WhileExecuting,
      while_busy: SidekiqUniqueJobs::Lock::WhileExecuting,
      while_executing: SidekiqUniqueJobs::Lock::WhileExecuting,
      while_working: SidekiqUniqueJobs::Lock::WhileExecuting,
      while_executing_reject: SidekiqUniqueJobs::Lock::WhileExecutingReject,
    }.freeze

    #
    # @return [Hash<Symbol, SidekiqUniqueJobs::Lock::BaseLock] all available default locks
    LOCKS =
      LOCKS_WHEN_BUSY.dup
                     .merge(LOCKS_WHILE_ENQUEUED.dup)
                     .merge(LOCKS_WITHOUT_UNLOCK.dup)
                     .merge(LOCKS_FROM_PUSH_TO_PROCESSED.dup)
                     .freeze

    #
    # @return [Hash<Symbol, SidekiqUniqueJobs::OnConflict::Strategy] all available default strategies
    STRATEGIES = {
      log: SidekiqUniqueJobs::OnConflict::Log,
      raise: SidekiqUniqueJobs::OnConflict::Raise,
      reject: SidekiqUniqueJobs::OnConflict::Reject,
      replace: SidekiqUniqueJobs::OnConflict::Replace,
      reschedule: SidekiqUniqueJobs::OnConflict::Reschedule,
    }.freeze

    #
    # @return ['uniquejobs'] by default we use this prefix
    PREFIX                = "uniquejobs"
    #
    # @return [0] by default don't wait for locks
    LOCK_TIMEOUT          = 0
    #
    # @return [nil]
    LOCK_TTL              = nil
    #
    # @return [true,false] by default false (don't disable logger)
    LOGGER_ENABLED        = true
    #
    # @return [true] by default the gem is enabled
    ENABLED               = true
    #
    # @return [false] by default we don't debug the lua scripts because it is slow
    DEBUG_LUA             = false
    #
    # @return [1_000] use a changelog history of 1_000 entries by default
    MAX_HISTORY           = 1_000
    #
    # @return [:ruby] prefer the ruby reaper by default since the lua reaper still has problems
    REAPER                = :ruby
    #
    # @return [1_000] reap 1_000 orphaned locks at a time by default
    REAPER_COUNT          = 1_000
    #
    # @return [600] reap locks every 10 minutes
    REAPER_INTERVAL       = 600
    #
    # @return [10] stop reaper after 10 seconds
    REAPER_TIMEOUT        = 10
    #
    # @return [3600] check if reaper is dead each 3600 seconds
    REAPER_RESURRECTOR_INTERVAL = 3600

    #
    # @return [false] enable reaper resurrector
    REAPER_RESURRECTOR_ENABLED = false

    #
    # @return [false] while useful it also adds overhead so disable lock_info by default
    USE_LOCK_INFO         = false
    #
    # @return [false] by default we don't raise validation errors for workers
    RAISE_ON_CONFIG_ERROR = false
    #
    # @return [0.0.0] default redis version is only to avoid NoMethodError on nil
    REDIS_VERSION         = "0.0.0"

    #
    # Returns a default configuration
    #
    # @example
    #   SidekiqUniqueJobs::Config.default => <concurrent/mutable_struct/thread_safe_config SidekiqUniqueJobs::Config {
    #   default_lock_timeout: 0,
    #   default_lock_ttl: nil,
    #   enabled: true,
    #   lock_prefix: "uniquejobs",
    #   logger: #<Sidekiq::Logger:0x00007f81e096b0e0 @level=1 ...>,
    #   locks: {
    #     around_perform: SidekiqUniqueJobs::Lock::WhileExecuting,
    #     while_busy: SidekiqUniqueJobs::Lock::WhileExecuting,
    #     while_executing: SidekiqUniqueJobs::Lock::WhileExecuting,
    #     while_working: SidekiqUniqueJobs::Lock::WhileExecuting,
    #     while_executing_reject: SidekiqUniqueJobs::Lock::WhileExecutingReject,
    #     until_executing: SidekiqUniqueJobs::Lock::UntilExecuting,
    #     while_enqueued: SidekiqUniqueJobs::Lock::UntilExecuting,
    #     until_expired: SidekiqUniqueJobs::Lock::UntilExpired,
    #     until_completed: SidekiqUniqueJobs::Lock::UntilExecuted,
    #     until_executed: SidekiqUniqueJobs::Lock::UntilExecuted,
    #     until_performed: SidekiqUniqueJobs::Lock::UntilExecuted,
    #     until_processed: SidekiqUniqueJobs::Lock::UntilExecuted,
    #     until_and_while_executing: SidekiqUniqueJobs::Lock::UntilAndWhileExecuting,
    #     until_successfully_completed: SidekiqUniqueJobs::Lock::UntilExecuted
    #   },
    #   strategies: {
    #     log: SidekiqUniqueJobs::OnConflict::Log,
    #     raise: SidekiqUniqueJobs::OnConflict::Raise,
    #     reject: SidekiqUniqueJobs::OnConflict::Reject,
    #     replace: SidekiqUniqueJobs::OnConflict::Replace,
    #     reschedule: SidekiqUniqueJobs::OnConflict::Reschedule
    #   },
    #   debug_lua: false,
    #   max_history: 1000,
    #   reaper:: ruby,
    #   reaper_count: 1000,
    #   lock_info: false,
    #   raise_on_config_error: false,
    #   }>
    #
    #
    # @return [SidekiqUniqueJobs::Config] a default configuration
    #
    def self.default # rubocop:disable Metrics/MethodLength
      new(
        LOCK_TIMEOUT,
        LOCK_TTL,
        ENABLED,
        PREFIX,
        Sidekiq.logger,
        LOGGER_ENABLED,
        LOCKS,
        STRATEGIES,
        DEBUG_LUA,
        MAX_HISTORY,
        REAPER,
        REAPER_COUNT,
        REAPER_INTERVAL,
        REAPER_TIMEOUT,
        REAPER_RESURRECTOR_INTERVAL,
        REAPER_RESURRECTOR_ENABLED,
        USE_LOCK_INFO,
        RAISE_ON_CONFIG_ERROR,
        REDIS_VERSION,
      )
    end

    #
    # Set the default_lock_ttl
    # @deprecated
    #
    # @param [Integer] obj value to set (seconds)
    #
    # @return [<type>] <description>
    #
    def default_lock_ttl=(obj)
      warn "[DEPRECATION] `#{class_name}##{__method__}` is deprecated." \
           " Please use `#{class_name}#lock_ttl=` instead."
      self.lock_ttl = obj
    end

    #
    # Set new value for default_lock_timeout
    # @deprecated
    #
    # @param [Integer] obj value to set (seconds)
    #
    # @return [Integer]
    #
    def default_lock_timeout=(obj)
      warn "[DEPRECATION] `#{class_name}##{__method__}` is deprecated." \
           " Please use `#{class_name}#lock_timeout=` instead."
      self.lock_timeout = obj
    end

    #
    # Default lock TTL (Time To Live)
    # @deprecated
    #
    # @return [nil, Integer] configured value or nil
    #
    def default_lock_ttl
      warn "[DEPRECATION] `#{class_name}##{__method__}` is deprecated." \
           " Please use `#{class_name}#lock_ttl` instead."
      lock_ttl
    end

    #
    # Default Lock Timeout
    # @deprecated
    #
    #
    # @return [nil, Integer] configured value or nil
    #
    def default_lock_timeout
      warn "[DEPRECATION] `#{class_name}##{__method__}` is deprecated." \
           " Please use `#{class_name}#lock_timeout` instead."
      lock_timeout
    end

    #
    # Memoized variable to get the class name
    #
    #
    # @return [String] name of the class
    #
    def class_name
      @class_name ||= self.class.name
    end

    #
    # Adds a lock type to the configuration. It will raise if the lock exists already
    #
    # @example Add a custom lock
    #   add_lock(:my_lock, CustomLocks::MyLock)
    #
    # @raise DuplicateLock when the name already exists
    #
    # @param [String, Symbol] name the name of the lock
    # @param [Class] klass the class describing the lock
    #
    # @return [void]
    #
    def add_lock(name, klass)
      lock_sym = name.to_sym
      raise DuplicateLock, ":#{name} already defined, please use another name" if locks.key?(lock_sym)

      new_locks = locks.dup.merge(lock_sym => klass).freeze
      self.locks = new_locks
    end

    #
    # Adds an on_conflict strategy to the configuration.
    #
    # @example Add a custom strategy
    #   add_lock(:my_strategy, CustomStrategies::MyStrategy)
    #
    # @raise [DuplicateStrategy] when the name already exists
    #
    # @param [String] name the name of the custom strategy
    # @param [Class] klass the class describing the strategy
    #
    def add_strategy(name, klass)
      strategy_sym = name.to_sym
      raise DuplicateStrategy, ":#{name} already defined, please use another name" if strategies.key?(strategy_sym)

      new_strategies = strategies.dup.merge(strategy_sym => klass).freeze
      self.strategies = new_strategies
    end

    #
    # The current version of redis
    #
    #
    # @return [String] a version string eg. `5.0.1`
    #
    def redis_version
      self.current_redis_version = SidekiqUniqueJobs.fetch_redis_version if current_redis_version == REDIS_VERSION
      current_redis_version
    end
  end
  # rubocop:enable Metrics/ClassLength
end
