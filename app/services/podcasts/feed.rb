require "rss"
require "rss/itunes"

module Podcasts
  class Feed
    def get_episodes(podcast:, limit: 100, force_update: false)
      rss = HTTParty.get(podcast.feed_url).body
      feed = RSS::Parser.parse(rss, false)

      set_unreachable(podcast, :unparsable) && return unless feed

      get_episode = Podcasts::GetEpisode.new(podcast)
      feed.items.first(limit).each do |item|
        get_episode.call(item: item, force_update: force_update)
      end
      podcast.update_columns(reachable: true, status_notice: "")
      feed.items.size
    rescue Net::OpenTimeout, Errno::ECONNREFUSED => _e
      set_unreachable(podcast, :unreachable)
    rescue OpenSSL::SSL::SSLError => _e
      set_unreachable(podcast, :ssl_failed)
    rescue RSS::NotWellFormedError => _e
      set_unreachable(podcast, :unparsable)
    end

    private

    def set_unreachable(podcast, status = :unreachable)
      podcast.update_columns(reachable: false, status_notice: I18n.t(status, scope: "podcasts.statuses"))
    end
  end
end
