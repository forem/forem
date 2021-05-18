if Rails.env.test?
  # NOTE: this middleware is only for test mode
  class SetTimeZone
    def initialize(app)
      @app = app
    end

    def call(env)
      Time.zone = ActiveSupport::TimeZone.new(ENV["TZ"]) if ENV["TZ"]

      @app.call(env)
    end
  end

  # Include middleware to ensure timezone for browser requests for Capybara specs
  # matches the random zonebie timezone set at the beginning of our spec run
  Rails.configuration.middleware.use SetTimeZone
end
