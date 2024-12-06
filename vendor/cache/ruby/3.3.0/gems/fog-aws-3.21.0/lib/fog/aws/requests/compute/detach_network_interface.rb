module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'
        # Detaches a network interface.
        #
        # ==== Parameters
        # * attachment_id<~String> - ID of the attachment to detach
        # * force<~Boolean>        - Set to true to force a detachment
        #
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String> - Id of request
        # * 'return'<~Boolean>   - Returns true if the request succeeds.
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/2012-03-01/APIReference/ApiReference-query-DetachNetworkInterface.html]
        def detach_network_interface(attachment_id, force = false)
          request(
            'Action'       => 'DetachNetworkInterface',
            'AttachmentId' => attachment_id,
            'Force'        => force,
            :parser        => Fog::Parsers::AWS::Compute::Basic.new
          )
        end
      end

      class Mock
        def detach_network_interface(attachment_id, force = false)
          response = Excon::Response.new
          nic_id = self.data[:network_interfaces].select { |k,v| v['attachment']['attachmentId'] == attachment_id} .first.first
          if nic_id
            self.data[:network_interfaces][nic_id]["attachment"] = {}
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
