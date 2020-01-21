module PodcastEpisodes
  class CreateWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority

    def perform(podcast_id, item)
      Podcasts::CreateEpisode.call(podcast_id, item)
    end
  end
end
