desc "This task is called by the Heroku scheduler add-on"

task :get_podcast_episodes => :environment do
  Podcast.find_each do |p|
    PodcastFeed.new.get_episodes(p,5)
  end
end

task :periodic_cache_bust => :environment do
  CacheBuster.new.bust("/enter")
  CacheBuster.new.bust("/new")
  CacheBuster.new.bust("/dashboard")
  CacheBuster.new.bust("/users/auth/twitter")
  CacheBuster.new.bust("/users/auth/github")
  CacheBuster.new.bust("/feed")
  CacheBuster.new.bust("/feed")
  CacheBuster.new.bust("/feed.xml")
end

task :hourly_bust => :environment do
  CacheBuster.new.bust("/")
end

task :fetch_all_rss => :environment do
  Rails.application.eager_load!
  RssReader.get_all_articles
end

task :resave_supported_tags => :environment do
  puts "resaving supported tags"
  Tag.where(supported: true).find_each(&:save)
end

task :renew_hired_articles => :environment do
  Article.
    tagged_with("hiring").
    where("featured_number < ?", 7.days.ago.to_i + 11.minutes.to_i).
    where(approved: true, published: true, automatically_renew: true).
  each do |article|
    if article.automatically_renew
      article.featured_number = Time.now.to_i
      article.save
    else
      article.approved = false
      article.body_markdown = article.body_markdown.gsub("published: true", "published: false")
      article.save
    end
  end
end

task :clear_memory_if_too_high => :environment do
  if Rails.cache.stats.flatten[1]["bytes"].to_i > 2000000000
    Rails.cache.clear
  end
end

task :save_nil_hotness_scores => :environment do
  Article.where(hotness_score: nil, published: true).find_each(&:save)
end

task :github_repo_fetch_all => :environment do
  GithubRepo.update_to_latest
end

task :send_email_digest => :environment do
  EmailDigest.send_periodic_digest_email
end
