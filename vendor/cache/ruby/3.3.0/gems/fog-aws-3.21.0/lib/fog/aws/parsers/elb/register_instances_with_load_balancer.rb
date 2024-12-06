module Fog
  module Parsers
    module AWS
      module ELB
        class RegisterInstancesWithLoadBalancer < Fog::Parsers::Base
          def reset
            @response = { 'RegisterInstancesWithLoadBalancerResult' => { 'Instances' => [] }, 'ResponseMetadata' => {} }
          end

          def end_element(name)
            case name
            when 'InstanceId'
              @response['RegisterInstancesWithLoadBalancerResult']['Instances'] << {name => value}
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            end
          end
        end
      end
    end
  end
end
