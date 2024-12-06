require "rails/generators"

class JsRoutes::Generators::Webpacker < Rails::Generators::Base

  source_root File.expand_path(__FILE__ + "/../../../templates")

  def create_webpack
    copy_file "initializer.rb", "config/initializers/js_routes.rb"
    copy_file "erb.js", "config/webpack/loaders/erb.js"
    copy_file "routes.js.erb", "#{Webpacker.config.source_path}/routes.js.erb"
    inject_into_file "config/webpack/environment.js", loader_content
    if path = application_js_path
      inject_into_file path, pack_content
    end
    command = Rails.root.join("./bin/yarn add rails-erb-loader")
    run command
  end

  protected

  def pack_content
    <<-JS
import * as Routes from 'routes.js.erb';
window.Routes = Routes;
    JS
  end

  def loader_content
    <<-JS
const erb = require('./loaders/erb')
environment.loaders.append('erb', erb)
    JS
  end
end
