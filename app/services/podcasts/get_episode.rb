module Podcasts
  class GetEpisode
    def initialize(podcast)
      @podcast = podcast
    end

    def call(item)
      item_data = item.is_a?(EpisodeRssItem) ? item : Podcasts::EpisodeRssItem.from_item(item)
      episode = podcast.existing_episode(item_data)
      if episode
        if !episode.published_at? && item_data.pubDate
          update_published_at(episode, item_data)
        end
        need_url_update = !(episode.https? && episode.reachable?)
        PodcastEpisodes::UpdateMediaUrlJob.perform_later(episode.id, item_data.enclosure_url) if need_url_update
      else
        PodcastEpisodes::CreateJob.perform_later(podcast.id, item_data.to_h)
      end
    end

    private

    attr_reader :podcast

    def update_published_at(episode, item_data)
      episode.published_at = item_data.pubDate.to_date
      episode.save
    rescue ArgumentError, NoMethodError => e
      Rails.logger.error("not a valid date: #{e}")
    end
  end
end
