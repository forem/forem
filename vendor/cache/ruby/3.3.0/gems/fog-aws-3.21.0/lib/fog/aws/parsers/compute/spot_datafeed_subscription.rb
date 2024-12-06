module Fog
  module Parsers
    module AWS
      module Compute
        class SpotDatafeedSubscription < Fog::Parsers::Base
          def reset
            @response = { 'spotDatafeedSubscription' => {} }
          end

          def end_element(name)
            case name
            when 'bucket', 'ownerId', 'prefix', 'state'
              @response['spotDatafeedSubscription'][name] = value
            when 'code', 'message'
              @response['spotDatafeedSubscription']['fault'] ||= {}
              @response['spotDatafeedSubscription'][name] = value
            when 'requestId'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
