module EdgeCache
  class BustPodcastEpisode < Buster
    def self.call(podcast_episode, path, podcast_slug)
      return unless podcast_episode && path && podcast_slug

      podcast_episode.purge
      podcast_episode.purge_all

      begin
        buster = EdgeCache::Buster.new
        buster.bust(path)
        buster.bust("/#{podcast_slug}")
        buster.bust("/pod")
      rescue StandardError => e
        Rails.logger.warn(e)
      end
    end
  end
end
