module Fog
  module AWS
    class DynamoDB
      class Real
        # Get DynamoDB items
        #
        # ==== Parameters
        # * 'request_items'<~Hash>:
        #   * 'table_name'<~Hash>:
        #     * 'Keys'<~Array>: array of keys
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'Responses'<~Hash>:
        #       * 'table_name'<~Array> - array of all elements
        #     * 'UnprocessedKeys':<~Hash> - tables and keys in excess of per request limit, pass this to subsequent batch get for pseudo-pagination
        #     * 'ConsumedCapacity':<~Hash>:
        #       * 'TableName'<~String> - the name of the table
        #       * 'CapacityUnits'<~Float> - Capacity units used in read
        #
        # See DynamoDB Documentation: http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_BatchGetItem.html
        #
        def batch_get_item(request_items)
          body = {
            'RequestItems' => request_items
          }

          request(
            :body       => Fog::JSON.encode(body),
            :headers    => {'x-amz-target' => 'DynamoDB_20120810.BatchGetItem'},
            :idempotent => true
          )
        end
      end
    end
  end
end
