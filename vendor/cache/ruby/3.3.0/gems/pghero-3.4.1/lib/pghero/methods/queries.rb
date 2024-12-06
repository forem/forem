module PgHero
  module Methods
    module Queries
      def running_queries(min_duration: nil, all: false)
        query = <<~SQL
          SELECT
            pid,
            state,
            application_name AS source,
            age(NOW(), COALESCE(query_start, xact_start)) AS duration,
            #{server_version_num >= 90600 ? "(wait_event IS NOT NULL) AS waiting" : "waiting"},
            query,
            COALESCE(query_start, xact_start) AS started_at,
            EXTRACT(EPOCH FROM NOW() - COALESCE(query_start, xact_start)) * 1000.0 AS duration_ms,
            usename AS user,
            #{server_version_num >= 100000 ? "backend_type" : "NULL AS backend_type"}
          FROM
            pg_stat_activity
          WHERE
            state <> 'idle'
            AND pid <> pg_backend_pid()
            AND datname = current_database()
            #{min_duration ? "AND NOW() - COALESCE(query_start, xact_start) > interval '#{min_duration.to_i} seconds'" : nil}
            #{all ? nil : "AND query <> '<insufficient privilege>'"}
          ORDER BY
            COALESCE(query_start, xact_start) DESC
        SQL

        select_all(query, query_columns: [:query])
      end

      def long_running_queries
        running_queries(min_duration: long_running_query_sec)
      end

      # from https://wiki.postgresql.org/wiki/Lock_Monitoring
      # and https://big-elephants.com/2013-09/exploring-query-locks-in-postgres/
      def blocked_queries
        query = <<~SQL
          SELECT
            COALESCE(blockingl.relation::regclass::text,blockingl.locktype) as locked_item,
            blockeda.pid AS blocked_pid,
            blockeda.usename AS blocked_user,
            blockeda.query as blocked_query,
            age(now(), blockeda.query_start) AS blocked_duration,
            blockedl.mode as blocked_mode,
            blockinga.pid AS blocking_pid,
            blockinga.usename AS blocking_user,
            blockinga.state AS state_of_blocking_process,
            blockinga.query AS current_or_recent_query_in_blocking_process,
            age(now(), blockinga.query_start) AS blocking_duration,
            blockingl.mode as blocking_mode
          FROM
            pg_catalog.pg_locks blockedl
          LEFT JOIN
            pg_stat_activity blockeda ON blockedl.pid = blockeda.pid
          LEFT JOIN
            pg_catalog.pg_locks blockingl ON blockedl.pid != blockingl.pid AND (
              blockingl.transactionid = blockedl.transactionid
              OR (blockingl.relation = blockedl.relation AND blockingl.locktype = blockedl.locktype)
            )
          LEFT JOIN
            pg_stat_activity blockinga ON blockingl.pid = blockinga.pid AND blockinga.datid = blockeda.datid
          WHERE
            NOT blockedl.granted
            AND blockeda.query <> '<insufficient privilege>'
            AND blockeda.datname = current_database()
          ORDER BY
            blocked_duration DESC
        SQL

        select_all(query, query_columns: [:blocked_query, :current_or_recent_query_in_blocking_process])
      end
    end
  end
end
