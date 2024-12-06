require "rails/generators"

module Hypershield
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.join(__dir__, "templates")

      def create_initializer
        template "initializer.rb", "config/initializers/hypershield.rb"
      end
    end
  end
end
