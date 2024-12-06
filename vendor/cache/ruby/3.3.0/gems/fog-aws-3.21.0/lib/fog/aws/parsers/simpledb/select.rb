require 'fog/aws/parsers/simpledb/basic'

module Fog
  module Parsers
    module AWS
      module SimpleDB
        class Select < Fog::Parsers::AWS::SimpleDB::Basic
          def reset
            @item_name = @attribute_name = nil
            @response = { 'Items' => {} }
          end

          def end_element(name)
            case name
            when 'BoxUsage'
              response[name] = value.to_f
            when 'Item'
              @item_name = @attribute_name = nil
            when 'Name'
              if @item_name.nil?
                @item_name = value
                response['Items'][@item_name] = {}
              else
                @attribute_name = value
                response['Items'][@item_name][@attribute_name] ||= []
              end
            when 'NextToken', 'RequestId'
              response[name] = value
            when 'Value'
              response['Items'][@item_name][@attribute_name] << sdb_decode(value)
            end
          end
        end
      end
    end
  end
end
