module Fog
  module Parsers
    module AWS
      module ELB
        class AttachLoadBalancerToSubnets < Fog::Parsers::Base
          def reset
            @response = { 'AttachLoadBalancerToSubnetsResult' => { 'Subnets' => [] }, 'ResponseMetadata' => {} }
          end

          def end_element(name)
            case name
            when 'member'
              @response['AttachLoadBalancerToSubnetsResult']['Subnets'] << value
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            end
          end
        end
      end
    end
  end
end
