module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/describe_route_tables'

        # Describe one or more of your route tables.
        #
        # ==== Parameters
        # * RouteTableId<~String> - One or more route table IDs.
        # * filters<~Hash> - List of filters to limit results with
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - The ID of the request.
        #     * 'routeTableSet'<~Array>:
        #       * 'routeTableId'<~String> - The route table's ID.
        #       * 'vpcId'<~String> - The ID of the VPC for the route table.
        #       * 'routeSet'<~Array>:
        #         * 'destinationCidrBlock'<~String> - The CIDR address block used for the destination match.
        #         * 'gatewayId'<~String> - The ID of a gateway attached to your VPC.
        #         * 'instanceId'<~String> - The ID of a NAT instance in your VPC.
        #         * 'instanceOwnerId'<~String> - The owner of the instance.
        #         * 'networkInterfaceId'<~String> - The network interface ID.
        #         * 'vpcPeeringConnectionId'<~String> - The peering connection ID.
        #         * 'natGatewayId'<~String> - The ID of a NAT gateway attached to your VPC.
        #         * 'state'<~String> - The state of the route. The blackhole state indicates that the route's target isn't available.
        #         * 'origin'<~String> - Describes how the route was created.
        #       * 'associationSet'<~Array>:
        #         * 'RouteTableAssociationId'<~String> - An identifier representing the association between a route table and a subnet.
        #         * 'routeTableId'<~String> - The ID of the route table.
        #         * 'subnetId'<~String> - The ID of the subnet.
        #         * 'main'<~Boolean> - Indicates whether this is the main route table.
        #       * 'propagatingVgwSet'<~Array>:
        #         * 'gatewayID'<~String> - The ID of the virtual private gateway (VGW).
        #       * 'tagSet'<~Array>:
        #         * 'key'<~String> - The tag key.
        #         * 'value'<~String> - The tag value.
        #
        # {Amazon API Reference}[http://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeRouteTables.html]
        def describe_route_tables(filters = {})
          unless filters.is_a?(Hash)
            Fog::Logger.deprecation("describe_route_tables with #{filters.class} param is deprecated, use describe_route_tables('route-table-id' => []) instead [light_black](#{caller.first})[/]")
            filters = {'route-table-id' => [*filters]}
          end
          params = Fog::AWS.indexed_filters(filters)
          request({
            'Action'    => 'DescribeRouteTables',
            :parser     => Fog::Parsers::AWS::Compute::DescribeRouteTables.new
          }.merge!(params))
        end
      end

      class Mock
        def describe_route_tables(filters = {})
          unless filters.is_a?(Hash)
            Fog::Logger.deprecation("describe_route_tables with #{filters.class} param is deprecated, use describe_route_tables('route-table-id' => []) instead [light_black](#{caller.first})[/]")
            filters = {'route-table-id' => [*filters]}
          end

          display_routes = self.data[:route_tables].dup

          aliases = {
            'route-table-id'  => 'routeTableId',
            'vpc-id'          => 'vpcId'
          }

          for filter_key, filter_value in filters
            filter_attribute = aliases[filter_key]
            case filter_attribute
            when 'routeTableId', 'vpcId'
              display_routes.reject! { |routetable| routetable[filter_attribute] != filter_value }
            end
          end

          display_routes.each do |route|
            tags = self.data[:tag_sets][route['routeTableId']]
            route.merge!('tagSet' => tags) if tags
          end

          Excon::Response.new(
            :status => 200,
            :body   => {
              'requestId' => Fog::AWS::Mock.request_id,
              'routeTableSet'    => display_routes
            }
          )
        end
      end
    end
  end
end
