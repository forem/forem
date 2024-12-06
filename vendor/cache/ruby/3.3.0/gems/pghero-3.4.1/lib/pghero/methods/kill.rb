module PgHero
  module Methods
    module Kill
      def kill(pid)
        select_one("SELECT pg_terminate_backend(#{pid.to_i})")
      end

      def kill_long_running_queries(min_duration: nil)
        running_queries(min_duration: min_duration || long_running_query_sec).each { |query| kill(query[:pid]) }
        true
      end

      def kill_all
        select_all <<~SQL
          SELECT
            pg_terminate_backend(pid)
          FROM
            pg_stat_activity
          WHERE
            pid <> pg_backend_pid()
            AND query <> '<insufficient privilege>'
            AND datname = current_database()
        SQL
        true
      end
    end
  end
end
