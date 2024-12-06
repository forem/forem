module PgHero
  module Methods
    module QueryStats
      def query_stats(historical: false, start_at: nil, end_at: nil, min_average_time: nil, min_calls: nil, **options)
        current_query_stats = historical && end_at && end_at < Time.now ? [] : current_query_stats(**options)
        historical_query_stats = historical && historical_query_stats_enabled? ? historical_query_stats(start_at: start_at, end_at: end_at, **options) : []

        query_stats = combine_query_stats((current_query_stats + historical_query_stats).group_by { |q| [q[:query_hash], q[:user]] })
        query_stats = combine_query_stats(query_stats.group_by { |q| [normalize_query(q[:query]), q[:user]] })

        # add percentages
        all_queries_total_minutes = [current_query_stats, historical_query_stats].sum { |s| (s.first || {})[:all_queries_total_minutes] || 0 }
        query_stats.each do |query|
          query[:average_time] = query[:total_minutes] * 1000 * 60 / query[:calls]
          query[:total_percent] = query[:total_minutes] * 100.0 / all_queries_total_minutes
        end

        sort = options[:sort] || "total_minutes"
        query_stats = query_stats.sort_by { |q| -q[sort.to_sym] }.first(100)
        if min_average_time
          query_stats.reject! { |q| q[:average_time] < min_average_time }
        end
        if min_calls
          query_stats.reject! { |q| q[:calls] < min_calls }
        end
        query_stats
      end

      def query_stats_available?
        select_one("SELECT COUNT(*) AS count FROM pg_available_extensions WHERE name = 'pg_stat_statements'") > 0
      end

      # only cache if true
      def query_stats_enabled?
        @query_stats_enabled ||= query_stats_readable?
      end

      def query_stats_extension_enabled?
        select_one("SELECT COUNT(*) AS count FROM pg_extension WHERE extname = 'pg_stat_statements'") > 0
      end

      def query_stats_readable?
        select_all("SELECT * FROM pg_stat_statements LIMIT 1")
        true
      rescue ActiveRecord::StatementInvalid
        false
      end

      def enable_query_stats
        execute("CREATE EXTENSION IF NOT EXISTS pg_stat_statements")
        true
      end

      def disable_query_stats
        execute("DROP EXTENSION IF EXISTS pg_stat_statements")
        true
      end

      def reset_query_stats(**options)
        raise PgHero::Error, "Use reset_instance_query_stats to pass database" if options.delete(:database)
        reset_instance_query_stats(**options, database: database_name)
      end

      # resets query stats for the entire instance
      # it's possible to reset stats for a specific
      # database, user or query hash in Postgres 12+
      def reset_instance_query_stats(database: nil, user: nil, query_hash: nil, raise_errors: false)
        if database || user || query_hash
          raise PgHero::Error, "Requires PostgreSQL 12+" if server_version_num < 120000

          if database
            database_id = execute("SELECT oid FROM pg_database WHERE datname = #{quote(database)}").first.try(:[], "oid")
            raise PgHero::Error, "Database not found: #{database}" unless database_id
          else
            database_id = 0
          end

          if user
            user_id = execute("SELECT usesysid FROM pg_user WHERE usename = #{quote(user)}").first.try(:[], "usesysid")
            raise PgHero::Error, "User not found: #{user}" unless user_id
          else
            user_id = 0
          end

          if query_hash
            query_id = query_hash.to_i
            # may not be needed
            # but not intuitive that all query hashes are reset with 0
            raise PgHero::Error, "Invalid query hash: #{query_hash}" if query_id == 0
          else
            query_id = 0
          end

          execute("SELECT pg_stat_statements_reset(#{quote(user_id.to_i)}, #{quote(database_id.to_i)}, #{quote(query_id.to_i)})")
        else
          execute("SELECT pg_stat_statements_reset()")
        end
        true
      rescue ActiveRecord::StatementInvalid => e
        raise e if raise_errors
        false
      end

      # https://stackoverflow.com/questions/20582500/how-to-check-if-a-table-exists-in-a-given-schema
      def historical_query_stats_enabled?
        # TODO use schema from config
        # make sure primary database is PostgreSQL first
        query_stats_table_exists? && capture_query_stats? && !missing_query_stats_columns.any?
      end

      def query_stats_table_exists?
        table_exists?("pghero_query_stats")
      end

      def missing_query_stats_columns
        %w(query_hash user) - PgHero::QueryStats.column_names
      end

      def supports_query_hash?
        server_version_num >= 90400
      end

      # resetting query stats will reset across the entire Postgres instance in Postgres < 12
      # this is problematic if multiple PgHero databases use the same Postgres instance
      #
      # to get around this, we capture queries for every Postgres database before we
      # reset query stats for the Postgres instance with the `capture_query_stats` option
      def capture_query_stats(raise_errors: false)
        return if config["capture_query_stats"] && config["capture_query_stats"] != true

        # get all databases that use same query stats and build mapping
        mapping = {id => database_name}
        PgHero.databases.select { |_, d| d.config["capture_query_stats"] == id }.each do |_, d|
          mapping[d.id] = d.database_name
        end

        now = Time.now

        query_stats = {}
        mapping.each do |database_id, database_name|
          query_stats[database_id] = query_stats(limit: 1000000, database: database_name)
        end

        query_stats = query_stats.select { |_, v| v.any? }

        # nothing to do
        return if query_stats.empty?

        # reset individual databases for Postgres 12+ instance
        if server_version_num >= 120000
          query_stats.each do |db_id, db_query_stats|
            if reset_instance_query_stats(database: mapping[db_id], raise_errors: raise_errors)
              insert_query_stats(db_id, db_query_stats, now)
            end
          end
        else
          if reset_instance_query_stats(raise_errors: raise_errors)
            query_stats.each do |db_id, db_query_stats|
              insert_query_stats(db_id, db_query_stats, now)
            end
          end
        end
      end

      def clean_query_stats(before: nil)
        before ||= 14.days.ago
        PgHero::QueryStats.where(database: id).where("captured_at < ?", before).delete_all
      end

      def slow_queries(query_stats: nil, **options)
        query_stats ||= self.query_stats(options)
        query_stats.select { |q| q[:calls].to_i >= slow_query_calls.to_i && q[:average_time].to_f >= slow_query_ms.to_f }
      end

      def query_hash_stats(query_hash, user: nil, current: false)
        if historical_query_stats_enabled? && supports_query_hash?
          start_at = 24.hours.ago
          stats = select_all_stats <<~SQL
            SELECT
              captured_at,
              total_time / 1000 / 60 AS total_minutes,
              (total_time / calls) AS average_time,
              calls,
              (SELECT regexp_matches(query, '.*/\\*(.+?)\\*/'))[1] AS origin
            FROM
              pghero_query_stats
            WHERE
              database = #{quote(id)}
              AND captured_at >= #{quote(start_at)}
              AND query_hash = #{quote(query_hash)}
              #{user ? "AND \"user\" = #{quote(user)}" : ""}
            ORDER BY
              1 ASC
          SQL
          if current
            captured_at = Time.current
            current_stats = current_query_stats(query_hash: query_hash, user: user, origin: true)
            current_stats.each do |r|
              r[:captured_at] = captured_at
            end
            stats += current_stats
          end
          stats
        else
          raise NotEnabled, "Query hash stats not enabled"
        end
      end

      private

      # http://www.craigkerstiens.com/2013/01/10/more-on-postgres-performance/
      def current_query_stats(limit: nil, sort: nil, database: nil, query_hash: nil, user: nil, origin: false)
        if query_stats_enabled?
          limit ||= 100
          sort ||= "total_minutes"
          total_time = server_version_num >= 130000 ? "(total_plan_time + total_exec_time)" : "total_time"
          query = <<~SQL
            WITH query_stats AS (
              SELECT
                LEFT(query, 10000) AS query,
                #{supports_query_hash? ? "queryid" : "md5(query)"} AS query_hash,
                rolname AS user,
                (#{total_time} / 1000 / 60) AS total_minutes,
                (#{total_time} / calls) AS average_time,
                calls
              FROM
                pg_stat_statements
              INNER JOIN
                pg_database ON pg_database.oid = pg_stat_statements.dbid
              INNER JOIN
                pg_roles ON pg_roles.oid = pg_stat_statements.userid
              WHERE
                calls > 0 AND
                pg_database.datname = #{database ? quote(database) : "current_database()"}
                #{query_hash ? "AND queryid = #{quote(query_hash)}" : nil}
                #{user ? "AND rolname = #{quote(user)}" : nil}
            )
            SELECT
              query,
              query AS explainable_query,
              #{origin ? "(SELECT regexp_matches(query, '.*/\\*(.+?)\\*/'))[1] AS origin," : nil}
              query_hash,
              query_stats.user,
              total_minutes,
              average_time,
              calls,
              total_minutes * 100.0 / (SELECT SUM(total_minutes) FROM query_stats) AS total_percent,
              (SELECT SUM(total_minutes) FROM query_stats) AS all_queries_total_minutes
            FROM
              query_stats
            ORDER BY
              #{quote_column_name(sort)} DESC
            LIMIT #{limit.to_i}
          SQL

          # we may be able to skip query_columns
          # in more recent versions of Postgres
          # as pg_stat_statements should be already normalized
          select_all(query, query_columns: [:query, :explainable_query])
        else
          raise NotEnabled, "Query stats not enabled"
        end
      end

      def historical_query_stats(sort: nil, start_at: nil, end_at: nil, query_hash: nil)
        if historical_query_stats_enabled?
          sort ||= "total_minutes"
          query = <<~SQL
            WITH query_stats AS (
              SELECT
                #{supports_query_hash? ? "query_hash" : "md5(query)"} AS query_hash,
                pghero_query_stats.user AS user,
                array_agg(LEFT(query, 10000) ORDER BY REPLACE(LEFT(query, 1000), '?', '!') COLLATE "C" ASC) AS query,
                (SUM(total_time) / 1000 / 60) AS total_minutes,
                (SUM(total_time) / SUM(calls)) AS average_time,
                SUM(calls) AS calls
              FROM
                pghero_query_stats
              WHERE
                database = #{quote(id)}
                #{supports_query_hash? ? "AND query_hash IS NOT NULL" : ""}
                #{start_at ? "AND captured_at >= #{quote(start_at)}" : ""}
                #{end_at ? "AND captured_at <= #{quote(end_at)}" : ""}
                #{query_hash ? "AND query_hash = #{quote(query_hash)}" : ""}
              GROUP BY
                1, 2
            )
            SELECT
              query_hash,
              query_stats.user,
              query[1] AS query,
              query[array_length(query, 1)] AS explainable_query,
              total_minutes,
              average_time,
              calls,
              total_minutes * 100.0 / (SELECT SUM(total_minutes) FROM query_stats) AS total_percent,
              (SELECT SUM(total_minutes) FROM query_stats) AS all_queries_total_minutes
            FROM
              query_stats
            ORDER BY
              #{quote_column_name(sort)} DESC
            LIMIT 100
          SQL

          # we can skip query_columns if all stored data is normalized
          # for now, assume it's not
          select_all_stats(query, query_columns: [:query, :explainable_query])
        else
          raise NotEnabled, "Historical query stats not enabled"
        end
      end

      def combine_query_stats(grouped_stats)
        query_stats = []
        grouped_stats.each do |_, stats2|
          value = {
            query: (stats2.find { |s| s[:query] } || {})[:query],
            user: (stats2.find { |s| s[:user] } || {})[:user],
            query_hash: (stats2.find { |s| s[:query_hash] } || {})[:query_hash],
            total_minutes: stats2.sum { |s| s[:total_minutes] },
            calls: stats2.sum { |s| s[:calls] }.to_i,
            all_queries_total_minutes: stats2.sum { |s| s[:all_queries_total_minutes] }
          }
          value[:total_percent] = value[:total_minutes] * 100.0 / value[:all_queries_total_minutes]
          value[:explainable_query] = stats2.map { |s| s[:explainable_query] }.select { |q| q && explainable?(q) }.first
          query_stats << value
        end
        query_stats
      end

      def explainable?(query)
        query =~ /select/i && (server_version_num >= 160000 || (!query.include?("?)") && !query.include?("= ?") && !query.include?("$1") && query !~ /limit \?/i))
      end

      # removes comments
      # combines ?, ?, ? => ?
      def normalize_query(query)
        squish(query.to_s.gsub(/\?(, ?\?)+/, "?").gsub(/\/\*.+?\*\//, ""))
      end

      def insert_query_stats(db_id, db_query_stats, now)
        values =
          db_query_stats.map do |qs|
            {
              database: db_id,
              query: qs[:query],
              total_time: qs[:total_minutes] * 60 * 1000,
              calls: qs[:calls],
              captured_at: now,
              query_hash: supports_query_hash? ? qs[:query_hash] : nil,
              user: qs[:user]
            }
          end
        PgHero::QueryStats.insert_all!(values)
      end
    end
  end
end
