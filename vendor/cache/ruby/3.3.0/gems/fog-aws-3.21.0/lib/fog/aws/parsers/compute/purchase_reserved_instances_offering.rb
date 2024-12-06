module Fog
  module Parsers
    module AWS
      module Compute
        class PurchaseReservedInstancesOffering < Fog::Parsers::Base
          def reset
            @response = {}
          end

          def end_element(name)
            case name
            when 'reservedInstancesId', 'requestId'
              @response[name] = value
            end
          end
        end
      end
    end
  end
end
