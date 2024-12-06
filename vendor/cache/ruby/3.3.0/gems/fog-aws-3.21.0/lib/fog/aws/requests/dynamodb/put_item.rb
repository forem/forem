module Fog
  module AWS
    class DynamoDB
      class Real
        # Update DynamoDB item
        #
        # ==== Parameters
        # * 'table_name'<~String> - name of table for item
        # * 'item'<~Hash>: data to update, must include primary key
        #   {
        #     "LastPostDateTime": {"S": "201303190422"}
        #   }
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     varies based on ReturnValues param, see: http://docs.amazonwebservices.com/amazondynamodb/latest/developerguide/API_UpdateItem.html
        #
        # See DynamoDB Documentation: http://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_PutItem.html
        #
        def put_item(table_name, item, options = {})
          body = {
            'Item'      => item,
            'TableName' => table_name
          }.merge(options)

          request(
            :body       => Fog::JSON.encode(body),
            :headers    => {'x-amz-target' => 'DynamoDB_20120810.PutItem'}
          )
        end
      end
    end
  end
end
