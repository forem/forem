module Podcasts
  class GetEpisodesJob < ApplicationJob
    queue_as :podcasts_get_episodes

    def perform(podcast_id:, limit: 1000, force_update: false, feed: Podcasts::Feed.new)
      podcast = Podcast.find_by(id: podcast_id)
      return unless podcast

      feed.get_episodes(podcast: podcast, limit: limit, force_update: force_update)
    end
  end
end
