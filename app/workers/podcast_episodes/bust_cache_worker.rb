module PodcastEpisodes
  class BustCacheWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 10

    def perform(podcast_episode_id, path, podcast_slug)
      podcast_episode = PodcastEpisode.find_by(id: podcast_episode_id)
      return if podcast_episode.nil?

      CacheBuster.bust_podcast_episode(podcast_episode, path, podcast_slug)
    end
  end
end
