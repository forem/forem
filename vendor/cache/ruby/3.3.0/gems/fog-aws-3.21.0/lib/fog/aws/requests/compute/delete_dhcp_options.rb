module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'
        #Deletes a set of DHCP options that you specify. Amazon VPC returns an error if the set of options you specify is currently
        #associated with a VPC. You can disassociate the set of options by associating either a new set of options or the default
        #options with the VPC.
        #
        # ==== Parameters
        # * dhcp_options_id<~String> - The ID of the DHCP options set you want to delete.
        #
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String> - Id of request
        # * 'return'<~Boolean> - Returns true if the request succeeds.
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteDhcpOptions.html]
        def delete_dhcp_options(dhcp_options_id)
          request(
            'Action' => 'DeleteDhcpOptions',
            'DhcpOptionsId' => dhcp_options_id,
            :parser => Fog::Parsers::AWS::Compute::Basic.new
          )
        end
      end

      class Mock
        def delete_dhcp_options(dhcp_options_id)
          Excon::Response.new.tap do |response|
            if dhcp_options_id
              response.status = 200
              self.data[:dhcp_options].reject! { |v| v['dhcpOptionsId'] == dhcp_options_id }

              response.body = {
                'requestId' => Fog::AWS::Mock.request_id,
                'return' => true
              }
            else
              message = 'MissingParameter => '
              message << 'The request must contain the parameter dhcp_options_id'
              raise Fog::AWS::Compute::Error.new(message)
            end
          end
        end
      end
    end
  end
end
