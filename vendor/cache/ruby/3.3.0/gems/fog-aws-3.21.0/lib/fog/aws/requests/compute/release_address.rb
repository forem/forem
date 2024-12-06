module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'

        # Release an elastic IP address.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'return'<~Boolean> - success?
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-ReleaseAddress.html]
        #
        # non-VPC: requires public_ip only
        #     VPC: requires allocation_id only
        def release_address(ip_or_allocation)
          field = if ip_or_allocation.to_s =~ /^(\d|\.)+$/
                    "PublicIp"
                  else
                    "AllocationId"
                  end
          request(
            'Action'    => 'ReleaseAddress',
            field       => ip_or_allocation,
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::Basic.new
          )
        end
      end

      class Mock
        def release_address(public_ip_or_allocation_id)
          response = Excon::Response.new

          address = self.data[:addresses][public_ip_or_allocation_id] || self.data[:addresses].values.find {|a| a['allocationId'] == public_ip_or_allocation_id }

          if address
            if address['allocationId'] && public_ip_or_allocation_id == address['publicIp']
              raise Fog::AWS::Compute::Error, "InvalidParameterValue => You must specify an allocation id when releasing a VPC elastic IP address"
            end

            self.data[:addresses].delete(address['publicIp'])
            response.status = 200
            response.body = {
              'requestId' => Fog::AWS::Mock.request_id,
              'return'    => true
            }
            response
          else
            raise Fog::AWS::Compute::Error.new("AuthFailure => The address '#{public_ip_or_allocation_id}' does not belong to you.")
          end
        end
      end
    end
  end
end
