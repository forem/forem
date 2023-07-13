module Middlewares
  class SetDevClientGeo
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)
      client_geo = request.params["client_geo"]

      env["HTTP_CLIENT_GEO"] = client_geo if client_geo

      @app.call(env)
    end
  end
end
