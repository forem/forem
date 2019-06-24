require "rss"
require "rss/itunes"

module Podcasts
  class Feed
    def get_episodes(podcast, num = 1000)
      rss = HTTParty.get(podcast.feed_url).body
      feed = RSS::Parser.parse(rss, false)
      get_episode = Podcasts::GetEpisode.new(podcast)
      feed.items.first(num).each do |item|
        get_episode.call(item)
      end
      feed.items.size
    rescue StandardError => e
      Rails.logger.error(e)
    end
  end
end
