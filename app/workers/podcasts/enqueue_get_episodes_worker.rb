module Podcasts
  class EnqueueGetEpisodesWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10

    def perform
      Podcast.published.select(:id).find_each do |podcast|
        Podcasts::GetEpisodesWorker.perform_async(podcast_id: podcast.id, limit: 5)
      end
    end
  end
end
