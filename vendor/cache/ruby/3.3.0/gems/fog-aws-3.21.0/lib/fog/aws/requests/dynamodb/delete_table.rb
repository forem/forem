module Fog
  module AWS
    class DynamoDB
      class Real
        # Delete DynamoDB table
        #
        # ==== Parameters
        # * 'table_name'<~String> - name of table to delete
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'TableDescription'<~Hash>
        #       * 'ProvisionedThroughput'<~Hash>:
        #         * 'ReadCapacityUnits'<~Integer> - read capacity for table, in 5..10000
        #         * 'WriteCapacityUnits'<~Integer> - write capacity for table, in 5..10000
        #       * 'TableName'<~String> - name of table
        #       * 'TableStatus'<~String> - status of table
        #
        # See DynamoDB Documentation: http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_DeleteTable.html
        #
        def delete_table(table_name)
          body = {
            'TableName' => table_name
          }

          request(
            :body       => Fog::JSON.encode(body),
            :headers    => {'x-amz-target' => 'DynamoDB_20120810.DeleteTable'},
            :idempotent => true
          )
        end
      end
    end
  end
end
