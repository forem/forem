module Fog
  module AWS
    class DynamoDB
      class Real
        # Update DynamoDB table throughput
        #
        # ==== Parameters
        # * 'table_name'<~String> - name of table to describe
        # * 'provisioned_throughput'<~Hash>:
        #   * 'ReadCapacityUnits'<~Integer> - read capacity for table, in 5..10000
        #   * 'WriteCapacityUnits'<~Integer> - write capacity for table, in 5..10000
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'Table'<~Hash>
        #       * 'KeySchema'<~Array> - schema for table
        #           * 'AttributeName'<~String> - name of attribute
        #           * 'KeyType'<~String> - type of attribute, in %w{N NS S SS} for number, number set, string, string set
        #       * 'ProvisionedThroughput'<~Hash>:
        #         * 'ReadCapacityUnits'<~Integer> - read capacity for table, in 5..10000
        #         * 'WriteCapacityUnits'<~Integer> - write capacity for table, in 5..10000
        #       * 'TableName'<~String> - name of table
        #       * 'TableStatus'<~String> - status of table
        #
        # See DynamoDB Documentation: http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_UpdateTable.html
        #
        def update_table(table_name, provisioned_throughput)
          body = {
            'ProvisionedThroughput' => provisioned_throughput,
            'TableName'             => table_name
          }

          request(
            :body       => Fog::JSON.encode(body),
            :headers    => {'x-amz-target' => 'DynamoDB_20120810.UpdateTable'},
            :idempotent => true
          )
        end
      end
    end
  end
end
