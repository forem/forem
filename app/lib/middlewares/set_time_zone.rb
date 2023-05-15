module Middlewares
  class SetTimeZone
    def initialize(app)
      @app = app
    end

    def call(env)
      Time.zone = "Europe/Kiev"

      @app.call(env)
    end
  end
end
