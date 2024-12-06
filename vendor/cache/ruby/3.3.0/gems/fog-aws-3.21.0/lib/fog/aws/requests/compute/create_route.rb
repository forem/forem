module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'

        # Creates a route in a route table within a VPC.
        #
        # ==== Parameters
        # * RouteTableId<~String> - The ID of the route table for the route.
        # * DestinationCidrBlock<~String> - The CIDR address block used for the destination match. Routing decisions are based on the most specific match.
        # * GatewayId<~String> - The ID of an Internet gateway attached to your VPC.
        # * InstanceId<~String> - The ID of a NAT instance in your VPC. The operation fails if you specify an instance ID unless exactly one network interface is attached.
        # * NetworkInterfaceId<~String> - The ID of a network interface.
        #
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String> - Id of the request
        # * 'return'<~Boolean> - Returns true if the request succeeds. Otherwise, returns an error.
        #
        # {Amazon API Reference}[http://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-CreateRoute.html]
        def create_route(route_table_id, destination_cidr_block, internet_gateway_id=nil, instance_id=nil, network_interface_id=nil)
          request_vars = {
            'Action'                => 'CreateRoute',
            'RouteTableId'          => route_table_id,
            'DestinationCidrBlock'  => destination_cidr_block,
            :parser                 => Fog::Parsers::AWS::Compute::Basic.new
          }
          if internet_gateway_id
            request_vars['GatewayId'] = internet_gateway_id
          elsif instance_id
            request_vars['InstanceId'] = instance_id
          elsif network_interface_id
            request_vars['NetworkInterfaceId'] = network_interface_id
          end
          request(request_vars)
        end
      end

      class Mock
        def create_route(route_table_id, destination_cidr_block, internet_gateway_id=nil, instance_id=nil, network_interface_id=nil)
          instance_owner_id = nil
          route_table = self.data[:route_tables].find { |routetable| routetable["routeTableId"].eql? route_table_id }
          if !route_table.nil? && destination_cidr_block
            if !internet_gateway_id.nil? || !instance_id.nil? || !network_interface_id.nil?
              if !internet_gateway_id.nil? && self.internet_gateways.all('internet-gateway-id'=>internet_gateway_id).first.nil?
                raise Fog::AWS::Compute::NotFound.new("The gateway ID '#{internet_gateway_id}' does not exist")
              elsif !instance_id.nil? && self.servers.all('instance-id'=>instance_id).first.nil?
                raise Fog::AWS::Compute::NotFound.new("The instance ID '#{instance_id}' does not exist")
              elsif !network_interface_id.nil? && self.network_interfaces.all('networkInterfaceId'=>network_interface_id).first.nil?
                raise Fog::AWS::Compute::NotFound.new("The networkInterface ID '#{network_interface_id}' does not exist")
              elsif !route_table['routeSet'].find { |route| route['destinationCidrBlock'].eql? destination_cidr_block }.nil?
                raise Fog::AWS::Compute::Error, "RouteAlreadyExists => The route identified by #{destination_cidr_block} already exists."
              else
                response = Excon::Response.new
                route_table['routeSet'].push({
                  "destinationCidrBlock" => destination_cidr_block,
                  "gatewayId" => internet_gateway_id,
                  "instanceId"=>instance_id,
                  "instanceOwnerId"=>instance_owner_id,
                  "networkInterfaceId"=>network_interface_id,
                  "state" => "pending",
                  "origin" => "CreateRoute"
                })
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
