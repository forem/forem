require "rss"
require "rss/itunes"

module Podcasts
  class Feed
    def get_episodes(podcast, num = 1000)
      rss = HTTParty.get(podcast.feed_url).body
      feed = RSS::Parser.parse(rss, false)
      return unless feed

      get_episode = Podcasts::GetEpisode.new(podcast)
      feed.items.first(num).each do |item|
        get_episode.call(item)
      end
      podcast.update_columns(reachable: true, status_notice: "")
      feed.items.size
    rescue Net::OpenTimeout, Errno::ECONNREFUSED => _e
      podcast.update_columns(reachable: false, status_notice: "Podcast's feed_url is not reachable")
    rescue RSS::NotWellFormedError => _e
      podcast.update_columns(reachable: false, status_notice: "Podcast's rss couldn't be parsed")
    end
  end
end
