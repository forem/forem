module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'

        # Deletes the specified route from the specified route table.
        #
        # ==== Parameters
        # * RouteTableId<~String> - The ID of the route table.
        # * DestinationCidrBlock<~String> - The CIDR range for the route. The value you specify must match the CIDR for the route exactly.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - The ID of the request.
        #     * 'return'<~Boolean> - Returns true if the request succeeds. Otherwise, returns an error.
        #
        # {Amazon API Reference}[http://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteRoute.html]
        def delete_route(route_table_id, destination_cidr_block)
          request(
            'Action'                => 'DeleteRoute',
            'RouteTableId'          => route_table_id,
            'DestinationCidrBlock'  => destination_cidr_block,
            :parser                 => Fog::Parsers::AWS::Compute::Basic.new
          )
        end
      end

      class Mock
        def delete_route(route_table_id, destination_cidr_block)
          route_table = self.data[:route_tables].find { |routetable| routetable["routeTableId"].eql? route_table_id }
          unless route_table.nil?
            route = route_table['routeSet'].find { |route| route["destinationCidrBlock"].eql? destination_cidr_block }
            if !route.nil? && route['gatewayId'] != "local"
              route_table['routeSet'].delete(route)
              response = Excon::Response.new
              response.status = 200
              response.body = {
                'requestId'=> Fog::AWS::Mock.request_id,
                'return' => true
              }
              response
            elsif route['gatewayId'] == "local"
              # Cannot delete the default route
              raise Fog::AWS::Compute::Error, "InvalidParameterValue => cannot remove local route #{destination_cidr_block} in route table #{route_table_id}"
            else
              raise Fog::AWS::Compute::NotFound.new("no route with destination-cidr-block #{destination_cidr_block} in route table #{route_table_id}")
            end
          else
            raise Fog::AWS::Compute::NotFound.new("no route with destination-cidr-block #{destination_cidr_block} in route table #{route_table_id}")
          end
        end
      end
    end
  end
end
