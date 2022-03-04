module Podcasts
  class UpdateEpisodeMediaUrl
    def initialize(episode, enclosure_url)
      @episode = episode
      @enclosure_url = enclosure_url
    end

    def self.call(...)
      new(...).call
    end

    def call
      result = GetMediaUrl.call(enclosure_url)
      episode.reachable = result.reachable
      episode.media_url = result.url
      episode.https = result.https
      episode.save!
    end

    private

    attr_reader :episode, :enclosure_url
  end
end
