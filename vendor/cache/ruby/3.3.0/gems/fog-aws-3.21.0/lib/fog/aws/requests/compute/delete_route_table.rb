module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'

        # Deletes the specified route table.
        #
        # ==== Parameters
        # * RouteTableId<~String> - The ID of the route table.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - The ID of request.
        #     * 'return'<~Boolean> - Returns true if the request succeeds. Otherwise, returns an error.
        #
        # {Amazon API Reference}[http://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-DeleteRouteTable.html]
        def delete_route_table(route_table_id)
          request(
            'Action'    => 'DeleteRouteTable',
            'RouteTableId'  => route_table_id,
            :parser     => Fog::Parsers::AWS::Compute::Basic.new
          )
        end
      end

      class Mock
        def delete_route_table(route_table_id)
          route_table = self.data[:route_tables].find { |routetable| routetable["routeTableId"].eql? route_table_id }
          if !route_table.nil? && route_table['associationSet'].empty?
            self.data[:route_tables].delete(route_table)
              response = Excon::Response.new
              response.status = 200
              response.body = {
                'requestId'=> Fog::AWS::Mock.request_id,
                'return' => true
              }
              response
          elsif route_table.nil?
            raise Fog::AWS::Compute::NotFound.new("The routeTable ID '#{route_table_id}' does not exist")
          elsif !route_table['associationSet'].empty?
            raise Fog::AWS::Compute::Error, "DependencyViolation => The routeTable '#{route_table_id}' has dependencies and cannot be deleted."
          end
        end
      end
    end
  end
end
