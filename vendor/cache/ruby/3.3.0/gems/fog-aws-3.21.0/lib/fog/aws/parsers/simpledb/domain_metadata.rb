require 'fog/aws/parsers/simpledb/basic'

module Fog
  module Parsers
    module AWS
      module SimpleDB
        class DomainMetadata < Fog::Parsers::AWS::SimpleDB::Basic
          def reset
            @response = {}
          end

          def end_element(name)
            case name
            when 'AttributeNameCount', 'AttributeNamesSizeBytes', 'AttributeValueCount', 'AttributeValuesSizeBytes', 'ItemCount', 'ItemNamesSizeBytes'
              response[name] = value.to_i
            when 'BoxUsage'
              response[name] = value.to_f
            when 'RequestId'
              response[name] = value
            when 'Timestamp'
              response[name] = Time.at(value.to_i)
            end
          end
        end
      end
    end
  end
end
