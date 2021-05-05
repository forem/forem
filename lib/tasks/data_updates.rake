namespace :data_updates do
  desc "Enqueue Sidekiq worker to handle data updates"
  task enqueue_data_update_worker: :environment do
    if Rails.env.development?
      Rake::Task["data_updates:run"].execute
    else
      # Ensure new code has been deployed before we run our update scripts
      DataUpdateWorker.perform_in(10.minutes)
    end
  end

  desc "Run data updates"
  task run: :environment do
    DataUpdateWorker.new.perform
  end

  desc "Get data update status"
  task status: :environment do
    # rubocop:disable Style/FormatStringToken
    puts format(" %-9s  %-14s  %-40s", "Status", "ID", "Description")
    puts "-" * 80
    DataUpdateScript.find_each do |dus|
      id, file_name = dus.file_name.split("_", 2)
      puts format("%+10s  %+14s  %-40s", dus.status, id, file_name.tr("_", " "))
    end
    # rubocop:enable Style/FormatStringToken
  end
end
