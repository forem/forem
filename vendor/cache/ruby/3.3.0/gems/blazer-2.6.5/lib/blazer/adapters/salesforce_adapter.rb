module Blazer
  module Adapters
    class SalesforceAdapter < BaseAdapter
      def run_statement(statement, comment)
        columns = []
        rows = []
        error = nil

        # remove comments manually
        statement = statement.gsub(/--.+/, "")
        # only supports single line /* */ comments
        # regex not perfect, but should be good enough
        statement = statement.gsub(/\/\*.+\*\//, "")

        # remove trailing semicolon
        statement = statement.sub(/;\s*\z/, "")

        begin
          response = client.query(statement)
          rows = response.map { |r| r.to_hash.except("attributes").values }
          columns = rows.any? ? response.first.to_hash.except("attributes").keys : []
        rescue => e
          error = e.message
        end

        [columns, rows, error]
      end

      def tables
        # cache
        @tables ||= client.describe.select { |r| r.queryable }.map(&:name)
      end

      def preview_statement
        "SELECT Id FROM {table} LIMIT 10"
      end

      # https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_quotedstringescapes.htm
      def quoting
        :backslash_escape
      end

      protected

      def client
        @client ||= Restforce.new
      end
    end
  end
end
