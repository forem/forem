module StrongMigrations
  module Adapters
    class AbstractAdapter
      def initialize(checker)
        @checker = checker
      end

      def name
        "Unknown"
      end

      def min_version
      end

      def set_statement_timeout(timeout)
        raise StrongMigrations::Error, "Statement timeout not supported for this database"
      end

      def set_lock_timeout(timeout)
        raise StrongMigrations::Error, "Lock timeout not supported for this database"
      end

      def check_lock_timeout(limit)
        # do nothing
      end

      def add_column_default_safe?
        false
      end

      def change_type_safe?(table, column, type, options, existing_column, existing_type)
        false
      end

      def rewrite_blocks
        "reads and writes"
      end

      private

      def connection
        @checker.send(:connection)
      end

      def select_all(statement)
        connection.select_all(statement)
      end

      def target_version(target_version)
        target_version ||= StrongMigrations.target_version
        version =
          if target_version && StrongMigrations.developer_env?
            if target_version.is_a?(Hash)
              # Active Record 6.0 supports multiple databases
              # but connection.pool.spec.name always returns "primary"
              # in migrations with rails db:migrate
              if ActiveRecord::VERSION::STRING.to_f < 6.1
                # error class is not shown in db:migrate output so ensure message is descriptive
                raise StrongMigrations::Error, "StrongMigrations.target_version does not support multiple databases for Active Record < 6.1"
              end

              db_config_name = connection.pool.db_config.name
              target_version.stringify_keys.fetch(db_config_name) do
                # error class is not shown in db:migrate output so ensure message is descriptive
                raise StrongMigrations::Error, "StrongMigrations.target_version is not configured for :#{db_config_name} database"
              end.to_s
            else
              target_version.to_s
            end
          else
            yield
          end
        Gem::Version.new(version)
      end
    end
  end
end
