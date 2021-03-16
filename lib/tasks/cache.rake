namespace :cache do
  desc "Enqueue BustCachePathWorker"
  task enqueue_path_bust_workers: :environment do
    # Trigger cache purges for globally-cached endpoints that could have changed
    [30, 180, 600].each do |n|
      BustCachePathWorker.set(queue: :high_priority).perform_in(n.seconds, "/")
      # TODO: Remove these "shell" endpoints, because they are for service worker functionality we no longer need.
      # We are keeping these around mid-March 2021 because previously-installed service workers may still expect them.
      BustCachePathWorker.set(queue: :high_priority).perform_in(n.seconds, "/shell_top")
      BustCachePathWorker.set(queue: :high_priority).perform_in(n.seconds, "/shell_bottom")
      BustCachePathWorker.set(queue: :high_priority).perform_in(n.seconds, "/async_info/shell_version")

      BustCachePathWorker.set(queue: :high_priority).perform_in(n.seconds, "/onboarding")
    end
  end
end
