# Monkey patch `stringify_keys` to make rack 2.1.1 compatible with Sidekiq UI Admin panel.
# Should be removed when 2.1.2 is released.
# https://github.com/rack/rack/pull/1428
module Rack
  module Session
    module Abstract
      class SessionHash
        private

        def stringify_keys(other)
          other.to_hash.transform_keys(&:to_s)
        end
      end
    end
  end
end

require Rails.root.join("lib/sidekiq/worker_retries_exhausted_reporter")

Sidekiq.configure_server do |config|
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
