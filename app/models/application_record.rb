class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  QUERY_ESTIMATED_COUNT = <<~SQL.squish.freeze
    SELECT (
      (reltuples / GREATEST(relpages, 1)) *
      (pg_relation_size($1) / (GREATEST(current_setting('block_size')::integer, 1)))
    )::bigint AS count
    FROM pg_class WHERE relname = $2;
  SQL

  # Computes an estimated count of the number of rows using stats collected by VACUUM
  # inspired by <https://www.citusdata.com/blog/2016/10/12/count-performance/#dup_counts_estimated_full>
  # and <https://stackoverflow.com/a/48391562/4186181>
  def self.estimated_count
    query_name = "SQL COUNT ESTIMATE: #{table_name}"
    table_name_attr = ActiveRecord::Relation::QueryAttribute.new(
      "relname", table_name, ActiveRecord::Type::String.new
    )

    result = connection.exec_query(
      QUERY_ESTIMATED_COUNT, query_name, [table_name_attr, table_name_attr]
    )

    result.first["count"]
  end
end
