module Podcasts
  class UpdateEpisode
    def initialize(episode, item)
      @episode = episode
      @item = item
    end

    def self.call(*args)
      new(*args).call
    end

    def call
      update_published_at unless episode.published_at?
      update_media_url if !episode.media_url.include?("https") && item.enclosure_url.include?("https")
    end

    private

    attr_reader :episode, :item

    def update_published_at
      episode.published_at = item.pubDate.to_date
      episode.save
    rescue StandardError => e
      Rails.logger.error("not a valid date: #{e}")
    end

    def update_media_url
      episode.update!(media_url: item.enclosure_url)
    rescue StandardError
      message = "something went wrong with #{episode.podcast_title}, #{episode.title} -- #{episode.media_url}"
      Rails.logger.error(message)
    end
  end
end
