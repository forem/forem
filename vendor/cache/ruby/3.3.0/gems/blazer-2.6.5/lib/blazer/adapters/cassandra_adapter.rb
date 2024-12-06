module Blazer
  module Adapters
    class CassandraAdapter < BaseAdapter
      def run_statement(statement, comment, bind_params)
        columns = []
        rows = []
        error = nil

        begin
          response = session.execute("#{statement} /*#{comment}*/", arguments: bind_params)
          rows = response.map { |r| r.values }
          columns = rows.any? ? response.first.keys : []
        rescue => e
          error = e.message
          error = Blazer::VARIABLE_MESSAGE if error.include?("no viable alternative at input '?'")
        end

        [columns, rows, error]
      end

      def tables
        session.execute("SELECT table_name FROM system_schema.tables WHERE keyspace_name = #{data_source.quote(keyspace)}").map { |r| r["table_name"] }
      end

      def schema
        result = session.execute("SELECT keyspace_name, table_name, column_name, type, position FROM system_schema.columns WHERE keyspace_name = #{data_source.quote(keyspace)}")
        result.map(&:values).group_by { |r| [r[0], r[1]] }.map { |k, vs| {schema: k[0], table: k[1], columns: vs.sort_by { |v| v[2] }.map { |v| {name: v[2], data_type: v[3]} }} }
      end

      def preview_statement
        "SELECT * FROM {table} LIMIT 10"
      end

      # https://docs.datastax.com/en/cql-oss/3.3/cql/cql_reference/escape_char_r.html
      def quoting
        :single_quote_escape
      end

      # https://docs.datastax.com/en/developer/nodejs-driver/3.0/features/parameterized-queries/
      def parameter_binding
        :positional
      end

      private

      def cluster
        @cluster ||= begin
          require "cassandra"
          options = {hosts: [uri.host]}
          options[:port] = uri.port if uri.port
          options[:username] = uri.user if uri.user
          options[:password] = uri.password if uri.password
          ::Cassandra.cluster(options)
        end
      end

      def session
        @session ||= cluster.connect(keyspace)
      end

      def uri
        @uri ||= URI.parse(data_source.settings["url"])
      end

      def keyspace
        @keyspace ||= uri.path[1..-1]
      end
    end
  end
end
