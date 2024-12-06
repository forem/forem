module PgHero
  module Methods
    module Connections
      def connections
        if server_version_num >= 90500
          select_all <<~SQL
            SELECT
              pg_stat_activity.pid,
              datname AS database,
              usename AS user,
              application_name AS source,
              client_addr AS ip,
              state,
              ssl
            FROM
              pg_stat_activity
            LEFT JOIN
              pg_stat_ssl ON pg_stat_activity.pid = pg_stat_ssl.pid
            ORDER BY
              pg_stat_activity.pid
          SQL
        else
          select_all <<~SQL
            SELECT
              pid,
              datname AS database,
              usename AS user,
              application_name AS source,
              client_addr AS ip,
              state
            FROM
              pg_stat_activity
            ORDER BY
              pid
          SQL
        end
      end

      def total_connections
        select_one("SELECT COUNT(*) FROM pg_stat_activity")
      end

      def connection_states
        states = select_all <<~SQL
          SELECT
            state,
            COUNT(*) AS connections
          FROM
            pg_stat_activity
          GROUP BY
            1
          ORDER BY
            2 DESC, 1
        SQL

        states.to_h { |s| [s[:state], s[:connections]] }
      end

      def connection_sources
        select_all <<~SQL
          SELECT
            datname AS database,
            usename AS user,
            application_name AS source,
            client_addr AS ip,
            COUNT(*) AS total_connections
          FROM
            pg_stat_activity
          GROUP BY
            1, 2, 3, 4
          ORDER BY
            5 DESC, 1, 2, 3, 4
        SQL
      end
    end
  end
end
