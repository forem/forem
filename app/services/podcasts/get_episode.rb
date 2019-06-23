module Podcasts
  class GetEpisode
    def initialize(podcast)
      @podcast = podcast
    end

    def call(item)
      ep = existing_episode(item, podcast).first
      if ep
        Podcasts::UpdateEpisode.call(ep, item)
      else
        Podcasts::CreateEpisode.call(podcast.id, item)
      end
    end

    private

    attr_reader :podcast

    # returns empty array if an episode doesn't exist
    def existing_episode(item, podcast)
      # presence returns nil if the query is an empty array, otherwise returns the array
      podcasts = PodcastEpisode.where(media_url: item.enclosure.url).presence ||
        PodcastEpisode.where(title: item.title).presence ||
        PodcastEpisode.where(guid: item.guid.to_s).presence ||
        (podcast.unique_website_url? && PodcastEpisode.where(website_url: item.link).presence)
      podcasts.to_a
    end
  end
end
