module Fog
  module Parsers
    module AWS
      module Compute
        class DescribeAccountAttributes < Fog::Parsers::Base
          def reset
            @attribute = { 'values' => []}
            @account_attributes = []
            @response = { 'accountAttributeSet' => [] }
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'attributeValueSet'
              @in_attribute_value_set = true
            end
          end

          def end_element(name)
            case name
            when 'attributeName'
              @attribute[name] = value
            when 'attributeValue'
              @attribute['values'] << value
            when['requestId']
              @response[name] = value
            when 'item'
              @response['accountAttributeSet'] << @attribute
              @attribute = { 'values' => []} unless @in_attribute_value_set
            when 'attributeValueSet'
              @in_attribute_value_set = false
            else
            end
            @response['accountAttributeSet'].uniq!
          end
        end
      end
    end
  end
end
