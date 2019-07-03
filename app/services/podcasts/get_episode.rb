module Podcasts
  class GetEpisode
    def initialize(podcast, update = Podcasts::UpdateEpisode)
      @podcast = podcast
      @update = update
    end

    def call(item)
      item_data = item.is_a?(Episodes::RssItemData) ? item : Podcasts::Episodes::RssItemData.from_item(item)
      episode = podcast.existing_episode(item_data)
      if episode
        update.call(episode, item_data)
      else
        # item_data = Podcasts::Episodes::RssItemData.from_item(item).to_h
        PodcastEpisodes::CreateJob.perform_later(podcast.id, item_data.to_h)
      end
    end

    private

    attr_reader :podcast, :update
  end
end
