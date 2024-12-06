module Fog
  module AWS
    class DynamoDB
      class Real
        def batch_put_item(request_items)
          Fog::Logger.deprecation("batch_put_item is deprecated, use batch_write_item instead")
          batch_write_item(request_items)
        end

        # request_items has form:
        #
        # {"table_name"=>
        #  [{"PutRequest"=>
        #    {"Item"=>
        #       {"hi" => {"N" => 99}}
        #    }
        #  }]
        # }
        #
        # See DynamoDB Documentation: http://docs.amazonwebservices.com/amazondynamodb/latest/developerguide/API_BatchWriteItems.html
        #
        def batch_write_item(request_items)
          body = {
            'RequestItems' => request_items
          }

          request(
            :body       => Fog::JSON.encode(body),
            :headers    => {'x-amz-target' => 'DynamoDB_20120810.BatchWriteItem'}
          )
        end
      end
    end
  end
end
