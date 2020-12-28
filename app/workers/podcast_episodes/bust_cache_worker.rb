module PodcastEpisodes
  class BustCacheWorker < BustCacheBaseWorker
    def perform(podcast_episode_id, path, podcast_slug)
      podcast_episode = PodcastEpisode.find_by(id: podcast_episode_id)

      return unless podcast_episode && path && podcast_slug

      EdgeCache::BustPodcastEpisode.call(podcast_episode, path, podcast_slug)
    end
  end
end
