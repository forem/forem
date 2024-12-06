require 'rails/generators/active_record'

class CounterCultureGenerator < ActiveRecord::Generators::Base

  desc "Create a migration that adds counter-cache columns to a model"

  argument :counter_cache_columns, :required => true, :type => :array,
    :desc => "The names of the counter cache columns to add",
    :banner => "counter_cache_one counter_cache_two counter_cache_three ..."

  source_root File.expand_path("../templates", __FILE__)

  def generate_migration
    migration_template "counter_culture_migration.rb.erb", "db/migrate/#{migration_file_name}", migration_version: migration_version
  end

  def migration_name
    "add_#{counter_cache_columns.join("_")}_to_#{name.underscore.pluralize}"
  end

  def migration_file_name
    "#{migration_name}.rb"
  end

  def migration_class_name
    migration_name.camelize
  end

  def migration_version
    if Gem::Version.new(Rails.version) >= Gem::Version.new('5.0.0')
      "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
    end
  end

end
