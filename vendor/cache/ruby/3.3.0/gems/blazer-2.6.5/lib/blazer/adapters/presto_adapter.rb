module Blazer
  module Adapters
    class PrestoAdapter < BaseAdapter
      def run_statement(statement, comment)
        columns = []
        rows = []
        error = nil

        begin
          columns, rows = client.run("#{statement} /*#{comment}*/")
          columns = columns.map(&:name)
        rescue => e
          error = e.message
        end

        [columns, rows, error]
      end

      def tables
        _, rows = client.run("SHOW TABLES")
        rows.map(&:first)
      end

      def preview_statement
        "SELECT * FROM {table} LIMIT 10"
      end

      def quoting
        :single_quote_escape
      end

      # TODO support prepared statements - https://prestodb.io/docs/current/sql/prepare.html
      # feature request for variables - https://github.com/prestodb/presto/issues/5918
      def parameter_binding
      end

      protected

      def client
        @client ||= begin
          uri = URI.parse(settings["url"])
          query = uri.query ? CGI::parse(uri.query) : {}
          Presto::Client.new(
            server: "#{uri.host}:#{uri.port}",
            catalog: uri.path.to_s.sub(/\A\//, ""),
            schema: query["schema"] || "public",
            user: uri.user,
            http_debug: false
          )
        end
      end
    end
  end
end
