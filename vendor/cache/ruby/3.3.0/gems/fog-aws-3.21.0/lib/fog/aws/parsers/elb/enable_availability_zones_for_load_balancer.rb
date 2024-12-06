module Fog
  module Parsers
    module AWS
      module ELB
        class EnableAvailabilityZonesForLoadBalancer < Fog::Parsers::Base
          def reset
            @response = { 'EnableAvailabilityZonesForLoadBalancerResult' => { 'AvailabilityZones' => [] }, 'ResponseMetadata' => {} }
          end

          def end_element(name)
            case name
            when 'member'
              @response['EnableAvailabilityZonesForLoadBalancerResult']['AvailabilityZones'] << value
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            end
          end
        end
      end
    end
  end
end
