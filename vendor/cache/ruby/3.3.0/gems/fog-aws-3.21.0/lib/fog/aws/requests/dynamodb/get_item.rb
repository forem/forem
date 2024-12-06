module Fog
  module AWS
    class DynamoDB
      class Real
        # Get DynamoDB item
        #
        # ==== Parameters
        # * 'table_name'<~String> - name of table for item
        # * 'key'<~Hash>:
        #     {
        #       "ForumName": {
        #         "S": "Amazon DynamoDB"
        #       }
        #     }
        # * 'options'<~Hash>:
        #   * 'AttributesToGet'<~Array>: list of array names to return, defaults to returning all
        #   * 'ConsistentRead'<~Boolean>: whether to wait for updates, defaults to false
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ConsumedCapacityUnits'<~Float> - Capacity units used in read
        #     * 'Item':<~Hash>:
        #       * 'AttributeName'<~Hash>: in form of {"type":value}
        #
        # See DynamoDB Documentation: http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_GetItem.html
        #
        def get_item(table_name, key, options = {})
          body = {
            'Key'               => key,
            'TableName'         => table_name
          }.merge(options)

          request(
            :body       => Fog::JSON.encode(body),
            :headers    => {'x-amz-target' => 'DynamoDB_20120810.GetItem'},
            :idempotent => true
          )
        end
      end
    end
  end
end
