require 'fog/aws/parsers/simpledb/basic'

module Fog
  module Parsers
    module AWS
      module SimpleDB
        class GetAttributes < Fog::Parsers::AWS::SimpleDB::Basic
          def reset
            @attribute = nil
            @response = { 'Attributes' => {} }
          end

          def end_element(name)
            case name
            when 'Attribute'
              @attribute = nil
            when 'BoxUsage'
              response[name] = value.to_f
            when 'Name'
              @attribute = value
              response['Attributes'][@attribute] ||= []
            when 'RequestId'
              response[name] = value
            when 'Value'
              response['Attributes'][@attribute] << sdb_decode(value)
            end
          end
        end
      end
    end
  end
end
