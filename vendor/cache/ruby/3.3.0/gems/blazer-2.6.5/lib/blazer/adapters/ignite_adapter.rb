module Blazer
  module Adapters
    class IgniteAdapter < BaseAdapter
      def run_statement(statement, comment, bind_params)
        columns = []
        rows = []
        error = nil

        begin
          result = client.query("#{statement} /*#{comment}*/", bind_params, schema: default_schema, statement_type: :select, timeout: data_source.timeout)
          columns = result.any? ? result.first.keys : []
          rows = result.map(&:values)
        rescue => e
          error = e.message
        end

        [columns, rows, error]
      end

      def preview_statement
        "SELECT * FROM {table} LIMIT 10"
      end

      def tables
        sql = "SELECT table_schema, table_name FROM information_schema.tables WHERE table_schema NOT IN ('INFORMATION_SCHEMA', 'SYS')"
        result = data_source.run_statement(sql)
        result.rows.reject { |row| row[1].start_with?("__") }.map do |row|
          (row[0] == default_schema ? row[1] : "#{row[0]}.#{row[1]}").downcase
        end
      end

      # TODO figure out error
      # Table `__T0` can be accessed only within Ignite query context.
      # def schema
      #   sql = "SELECT table_schema, table_name, column_name, data_type, ordinal_position FROM information_schema.columns WHERE table_schema NOT IN ('INFORMATION_SCHEMA', 'SYS')"
      #   result = data_source.run_statement(sql)
      #   result.rows.group_by { |r| [r[0], r[1]] }.map { |k, vs| {schema: k[0], table: k[1], columns: vs.sort_by { |v| v[2] }.map { |v| {name: v[2], data_type: v[3]} }} }.sort_by { |t| [t[:schema] == default_schema ? "" : t[:schema], t[:table]] }
      # end

      def quoting
        :single_quote_escape
      end

      # query arguments
      # https://ignite.apache.org/docs/latest/binary-client-protocol/sql-and-scan-queries#op_query_sql
      def parameter_binding
        :positional
      end

      private

      def default_schema
        "PUBLIC"
      end

      def client
        @client ||= begin
          uri = URI(settings["url"])
          Ignite::Client.new(host: uri.host, port: uri.port, username: uri.user, password: uri.password)
        end
      end
    end
  end
end
