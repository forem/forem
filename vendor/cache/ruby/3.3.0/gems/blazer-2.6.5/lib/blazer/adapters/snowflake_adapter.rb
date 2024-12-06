module Blazer
  module Adapters
    class SnowflakeAdapter < SqlAdapter
      def initialize(data_source)
        @data_source = data_source

        @@registered ||= begin
          require "active_record/connection_adapters/odbc_adapter"
          require "odbc_adapter/adapters/postgresql_odbc_adapter"

          ODBCAdapter.register(/snowflake/, ODBCAdapter::Adapters::PostgreSQLODBCAdapter) do
            # Explicitly turning off prepared statements as they are not yet working with
            # snowflake + the ODBC ActiveRecord adapter
            def prepared_statements
              false
            end

            # Quoting needs to be changed for snowflake
            def quote_column_name(name)
              name.to_s
            end

            private

            # Override dbms_type_cast to get the values encoded in UTF-8
            def dbms_type_cast(columns, values)
              int_column = {}
              columns.each_with_index do |c, i|
                int_column[i] = c.type == 3 && c.scale == 0
              end

              float_column = {}
              columns.each_with_index do |c, i|
                float_column[i] = c.type == 3 && c.scale != 0
              end

              values.each do |row|
                row.each_index do |idx|
                  val = row[idx]
                  if val
                    if int_column[idx]
                      row[idx] = val.to_i
                    elsif float_column[idx]
                      row[idx] = val.to_f
                    elsif val.is_a?(String)
                      row[idx] = val.force_encoding('UTF-8')
                    end
                  end
                end
              end
            end
          end
        end

        @connection_model =
          Class.new(Blazer::Connection) do
            def self.name
              "Blazer::Connection::SnowflakeAdapter#{object_id}"
            end
            if data_source.settings["conn_str"]
              establish_connection(adapter: "odbc", conn_str: data_source.settings["conn_str"])
            elsif data_source.settings["dsn"]
              establish_connection(adapter: "odbc", dsn: data_source.settings["dsn"])
            end
        end
      end

      def cancel(run_id)
        # todo
      end

      # https://docs.snowflake.com/en/sql-reference/data-types-text.html#escape-sequences
      def quoting
        :backslash_escape
      end

      def parameter_binding
        # TODO
      end
    end
  end
end
