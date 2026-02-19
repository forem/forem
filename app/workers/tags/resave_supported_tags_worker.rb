module Tags
  class ResaveSupportedTagsWorker
    include Sidekiq::Job
    include Sidekiq::Throttled::Job

    sidekiq_throttle(concurrency: { limit: 1 })

    sidekiq_options queue: :low_priority, retry: 5

    def perform
      Tag.supported.find_each(&:save)
      Subforem.find_each(&:update_scores!)
    end
  end
end
