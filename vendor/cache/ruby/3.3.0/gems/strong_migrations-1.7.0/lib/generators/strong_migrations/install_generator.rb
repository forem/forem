require "rails/generators"

module StrongMigrations
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.join(__dir__, "templates")

      def create_initializer
        template "initializer.rb", "config/initializers/strong_migrations.rb"
      end

      def start_after
        Time.now.utc.strftime("%Y%m%d%H%M%S")
      end

      def pgbouncer_message
        if postgresql?
          "\n# If you use PgBouncer in transaction mode, delete these lines and set timeouts on the database user"
        end
      end

      def target_version
        case adapter
        when /mysql/
          # could try to connect to database and check for MariaDB
          # but this should be fine
          '"8.0.12"'
        else
          "10"
        end
      end

      def adapter
        if ActiveRecord::VERSION::STRING.to_f >= 6.1
          ActiveRecord::Base.connection_db_config.adapter.to_s
        else
          ActiveRecord::Base.connection_config[:adapter].to_s
        end
      end

      def postgresql?
        adapter =~ /postg/
      end
    end
  end
end
