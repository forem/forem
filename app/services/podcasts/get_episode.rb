module Podcasts
  class GetEpisode
    def initialize(podcast, update = Podcasts::UpdateEpisode)
      @podcast = podcast
      @update = update
    end

    def call(item)
      episode = podcast.existing_episode(item)
      if episode
        update.call(episode, item)
      else
        item_data = Podcasts::Episodes::RssItemData.from_item(item).to_h
        PodcastEpisodes::CreateJob.perform_later(podcast.id, item_data)
      end
    end

    private

    attr_reader :podcast, :update
  end
end
