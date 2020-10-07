namespace :cache do
  desc "Enqueue BustCachePathWorker"
  task enqueue_path_bust_workers: :environment do
    # Trigger cache purges for globally-cached endpoints that could have changed
    BustCachePathWorker.set(queue: :high_priority).perform_in(10.minutes, "/shell_top")
    BustCachePathWorker.set(queue: :high_priority).perform_in(10.minutes, "/shell_bottom")
    BustCachePathWorker.set(queue: :high_priority).perform_in(10.minutes, "/onboarding")
    BustCachePathWorker.set(queue: :high_priority).perform_in(10.minutes, "/async_info/shell_version")
  end
end
