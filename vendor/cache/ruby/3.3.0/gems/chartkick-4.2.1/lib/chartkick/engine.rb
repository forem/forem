module Chartkick
  class Engine < ::Rails::Engine
    # for assets

    # for importmap
    initializer "chartkick.importmap" do |app|
      if defined?(Importmap)
        app.config.assets.precompile << "chartkick.js"
        app.config.assets.precompile << "Chart.bundle.js"
      end
    end
  end
end
