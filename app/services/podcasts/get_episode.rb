module Podcasts
  class GetEpisode
    def initialize(podcast)
      @podcast = podcast
    end

    def call(item:, force_update: false)
      item_data = item.is_a?(EpisodeRssItem) ? item : Podcasts::EpisodeRssItem.from_item(item)
      return unless item_data.enclosure_url

      episode = podcast.existing_episode(item_data)
      if episode
        if !episode.published_at? && item_data.pubDate
          update_published_at(episode, item_data)
        end
        unreachable = !(episode.https? && episode.reachable?)
        need_url_update = (unreachable && episode.created_at > 12.hours.ago) || force_update
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
