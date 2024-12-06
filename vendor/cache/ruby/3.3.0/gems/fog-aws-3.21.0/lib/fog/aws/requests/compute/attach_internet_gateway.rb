module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'
        # Attaches an Internet gateway to a VPC, enabling connectivity between the Internet and the VPC
        #
        # ==== Parameters
        # * internet_gateway_id<~String> - The ID of the Internet gateway to attach
        # * vpc_id<~String> - The ID of the VPC
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'return'<~Boolean> - Returns true if the request succeeds.
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-AttachInternetGateway.html]
        def attach_internet_gateway(internet_gateway_id, vpc_id)
          request(
            'Action'               => 'AttachInternetGateway',
            'InternetGatewayId'    => internet_gateway_id,
            'VpcId'                => vpc_id,
            :idempotent   => true,
            :parser       => Fog::Parsers::AWS::Compute::Basic.new
          )
        end
      end

      class Mock
        def attach_internet_gateway(internet_gateway_id, vpc_id)
          response = Excon::Response.new
          if internet_gateway_id && vpc_id
            response.status = 200
            response.body = {
              'requestId' => Fog::AWS::Mock.request_id,
              'return' => true
            }
            response
          else
            if !internet_gateway_id
              message << 'The request must contain the parameter internet_gateway_id'
            elsif !vpc_id
              message << 'The request must contain the parameter vpc_id'
            end
            raise Fog::AWS::Compute::Error.new(message)
          end
        end
      end
    end
  end
end
