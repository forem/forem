module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'

        # Disassociates a subnet from a route table.
        #
        # ==== Parameters
        # * AssociationId<~String> - The association ID representing the current association between the route table and subnet.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - The ID of the request.
        #     * 'return'<~Boolean> - Returns true if the request succeeds. Otherwise, returns an error.
        #
        # {Amazon API Reference}[http://docs.aws.amazon.com/AWSEC2/latest/APIReference/ApiReference-query-DisassociateRouteTable.html]
        def disassociate_route_table(association_id)
          request(
            'Action'        => 'DisassociateRouteTable',
            'AssociationId' => association_id,
            :parser         => Fog::Parsers::AWS::Compute::Basic.new
          )
        end
      end

      class Mock
        def disassociate_route_table(association_id)
          assoc_array = nil
          routetable = self.data[:route_tables].find { |routetable|
            assoc_array = routetable["associationSet"].find { |association|
              association['routeTableAssociationId'].eql? association_id
            }
          }
          if !assoc_array.nil? && assoc_array['main'] == false
            routetable['associationSet'].delete(assoc_array)
            response = Excon::Response.new
            response.status = 200
            response.body = {
                'requestId'     => Fog::AWS::Mock.request_id,
                'return'        => true
            }
            response
          elsif assoc_array.nil?
            raise Fog::AWS::Compute::NotFound.new("The association ID '#{association_id}' does not exist")
          elsif assoc_array['main'] == true
            raise Fog::AWS::Compute::Error, "InvalidParameterValue => cannot disassociate the main route table association #{association_id}"
          end
        end
      end
    end
  end
end
