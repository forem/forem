desc "This task is called by the Heroku scheduler add-on"

task get_podcast_episodes: :environment do
  Podcast.published.select(:id).find_each do |podcast|
    Podcasts::GetEpisodesWorker.perform_async(podcast_id: podcast.id, limit: 5)
  end
end

task github_repo_fetch_all: :environment do
  GithubRepo.update_to_latest
end
