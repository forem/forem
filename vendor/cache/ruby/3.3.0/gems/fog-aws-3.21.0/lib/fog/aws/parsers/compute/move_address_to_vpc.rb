module Fog
  module Parsers
    module AWS
      module Compute
        class MoveAddressToVpc < Fog::Parsers::Base
          def end_element(name)
            case name
            when 'requestId', 'allocationId', 'status'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
