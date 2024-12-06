require "rails/generators"
require "rails/generators/active_record"

module Pghero
  module Generators
    class SpaceStatsGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration
      source_root File.join(__dir__, "templates")

      def copy_migration
        migration_template "space_stats.rb", "db/migrate/create_pghero_space_stats.rb", migration_version: migration_version
      end

      def migration_version
        "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
      end
    end
  end
end
