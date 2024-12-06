module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/allocate_address'

        # Acquire an elastic IP address.
        #
        # ==== Parameters
        # * domain<~String> - Type of EIP, either standard or vpc
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'publicIp'<~String> - The acquired address
        #     * 'requestId'<~String> - Id of the request
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-AllocateAddress.html]
        def allocate_address(domain='standard')
          domain = domain == 'vpc' ? 'vpc' : 'standard'
          request(
            'Action'  => 'AllocateAddress',
            'Domain'  => domain,
            :parser   => Fog::Parsers::AWS::Compute::AllocateAddress.new
          )
        end
      end

      class Mock
        def allocate_address(domain = 'standard')
          unless describe_addresses.body['addressesSet'].size < self.data[:limits][:addresses]
            raise Fog::AWS::Compute::Error, "AddressLimitExceeded => Too many addresses allocated"
          end

          response = Excon::Response.new
          response.status = 200

          domain    = domain == 'vpc' ? 'vpc' : 'standard'
          public_ip = Fog::AWS::Mock.ip_address

          data = {
            'instanceId' => nil,
            'publicIp'   => public_ip,
            'domain'     => domain,
            :origin      => domain
          }

          if domain == 'vpc'
            data['allocationId'] = "eipalloc-#{Fog::Mock.random_hex(8)}"
          end

          self.data[:addresses][public_ip] = data
          response.body = data.reject {|k, v| k == 'instanceId' }.merge('requestId' => Fog::AWS::Mock.request_id)
          response
        end
      end
    end
  end
end
