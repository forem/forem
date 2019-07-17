desc "A task to check potentially unplayable podcasts and update their and their episodes' statuses if needed"

task update_podcasts_statuses: :environment do
  Podcast.where("status_notice ILIKE ?", "%may not be playable%").pluck(:id).each do |podcast_id|
    Podcasts::GetEpisodesJob.perform_later(podcast_id: podcast_id, limit: 1000, force_update: true)
  end
end
