desc "This task is called by the Heroku scheduler add-on"

task get_podcast_episodes: :environment do
  Podcast.published.select(:id).find_each do |podcast|
    Podcasts::GetEpisodesWorker.perform_async(podcast_id: podcast.id, limit: 5)
  end
end

task fetch_all_rss: :environment do
  Rails.application.eager_load!
  RssReader.get_all_articles(false) # False means don't force fetch. Fetch "random" subset instead of all of them.
end

task resave_supported_tags: :environment do
  puts "resaving supported tags"
  Tag.where(supported: true).find_each(&:save)
end

task expire_old_listings: :environment do
  ClassifiedListing.where("bumped_at < ?", 30.days.ago).each do |listing|
    listing.update(published: false)
  end
  ClassifiedListing.where("expires_at = ?", Time.zone.today).each do |listing|
    listing.update(published: false)
  end
end

task save_nil_hotness_scores: :environment do
  Article.published.where(hotness_score: nil).find_each(&:save)
end

task github_repo_fetch_all: :environment do
  GithubRepo.update_to_latest
end

task send_email_digest: :environment do
  if Time.current.wday >= 3
    EmailDigest.send_periodic_digest_email
  end
end

# This task is meant to be scheduled daily
task prune_old_field_tests: :environment do
  # For rolling ongoing experiemnts, we remove old experiment memberships
  # So that they can be re-tested.
  FieldTests::PruneOldExperimentsWorker.perform_async
end

task remove_old_html_variant_data: :environment do
  HtmlVariantTrial.where("created_at < ?", 2.weeks.ago).destroy_all
  HtmlVariantSuccess.where("created_at < ?", 2.weeks.ago).destroy_all
  HtmlVariant.find_each do |html_variant|
    html_variant.calculate_success_rate! if html_variant.html_variant_successes.any?
  end
end

task fix_credits_count_cache: :environment do
  Credit.counter_culture_fix_counts only: %i[user organization]
end
