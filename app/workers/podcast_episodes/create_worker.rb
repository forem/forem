module PodcastEpisodes
  class CreateWorker
    include Sidekiq::Job

    sidekiq_options queue: :high_priority

    def perform(podcast_id, episode_cache_key)
      item = Rails.cache.read(episode_cache_key)
      return unless item

      Podcasts::CreateEpisode.call(podcast_id, item.with_indifferent_access)
    end
  end
end
