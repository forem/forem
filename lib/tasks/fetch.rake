desc "This task is called by the Heroku scheduler add-on"

task get_podcast_episodes: :environment do
  Podcast.find_each do |p|
    PodcastFeed.new.get_episodes(p, 5)
  end
end

task periodic_cache_bust: :environment do
  cache_buster = CacheBuster.new
  cache_buster.bust("/enter")
  cache_buster.bust("/new")
  cache_buster.bust("/dashboard")
  cache_buster.bust("/users/auth/twitter")
  cache_buster.bust("/users/auth/github")
  cache_buster.bust("/feed")
  cache_buster.bust("/feed")
  cache_buster.bust("/feed.xml")
end

task hourly_bust: :environment do
  CacheBuster.new.bust("/")
end

task fetch_all_rss: :environment do
  Rails.application.eager_load!
  RssReader.get_all_articles
end

task resave_supported_tags: :environment do
  puts "resaving supported tags"
  Tag.where(supported: true).find_each(&:save)
end

task renew_hired_articles: :environment do
  Article.
    tagged_with("hiring").
    where("featured_number < ?", 7.days.ago.to_i + 11.minutes.to_i).
    where(approved: true, published: true, automatically_renew: true).
    each do |article|

    if article.automatically_renew
      article.featured_number = Time.now.to_i
    else
      article.approved = false
      article.body_markdown = article.body_markdown.gsub(
        "published: true", "published: false"
      )
    end

    article.save
  end
end

task clear_memory_if_too_high: :environment do
  if Rails.cache.stats.flatten[1]["bytes"].to_i > 2000000000
    Rails.cache.clear
  end
end

task save_nil_hotness_scores: :environment do
  Article.where(hotness_score: nil, published: true).find_each(&:save)
end

task github_repo_fetch_all: :environment do
  GithubRepo.update_to_latest
end

task send_email_digest: :environment do
  return if Time.now.wday < 3
  EmailDigest.send_periodic_digest_email
end

task award_badges: :environment do
  BadgeRewarder.award_yearly_club_badges
  BadgeRewarder.award_beloved_comment_badges
end

# rake award_top_seven_badges["ben jess peter mac liana andy"]
task :award_top_seven_badges, [:arg1] => :environment do |_t, args|
  usernames = args[:arg1].split(" ")
  puts "Awarding top-7 badges to #{usernames}"
  BadgeRewarder.award_top_seven_badges(usernames)
  puts "Done!"
end

# rake award_contributor_badges["ben jess peter mac liana andy"]
task :award_contributor_badges, [:arg1] => :environment do |_t, args|
  usernames = args[:arg1].split(" ")
  puts "Awarding dev-contributor badges to #{usernames}"
  BadgeRewarder.award_contributor_badges(usernames)
  puts "Done!"
end
