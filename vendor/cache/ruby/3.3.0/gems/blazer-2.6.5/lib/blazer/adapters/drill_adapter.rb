module Blazer
  module Adapters
    class DrillAdapter < BaseAdapter
      def run_statement(statement, comment)
        columns = []
        rows = []
        error = nil

        begin
          # remove trailing semicolon
          response = drill.query(statement.sub(/;\s*\z/, ""))
          rows = response.map { |r| r.values }
          columns = rows.any? ? response.first.keys : []
        rescue => e
          error = e.message
        end

        [columns, rows, error]
      end

      # https://drill.apache.org/docs/lexical-structure/#string
      def quoting
        :single_quote_escape
      end

      # https://issues.apache.org/jira/browse/DRILL-5079
      def parameter_binding
        # not supported
      end

      private

      def drill
        @drill ||= ::Drill.new(url: settings["url"])
      end
    end
  end
end
