require "rails/generators/active_record"

module FieldTest
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration
      source_root File.join(__dir__, "templates")

      def copy_migration
        migration_template "memberships.rb", "db/migrate/create_field_test_memberships.rb", migration_version: migration_version
      end

      def copy_config
        template "config.yml", "config/field_test.yml"
      end

      def migration_version
        "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
      end
    end
  end
end
