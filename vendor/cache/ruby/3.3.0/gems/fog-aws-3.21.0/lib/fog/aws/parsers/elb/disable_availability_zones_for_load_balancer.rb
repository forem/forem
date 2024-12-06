module Fog
  module Parsers
    module AWS
      module ELB
        class DisableAvailabilityZonesForLoadBalancer < Fog::Parsers::Base
          def reset
            @response = { 'DisableAvailabilityZonesForLoadBalancerResult' => { 'AvailabilityZones' => [] }, 'ResponseMetadata' => {} }
          end

          def end_element(name)
            case name
            when 'member'
              @response['DisableAvailabilityZonesForLoadBalancerResult']['AvailabilityZones'] << value
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            end
          end
        end
      end
    end
  end
end
