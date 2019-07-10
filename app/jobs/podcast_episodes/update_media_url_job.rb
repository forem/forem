module PodcastEpisodes
  class UpdateMediaUrlJob < ApplicationJob
    queue_as :podcast_episode_update

    # @param episode_id [Integer] - podcast id
    # @param item [Hash] according to the Podcasts::EpisodeRssItem::ATTRIBUTES
    def perform(episode_id, enclosure_url)
      episode = PodcastEpisode.find_by(id: episode_id)
      Podcasts::UpdateEpisodeMediaUrl.call(episode, enclosure_url) if episode
    end
  end
end
