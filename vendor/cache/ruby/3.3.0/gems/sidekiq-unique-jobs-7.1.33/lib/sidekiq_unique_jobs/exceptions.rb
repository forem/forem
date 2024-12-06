# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Base class for all exceptions raised from the gem
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  #
  class UniqueJobsError < ::RuntimeError
  end

  # Error raised when a Lua script fails to execute
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  class Conflict < UniqueJobsError
    def initialize(item)
      super("Item with the key: #{item[LOCK_DIGEST]} is already scheduled or processing")
    end
  end

  #
  # Raised when no block was given
  #
  class NoBlockGiven < SidekiqUniqueJobs::UniqueJobsError; end

  #
  # Raised when a notification has been mistyped
  #
  class NoSuchNotificationError < UniqueJobsError; end

  #
  # Error raised when trying to add a duplicate lock
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  #
  class DuplicateLock < UniqueJobsError
  end

  #
  # Error raised when trying to add a duplicate stragegy
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  #
  class DuplicateStrategy < UniqueJobsError
  end

  #
  # Error raised when an invalid argument is given
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  #
  class InvalidArgument < UniqueJobsError
  end

  #
  # Raised when a workers configuration is invalid
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  #
  class InvalidWorker < UniqueJobsError
    def initialize(lock_config)
      super(<<~FAILURE_MESSAGE)
        Expected #{lock_config.worker} to have valid sidekiq options but found the following problems:
        #{lock_config.errors_as_string}
      FAILURE_MESSAGE
    end
  end

  # Error raised when a Lua script fails to execute
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  class InvalidUniqueArguments < UniqueJobsError
    def initialize(options)
      given            = options[:given]
      job_class        = options[:job_class]
      lock_args_method = options[:lock_args_method]
      lock_args_meth   = job_class.method(lock_args_method)
      num_args         = lock_args_meth.arity
      source_location  = lock_args_meth.source_location

      super(
        "#{job_class}##{lock_args_method} takes #{num_args} arguments, received #{given.inspect}" \
        "\n\n" \
        "   #{source_location.join(':')}"
      )
    end
  end

  #
  # Raised when a workers configuration is invalid
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  #
  class NotUniqueWorker < UniqueJobsError
    def initialize(options)
      super("#{options[:class]} is not configured for uniqueness. Missing the key `:lock` in #{options.inspect}")
    end
  end

  # Error raised from {OptionsWithFallback#lock_class}
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  class UnknownLock < UniqueJobsError
  end
end
