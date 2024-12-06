module Fog
  module AWS
    class DynamoDB
      class Real
        # Delete DynamoDB item
        #
        # ==== Parameters
        # * 'table_name'<~String> - name of table for item
        # * 'key'<~Hash> - hash of attributes
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     varies based on ReturnValues param, see: http://docs.amazonwebservices.com/amazondynamodb/latest/developerguide/API_UpdateItem.html
        #
        # See DynamoDB Documentation: http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_DeleteItem.html
        #
        def delete_item(table_name, key, options = {})
          body = {
            'Key'               => key,
            'TableName'         => table_name
          }.merge(options)

          request(
            :body       => Fog::JSON.encode(body),
            :headers    => {'x-amz-target' => 'DynamoDB_20120810.DeleteItem'},
            :idempotent => true
          )
        end
      end
    end
  end
end
