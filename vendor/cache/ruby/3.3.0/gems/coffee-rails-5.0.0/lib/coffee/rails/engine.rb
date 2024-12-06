require 'rails/engine'
require 'rails/generators'
require 'coffee/rails/js_hook'

module Coffee
  module Rails
    class Engine < ::Rails::Engine
      config.app_generators.javascripts true
      config.app_generators.javascript_engine :coffee

      if config.respond_to?(:annotations)
        config.annotations.register_extensions("coffee") { |annotation| /#\s*(#{annotation}):?\s*(.*)$/ }
      end

      initializer 'override js_template hook' do |app|
        if app.config.generators.rails[:javascript_engine] == :coffee
          ::Rails::Generators::NamedBase.send :include, Coffee::Rails::JsHook
        end
      end
    end
  end
end
