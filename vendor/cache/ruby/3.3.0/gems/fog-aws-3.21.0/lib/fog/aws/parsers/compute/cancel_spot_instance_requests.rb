module Fog
  module Parsers
    module AWS
      module Compute
        class CancelSpotInstanceRequests < Fog::Parsers::Base
          def reset
            @spot_instance_request = {}
            @response = { 'spotInstanceRequestSet' => [] }
          end

          def end_element(name)
            case name
            when 'item'
              @response['spotInstanceRequestSet'] << @spot_instance_request
              @spot_instance_request = {}
            when 'requestId'
              @response[name] = value
            when 'spotInstanceRequestId', 'state'
              @spot_instance_request[name] = value
            end
          end
        end
      end
    end
  end
end
