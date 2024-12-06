module Fog
  module Parsers
    module AWS
      module RDS
        require 'fog/aws/parsers/rds/subnet_group_parser'

        class DeleteDBSubnetGroup < Fog::Parsers::AWS::RDS::SubnetGroupParser
          def reset
            @response = { 'DeleteDBSubnetGroupResponse' => {}, 'ResponseMetadata' => {} }
            super
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            else
              super
            end
          end
        end
      end
    end
  end
end
