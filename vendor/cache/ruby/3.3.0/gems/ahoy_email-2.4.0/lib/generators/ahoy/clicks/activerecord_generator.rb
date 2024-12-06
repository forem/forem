require "rails/generators/active_record"

module Ahoy
  module Generators
    module Clicks
      class ActiverecordGenerator < Rails::Generators::Base
        include ActiveRecord::Generators::Migration
        source_root File.join(__dir__, "templates")

        def copy_migration
          migration_template "migration.rb", "db/migrate/create_ahoy_clicks.rb", migration_version: migration_version
        end

        def migration_version
          "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
        end
      end
    end
  end
end
