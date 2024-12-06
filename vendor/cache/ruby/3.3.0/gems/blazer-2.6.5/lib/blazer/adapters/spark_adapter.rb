module Blazer
  module Adapters
    class SparkAdapter < HiveAdapter
      def tables
        client.execute("SHOW TABLES").map { |r| r["tableName"] }
      end

      # https://spark.apache.org/docs/latest/sql-ref-literals.html
      def quoting
        :backslash_escape
      end
    end
  end
end
