module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'
        #
        #
        # ==== Parameters
        # * dhcp_options_id<~String> - The ID of the DHCP options you want to associate with the VPC, or "default" if you want the VPC
        #   to use no DHCP options.
        # * vpc_id<~String> - The ID of the VPC
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'return'<~Boolean> - Returns true if the request succeeds.
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-AssociateDhcpOptions.html]
        def associate_dhcp_options(dhcp_options_id, vpc_id)
          request(
            'Action'               => 'AssociateDhcpOptions',
            'DhcpOptionsId'        => dhcp_options_id,
            'VpcId'                => vpc_id,
            :idempotent   => true,
            :parser       => Fog::Parsers::AWS::Compute::Basic.new
          )
        end
      end

      class Mock
        def associate_dhcp_options(dhcp_options_id, vpc_id)
          response = Excon::Response.new
          if dhcp_options_id && vpc_id
            response.status = 200
            response.body = {
              'requestId' => Fog::AWS::Mock.request_id,
              'return' => true
            }
            response
          else
            if !dhcp_options_id
              message << 'The request must contain the parameter dhcp_options_id'
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
