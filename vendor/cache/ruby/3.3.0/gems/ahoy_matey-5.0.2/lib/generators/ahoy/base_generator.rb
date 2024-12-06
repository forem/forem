require "rails/generators"

module Ahoy
  module Generators
    class BaseGenerator < Rails::Generators::Base
      source_root File.join(__dir__, "templates")

      def copy_templates
        template "base_store_initializer.rb", "config/initializers/ahoy.rb"
      end
    end
  end
end
