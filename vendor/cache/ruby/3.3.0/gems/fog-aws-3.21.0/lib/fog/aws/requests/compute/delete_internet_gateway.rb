module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'
        #Deletes an Internet gateway from your AWS account. The gateway must not be attached to a VPC
        #
        # ==== Parameters
        # * internet_gateway_id<~String> - The ID of the InternetGateway you want to delete.
        #
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String> - Id of request
        # * 'return'<~Boolean> - Returns true if the request succeeds.
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteInternetGateway.html]
        def delete_internet_gateway(internet_gateway_id)
          request(
            'Action' => 'DeleteInternetGateway',
            'InternetGatewayId' => internet_gateway_id,
            :parser => Fog::Parsers::AWS::Compute::Basic.new
          )
        end
      end

      class Mock
        def delete_internet_gateway(internet_gateway_id)
          Excon::Response.new.tap do |response|
            if internet_gateway_id
              response.status = 200
              self.data[:internet_gateways].delete(internet_gateway_id)

              response.body = {
                'requestId' => Fog::AWS::Mock.request_id,
                'return' => true
              }
            else
              message = 'MissingParameter => '
              message << 'The request must contain the parameter internet_gateway_id'
              raise Fog::AWS::Compute::Error.new(message)
            end
          end
        end
      end
    end
  end
end
