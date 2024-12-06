module StrongMigrations
  module Adapters
    class PostgreSQLAdapter < AbstractAdapter
      def name
        "PostgreSQL"
      end

      def min_version
        "10"
      end

      def server_version
        @version ||= begin
          target_version(StrongMigrations.target_postgresql_version) do
            version = select_all("SHOW server_version_num").first["server_version_num"].to_i
            # major and minor version
            "#{version / 10000}.#{(version % 10000)}"
          end
        end
      end

      def set_statement_timeout(timeout)
        set_timeout("statement_timeout", timeout)
      end

      def set_lock_timeout(timeout)
        set_timeout("lock_timeout", timeout)
      end

      def check_lock_timeout(limit)
        lock_timeout = connection.select_all("SHOW lock_timeout").first["lock_timeout"]
        lock_timeout_sec = timeout_to_sec(lock_timeout)
        if lock_timeout_sec == 0
          warn "[strong_migrations] DANGER: No lock timeout set"
        elsif lock_timeout_sec > limit
          warn "[strong_migrations] DANGER: Lock timeout is longer than #{limit} seconds: #{lock_timeout}"
        end
      end

      def analyze_table(table)
        connection.execute "ANALYZE #{connection.quote_table_name(table.to_s)}"
      end

      def add_column_default_safe?
        server_version >= Gem::Version.new("11")
      end

      def change_type_safe?(table, column, type, options, existing_column, existing_type)
        safe = false

        case type.to_s
        when "string"
          # safe to increase limit or remove it
          # not safe to decrease limit or add a limit
          case existing_type
          when "character varying"
            safe = !options[:limit] || (existing_column.limit && options[:limit] >= existing_column.limit)
          when "text"
            safe = !options[:limit]
          when "citext"
            safe = !options[:limit] && !indexed?(table, column)
          end
        when "text"
          # safe to change varchar to text (and text to text)
          safe =
            ["character varying", "text"].include?(existing_type) ||
            (existing_type == "citext" && !indexed?(table, column))
        when "citext"
          safe = ["character varying", "text"].include?(existing_type) && !indexed?(table, column)
        when "varbit"
          # increasing length limit or removing the limit is safe
          # but there doesn't seem to be a way to set/modify it
          # https://wiki.postgresql.org/wiki/What%27s_new_in_PostgreSQL_9.2#Reduce_ALTER_TABLE_rewrites
        when "numeric", "decimal"
          # numeric and decimal are equivalent and can be used interchangeably
          safe = ["numeric", "decimal"].include?(existing_type) &&
            (
              (
                # unconstrained
                !options[:precision] && !options[:scale]
              ) || (
                # increased precision, same scale
                options[:precision] && existing_column.precision &&
                options[:precision] >= existing_column.precision &&
                options[:scale] == existing_column.scale
              )
            )
        when "datetime", "timestamp", "timestamptz"
          # precision for datetime
          # limit for timestamp, timestamptz
          precision = (type.to_s == "datetime" ? options[:precision] : options[:limit]) || 6
          existing_precision = existing_column.limit || existing_column.precision || 6

          type_map = {
            "timestamp" => "timestamp without time zone",
            "timestamptz" => "timestamp with time zone"
          }
          maybe_safe = type_map.values.include?(existing_type) && precision >= existing_precision

          if maybe_safe
            new_type = type.to_s == "datetime" ? datetime_type : type.to_s

            # resolve with fallback
            new_type = type_map[new_type] || new_type

            safe = new_type == existing_type || (server_version >= Gem::Version.new("12") && time_zone == "UTC")
          end
        when "time"
          precision = options[:precision] || options[:limit] || 6
          existing_precision = existing_column.precision || existing_column.limit || 6

          safe = existing_type == "time without time zone" && precision >= existing_precision
        when "timetz"
          # increasing precision is safe
          # but there doesn't seem to be a way to set/modify it
        when "interval"
          # https://wiki.postgresql.org/wiki/What%27s_new_in_PostgreSQL_9.2#Reduce_ALTER_TABLE_rewrites
          # Active Record uses precision before limit
          precision = options[:precision] || options[:limit] || 6
          existing_precision = existing_column.precision || existing_column.limit || 6

          safe = existing_type == "interval" && precision >= existing_precision
        when "inet"
          safe = existing_type == "cidr"
        end

        safe
      end

      def constraints(table_name)
        query = <<~SQL
          SELECT
            conname AS name,
            pg_get_constraintdef(oid) AS def
          FROM
            pg_constraint
          WHERE
            contype = 'c' AND
            convalidated AND
            conrelid = #{connection.quote(connection.quote_table_name(table_name))}::regclass
        SQL
        select_all(query.squish).to_a
      end

      def writes_blocked?
        query = <<~SQL
          SELECT
            relation::regclass::text
          FROM
            pg_locks
          WHERE
            mode IN ('ShareRowExclusiveLock', 'AccessExclusiveLock') AND
            pid = pg_backend_pid()
        SQL
        select_all(query.squish).any?
      end

      # only check in non-developer environments (where actual server version is used)
      def index_corruption?
        server_version >= Gem::Version.new("14.0") &&
          server_version < Gem::Version.new("14.4") &&
          !StrongMigrations.developer_env?
      end

      # default to true if unsure
      def default_volatile?(default)
        name = default.to_s.delete_suffix("()")
        rows = select_all("SELECT provolatile FROM pg_proc WHERE proname = #{connection.quote(name)}").to_a
        rows.empty? || rows.any? { |r| r["provolatile"] == "v" }
      end

      private

      def set_timeout(setting, timeout)
        # use ceil to prevent no timeout for values under 1 ms
        timeout = (timeout.to_f * 1000).ceil unless timeout.is_a?(String)

        select_all("SET #{setting} TO #{connection.quote(timeout)}")
      end

      # units: https://www.postgresql.org/docs/current/config-setting.html
      def timeout_to_sec(timeout)
        units = {
          "us" => 0.001,
          "ms" => 1,
          "s" => 1000,
          "min" => 1000 * 60,
          "h" => 1000 * 60 * 60,
          "d" => 1000 * 60 * 60 * 24
        }
        timeout_ms = timeout.to_i
        units.each do |k, v|
          if timeout.end_with?(k)
            timeout_ms *= v
            break
          end
        end
        timeout_ms / 1000.0
      end

      # columns is array for column index and string for expression index
      # the current approach can yield false positives for expression indexes
      # but prefer to keep it simple for now
      def indexed?(table, column)
        connection.indexes(table).any? { |i| i.columns.include?(column.to_s) }
      end

      def datetime_type
        key =
          if ActiveRecord::VERSION::MAJOR >= 7
            # https://github.com/rails/rails/pull/41084
            # no need to support custom datetime_types
            connection.class.datetime_type
          else
            # https://github.com/rails/rails/issues/21126#issuecomment-327895275
            :datetime
          end

        # could be timestamp, timestamp without time zone, timestamp with time zone, etc
        connection.class.const_get(:NATIVE_DATABASE_TYPES).fetch(key).fetch(:name)
      end

      # do not memoize
      # want latest value
      def time_zone
        select_all("SHOW timezone").first["TimeZone"]
      end
    end
  end
end
