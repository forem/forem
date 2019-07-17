desc "A task to check potentially unplayable podcasts and update their and their episodes' statuses if needed"

task update_podcasts_statuses: :environment do
  Podcast.where("status_notice ilike %may not be playable%").pluck(:id).find_each do |podcast_id|
    Podcasts::GetEpisodesJob.new(podcast_id: podcast_id, limit: 1000, force_update: true).perform_later
  end
end
