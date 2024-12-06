module Fog
  module Parsers
    module AWS
      module Compute
        class DetachVolume < Fog::Parsers::Base
          def end_element(name)
            case name
            when 'attachTime'
              @response[name] = Time.parse(value)
            when 'device', 'instanceId', 'requestId', 'status', 'volumeId'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
