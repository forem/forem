module PodcastEpisodes
  class UpdateMediaUrlJob < ApplicationJob
    queue_as :podcast_episode_update

    # @param episode_id [Integer] - episode id
    # @param enclosure_url [String] enclosure url from podcast RSS
    def perform(episode_id, enclosure_url, service = Podcasts::UpdateEpisodeMediaUrl)
      episode = PodcastEpisode.find_by(id: episode_id)
      service.call(episode, enclosure_url) if episode
    end
  end
end
