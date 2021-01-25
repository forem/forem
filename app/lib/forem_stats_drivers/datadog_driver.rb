module ForemStatsDrivers
  class DatadogDriver
    include ActsAsForemStatsDriver
    setup_driver do
      Datadog.configure do |c|
        c.tracer env: Rails.env
        c.tracer enabled: ENV["DD_API_KEY"].present?
        c.tracer partial_flush: true
        c.tracer priority_sampling: true
        c.use :elasticsearch
        c.use :sidekiq
        c.use :redis
        c.use :rails
        c.use :http
      end
      Datadog::Statsd.new
    end
  end
end
