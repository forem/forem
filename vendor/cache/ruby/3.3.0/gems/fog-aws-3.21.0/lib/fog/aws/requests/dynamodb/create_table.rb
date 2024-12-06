module Fog
  module AWS
    class DynamoDB
      class Real
        # Create DynamoDB table
        #
        # ==== Parameters
        # * 'table_name'<~String> - name of table to create
        # * 'key_schema'<~Array>:
        #     * 'AttributeName'<~String> - name of attribute
        #     * 'KeyType'<~String> - type of attribute, in %w{N NS S SS} for number, number set, string, string set
        # * 'ProvisionedThroughput'<~Hash>:
        #   * 'ReadCapacityUnits'<~Integer> - read capacity for table, in 5..10000
        #   * 'WriteCapacityUnits'<~Integer> - write capacity for table, in 5..10000
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'TableDescription'<~Hash>
        #       * 'CreationDateTime'<~Float> - Unix epoch time of table creation
        #       * 'KeySchema'<~Array> - schema for table
        #           * 'AttributeName'<~String> - name of attribute
        #           * 'KeyType'<~String> - type of attribute, in %w{N NS S SS} for number, number set, string, string set
        #       * 'ProvisionedThroughput'<~Hash>:
        #         * 'ReadCapacityUnits'<~Integer> - read capacity for table, in 5..10000
        #         * 'WriteCapacityUnits'<~Integer> - write capacity for table, in 5..10000
        #       * 'TableName'<~String> - name of table
        #       * 'TableStatus'<~String> - status of table
        #
        # See DynamoDB Documentation: http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_CreateTable.html
        #
        def create_table(table_name, key_schema, provisioned_throughput)
          body = {
            'KeySchema'             => key_schema,
            'ProvisionedThroughput' => provisioned_throughput,
            'TableName'             => table_name
          }

          request(
            :body       => Fog::JSON.encode(body),
            :headers    => {'x-amz-target' => 'DynamoDB_20120810.CreateTable'},
            :idempotent => true
          )
        end
      end
    end
  end
end
