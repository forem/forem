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
        try_update_media_url(episode: episode, item_data: item_data, force_update: force_update)
      else
        episode_cache_key = cache_key(item_data)
        cache_episode_data(episode_cache_key, item_data)
        PodcastEpisodes::CreateWorker.perform_async(podcast.id, episode_cache_key)
      end
    end

    private

    attr_reader :podcast

    def try_update_media_url(episode:, item_data:, force_update:)
      if !episode.published_at? && item_data.pubDate
        update_published_at(episode, item_data)
      end

      unreachable = !(episode.https? && episode.reachable?)
      need_url_update = (unreachable && episode.created_at > 12.hours.ago) || force_update
      PodcastEpisodes::UpdateMediaUrlWorker.perform_async(episode.id, item_data.enclosure_url) if need_url_update
    end

    def update_published_at(episode, item_data)
      episode.published_at = item_data.pubDate.to_date
      episode.save
    rescue ArgumentError, NoMethodError => e
      Rails.logger.error("not a valid date: #{e}")
    end

    def cache_episode_data(episode_cache_key, item_data)
      Rails.cache.write(episode_cache_key, item_data.to_h)
    end

    def cache_key(item_data)
      Digest::SHA1.hexdigest(item_data.to_s)
    end
  end
end
