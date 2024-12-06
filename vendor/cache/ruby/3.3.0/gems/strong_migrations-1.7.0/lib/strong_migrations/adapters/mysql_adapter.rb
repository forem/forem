# note: MariaDB inherits from this adapter
# when making changes, be sure to see how it affects it
module StrongMigrations
  module Adapters
    class MySQLAdapter < AbstractAdapter
      def name
        "MySQL"
      end

      def min_version
        "5.7"
      end

      def server_version
        @server_version ||= begin
          target_version(StrongMigrations.target_mysql_version) do
            select_all("SELECT VERSION()").first["VERSION()"].split("-").first
          end
        end
      end

      def set_statement_timeout(timeout)
        # use ceil to prevent no timeout for values under 1 ms
        select_all("SET max_execution_time = #{connection.quote((timeout.to_f * 1000).ceil)}")
      end

      def set_lock_timeout(timeout)
        # fix deprecation warning with Active Record 7.1
        timeout = timeout.value if timeout.is_a?(ActiveSupport::Duration)

        select_all("SET lock_wait_timeout = #{connection.quote(timeout)}")
      end

      def check_lock_timeout(limit)
        lock_timeout = connection.select_all("SHOW VARIABLES LIKE 'lock_wait_timeout'").first["Value"]
        # lock timeout is an integer
        if lock_timeout.to_i > limit
          warn "[strong_migrations] DANGER: Lock timeout is longer than #{limit} seconds: #{lock_timeout}"
        end
      end

      def analyze_table(table)
        connection.execute "ANALYZE TABLE #{connection.quote_table_name(table.to_s)}"
      end

      def add_column_default_safe?
        server_version >= Gem::Version.new("8.0.12")
      end

      def change_type_safe?(table, column, type, options, existing_column, existing_type)
        safe = false

        case type.to_s
        when "string"
          limit = options[:limit] || 255
          if ["varchar"].include?(existing_type) && limit >= existing_column.limit
            # https://dev.mysql.com/doc/refman/5.7/en/innodb-online-ddl-operations.html
            # https://mariadb.com/kb/en/innodb-online-ddl-operations-with-the-instant-alter-algorithm/#changing-the-data-type-of-a-column
            # increased limit, but doesn't change number of length bytes
            # 1-255 = 1 byte, 256-65532 = 2 bytes, 65533+ = too big for varchar

            # account for charset
            # https://dev.mysql.com/doc/refman/8.0/en/charset-mysql.html
            # https://mariadb.com/kb/en/supported-character-sets-and-collations/
            sql = <<~SQL
              SELECT cs.MAXLEN
              FROM INFORMATION_SCHEMA.CHARACTER_SETS cs
              INNER JOIN INFORMATION_SCHEMA.COLLATIONS c ON c.CHARACTER_SET_NAME = cs.CHARACTER_SET_NAME
              INNER JOIN INFORMATION_SCHEMA.TABLES t ON t.TABLE_COLLATION = c.COLLATION_NAME
              WHERE t.TABLE_SCHEMA = database() AND t.TABLE_NAME = #{connection.quote(table)}
            SQL
            row = connection.select_all(sql).first
            if row
              threshold = 255 / row["MAXLEN"]
              safe = limit <= threshold || existing_column.limit > threshold
            else
              warn "[strong_migrations] Could not determine charset"
            end
          end
        end

        safe
      end

      def strict_mode?
        sql_modes = sql_modes()
        sql_modes.include?("STRICT_ALL_TABLES") || sql_modes.include?("STRICT_TRANS_TABLES")
      end

      def rewrite_blocks
        "writes"
      end

      private

      # do not memoize
      # want latest value
      def sql_modes
        if StrongMigrations.target_sql_mode && StrongMigrations.developer_env?
          StrongMigrations.target_sql_mode.split(",")
        else
          select_all("SELECT @@SESSION.sql_mode").first["@@SESSION.sql_mode"].split(",")
        end
      end
    end
  end
end
