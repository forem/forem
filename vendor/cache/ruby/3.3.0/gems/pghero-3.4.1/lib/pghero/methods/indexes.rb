module PgHero
  module Methods
    module Indexes
      def index_hit_rate
        select_one <<~SQL
          SELECT
            (sum(idx_blks_hit)) / nullif(sum(idx_blks_hit + idx_blks_read), 0) AS rate
          FROM
            pg_statio_user_indexes
        SQL
      end

      def index_caching
        select_all <<~SQL
          SELECT
            schemaname AS schema,
            relname AS table,
            indexrelname AS index,
            CASE WHEN idx_blks_hit + idx_blks_read = 0 THEN
              0
            ELSE
              ROUND(1.0 * idx_blks_hit / (idx_blks_hit + idx_blks_read), 2)
            END AS hit_rate
          FROM
            pg_statio_user_indexes
          ORDER BY
            3 DESC, 1
        SQL
      end

      def index_usage
        select_all <<~SQL
          SELECT
            schemaname AS schema,
            relname AS table,
            CASE idx_scan
              WHEN 0 THEN 'Insufficient data'
              ELSE (100 * idx_scan / (seq_scan + idx_scan))::text
            END percent_of_times_index_used,
            n_live_tup AS estimated_rows
          FROM
            pg_stat_user_tables
          ORDER BY
            n_live_tup DESC,
            relname ASC
         SQL
      end

      def missing_indexes
        select_all <<~SQL
          SELECT
            schemaname AS schema,
            relname AS table,
            CASE idx_scan
              WHEN 0 THEN 'Insufficient data'
              ELSE (100 * idx_scan / (seq_scan + idx_scan))::text
            END percent_of_times_index_used,
            n_live_tup AS estimated_rows
          FROM
            pg_stat_user_tables
          WHERE
            idx_scan > 0
            AND (100 * idx_scan / (seq_scan + idx_scan)) < 95
            AND n_live_tup >= 10000
          ORDER BY
            n_live_tup DESC,
            relname ASC
         SQL
      end

      def unused_indexes(max_scans: 50, across: [])
        result = select_all_size <<~SQL
          SELECT
            schemaname AS schema,
            relname AS table,
            indexrelname AS index,
            pg_relation_size(i.indexrelid) AS size_bytes,
            idx_scan as index_scans
          FROM
            pg_stat_user_indexes ui
          INNER JOIN
            pg_index i ON ui.indexrelid = i.indexrelid
          WHERE
            NOT indisunique
            AND idx_scan <= #{max_scans.to_i}
          ORDER BY
            pg_relation_size(i.indexrelid) DESC,
            relname ASC
        SQL

        across.each do |database_id|
          database = PgHero.databases.values.find { |d| d.id == database_id }
          raise PgHero::Error, "Database not found: #{database_id}" unless database
          across_result = Set.new(database.unused_indexes(max_scans: max_scans).map { |v| [v[:schema], v[:index]] })
          result.select! { |v| across_result.include?([v[:schema], v[:index]]) }
        end

        result
      end

      def reset_stats
        execute("SELECT pg_stat_reset()")
        true
      end

      def last_stats_reset_time
        select_one <<~SQL
          SELECT
            pg_stat_get_db_stat_reset_time(oid) AS reset_time
          FROM
            pg_database
          WHERE
            datname = current_database()
        SQL
      end

      def invalid_indexes(indexes: nil)
        indexes = (indexes || self.indexes).select { |i| !i[:valid] && !i[:creating] }
        indexes.each do |index|
          # map name -> index for backward compatibility
          index[:index] = index[:name]
        end
        indexes
      end

      # TODO parse array properly
      # https://stackoverflow.com/questions/2204058/list-columns-with-indexes-in-postgresql
      def indexes
        indexes = select_all(<<~SQL
          SELECT
            schemaname AS schema,
            t.relname AS table,
            ix.relname AS name,
            regexp_replace(pg_get_indexdef(i.indexrelid), '^[^\\(]*\\((.*)\\)$', '\\1') AS columns,
            regexp_replace(pg_get_indexdef(i.indexrelid), '.* USING ([^ ]*) \\(.*', '\\1') AS using,
            indisunique AS unique,
            indisprimary AS primary,
            indisvalid AS valid,
            indexprs::text,
            indpred::text,
            pg_get_indexdef(i.indexrelid) AS definition
          FROM
            pg_index i
          INNER JOIN
            pg_class t ON t.oid = i.indrelid
          INNER JOIN
            pg_class ix ON ix.oid = i.indexrelid
          LEFT JOIN
            pg_stat_user_indexes ui ON ui.indexrelid = i.indexrelid
          WHERE
            schemaname IS NOT NULL
          ORDER BY
            1, 2
        SQL
        ).map { |v| v[:columns] = v[:columns].sub(") WHERE (", " WHERE ").split(", ").map { |c| unquote(c) }; v }

        # determine if any invalid indexes being created
        # hacky, but works for simple cases
        # can be a race condition, but that's fine
        invalid_indexes = indexes.select { |i| !i[:valid] }
        if invalid_indexes.any?
          create_index_queries = running_queries.select { |q| /\s*CREATE\s+INDEX\s+CONCURRENTLY\s+/i.match(q[:query]) }
          invalid_indexes.each do |index|
            index[:creating] = create_index_queries.any? { |q| q[:query].include?(index[:table]) && index[:columns].all? { |c| q[:query].include?(c) } }
          end
        end

        indexes
      end

      def duplicate_indexes(indexes: nil)
        dup_indexes = []

        indexes_by_table = (indexes || self.indexes).group_by { |i| [i[:schema], i[:table]] }
        indexes_by_table.values.flatten.select { |i| i[:valid] && !i[:primary] && !i[:unique] }.each do |index|
          covering_index = indexes_by_table[[index[:schema], index[:table]]].find { |i| i[:valid] && i[:name] != index[:name] && index_covers?(i[:columns], index[:columns]) && i[:using] == index[:using] && i[:indexprs] == index[:indexprs] && i[:indpred] == index[:indpred] }
          if covering_index && (covering_index[:columns] != index[:columns] || index[:name] > covering_index[:name] || covering_index[:primary] || covering_index[:unique])
            dup_indexes << {unneeded_index: index, covering_index: covering_index}
          end
        end

        dup_indexes.sort_by { |i| ui = i[:unneeded_index]; [ui[:table], ui[:columns]] }
      end

      # https://gist.github.com/mbanck/9976015/71888a24e464e2f772182a7eb54f15a125edf398
      # thanks @jberkus and @mbanck
      def index_bloat(min_size: nil)
        min_size ||= index_bloat_bytes
        select_all <<~SQL
          WITH btree_index_atts AS (
            SELECT
              nspname, relname, reltuples, relpages, indrelid, relam,
              regexp_split_to_table(indkey::text, ' ')::smallint AS attnum,
              indexrelid as index_oid
            FROM
              pg_index
            JOIN
              pg_class ON pg_class.oid = pg_index.indexrelid
            JOIN
              pg_namespace ON pg_namespace.oid = pg_class.relnamespace
            JOIN
              pg_am ON pg_class.relam = pg_am.oid
            WHERE
              pg_am.amname = 'btree'
          ),
          index_item_sizes AS (
            SELECT
              i.nspname,
              i.relname,
              i.reltuples,
              i.relpages,
              i.relam,
              (quote_ident(s.schemaname) || '.' || quote_ident(s.tablename))::regclass AS starelid,
              a.attrelid AS table_oid, index_oid,
              current_setting('block_size')::numeric AS bs,
              /* MAXALIGN: 4 on 32bits, 8 on 64bits (and mingw32 ?) */
              CASE
                WHEN version() ~ 'mingw32' OR version() ~ '64-bit' THEN 8
                ELSE 4
              END AS maxalign,
              24 AS pagehdr,
              /* per tuple header: add index_attribute_bm if some cols are null-able */
              CASE WHEN max(coalesce(s.null_frac,0)) = 0
                THEN 2
                ELSE 6
              END AS index_tuple_hdr,
              /* data len: we remove null values save space using it fractionnal part from stats */
              sum( (1-coalesce(s.null_frac, 0)) * coalesce(s.avg_width, 2048) ) AS nulldatawidth
            FROM
              pg_attribute AS a
            JOIN
              pg_stats AS s ON (quote_ident(s.schemaname) || '.' || quote_ident(s.tablename))::regclass=a.attrelid AND s.attname = a.attname
            JOIN
              btree_index_atts AS i ON i.indrelid = a.attrelid AND a.attnum = i.attnum
            WHERE
              a.attnum > 0
            GROUP BY
              1, 2, 3, 4, 5, 6, 7, 8, 9
          ),
          index_aligned AS (
            SELECT
              maxalign,
              bs,
              nspname,
              relname AS index_name,
              reltuples,
              relpages,
              relam,
              table_oid,
              index_oid,
              ( 2 +
                maxalign - CASE /* Add padding to the index tuple header to align on MAXALIGN */
                  WHEN index_tuple_hdr%maxalign = 0 THEN maxalign
                  ELSE index_tuple_hdr%maxalign
                END
              + nulldatawidth + maxalign - CASE /* Add padding to the data to align on MAXALIGN */
                  WHEN nulldatawidth::integer%maxalign = 0 THEN maxalign
                  ELSE nulldatawidth::integer%maxalign
                END
              )::numeric AS nulldatahdrwidth, pagehdr
            FROM
              index_item_sizes AS s1
          ),
          otta_calc AS (
            SELECT
              bs,
              nspname,
              table_oid,
              index_oid,
              index_name,
              relpages,
              coalesce(
                ceil((reltuples*(4+nulldatahdrwidth))/(bs-pagehdr::float)) +
                CASE WHEN am.amname IN ('hash','btree') THEN 1 ELSE 0 END , 0 /* btree and hash have a metadata reserved block */
              ) AS otta
            FROM
              index_aligned AS s2
            LEFT JOIN
              pg_am am ON s2.relam = am.oid
          ),
          raw_bloat AS (
            SELECT
              nspname,
              c.relname AS table_name,
              index_name,
              bs*(sub.relpages)::bigint AS totalbytes,
              CASE
                WHEN sub.relpages <= otta THEN 0
                ELSE bs*(sub.relpages-otta)::bigint END
                AS wastedbytes,
              CASE
                WHEN sub.relpages <= otta
                THEN 0 ELSE bs*(sub.relpages-otta)::bigint * 100 / (bs*(sub.relpages)::bigint) END
                AS realbloat,
              pg_relation_size(sub.table_oid) as table_bytes,
              stat.idx_scan as index_scans,
              stat.indexrelid
            FROM
              otta_calc AS sub
            JOIN
              pg_class AS c ON c.oid=sub.table_oid
            JOIN
              pg_stat_user_indexes AS stat ON sub.index_oid = stat.indexrelid
          )
          SELECT
            nspname AS schema,
            table_name AS table,
            index_name AS index,
            wastedbytes AS bloat_bytes,
            totalbytes AS index_bytes,
            pg_get_indexdef(rb.indexrelid) AS definition,
            indisprimary AS primary
          FROM
            raw_bloat rb
          INNER JOIN
            pg_index i ON i.indexrelid = rb.indexrelid
          WHERE
            wastedbytes >= #{min_size.to_i}
          ORDER BY
            wastedbytes DESC,
            index_name
        SQL
      end

      protected

      def index_covers?(indexed_columns, columns)
        indexed_columns.first(columns.size) == columns
      end
    end
  end
end
