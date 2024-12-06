require 'fog/aws/parsers/simpledb/basic'

module Fog
  module Parsers
    module AWS
      module SimpleDB
        class ListDomains < Fog::Parsers::AWS::SimpleDB::Basic
          def reset
            @response = { 'Domains' => [] }
          end

          def end_element(name)
            case(name)
            when 'BoxUsage'
              response[name] = value.to_f
            when 'DomainName'
              response['Domains'] << value
            when 'NextToken', 'RequestId'
              response[name] = value
            end
          end
        end
      end
    end
  end
end
