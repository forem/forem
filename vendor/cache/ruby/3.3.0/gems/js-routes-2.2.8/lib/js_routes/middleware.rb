module JsRoutes
  # A Rack middleware that automatically updates routes file
  # whenever routes.rb is modified
  #
  # Inspired by
  # https://github.com/fnando/i18n-js/blob/main/lib/i18n/js/middleware.rb
  class Middleware
    def initialize(app)
      @app = app
      @routes_file = Rails.root.join("config/routes.rb")
      @mtime = nil
    end

    def call(env)
      update_js_routes
      @app.call(env)
    end

    protected

    def update_js_routes
      new_mtime = routes_mtime
      unless new_mtime == @mtime
        regenerate
        @mtime = new_mtime
      end
    end

    def regenerate
      JsRoutes.generate!
      JsRoutes.definitions!
    end

    def routes_mtime
      File.mtime(@routes_file)
    rescue Errno::ENOENT
      nil
    end
  end
end
