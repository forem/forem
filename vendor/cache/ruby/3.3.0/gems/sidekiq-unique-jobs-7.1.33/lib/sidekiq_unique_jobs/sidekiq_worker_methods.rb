# frozen_string_literal: true

module SidekiqUniqueJobs
  # Module with convenience methods for the Sidekiq::Worker class
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  module SidekiqWorkerMethods
    #
    # @!attribute [r] job_class
    #   @return [Sidekiq::Worker] The Sidekiq::Worker implementation
    attr_reader :job_class

    # Avoids duplicating worker_class.respond_to? in multiple places
    # @return [true, false]
    def job_method_defined?(method_sym)
      job_class.respond_to?(method_sym)
    end

    # Wraps #get_sidekiq_options to always work with a hash
    # @return [Hash] of the worker class sidekiq options
    def job_options
      return {} unless sidekiq_job_class?

      job_class.get_sidekiq_options.deep_stringify_keys
    end

    # Tests that the
    # @return [true] if job_class responds to get_sidekiq_options
    # @return [false] if job_class does not respond to get_sidekiq_options
    def sidekiq_job_class?
      job_method_defined?(:get_sidekiq_options)
    end

    def job_class=(obj)
      # this is what was originally passed in, it can be an instance or a class depending on sidekiq version
      @original_job_class = obj
      @job_class = job_class_constantize(obj)
    end

    # The hook to call after a successful unlock
    # @return [Proc]
    def after_unlock_hook # rubocop:disable Metrics/MethodLength
      lambda do
        if @original_job_class.respond_to?(:after_unlock)
          # instance method in sidekiq v6
          if @original_job_class.method(:after_unlock).arity.positive? # arity check to maintain backwards compatibility
            @original_job_class.after_unlock(item)
          else
            @original_job_class.after_unlock
          end
        elsif job_class.respond_to?(:after_unlock)
          # class method regardless of sidekiq version
          if job_class.method(:after_unlock).arity.positive? # arity check to maintain backwards compatibility
            job_class.after_unlock(item)
          else
            job_class.after_unlock
          end
        end
      end
    end

    # Attempt to constantize a string worker_class argument, always
    # failing back to the original argument when the constant can't be found
    #
    # @return [Sidekiq::Worker]
    def job_class_constantize(klazz = @job_class)
      SidekiqUniqueJobs.safe_constantize(klazz)
    end

    #
    # Returns the default worker options from Sidekiq
    #
    #
    # @return [Hash<Symbol, Object>]
    #
    def default_job_options
      if Sidekiq.respond_to?(:default_job_options)
        Sidekiq.default_job_options
      else
        Sidekiq.default_worker_options
      end
    end
  end
end
