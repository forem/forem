module Fog
  module Parsers
    module AWS
      module Compute
        class DescribeRouteTables < Fog::Parsers::Base
          def reset
            @association = { 'routeTableAssociationId' => nil, 'routeTableId' => nil, 'subnetId' => nil, 'main' => false }
            @in_association_set = false
            @in_route_set = false
            @route = { 'destinationCidrBlock' => nil, 'gatewayId' => nil, 'instanceId' => nil, 'instanceOwnerId' => nil, 'networkInterfaceId' => nil, 'vpcPeeringConnectionId' => nil, 'natGatewayId' => nil, 'state' => nil, 'origin' => nil }
            @response = { 'routeTableSet' => [] }
            @tag = {}
            @route_table = { 'associationSet' => [], 'tagSet' => {}, 'routeSet' => [] }
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'associationSet'
              @in_association_set = true
            when 'tagSet'
              @in_tag_set = true
            when 'routeSet'
              @in_route_set = true
            end
          end

          def end_element(name)
            if @in_association_set
              case name
              when 'associationSet'
                @in_association_set = false
              when 'routeTableAssociationId', 'routeTableId', 'subnetId'
                @association[name] = value
              when 'main'
                if value == 'true'
                  @association[name] = true
                else
                  @association[name] = false
                end
              when 'item'
                @route_table['associationSet'] << @association
                @association = { 'routeTableAssociationId' => nil, 'routeTableId' => nil, 'subnetId' => nil, 'main' => false }
              end
            elsif @in_tag_set
              case name
              when 'key', 'value'
                @tag[name] = value
              when 'item'
                @route_table['tagSet'][@tag['key']] = @tag['value']
                @tag = {}
              when 'tagSet'
                @in_tag_set = false
              end
            elsif @in_route_set
              case name
              when 'destinationCidrBlock', 'gatewayId', 'instanceId', 'instanceOwnerId', 'networkInterfaceId', 'vpcPeeringConnectionId', 'natGatewayId', 'state', 'origin'
                @route[name] = value
              when 'item'
                @route_table['routeSet'] << @route
                @route = { 'destinationCidrBlock' => nil, 'gatewayId' => nil, 'instanceId' => nil, 'instanceOwnerId' => nil, 'networkInterfaceId' => nil, 'vpcPeeringConnectionId' => nil, 'natGatewayId' => nil, 'state' => nil, 'origin' => nil }
              when 'routeSet'
                @in_route_set = false
              end
            else
              case name
              when 'routeTableId', 'vpcId'
                @route_table[name] = value
              when 'item'
                @response['routeTableSet'] << @route_table
                @route_table = { 'associationSet' => [], 'tagSet' => {}, 'routeSet' => [] }
              when 'requestId'
                @response[name] = value
              end
            end
          end
        end
      end
    end
  end
end
