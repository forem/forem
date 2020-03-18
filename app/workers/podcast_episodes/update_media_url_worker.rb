module PodcastEpisodes
  class UpdateMediaUrlWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority

    def perform(episode_id, enclosure_url)
      episode = PodcastEpisode.find_by!(id: episode_id)
      Podcasts::UpdateEpisodeMediaUrl.call(episode, enclosure_url)
    end
  end
end
