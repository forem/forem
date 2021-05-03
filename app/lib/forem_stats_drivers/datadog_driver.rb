require "httpclient"

module ForemStatsDrivers
  class DatadogDriver
    include ActsAsForemStatsDriver
    setup_driver do
      Datadog.configure do |c|
        c.tracer env: Rails.env
        c.tracer enabled: ENV["DD_API_KEY"].present?
        c.tracer partial_flush: true
        c.tracer priority_sampling: true
        c.use :sidekiq
        c.use :redis, service_name: "redis", describes: { url: ENV["REDIS_URL"] }
        c.use :redis, service_name: "redis-sessions", describes: { url: ENV["REDIS_SESSIONS_URL"] }
        c.use :redis, service_name: "redis-sidekiq", describes: { url: ENV["REDIS_SIDEKIQ_URL"] }
        c.use :redis, service_name: "redis-rpush", describes: { url: ENV["REDIS_RPUSH_URL"] }
        c.use :rails
        c.use :http, split_by_domain: false
        c.use :faraday, split_by_domain: true
        c.use :excon, split_by_domain: true
        c.use :httpclient, split_by_domain: false
        c.use :httprb, split_by_domain: true
        c.use :rest_client
        c.use :concurrent_ruby
      end
      Datadog::Statsd.new
    end
  end
end
