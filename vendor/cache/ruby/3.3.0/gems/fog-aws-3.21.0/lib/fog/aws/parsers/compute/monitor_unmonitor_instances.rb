module Fog
  module Parsers
    module AWS
      module Compute
        class MonitorUnmonitorInstances < Fog::Parsers::Base
          def reset
            @response = {}
            @instance_set = []
            @current_instance_set = {}
          end

          def end_element(name)
            case name
            when 'requestId'
              @response['requestId'] = value
            when 'instanceId'
              @current_instance_set['instanceId'] = value
            when 'item'
              @instance_set << @current_instance_set
              @current_instance_set = {}
            when 'state'
              @current_instance_set['monitoring'] = value
            when 'instancesSet'
              @response['instancesSet'] = @instance_set
            end
          end
        end
      end
    end
  end
end
