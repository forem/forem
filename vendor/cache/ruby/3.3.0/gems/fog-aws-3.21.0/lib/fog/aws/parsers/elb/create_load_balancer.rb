module Fog
  module Parsers
    module AWS
      module ELB
        class CreateLoadBalancer < Fog::Parsers::Base
          def reset
            @response = { 'CreateLoadBalancerResult' => {}, 'ResponseMetadata' => {} }
          end

          def end_element(name)
            case name
            when 'DNSName'
              @response['CreateLoadBalancerResult'][name] = value
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            end
          end
        end
      end
    end
  end
end
