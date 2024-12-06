require "rails/generators"

module Ahoy
  module Generators
    module Clicks
      class MongoidGenerator < Rails::Generators::Base
        source_root File.join(__dir__, "templates")

        def copy_templates
          template "mongoid.rb", "app/models/ahoy/click.rb"
        end
      end
    end
  end
end
