module Podcasts
  class UpdateEpisodeMediaUrl
    def initialize(episode, enclosure_url)
      @episode = episode
      @enclosure_url = enclosure_url
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      # update_published_at unless episode.published_at?
      # if !episode.media_url.include?("https") && item.enclosure_url.include?("https")
      result = GetMediaUrl.call(enclosure_url)
      episode.reachable = result.reachable
      episode.media_url = result.url
      episode.https = result.https
      episode.save!
    end

    private

    attr_reader :episode, :enclosure_url

    # def update_published_at
    #   episode.published_at = item.pubDate.to_date
    #   episode.save
    # rescue StandardError => e
    #   Rails.logger.error("not a valid date: #{e}")
    # end
  end
end
