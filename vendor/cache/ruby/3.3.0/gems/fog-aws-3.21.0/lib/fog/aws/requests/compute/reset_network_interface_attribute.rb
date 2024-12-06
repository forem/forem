module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'

        # Resets a network interface attribute value
        #
        # ==== Parameters
        # * network_interface_id<~String> - The ID of the network interface you want to describe an attribute of
        # * attribute<~String>            - The attribute to reset, only 'sourceDestCheck' is supported.
        #
        # === Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'return'<~Boolean> - success?
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/2012-03-01/APIReference/ApiReference-query-DescribeNetworkInterfaceAttribute.html]
        def reset_network_interface_attribute(network_interface_id, attribute)
          if attribute != 'sourceDestCheck'
            raise Fog::AWS::Compute::Error.new("Illegal attribute '#{attribute}' specified")
          end
          request(
            'Action'             => 'ResetNetworkInterfaceAttribute',
            'NetworkInterfaceId' => network_interface_id,
            'Attribute'          => attribute,
            :parser              => Fog::Parsers::AWS::Compute::Basic.new
          )
        end
      end

      class Mock
        def reset_network_interface_attribute(network_interface_id, attribute)
          response = Excon::Response.new
          if self.data[:network_interfaces][network_interface_id]

            response.status = 200
            response.body = {
              'requestId' => Fog::AWS::Mock.request_id,
              'return'    => true
            }
            if attribute == 'sourceDestCheck'
              self.data[:network_interfaces][network_interface_id]['sourceDestCheck'] = true
            else
              raise Fog::AWS::Compute::Error.new("Illegal attribute '#{attribute}' specified")
            end
            response
          else
            raise Fog::AWS::Compute::NotFound.new("The network interface '#{network_interface_id}' does not exist")
          end
        end
      end
    end
  end
end
