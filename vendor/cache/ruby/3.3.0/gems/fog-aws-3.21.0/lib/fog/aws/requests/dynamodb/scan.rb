module Fog
  module AWS
    class DynamoDB
      class Real
        # Scan DynamoDB items
        #
        # ==== Parameters
        # * 'table_name'<~String> - name of table to query
        # * options<~Hash>:
        #   * 'AttributesToGet'<~Array> - Array of attributes to get for each item, defaults to all
        #   * 'ConsistentRead'<~Boolean> - Whether to wait for consistency, defaults to false
        #   * 'Count'<~Boolean> - If true, returns only a count of such items rather than items themselves, defaults to false
        #   * 'Limit'<~Integer> - limit of total items to return
        #   * 'KeyConditionExpression'<~String> - the condition elements need to match
        #   * 'ExpressionAttributeValues'<~Hash> - values to be used in the key condition expression
        #   * 'ScanIndexForward'<~Boolean>: Whether to scan from start or end of index, defaults to start
        #   * 'ExclusiveStartKey'<~Hash>: Key to start listing from, can be taken from LastEvaluatedKey in response
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ConsumedCapacityUnits'<~Integer> - number of capacity units used for scan
        #     * 'Count'<~Integer> - number of items in response
        #     * 'Items'<~Array> - array of items returned
        #     * 'LastEvaluatedKey'<~Hash> - last key scanned, can be passed to ExclusiveStartKey for pagination
        #     * 'ScannedCount'<~Integer> - number of items scanned before applying filters
        #
        # See DynamoDB Documentation: http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_UpdateItem.html
        #
        def scan(table_name, options = {})
          body = {
            'TableName'     => table_name
          }.merge(options)

          request(
            :body     => Fog::JSON.encode(body),
            :headers  => {'x-amz-target' => 'DynamoDB_20120810.Scan'},
            :idempotent => true
          )
        end
      end
    end
  end
end
