require "rails/generators"

module Ahoy
  module Generators
    class MongoidGenerator < Rails::Generators::Base
      source_root File.join(__dir__, "templates")

      def copy_templates
        template "database_store_initializer.rb", "config/initializers/ahoy.rb"
        template "mongoid_visit_model.rb", "app/models/ahoy/visit.rb"
        template "mongoid_event_model.rb", "app/models/ahoy/event.rb"
        puts "\nAlmost set! Last, run:\n\n    rake db:mongoid:create_indexes"
      end
    end
  end
end
