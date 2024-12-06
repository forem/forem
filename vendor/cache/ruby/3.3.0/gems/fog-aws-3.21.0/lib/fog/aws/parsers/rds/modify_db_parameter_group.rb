module Fog
  module Parsers
    module AWS
      module RDS
        class ModifyDbParameterGroup < Fog::Parsers::Base
          def reset
            @response = { 'ModifyDBParameterGroupResult' => {}, 'ResponseMetadata' => {} }
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'DBParameterGroupName'
              @response['ModifyDBParameterGroupResult']['DBParameterGroupName'] = value
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            end
          end
        end
      end
    end
  end
end
