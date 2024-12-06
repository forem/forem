# frozen_string_literal: true

require "sidekiq/api"

#
# @api private
#
module Sidekiq
  # See Sidekiq::Api
  class SortedEntry
    #
    # Provides extensions for unlocking jobs that are removed and deleted
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    module UniqueExtension
      #
      # Wraps the original method to ensure locks for the job are deleted
      #
      #
      # @return [Hash] the deleted sidekiq job hash
      #
      def delete
        SidekiqUniqueJobs::Unlockable.delete!(item) if super
        item
      end

      private

      #
      # Wraps the original method to ensure locks for the job are deleted
      #
      #
      # @yieldparam [Hash] message the sidekiq job hash
      def remove_job
        super do |message|
          SidekiqUniqueJobs::Unlockable.delete!(Sidekiq.load_json(message))
          yield message
        end
      end
    end

    prepend UniqueExtension
  end

  # See Sidekiq::Api
  class ScheduledSet
    #
    # Provides extensions for unlocking jobs that are removed and deleted
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    module UniqueExtension
      #
      # Wraps the original method to ensure locks for the job are deleted
      #
      #
      # @param [Integer, Float] score the score in the scheduled set
      # @param [String] job_id the Sidekiq JID
      #
      def delete(score, job_id)
        entry = find_job(job_id)
        SidekiqUniqueJobs::Unlockable.delete!(entry.item) if super(score, job_id)
        entry
      end
    end

    prepend UniqueExtension
  end

  if Sidekiq.const_defined?(:JobRecord)
    # See Sidekiq::Api
    class JobRecord
      #
      # Provides extensions for unlocking jobs that are removed and deleted
      #
      # @author Mikael Henriksson <mikael@mhenrixon.com>
      #
      module UniqueExtension
        #
        # Wraps the original method to ensure locks for the job are deleted
        #
        def delete
          SidekiqUniqueJobs::Unlockable.delete!(item)
          super
        end
      end

      prepend UniqueExtension
    end
  else
    # See Sidekiq::Api
    class Job
      #
      # Provides extensions for unlocking jobs that are removed and deleted
      #
      # @author Mikael Henriksson <mikael@mhenrixon.com>
      #
      module UniqueExtension
        #
        # Wraps the original method to ensure locks for the job are deleted
        #
        def delete
          SidekiqUniqueJobs::Unlockable.delete!(item)
          super
        end
      end

      prepend UniqueExtension
    end
  end

  # See Sidekiq::Api
  class Queue
    #
    # Provides extensions for unlocking jobs that are removed and deleted
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    module UniqueExtension
      #
      # Wraps the original method to ensure locks for the job are deleted
      #
      def clear
        each(&:delete)
        super
      end
    end

    prepend UniqueExtension
  end

  # See Sidekiq::Api
  class JobSet
    #
    # Provides extensions for unlocking jobs that are removed and deleted
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    module UniqueExtension
      #
      # Wraps the original method to ensure locks for the job are deleted
      #
      def clear
        each(&:delete)
        super
      end

      #
      # Wraps the original method to ensure locks for the job are deleted
      #
      #
      # @param [String] name the name of the key
      # @param [String] value a sidekiq job hash
      #
      def delete_by_value(name, value)
        SidekiqUniqueJobs::Unlockable.delete!(Sidekiq.load_json(value)) if super(name, value)
      end
    end

    prepend UniqueExtension
  end
end
