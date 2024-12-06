module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'

        # Replaces a route in a route table within a VPC.
        #
        # ==== Parameters
        # * RouteTableId<~String> - The ID of the route table for the route.
        # * options<~Hash>:
        #   * DestinationCidrBlock<~String> - The CIDR address block used for the destination match. Routing decisions are based on the most specific match.
        #   * GatewayId<~String> - The ID of an Internet gateway attached to your VPC.
        #   * InstanceId<~String> - The ID of a NAT instance in your VPC. The operation fails if you specify an instance ID unless exactly one network interface is attached.
        #   * NetworkInterfaceId<~String> - The ID of a network interface.
        #
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String> - Id of the request
        # * 'return'<~Boolean> - Returns true if the request succeeds. Otherwise, returns an error.
        #
        # {Amazon API Reference}[http://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-ReplaceRoute.html]
        def replace_route(route_table_id, destination_cidr_block, options = {})
          options['DestinationCidrBlock'] ||= destination_cidr_block

          request({
            'Action' => 'ReplaceRoute',
            'RouteTableId' => route_table_id,
            :idempotent => true,
            :parser => Fog::Parsers::AWS::Compute::Basic.new
          }.merge!(options))
        end
      end

      class Mock
        def replace_route(route_table_id, destination_cidr_block, options = {})
          options['instanceOwnerId'] ||= nil
          options['DestinationCidrBlock'] ||= destination_cidr_block

          route_table = self.data[:route_tables].find { |routetable| routetable["routeTableId"].eql? route_table_id }
          if !route_table.nil? && destination_cidr_block
            if !options['gatewayId'].nil? || !options['instanceId'].nil? || !options['networkInterfaceId'].nil?
              if !options['gatewayId'].nil? && self.internet_gateways.all('internet-gateway-id'=>options['gatewayId']).first.nil?
                raise Fog::AWS::Compute::NotFound.new("The gateway ID '#{options['gatewayId']}' does not exist")
              elsif !options['instanceId'].nil? && self.servers.all('instance-id'=>options['instanceId']).first.nil?
                raise Fog::AWS::Compute::NotFound.new("The instance ID '#{options['instanceId']}' does not exist")
              elsif !options['networkInterfaceId'].nil? && self.network_interfaces.all('networkInterfaceId'=>options['networkInterfaceId']).first.nil?
                raise Fog::AWS::Compute::NotFound.new("The networkInterface ID '#{options['networkInterfaceId']}' does not exist")
              elsif route_table['routeSet'].find { |route| route['destinationCidrBlock'].eql? destination_cidr_block }.nil?
                raise Fog::AWS::Compute::Error, "RouteAlreadyExists => The route identified by #{destination_cidr_block} doesn't exist."
              else
                response = Excon::Response.new
                route_set = route_table['routeSet'].find { |routeset| routeset['destinationCidrBlock'].eql? destination_cidr_block }
                route_set.merge!(options)
                route_set['state'] = 'pending'
                route_set['origin'] = 'ReplaceRoute'

                response.status = 200
                response.body = {
                  'requestId'=> Fog::AWS::Mock.request_id,
                  'return' => true
                }
                response
              end
            else
              message = 'MissingParameter => '
              message << 'The request must contain either a gateway id, a network interface id, or an instance id'
              raise Fog::AWS::Compute::Error.new(message)
            end
          elsif route_table.nil?
            raise Fog::AWS::Compute::NotFound.new("The routeTable ID '#{route_table_id}' does not exist")
          elsif destination_cidr_block.empty?
            raise Fog::AWS::Compute::InvalidParameterValue.new("Value () for parameter destinationCidrBlock is invalid. This is not a valid CIDR block.")
          end
        end
      end
    end
  end
end
