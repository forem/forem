namespace :cache do
  desc "Enqueue BustCachePathWorker"
  task enqueue_path_bust_workers: :environment do
    # Trigger cache purges for globally-cached endpoints after Heroku Preboot (~180s)
    # has completed and new web dynos are warm.
    delays = ENV.fetch("CACHE_BUST_DELAYS_SECONDS", "240,420,600")
      .split(",")
      .map(&:strip)
      .reject(&:empty?)
      .map(&:to_i)
    delays = [240, 420, 600] if delays.empty?

    delays.each do |n|
      BustCachePathWorker.set(queue: :high_priority).perform_in(n.seconds, "/")
      BustCachePathWorker.set(queue: :high_priority).perform_in(n.seconds, "/onboarding")
    end
  end

  desc "Clear application cache"
  task clear_app_cache: :environment do
    raise "Attempting to clear Rails cache in production" if Rails.env.production?

    Rails.cache.clear
  end
end
