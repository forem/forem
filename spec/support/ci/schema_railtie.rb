if ENV["CI"] && !defined?(CiSchemaRailtie)
  ENV["RAILS_ENV"] = "test"
  require "rails"

  class CiSchemaRailtie < Rails::Railtie
    config.after_initialize do
      ActiveRecord::Base.with_connection do |conn|
        next if conn.data_source_exists?("schema_migrations")

        ActiveRecord::Migration.suppress_messages do
          ActiveRecord::Tasks::DatabaseTasks.load_schema_current(:ruby, Rails.root.join("db/schema.rb"))
        end
      end
    end
  end
end
