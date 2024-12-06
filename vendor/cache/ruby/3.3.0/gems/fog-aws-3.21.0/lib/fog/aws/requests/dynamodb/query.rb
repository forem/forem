module Fog
  module AWS
    class DynamoDB
      class Real
        # Query DynamoDB items
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
        #     * 'ConsumedCapacityUnits'<~Integer> - number of capacity units used for query
        #     * 'Count'<~Integer> - number of items in response
        #     * 'Items'<~Array> - array of items returned
        #     * 'LastEvaluatedKey'<~Hash> - last key scanned, can be passed to ExclusiveStartKey for pagination
        #
        # See DynamoDB Documentation: http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_Query.html
        #
        def query(table_name, options = {}, hash_key_deprecated = nil)
          if hash_key_deprecated || (options.keys.length == 1 && [:S, :N, :B].include?(options.keys.first.to_sym))
            Fog::Logger.deprecation("The `20111205` API version is deprecated. You need to use `KeyConditionExpression` instead of `HashKey`.")
            apiVersion = '20111205'
            hash_key = options
            options = hash_key_deprecated
          end

          body = {
            'TableName'     => table_name,
            'HashKeyValue'  => hash_key
          }.merge(options)

          request(
            :body     => Fog::JSON.encode(body),
            :headers  => {'x-amz-target' => "DynamoDB_#{apiVersion || '20120810'}.Query"}
          )
        end
      end
    end
  end
end
