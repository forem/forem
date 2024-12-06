module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/create_internet_gateway'

        # Creates an InternetGateway
        #
        # ==== Parameters
        # (none)
        #
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String> - Id of request
        # * 'internetGateway'<~Array>:
        # *   'attachmentSet'<~Array>: 	A list of VPCs attached to the Internet gateway
        # *     'vpcId'<~String> - The ID of the VPC the Internet gateway is attached to.
        # *     'state'<~String> - The current state of the attachment.
        # *   'tagSet'<~Array>: Tags assigned to the resource.
        # *     'key'<~String> - Tag's key
        # *     'value'<~String> - Tag's value
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-ItemType-InternetGatewayAttachmentType.html]
        def create_internet_gateway()
          request({
            'Action'     => 'CreateInternetGateway',
            :parser      => Fog::Parsers::AWS::Compute::CreateInternetGateway.new
          })
        end
      end

      class Mock
        def create_internet_gateway()
          gateway_id = Fog::AWS::Mock.internet_gateway_id
        self.data[:internet_gateways][gateway_id] = {
          'internetGatewayId' => gateway_id,
          'attachmentSet'     => {},
          'tagSet'            => {}
        }
         Excon::Response.new(
            :status => 200,
            :body   => {
              'requestId' => Fog::AWS::Mock.request_id,
              'internetGatewaySet' => [self.data[:internet_gateways][gateway_id]]
            }
          )
        end
      end
    end
  end
end
