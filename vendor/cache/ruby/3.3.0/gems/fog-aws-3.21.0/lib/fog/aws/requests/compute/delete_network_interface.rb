module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'
        # Deletes a network interface.
        #
        # ==== Parameters
        # * network_interface_id<~String> - The ID of the network interface you want to delete.
        #
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String> - Id of request
        # * 'return'<~Boolean> - Returns true if the request succeeds.
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/2012-03-01/APIReference/ApiReference-query-DeleteNetworkInterface.html]
        def delete_network_interface(network_interface_id)
          request(
            'Action'             => 'DeleteNetworkInterface',
            'NetworkInterfaceId' => network_interface_id,
            :parser => Fog::Parsers::AWS::Compute::Basic.new
          )
        end
      end

      class Mock
        def delete_network_interface(network_interface_id)
          response = Excon::Response.new
          if self.data[:network_interfaces][network_interface_id]

            if self.data[:network_interfaces][network_interface_id]['attachment']['attachmentId']
              raise Fog::AWS::Compute::Error.new("Interface is in use")
            end

            self.data[:network_interfaces].delete(network_interface_id)

            response.status = 200
            response.body = {
              'requestId' => Fog::AWS::Mock.request_id,
              'return'    => true
            }
            response
          else
            raise Fog::AWS::Compute::NotFound.new("The network interface '#{network_interface_id}' does not exist")
          end
        end
      end
    end
  end
end
