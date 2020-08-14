Rails.application.config.to_prepare do
  Dir.glob(Rails.root.join("lib/sidekiq/*.rb")).sort.each do |filename|
    require_dependency filename
  end
end

Sidekiq.configure_server do |config|
  schedule_file = "config/schedule.yml"

  if File.exist?(schedule_file)
    Sidekiq::Cron::Job.load_from_hash(YAML.load_file(schedule_file))
  end

  sidekiq_url = ApplicationConfig["REDIS_SIDEKIQ_URL"] || ApplicationConfig["REDIS_URL"]
  # On Heroku this configuration is overridden and Sidekiq will point at the redis
  # instance given by the ENV variable REDIS_PROVIDER
  config.redis = { url: sidekiq_url }

  config.server_middleware do |chain|
    chain.add Sidekiq::HoneycombMiddleware
  end

  # This allows us to define custom logic to handle when a worker has exhausted all
  # of it's retries. For more details: https://github.com/mperham/sidekiq/wiki/Error-Handling#death-notification
  config.death_handlers << lambda do |job, _ex|
    Sidekiq::WorkerRetriesExhaustedReporter.report_final_failure(job)
  end
end
