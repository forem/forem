module Fog
  module Parsers
    module AWS
      module Compute
        require 'fog/aws/parsers/compute/network_interface_parser'

        class DescribeNetworkInterfaces < NetworkInterfaceParser
          def reset
            super
            @response = { 'networkInterfaceSet' => [] }
            @item_level = 0
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'item'
              @item_level += 1
            end
          end

          def end_element(name)
            case name
            when 'requestId'
              @response[name] = value
            when 'item'
              @item_level -= 1
              if @item_level == 0
                @response['networkInterfaceSet'] << @nic
                reset_nic
              else
                super
              end
            else
              super
            end
          end
        end
      end
    end
  end
end
