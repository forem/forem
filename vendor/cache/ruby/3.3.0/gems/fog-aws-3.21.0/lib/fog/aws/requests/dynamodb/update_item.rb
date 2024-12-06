module Fog
  module AWS
    class DynamoDB
      class Real
        class DeprecatedAttributeUpdates < Exception; end
        # Update DynamoDB item
        #
        # ==== Parameters
        # * 'table_name'<~String> - name of table for item
        # * 'key'<~Hash> - list of Key attributes
        #   {
        #     "ForumName": {"S": "Amazon DynamoDB"},
        #     "Subject": {"S": "Maximum number of items?"}
        #   }
        #
        # * 'options'<~Hash>:
        #   * 'UpdateExpression'<~String> - the expression that will update the item
        #   * 'ExpressionAttributeValues'<~Hash> - values to be used in the update expression
        #   * 'ReturnValues'<~String> - data to return in %w{ALL_NEW ALL_OLD NONE UPDATED_NEW UPDATED_OLD}, defaults to NONE
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     varies based on ReturnValues param, see: http://docs.amazonwebservices.com/amazondynamodb/latest/developerguide/API_UpdateItem.html
        #
        # See DynamoDB Documentation: http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_UpdateItem.html
        #
        def update_item(table_name, key, options = {}, deprecated_attribute_updates = nil)
          if deprecated_attribute_updates
            raise DeprecatedAttributeUpdates, "The `20111205` DynamoDB API is deprecated. You need to use `ExpressionAttributeValues` instead of `AttributeUpdates`."
            attribute_updates = options
            options = deprecated_attribute_updates.merge(
              'AttributeUpdates'  => attribute_updates,
            )
          end

          body = {
            'Key'               => key,
            'TableName'         => table_name,
          }.merge(options)

          request(
            :body     => Fog::JSON.encode(body),
            :headers  => {'x-amz-target' => 'DynamoDB_20120810.UpdateItem'}
          )
        end
      end
    end
  end
end
