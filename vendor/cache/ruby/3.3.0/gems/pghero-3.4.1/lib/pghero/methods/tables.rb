module PgHero
  module Methods
    module Tables
      def table_hit_rate
        select_one <<~SQL
          SELECT
            sum(heap_blks_hit) / nullif(sum(heap_blks_hit) + sum(heap_blks_read), 0) AS rate
          FROM
            pg_statio_user_tables
        SQL
      end

      def table_caching
        select_all <<~SQL
          SELECT
            schemaname AS schema,
            relname AS table,
            CASE WHEN heap_blks_hit + heap_blks_read = 0 THEN
              0
            ELSE
              ROUND(1.0 * heap_blks_hit / (heap_blks_hit + heap_blks_read), 2)
            END AS hit_rate
          FROM
            pg_statio_user_tables
          ORDER BY
            2 DESC, 1
        SQL
      end

      def unused_tables
        select_all <<~SQL
          SELECT
            schemaname AS schema,
            relname AS table,
            n_live_tup AS estimated_rows
          FROM
            pg_stat_user_tables
          WHERE
            idx_scan = 0
          ORDER BY
            n_live_tup DESC,
            relname ASC
         SQL
      end

      def table_stats(schema: nil, table: nil)
        select_all <<~SQL
          SELECT
            nspname AS schema,
            relname AS table,
            reltuples::bigint AS estimated_rows,
            pg_total_relation_size(pg_class.oid) AS size_bytes
          FROM
            pg_class
          INNER JOIN
            pg_namespace ON pg_namespace.oid = pg_class.relnamespace
          WHERE
            relkind = 'r'
            #{schema ? "AND nspname = #{quote(schema)}" : nil}
            #{table ? "AND relname IN (#{Array(table).map { |t| quote(t) }.join(", ")})" : nil}
          ORDER BY
            1, 2
        SQL
      end
    end
  end
end
