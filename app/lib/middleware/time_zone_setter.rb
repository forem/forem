module Middleware
  class TimeZoneSetter
    def initialize(app)
      @app = app
    end

    def call(env)
      Time.zone = ActiveSupport::TimeZone.new(ENV["TZ"])

      @app.call(env)
    end
  end
end
