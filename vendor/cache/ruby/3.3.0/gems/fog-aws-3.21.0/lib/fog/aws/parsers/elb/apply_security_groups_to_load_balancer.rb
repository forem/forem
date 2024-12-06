module Fog
  module Parsers
    module AWS
      module ELB
        class ApplySecurityGroupsToLoadBalancer < Fog::Parsers::Base
          def reset
            @response = { 'ApplySecurityGroupsToLoadBalancerResult' => { 'SecurityGroups' => [] }, 'ResponseMetadata' => {} }
          end

          def end_element(name)
            case name
            when 'member'
              @response['ApplySecurityGroupsToLoadBalancerResult']['SecurityGroups'] << value
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            end
          end
        end
      end
    end
  end
end
