module Tags
  class ResaveSupportedTagsWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority, retry: 5

    def perform
      Tag.supported.find_each(&:save)
      Subforem.find_each(&:update_scores!)
    end
  end
end
