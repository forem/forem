module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/create_route_table'

        # Creates a route table for the specified VPC.
        #
        # ==== Parameters
        # * VpcId<~String> - The ID of the VPC.
        #
        # === Returns
        # * response<~Excon::Response>:
        # * body<~Hash>:
        # * 'requestId'<~String> - Id of the request
        # * 'routeTable'<~Array> - Information about the newly created route table
        # *   'routeTableId'<~String>
        # *   'vpcId'<~String>
        # *   'routeSet'<~Array>
        # *     'item'<~Array>
        # *       'destinationCidrBlock'<~String> - The CIDR address block used for the destination match.
        # *       'gatewayId'<~String> - The ID of an Internet gateway attached to your VPC.
        # *       'state'<~String> - The state of the route. ['blackhole', 'available']
        #
        # {Amazon API Reference}[http://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-CreateRouteTable.html]
        def create_route_table(vpc_id)
          request({
            'Action' => 'CreateRouteTable',
            'VpcId' => vpc_id,
            :parser => Fog::Parsers::AWS::Compute::CreateRouteTable.new
          })
        end
      end

      class Mock
        def create_route_table(vpc_id)
          response = Excon::Response.new
          vpc = self.data[:vpcs].find { |vpc| vpc["vpcId"].eql? vpc_id }
          unless vpc.nil?
            response.status = 200
            route_table = {
              'routeTableId' => Fog::AWS::Mock.route_table_id,
              'vpcId' => vpc["vpcId"],
              'routeSet' => [{
                "destinationCidrBlock" => vpc["cidrBlock"],
                "gatewayId" => "local",
                "instanceId"=>nil,
                "instanceOwnerId"=>nil,
                "networkInterfaceId"=>nil,
                "state" => "pending",
                "origin" => "CreateRouteTable"
              }],
              'associationSet' => [],
              'tagSet' => {}
            }
            self.data[:route_tables].push(route_table)
            response.body = {
              'requestId'=> Fog::AWS::Mock.request_id,
              'routeTable' => [route_table]
            }
            response
          else
            raise Fog::AWS::Compute::NotFound.new("The vpc ID '#{vpc_id}' does not exist")
          end
        end
      end
    end
  end
end
