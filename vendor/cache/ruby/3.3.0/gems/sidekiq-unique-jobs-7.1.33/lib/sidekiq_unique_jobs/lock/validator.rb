# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    #
    # Validator base class to avoid some duplication
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    class Validator
      #
      # @return [Hash] a hash mapping of deprecated keys and their new value
      DEPRECATED_KEYS = {
        UNIQUE.to_sym => LOCK.to_sym,
        UNIQUE_ARGS.to_sym => LOCK_ARGS_METHOD.to_sym,
        LOCK_ARGS.to_sym => LOCK_ARGS_METHOD.to_sym,
        UNIQUE_PREFIX.to_sym => LOCK_PREFIX.to_sym,
      }.freeze

      #
      # Shorthand for `new(options).validate`
      #
      # @param [Hash] options the sidekiq_options for the worker being validated
      #
      # @return [LockConfig] the lock configuration with errors if any
      #
      def self.validate(options)
        new(options).validate
      end

      #
      # @!attribute [r] lock_config
      #   @return [LockConfig] the lock configuration for this worker
      attr_reader :lock_config

      #
      # Initialize a new validator
      #
      # @param [Hash] options the sidekiq_options for the worker being validated
      #
      def initialize(options)
        @options     = options.transform_keys(&:to_sym)
        @lock_config = LockConfig.new(options)
        handle_deprecations
      end

      #
      # Validate the workers lock configuration
      #
      #
      # @return [LockConfig] the lock configuration with errors if any
      #
      def validate
        case lock_config.type
        when :while_executing
          validate_server
        when :until_executing
          validate_client
        else
          validate_client
          validate_server
        end

        lock_config
      end

      #
      # Validate deprecated keys
      #   adds useful information about how to proceed with fixing handle_deprecations
      #
      # @return [void]
      #
      def handle_deprecations
        DEPRECATED_KEYS.each do |old, new|
          next unless @options.key?(old)

          lock_config.errors[old] = "is deprecated, use `#{new}: #{@options[old]}` instead."
        end
      end

      #
      # Validates the client configuration
      #
      def validate_client
        ClientValidator.validate(lock_config)
      end

      #
      # Validates the server configuration
      #
      def validate_server
        ServerValidator.validate(lock_config)
      end
    end
  end
end
