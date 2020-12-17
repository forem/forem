module EdgeCache
  class BustPodcastEpisode < Bust
    def self.call(podcast_episode, path, podcast_slug)
      return unless podcast_episode && path && podcast_slug

      podcast_episode.purge
      podcast_episode.purge_all

      begin
        bust(path)
        bust("/#{podcast_slug}")
        bust("/pod")
      rescue StandardError => e
        Rails.logger.warn(e)
      end
    end
  end
end
