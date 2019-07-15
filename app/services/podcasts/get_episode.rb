module Podcasts
  class GetEpisode
    def initialize(podcast, update = Podcasts::UpdateEpisode)
      @podcast = podcast
      @update = update
    end

    def call(item)
      item_data = item.is_a?(EpisodeRssItem) ? item : Podcasts::EpisodeRssItem.from_item(item)
      return unless item_data.enclosure_url

      episode = podcast.existing_episode(item_data)
      if episode
        update.call(episode, item_data)
      else
        PodcastEpisodes::CreateJob.perform_later(podcast.id, item_data.to_h)
      end
    end

    private

    attr_reader :podcast, :update
  end
end
