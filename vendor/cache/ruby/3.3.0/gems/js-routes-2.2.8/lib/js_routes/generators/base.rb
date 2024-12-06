
require "rails/generators"

class JsRoutes::Generators::Base < Rails::Generators::Base

  protected

  def application_js_path
    [
      "app/javascript/packs/application.js",
      "app/javascript/controllers/application.js",
    ].find do |path|
      File.exist?(Rails.root.join(path))
    end
  end
end
