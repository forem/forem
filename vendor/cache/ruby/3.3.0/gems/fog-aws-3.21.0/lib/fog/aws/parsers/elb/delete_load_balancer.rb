module Fog
  module Parsers
    module AWS
      module ELB
        class DeleteLoadBalancer < Fog::Parsers::Base
          def reset
            @response = { 'DeleteLoadBalancerResult' => nil, 'ResponseMetadata' => {} }
          end

          def end_element(name)
            case name
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            end
          end
        end
      end
    end
  end
end
