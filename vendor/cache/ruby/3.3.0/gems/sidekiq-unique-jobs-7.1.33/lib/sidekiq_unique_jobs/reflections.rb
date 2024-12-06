# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Class NotificationCollection provides a collection with known notifications
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  #
  class Reflections
    #
    # @return [Array<Symbol>] list of notifications
    REFLECTIONS = [
      :after_unlock_callback_failed,
      :debug,
      :duplicate,
      :error,
      :execution_failed,
      :lock_failed,
      :locked,
      :reschedule_failed,
      :rescheduled,
      :timeout,
      :unknown_sidekiq_worker,
      :unlock_failed,
      :unlocked,
    ].freeze

    #
    # @return [Hash<Symbol, Array<Symbol, String>>] a hash with deprecated notifications
    DEPRECATIONS = {}.freeze

    REFLECTIONS.each do |reflection|
      class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
        def #{reflection}(*args, &block)                            # def unlock_failed(*args, &block)
          raise NoBlockGiven, "block required" unless block_given?  #   raise NoBlockGiven, "block required" unless block_given?
          @reflections[:#{reflection}] = block                      #   @notifications[:unlock_failed] = block
        end                                                         # end
      RUBY
    end

    def initialize
      @reflections = {}
    end

    #
    # Dispatch a reflected event
    #
    # @param [reflection] reflection the reflected event
    # @param [Array] args the arguments to provide to the block
    #
    # @return [void] <description>
    #
    def dispatch(reflection, *args)
      if (block = @reflections[reflection])
        block.call(*args)

        if DEPRECATIONS.key?(reflection)
          replacement, removal_version = DEPRECATIONS[reflection]
          SidekiqUniqueJobs::Deprecation.warn(
            "#{reflection} is deprecated and will be removed in version #{removal_version}." \
            " Use #{replacement} instead.",
          )
        end
      elsif misconfigured?(reflection)
        raise NoSuchNotificationError, reflection
      end

      nil
    end

    def configured?(reflection)
      REFLECTIONS.include?(reflection)
    end

    def misconfigured?(reflection)
      !configured?(reflection)
    end
  end
end
