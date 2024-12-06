# frozen_string_literal: true

module SidekiqUniqueJobs
  module OnConflict
    # Strategy to reschedule job on conflict
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class Reschedule < OnConflict::Strategy
      include SidekiqUniqueJobs::SidekiqWorkerMethods
      include SidekiqUniqueJobs::Logging
      include SidekiqUniqueJobs::JSON
      include SidekiqUniqueJobs::Reflectable

      # @param [Hash] item sidekiq job hash
      def initialize(item, redis_pool = nil)
        super(item, redis_pool)
        self.job_class = item[CLASS]
      end

      # Create a new job from the current one.
      #   This will mess up sidekiq stats because a new job is created
      def call
        if sidekiq_job_class?
          if job_class.set(queue: item["queue"].to_sym).perform_in(5, *item[ARGS])
            reflect(:rescheduled, item)
          else
            reflect(:reschedule_failed, item)
          end
        else
          reflect(:unknown_sidekiq_worker, item)
        end
      end
    end
  end
end
