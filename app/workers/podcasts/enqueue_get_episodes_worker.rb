module Podcasts
  class EnqueueGetEpisodesWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10

    def perform
      # `perform_bulk` expects an array of argument arrays we need to wrap the hashes.
      job_params = Podcast.published.ids.map { |id| [{ "podcast_id" => id, "limit" => 5 }] }
      Podcasts::GetEpisodesWorker.perform_bulk(job_params)
    end
  end
end
