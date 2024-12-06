module Fog
  module Parsers
    module AWS
      module EMR
        class AddInstanceGroups < Fog::Parsers::Base
          def start_element(name, attrs = [])
            super
            case name
            when 'InstanceGroupIds'
              @response['InstanceGroupIds'] = []
            end
          end

          def end_element(name)
            case name
            when 'JobFlowId'
              @response[name] = value
            when 'member'
              @response['InstanceGroupIds'] << value
            end
          end
        end
      end
    end
  end
end
