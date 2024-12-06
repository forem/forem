module Fog
  module AWS
    class DynamoDB
      class Real
        # List DynamoDB tables
        #
        # ==== Parameters
        # * 'options'<~Hash> - options, defaults to {}
        #   * 'ExclusiveStartTableName'<~String> - name of table to begin listing with
        #   * 'Limit'<~Integer> - limit number of tables to return
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'LastEvaluatedTableName'<~String> - last table name, for pagination
        #     * 'TableNames'<~Array> - table names
        #
        # See DynamoDB Documentation: http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_ListTables.html
        #
        def list_tables(options = {})
          request(
            :body       => Fog::JSON.encode(options),
            :headers    => {'x-amz-target' => 'DynamoDB_20120810.ListTables'},
            :idempotent => true
          )
        end
      end
    end
  end
end
