# Based on https://github.com/huacnlee/rails-settings-cached/blob/main/lib/generators/settings/install_generator.rb

require "rails/generators"
require "rails/generators/migration"

class SettingsModelGenerator < Rails::Generators::NamedBase
  include Rails::Generators::Migration

  argument :name, type: :string, default: "setting"

  source_root File.expand_path("templates", __dir__)

  @migrations = false

  def self.next_migration_number(dirname) # :nodoc:
    if ActiveRecord::Base.timestamped_migrations
      if @migrations
        (current_migration_number(dirname) + 1)
      else
        @migrations = true
        Time.now.utc.strftime("%Y%m%d%H%M%S")
      end
    else
      format "%.3<number>d", number: current_migration_number(dirname) + 1
    end
  end

  def create_migration_file
    migration_template(
      "migration.erb",
      "db/migrate/create_#{table_name}.rb",
      migration_version: migration_version,
      table_name: table_name,
    )
  end

  def create_model
    template(
      "model.erb",
      File.join("app/models/settings", class_path, "#{file_name}.rb"),
    )
  end

  def rails_version_major
    Rails::VERSION::MAJOR
  end

  def rails_version_minor
    Rails::VERSION::MINOR
  end

  def migration_version
    "[#{rails_version_major}.#{rails_version_minor}]" if rails_version_major >= 5
  end

  def table_name
    @table_name ||= "settings_#{class_name.underscore.pluralize}"
  end
end
