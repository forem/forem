module Podcasts
  class GetEpisodesWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 10

    # podcast_data should be a Hash with keys :podcast_id, :limit, and :force_update
    # :limit and :force_update are both optional - there are default values
    def perform(podcast_data = {})
      # Sidekiq turns arguments into Strings so the Ruby keyword argument sorcery doesn't work here
      # prevent any mismatch between String keys and Symbol keys
      podcast_data.symbolize_keys!

      podcast_id = podcast_data[:podcast_id]
      limit = podcast_data[:limit] || 1_000
      force_update = podcast_data[:force_update] || false

      podcast = Podcast.find_by(id: podcast_id)
      return unless podcast

      Podcasts::Feed.new(podcast).get_episodes(limit: limit, force_update: force_update)
    end
  end
end
