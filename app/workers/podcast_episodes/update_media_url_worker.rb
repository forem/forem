module PodcastEpisodes
  class UpdateMediaUrlWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority

    def perform(episode_id, enclosure_url)
      episode = PodcastEpisode.find(episode_id)
      Podcasts::UpdateEpisodeMediaUrl.call(episode, enclosure_url)
    end
  end
end
