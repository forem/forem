# NOTE: this middleware is only for test mode
class TimeZoneSetter
  def initialize(app)
    @app = app
  end

  def call(env)
    Time.zone = ActiveSupport::TimeZone.new(ENV["TZ"]) if ENV["TZ"]

    @app.call(env)
  end
end
