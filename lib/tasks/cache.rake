namespace :cache do
  desc "Enqueue BustCachePathWorker"
  task enqueue_path_bust_workers: :environment do
    # Trigger cache purges for globally-cached endpoints that could have changed
    [30, 180, 600].each do |n|
      BustCachePathWorker.set(queue: :high_priority).perform_in(n.seconds, "/")
      BustCachePathWorker.set(queue: :high_priority).perform_in(n.seconds, "/shell_top")
      BustCachePathWorker.set(queue: :high_priority).perform_in(n.seconds, "/shell_bottom")
      BustCachePathWorker.set(queue: :high_priority).perform_in(n.seconds, "/onboarding")
      BustCachePathWorker.set(queue: :high_priority).perform_in(n.seconds, "/async_info/shell_version")
    end
  end
end
