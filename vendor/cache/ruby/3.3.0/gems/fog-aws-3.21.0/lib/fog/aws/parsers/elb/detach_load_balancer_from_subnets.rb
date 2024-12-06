module Fog
  module Parsers
    module AWS
      module ELB
        class DetachLoadBalancerFromSubnets < Fog::Parsers::Base
          def reset
            @response = { 'DetachLoadBalancerFromSubnetsResult' => { 'Subnets' => [] }, 'ResponseMetadata' => {} }
          end

          def end_element(name)
            case name
            when 'member'
              @response['DetachLoadBalancerFromSubnetsResult']['Subnets'] << value
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            end
          end
        end
      end
    end
  end
end
