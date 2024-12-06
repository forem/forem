module Fog
  module Parsers
    module AWS
      module ELB
        class DeregisterInstancesFromLoadBalancer < Fog::Parsers::Base
          def reset
            @response = { 'DeregisterInstancesFromLoadBalancerResult' => { 'Instances' => [] }, 'ResponseMetadata' => {} }
          end

          def end_element(name)
            case name
            when 'InstanceId'
              @response['DeregisterInstancesFromLoadBalancerResult']['Instances'] << {name => value}
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            end
          end
        end
      end
    end
  end
end
