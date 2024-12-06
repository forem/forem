module Fog
  module AWS
    class DynamoDB
      class Real
        # Describe DynamoDB table
        #
        # ==== Parameters
        # * 'table_name'<~String> - name of table to describe
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'Table'<~Hash>
        #       * 'CreationDateTime'<~Float> - Unix epoch time of table creation
        #       * 'KeySchema'<~Array> - schema for table
        #         * 'AttributeName'<~String> - name of attribute
        #         * 'KeyType'<~String> - type of attribute, in %w{N NS S SS} for number, number set, string, string set
        #       * 'ProvisionedThroughput'<~Hash>:
        #         * 'ReadCapacityUnits'<~Integer> - read capacity for table, in 5..10000
        #         * 'WriteCapacityUnits'<~Integer> - write capacity for table, in 5..10000
        #       * 'TableName'<~String> - name of table
        #       * 'TableSizeBytes'<~Integer> - size of table in bytes
        #       * 'TableStatus'<~String> - status of table
        #
        # See DynamoDB Documentation: http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_DescribeTable.html
        #
        def describe_table(table_name)
          body = {
            'TableName' => table_name
          }

          request(
            :body       => Fog::JSON.encode(body),
            :headers    => {'x-amz-target' => 'DynamoDB_20120810.DescribeTable'},
            :idempotent => true
          )
        end
      end
    end
  end
end
