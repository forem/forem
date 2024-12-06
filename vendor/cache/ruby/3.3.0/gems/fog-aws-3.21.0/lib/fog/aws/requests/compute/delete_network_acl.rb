module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'

        # Deletes a network ACL.
        #
        # ==== Parameters
        # * network_acl_id<~String> - The ID of the network ACL you want to delete.
        #
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String> - Id of request
        # * 'return'<~Boolean> - Returns true if the request succeeds.
        #
        # {Amazon API Reference}[http://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteNetworkAcl.html]
        def delete_network_acl(network_acl_id)
          request(
            'Action'       => 'DeleteNetworkAcl',
            'NetworkAclId' => network_acl_id,
            :parser        => Fog::Parsers::AWS::Compute::Basic.new
          )
        end
      end

      class Mock
        def delete_network_acl(network_acl_id)
          response = Excon::Response.new
          if self.data[:network_acls][network_acl_id]

            if self.data[:network_acls][network_acl_id]['associationSet'].any?
              raise Fog::AWS::Compute::Error.new("ACL is in use")
            end

            self.data[:network_acls].delete(network_acl_id)

            response.status = 200
            response.body = {
              'requestId' => Fog::AWS::Mock.request_id,
              'return'    => true
            }
            response
          else
            raise Fog::AWS::Compute::NotFound.new("The network ACL '#{network_acl_id}' does not exist")
          end
        end
      end
    end
  end
end
