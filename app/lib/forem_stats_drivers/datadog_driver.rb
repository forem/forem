module ForemStatsDrivers
  class DatadogDriver
    attr_reader :driver

    def initialize
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

      @driver = Datadog::Statsd.new
    end

    def increment(*args)
      @driver.increment(*args)
    end

    def count(*args)
      @driver.increment(*args)
    end

    def time(*args)
      @driver.time(*args)
    end

    def gauge(*args)
      @driver.gauge(*args)
    end
  end
end
