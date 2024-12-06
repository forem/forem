module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/restore_address_to_classic'

        # Move address from VPC to Classic
        #
        # === Returns
        # * response<~Excon::Response>:
        #   * body<~<Hash>:
        #     * 'publicIp'<~String> - IP address
        #     * 'requestId'<~String> - Id of the request
        #     * 'status'<~String> - The status of the move of the IP address (MoveInProgress | InVpc | InClassic)

        def restore_address_to_classic(public_ip)
          request(
            'Action' => 'RestoreAddressToClassic',
            'PublicIp' => public_ip,
            :idempotent => true,
            :parser => Fog::Parsers::AWS::Compute::RestoreAddressToClassic.new
          )
        end
      end

      class Mock
        def restore_address_to_classic(public_ip)
          response      = Excon::Response.new

          address = self.data[:addresses][public_ip]

          if address
            if address[:origin] == 'vpc'
              raise Fog::AWS::Compute::Error.new("InvalidState => You cannot migrate an Elastic IP address that was originally allocated for use in EC2-VPC to EC2-Classic.")
            end

            address['domain']       = 'standard'
            address.delete("allocationId")

            response.status = 200
            response.body = {
              'requestId' => Fog::AWS::Mock.request_id,
              'publicIp'  => public_ip,
              'status'    => "InClassic"
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
