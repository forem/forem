module Fog
  module Parsers
    module AWS
      module Compute
        require 'fog/aws/parsers/compute/network_acl_parser'

        class CreateNetworkAcl < NetworkAclParser
          def reset
            super
            @response = { 'networkAcl' => {} }
          end

          def end_element(name)
            case name
            when 'requestId'
              @response[name] = value
            when 'networkAcl'
              @response['networkAcl'] = @network_acl
              reset_nacl
            else
              super
            end
          end
        end
      end
    end
  end
end
