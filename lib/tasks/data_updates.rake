namespace :data_updates do
  desc "Enqueue Sidekiq worker to handle data updates"
  task enqueue_data_update_worker: :environment do
    if Rails.env.development?
      Rake::Task["data_updates:run"].execute
    else
      # @mstruve: Due to many folks already hosting their Forems on Heroku lets
      # set a friendly default for them. Ideally we get everyone to use
      # the ENV variable below but until we can do a hard cut over with
      # a version I think this is a good compromise
      default_delay = ENV["HEROKU_SLUG_COMMIT"].present? ? 10.minutes : 0

      # Use the env variable to delay running data update scripts if your
      # deploy strategy requires it
      DataUpdateWorker.perform_in(ENV["WORKERS_DATA_UPDATE_DELAY_SECONDS"] || default_delay)
    end
  end

  desc "Run data updates"
  task run: :environment do
    DataUpdateWorker.new.perform
  end

  desc "Get data update status"
  task status: :environment do
    # Disable ActiveRecord logging for this task.
    # See: https://github.com/forem/forem/pull/13653#discussion_r626278422
    ActiveRecord::Base.logger = nil
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
