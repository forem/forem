class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  QUERY_ESTIMATED_COUNT = <<~SQL.squish.freeze
    SELECT (
      (reltuples / GREATEST(relpages, 1)) *
      (pg_relation_size(?) / (GREATEST(current_setting('block_size')::integer, 1)))
    )::bigint AS count
    FROM pg_class WHERE relname = ?;
  SQL

  # Computes an estimated count of the number of rows using stats collected by VACUUM
  # inspired by <https://www.citusdata.com/blog/2016/10/12/count-performance/#dup_counts_estimated_full>
  # and <https://stackoverflow.com/a/48391562/4186181>
  def self.estimated_count
    query = sanitize_sql_array([QUERY_ESTIMATED_COUNT, table_name, table_name])
    result = connection.execute(query)

    count = result.first["count"]
    result.clear # PG::Result is manually managed in memory, we need to release its resources
    count
  end
end
