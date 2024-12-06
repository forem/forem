module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/assign_private_ip_addresses'

        # Assigns one or more secondary private IP addresses to the specified network interface.
        #
        # ==== Parameters
        # * NetworkInterfaceId<~String> - The ID of the network interface
        # * PrivateIpAddresses<~Array> - One or more IP addresses to be assigned as a secondary private IP address (conditional)
        # * SecondaryPrivateIpAddressCount<~String> - The number of secondary IP addresses to assign (conditional)
        # * AllowReassignment<~Boolean> - Whether to reassign an IP address
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - The ID of the request.
        #     * 'return'<~Boolean> - success?
        #
        # {Amazon API Reference}[http://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-AssignPrivateIpAddresses.html]
        def assign_private_ip_addresses(network_interface_id, options={})
          if options['PrivateIpAddresses'] && options['SecondaryPrivateIpAddressCount']
            raise Fog::AWS::Compute::Error.new("You may specify secondaryPrivateIpAddressCount or specific secondary private IP addresses, but not both.")
          end

          if private_ip_addresses = options.delete('PrivateIpAddresses')
            options.merge!(Fog::AWS.indexed_param('PrivateIpAddress.%d', [*private_ip_addresses]))
          end

          request({
            'Action'  => 'AssignPrivateIpAddresses',
            'NetworkInterfaceId' => network_interface_id,
            :parser   => Fog::Parsers::AWS::Compute::AssignPrivateIpAddresses.new
          }.merge(options))
        end
      end

      class Mock
        def assign_private_ip_addresses(network_interface_id, options={})
          if options['PrivateIpAddresses'] && options['SecondaryPrivateIpAddressCount']
            raise Fog::AWS::Compute::Error.new("You may specify secondaryPrivateIpAddressCount or specific secondary private IP addresses, but not both.")
          end

          response = Excon::Response.new
          response.status = 200
          response.body = {
            'requestId' => Fog::AWS::Mock.request_id,
            'return' => true
          }
          response
        end
      end
    end
  end
end
