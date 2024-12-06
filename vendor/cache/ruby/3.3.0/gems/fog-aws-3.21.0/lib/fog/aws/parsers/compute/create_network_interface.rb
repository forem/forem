module Fog
  module Parsers
    module AWS
      module Compute
        require 'fog/aws/parsers/compute/network_interface_parser'

        class CreateNetworkInterface < NetworkInterfaceParser
          def reset
            super
            @response = { 'networkInterface' => {} }
          end

          def end_element(name)
            case name
            when 'requestId'
              @response[name] = value
            when 'networkInterface'
              @response['networkInterface'] = @nic
              reset_nic
            else
              super
            end
          end
        end
      end
    end
  end
end
