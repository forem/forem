desc "This task is called by the Heroku scheduler add-on"

task get_podcast_episodes: :environment do
  Podcast.published.select(:id).find_each do |podcast|
    Podcasts::GetEpisodesWorker.perform_async(podcast_id: podcast.id, limit: 5)
  end
end

task fetch_all_rss: :environment do
  Rails.application.eager_load!

  RssReader.get_all_articles(force: false) # don't force fetch. Fetch "random" subset instead of all of them.
end

task save_nil_hotness_scores: :environment do
  Article.published.where(hotness_score: nil).find_each(&:save)
end

task github_repo_fetch_all: :environment do
  GithubRepo.update_to_latest
end

task remove_old_html_variant_data: :environment do
  HtmlVariantTrial.destroy_by("created_at < ?", 2.weeks.ago)
  HtmlVariantSuccess.destroy_by("created_at < ?", 2.weeks.ago)
  HtmlVariant.find_each do |html_variant|
    html_variant.calculate_success_rate! if html_variant.html_variant_successes.any?
  end
end

task fix_credits_count_cache: :environment do
  Credit.counter_culture_fix_counts only: %i[user organization]
end
