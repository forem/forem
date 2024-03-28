require "sidekiq/honeycomb_middleware"
require "sidekiq/worker_retries_exhausted_reporter"

module Sidekiq
  module Cron
    class Job
      def not_past_scheduled_time?(current_time)
        last_cron_time = parsed_cron.previous_time(current_time).utc
        # @mstruve/@sre: method monkey patched to increase time we look back for
        # unrun scheduled jobs from 60 to 120. Heroku takes 60 seconds to restart
        # sidekiq workers, we need to ensure any job scheduled during that down time
        # is run once Sidekiq boots back up
        # https://github.com/ondrejbartas/sidekiq-cron/blob/074a87546f16122c1f508bb2805b9951588f2510/lib/sidekiq/cron/job.rb#L593
        return false if (current_time.to_i - last_cron_time.to_i) > ENV.fetch("CRON_LOOKBACK_TIME", 60).to_i

        true
      end
    end
  end
end

Sidekiq.configure_server do |config|
  # @mstruve/@sre: sidekiq-cron still uses the removed poll_interval
  # to determine how often to poll for jobs so we should manually set it
  # https://github.com/ondrejbartas/sidekiq-cron/issues/254
  # Sidekiq default is 5, we don't need it quite that often but would like it more than
  # every 30 seconds which the gem defaults to
  config[:poll_interval] = 10

  sidekiq_url = ApplicationConfig["REDIS_SIDEKIQ_URL"] || ApplicationConfig["REDIS_URL"]
  # On Heroku this configuration is overridden and Sidekiq will point at the redis
  # instance given by the ENV variable REDIS_PROVIDER
  config.redis = { url: sidekiq_url }

  config.server_middleware do |chain|
    chain.add Sidekiq::HoneycombMiddleware
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  SidekiqUniqueJobs::Server.configure(config)

  # This allows us to define custom logic to handle when a worker has exhausted all
  # of it's retries. For more details: https://github.com/mperham/sidekiq/wiki/Error-Handling#death-notification
  config.death_handlers << lambda do |job, _ex|
    Sidekiq::WorkerRetriesExhaustedReporter.report_final_failure(job)
  end
end

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end

Sidekiq.strict_args! unless Rails.env.production?
