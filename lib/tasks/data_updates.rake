namespace :data_updates do
  desc "Enqueue Sidekiq worker to handle data updates"
  task enqueue_data_update_worker: :environment do
    # Ensure new code has been deployed before we run our update scripts
    DataUpdateWorker.perform_in(10.minutes)
  end

  desc "Run data updates"
  task run: :environment do
    DataUpdateWorker.new.perform
  end
end
