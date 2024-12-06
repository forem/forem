require "rails/generators"
require "rails/generators/active_record"

module Ahoy
  module Generators
    class ActiverecordGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration
      source_root File.join(__dir__, "templates")

      class_option :database, type: :string, aliases: "-d"

      def copy_templates
        template "database_store_initializer.rb", "config/initializers/ahoy.rb"
        template "active_record_visit_model.rb", "app/models/ahoy/visit.rb"
        template "active_record_event_model.rb", "app/models/ahoy/event.rb"
        migration_template "active_record_migration.rb", "db/migrate/create_ahoy_visits_and_events.rb", migration_version: migration_version
        puts "\nAlmost set! Last, run:\n\n    rails db:migrate"
      end

      def properties_type
        case adapter
        when /postg/i # postgres, postgis
          "jsonb"
        when /mysql/i
          "json"
        else
          "text"
        end
      end

      # requires database connection to check for MariaDB
      def serialize_properties?
        properties_type == "text" || (properties_type == "json" && ActiveRecord::Base.connection.try(:mariadb?))
      end

      def serialize_options
        ActiveRecord::VERSION::STRING.to_f >= 7.1 ? "coder: JSON" : "JSON"
      end

      # use connection_config instead of connection.adapter
      # so database connection isn't needed
      def adapter
        if ActiveRecord::VERSION::STRING.to_f >= 6.1
          ActiveRecord::Base.connection_db_config.adapter.to_s
        else
          ActiveRecord::Base.connection_config[:adapter].to_s
        end
      end

      def migration_version
        "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
      end

      def primary_key_type
        ", id: :#{key_type}" if key_type
      end

      def foreign_key_type
        ", type: :#{key_type}" if key_type
      end

      def key_type
        Rails.configuration.generators.options.dig(:active_record, :primary_key_type)
      end
    end
  end
end
