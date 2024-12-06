module Fog
  module Parsers
    module AWS
      module Compute
        require 'fog/aws/parsers/compute/network_acl_parser'

        class DescribeNetworkAcls < NetworkAclParser
          def reset
            super
            @response = { 'networkAclSet' => [] }
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
                @response['networkAclSet'] << @network_acl
                reset_nacl
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
