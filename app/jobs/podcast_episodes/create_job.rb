module PodcastEpisodes
  class CreateJob < ApplicationJob
    queue_as :podcast_episode_create

    # @param podcast_id [Integer] - podcast id
    # @param item [Hash] according to the Podcasts::EpisodeRssItem::ATTRIBUTES
    def perform(podcast_id, item)
      Podcasts::CreateEpisode.call(podcast_id, item)
    end
  end
end
