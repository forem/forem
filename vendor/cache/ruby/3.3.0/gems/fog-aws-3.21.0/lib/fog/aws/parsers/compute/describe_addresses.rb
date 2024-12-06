module Fog
  module Parsers
    module AWS
      module Compute
        class DescribeAddresses < Fog::Parsers::Base
          def reset
            @response = { 'addressesSet' => [] }
            @address = {'tagSet' => {}}
            @tag = {}
          end

          def start_element(name, attrs = [])
            super
            if name == 'tagSet'
              @in_tag_set = true
            end
          end

          def end_element(name)
            if @in_tag_set
              case name
              when 'item'
                @address['tagSet'][@tag['key']] = @tag['value']
                @tag = {}
              when 'key', 'value'
                @tag[name] = value
              when 'tagSet'
                @in_tag_set = false
              end
            else
              case name
              when 'instanceId', 'publicIp', 'domain', 'allocationId', 'associationId', 'networkInterfaceId', 'networkInterfaceOwnerId', 'privateIpAddress'
                @address[name] = value
              when 'item'
                @response['addressesSet'] << @address
                @address = { 'tagSet' => {} }
              when 'requestId'
                @response[name] = value
              end

            end
          end
        end
      end
    end
  end
end
