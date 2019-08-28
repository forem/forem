module PodcastEpisodes
  class BustCacheJob < ApplicationJob
    queue_as :podcast_episodes_bust_cache

    def perform(podcast_episode_id, path, podcast_slug, cache_buster = CacheBuster.new)
      podcast_episode = PodcastEpisode.find_by(id: podcast_episode_id)
      return unless podcast_episode

      cache_buster.bust_podcast_episode(podcast_episode, path, podcast_slug)
    end
  end
end
