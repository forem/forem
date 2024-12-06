module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/associate_route_table'
        # Associates a subnet with a route table.
        #
        # ==== Parameters
        # * RouteTableId<~String> - The ID of the route table
        # * SubnetId<~String> - The ID of the subnet
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - The ID of the request
        #     * 'associationId'<~String> - The route table association ID (needed to disassociate the route table)
        #
        # {Amazon API Reference}[http://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-AssociateRouteTable.html]
        def associate_route_table(routeTableId, subnetId)
          request(
            'Action'       => 'AssociateRouteTable',
            'RouteTableId' => routeTableId,
            'SubnetId'     => subnetId,
            :parser        => Fog::Parsers::AWS::Compute::AssociateRouteTable.new
          )
        end
      end

      class Mock
        def associate_route_table(routeTableId, subnetId)
          routetable = self.data[:route_tables].find { |routetable| routetable["routeTableId"].eql? routeTableId }
          subnet = self.data[:subnets].find { |subnet| subnet["subnetId"].eql? subnetId }

          if !routetable.nil? && !subnet.nil?
            response = Excon::Response.new
            response.status = 200
            association = add_route_association(routeTableId, subnetId)
            routetable["associationSet"].push(association)
            response.body = {
                'requestId'     => Fog::AWS::Mock.request_id,
                'associationId' => association['routeTableAssociationId']
            }
            response
          elsif routetable.nil?
            raise Fog::AWS::Compute::NotFound.new("The routeTable ID '#{routeTableId}' does not exist")
          else
            raise Fog::AWS::Compute::NotFound.new("The subnet ID '#{subnetId}' does not exist")
          end
        end

        private

        def add_route_association(routeTableId, subnetId, main=nil)
          response = {
              "routeTableAssociationId" => "rtbassoc-#{Fog::Mock.random_hex(8)}",
              "routeTableId" => routeTableId,
              "subnetId" => nil,
              "main" => false
            }
          if main
            response['main'] = true
          else
            response['subnetId'] = subnetId
          end
          response
        end
      end
    end
  end
end
