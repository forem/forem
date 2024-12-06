module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/move_address_to_vpc'

        # Move address to VPC scope
        #
        # === Returns
        # * response<~Excon::Response>:
        #   * body<~<Hash>:
        #     * 'allocationId'<~String> - The allocation ID for the Elastic IP address
        #     * 'requestId'<~String> - Id of the request
        #     * 'status'<~String> - The status of the move of the IP address (MoveInProgress | InVpc | InClassic)

        def move_address_to_vpc(public_ip)
          request(
            'Action' => 'MoveAddressToVpc',
            'PublicIp' => public_ip,
            :idempotent => true,
            :parser => Fog::Parsers::AWS::Compute::MoveAddressToVpc.new
          )
        end
      end

      class Mock
        def move_address_to_vpc(public_ip)
          response      = Excon::Response.new
          allocation_id = "eip-#{Fog::Mock.random_hex(8)}"

          address = self.data[:addresses][public_ip]

          if address
            address['domain']       = 'vpc'
            address['allocationId'] = allocation_id

            response.status = 200
            response.body = {
              'requestId'    => Fog::AWS::Mock.request_id,
              'allocationId' => allocation_id,
              'status'       => "InVpc"
            }

            response
          else
            raise Fog::AWS::Compute::NotFound.new("Address does not exist")
          end
        end
      end
    end
  end
end
