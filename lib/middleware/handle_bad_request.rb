module Middleware
  class HandleBadRequest
    def initialize(app)
      @app = app
    end

    def call(env)
      @app.call(env)
    rescue  ActionController::BadRequest => e
      [400, { "Content-Type" => "text/plain" }, ["Bad Request: #{e.message}"]]
    end
  end
end
