module Blazer
  module Adapters
    class DruidAdapter < BaseAdapter
      TIMESTAMP_REGEX = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z/

      def run_statement(statement, comment, bind_params)
        require "json"
        require "net/http"
        require "uri"

        columns = []
        rows = []
        error = nil

        params =
          bind_params.map do |v|
            type =
              case v
              when Integer
                "BIGINT"
              when Float
                "DOUBLE"
              when ActiveSupport::TimeWithZone
                v = (v.to_f * 1000).round
                "TIMESTAMP"
              else
                "VARCHAR"
              end
            {type: type, value: v}
          end

        header = {"Content-Type" => "application/json", "Accept" => "application/json"}
        timeout = data_source.timeout ? data_source.timeout.to_i : 300
        data = {
          query: statement,
          parameters: params,
          context: {
            timeout: timeout * 1000
          }
        }

        uri = URI.parse("#{settings["url"]}/druid/v2/sql/")
        http = Net::HTTP.new(uri.host, uri.port)
        http.read_timeout = timeout

        begin
          response = JSON.parse(http.post(uri.request_uri, data.to_json, header).body)
          if response.is_a?(Hash)
            error = response["errorMessage"] || "Unknown error: #{response.inspect}"
            if error.include?("timed out")
              error = Blazer::TIMEOUT_MESSAGE
            elsif error.include?("Encountered \"?\" at")
              error = Blazer::VARIABLE_MESSAGE
            end
          else
            columns = (response.first || {}).keys
            rows = response.map { |r| r.values }

            # Druid doesn't return column types
            # and no timestamp type in JSON
            rows.each do |row|
              row.each_with_index do |v, i|
                if v.is_a?(String) && TIMESTAMP_REGEX.match(v)
                  row[i] = Time.parse(v)
                end
              end
            end
          end
        rescue => e
          error = e.message
        end

        [columns, rows, error]
      end

      def tables
        result = data_source.run_statement("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA NOT IN ('INFORMATION_SCHEMA') ORDER BY TABLE_NAME")
        result.rows.map(&:first)
      end

      def schema
        result = data_source.run_statement("SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE, ORDINAL_POSITION FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA NOT IN ('INFORMATION_SCHEMA') ORDER BY 1, 2")
        result.rows.group_by { |r| [r[0], r[1]] }.map { |k, vs| {schema: k[0], table: k[1], columns: vs.sort_by { |v| v[2] }.map { |v| {name: v[2], data_type: v[3]} }} }
      end

      def preview_statement
        "SELECT * FROM {table} LIMIT 10"
      end

      # https://druid.apache.org/docs/latest/querying/sql.html#identifiers-and-literals
      # docs only mention double quotes
      def quoting
        :single_quote_escape
      end

      # https://druid.apache.org/docs/latest/querying/sql.html#dynamic-parameters
      def parameter_binding
        :positional
      end
    end
  end
end
