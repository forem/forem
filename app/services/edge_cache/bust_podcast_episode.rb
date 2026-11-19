module EdgeCache
  class BustPodcastEpisode
    def self.call(podcast_episode, path, podcast_slug)
      return unless podcast_episode && path && podcast_slug

      slug = podcast_slug.to_s.delete_prefix("/")
      EdgeCache::PurgeByKey.call(
        [podcast_episode.record_key, podcast_episode.table_key, "podcast_episodes_all", "podcasts/#{slug}"],
        fallback_paths: [path, "/#{slug}", "/pod"],
      )
    rescue StandardError => e
      Rails.logger.warn(e)
    end
  end
end
