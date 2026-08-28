module CommunityLeaders
  class PruneInactiveWorker
    include Sidekiq::Job
    include Sidekiq::Throttled::Job

    sidekiq_throttle(concurrency: { limit: 1 })

    sidekiq_options queue: :low_priority, retry: 5, lock: :until_and_while_executing

    def perform
      CommunityLeaders::PruneInactive.call
    end
  end
end
