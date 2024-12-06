module Fog
  module Parsers
    module AWS
      module Compute
        class CreateRouteTable < Fog::Parsers::Base
          def reset
            @in_route_set = false
            @in_association_set = false
            @route = {}
            @association = {}
            @route_table = { 'routeSet' => [], 'tagSet' => {}, 'associationSet' => [] }
            @response = { 'routeTable' => [] }
            @tag = {}
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'tagSet'
              @in_tag_set = true
            when 'routeSet'
              @in_route_set = true
            when 'associationSet'
              @in_association_set = true
            end
          end

          def end_element(name)
            if @in_tag_set
              case name
                when 'item'
                  @route_table['tagSet'][@tag['key']] = @tag['value']
                  @tag = {}
                when 'tagSet'
                  @in_tag_set = false
              end
            elsif @in_route_set
              case name
              when 'routeSet'
                @in_route_set = false
              when 'destinationCidrBlock', 'gatewayId', 'state'
                @route[name] = value
              when 'item'
                @route_table['routeSet'] << @route
                @route = {}
              end
            elsif @in_association_set
              case name
              when 'routeTableAssociationId', 'routeTableId', 'main'
                @association[name] = value
              when 'associationSet'
                @route_table['associationSet'] << @association
                @in_association_set = false
              end
            else
              case name
              when 'routeTableId', 'vpcId'
                @route_table[name] = value
              when 'routeTable'
                @response['routeTable'] << @route_table
                @route_table = { 'routeSet' => {}, 'tagSet' => {}, 'associationSet' => {} }
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
