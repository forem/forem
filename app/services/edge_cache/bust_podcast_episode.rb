module EdgeCache
  class BustPodcastEpisode
    def self.call(podcast_episode, path, podcast_slug)
      return unless podcast_episode && path && podcast_slug

      podcast_episode.purge
      podcast_episode.purge_all

      begin
        cache_bust = EdgeCache::Bust.new
        cache_bust.call(path)
        cache_bust.call("/#{podcast_slug}")
        cache_bust.call("/pod")
      rescue StandardError => e
        Rails.logger.warn(e)
      end
    end
  end
end
