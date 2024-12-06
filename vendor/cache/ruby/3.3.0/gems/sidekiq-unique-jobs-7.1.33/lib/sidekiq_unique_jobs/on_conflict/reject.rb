# frozen_string_literal: true

module SidekiqUniqueJobs
  module OnConflict
    # Strategy to send jobs to dead queue
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class Reject < OnConflict::Strategy
      include SidekiqUniqueJobs::Timing

      # Send jobs to dead queue
      def call
        log_info { "Adding dead #{item[CLASS]} job #{item[JID]}" }

        if deadset_kill?
          deadset_kill
        else
          push_to_deadset
        end
      end

      #
      # Sidekiq version compatibility check
      # @api private
      #
      #
      # @return [true, false] depending on if Sidekiq::Deadset responds to kill
      #
      def deadset_kill?
        deadset.respond_to?(:kill)
      end

      #
      # Use Sidekiqs built in Sidekiq::DeadSet#kill
      #   to get rid of the job
      # @api private
      #
      #
      # @return [void]
      #
      def deadset_kill
        if kill_with_options?
          kill_job_with_options
        else
          kill_job_without_options
        end
      end

      #
      # Sidekiq version compatibility check
      # @api private
      #
      #
      # @return [true] when Sidekiq::Deadset#kill takes more than 1 argument
      # @return [false] when Sidekiq::Deadset#kill does not take multiple arguments
      #
      def kill_with_options?
        Sidekiq::DeadSet.instance_method(:kill).arity > 1
      end

      #
      # Executes the kill instructions without arguments
      # @api private
      #
      # @return [void]
      #
      def kill_job_without_options
        deadset.kill(payload)
      end

      #
      # Executes the kill instructions with arguments
      # @api private
      #
      # @return [void]
      #
      def kill_job_with_options
        deadset.kill(payload, notify_failure: false)
      end

      #
      # An instance of Sidekiq::Deadset
      # @api private
      #
      # @return [Sidekiq::Deadset]>
      #
      def deadset
        @deadset ||= Sidekiq::DeadSet.new
      end

      #
      # Used for compatibility with older Sidekiq versions
      #
      #
      # @return [void]
      #
      def push_to_deadset
        redis do |conn|
          conn.multi do |pipeline|
            pipeline.zadd("dead", now_f, payload)
            pipeline.zremrangebyscore("dead", "-inf", now_f - Sidekiq::DeadSet.timeout)
            pipeline.zremrangebyrank("dead", 0, -Sidekiq::DeadSet.max_jobs)
          end
        end
      end

      #
      # The Sidekiq job hash as JSON
      #
      #
      # @return [String] a JSON formatted string
      #
      def payload
        @payload ||= dump_json(item)
      end
    end
  end
end
