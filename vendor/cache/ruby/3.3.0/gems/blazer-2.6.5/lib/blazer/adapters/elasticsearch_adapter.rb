module Blazer
  module Adapters
    class ElasticsearchAdapter < BaseAdapter
      def run_statement(statement, comment, bind_params)
        columns = []
        rows = []
        error = nil

        begin
          response = client.transport.perform_request("POST", endpoint, {}, {query: "#{statement} /*#{comment}*/", params: bind_params}).body
          columns = response["columns"].map { |v| v["name"] }
          # Elasticsearch does not differentiate between dates and times
          date_indexes = response["columns"].each_index.select { |i| ["date", "datetime"].include?(response["columns"][i]["type"]) }
          if columns.any?
            rows = response["rows"]
            date_indexes.each do |i|
              rows.each do |row|
                row[i] &&= Time.parse(row[i])
              end
            end
          end
        rescue => e
          error = e.message
          error = Blazer::VARIABLE_MESSAGE if error.include?("mismatched input '?'")
        end

        [columns, rows, error]
      end

      def tables
        indices = client.cat.indices(format: "json").map { |v| v["index"] }
        aliases = client.cat.aliases(format: "json").map { |v| v["alias"] }
        (indices + aliases).uniq.sort
      end

      def preview_statement
        "SELECT * FROM \"{table}\" LIMIT 10"
      end

      # https://www.elastic.co/guide/en/elasticsearch/reference/current/sql-lexical-structure.html#sql-syntax-string-literals
      def quoting
        :single_quote_escape
      end

      # https://www.elastic.co/guide/en/elasticsearch/reference/current/sql-rest-params.html
      def parameter_binding
        :positional
      end

      protected

      def endpoint
        @endpoint ||= client.info["version"]["number"].to_i >= 7 ? "_sql" : "_xpack/sql"
      end

      def client
        @client ||= Elasticsearch::Client.new(url: settings["url"])
      end
    end
  end
end
