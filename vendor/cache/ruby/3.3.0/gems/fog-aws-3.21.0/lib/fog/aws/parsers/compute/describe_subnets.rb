module Fog
  module Parsers
    module AWS
      module Compute
        class DescribeSubnets < Fog::Parsers::Base
          def reset
            @subnet = { 'tagSet' => {} }
            @response = { 'subnetSet' => [] }
            @tag = {}
            @ipv6_cidr_block_association = {}
            @in_tag_set = false
            @in_ipv6_cidr_block_association_set = false
            @in_cidr_block_state = false
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'tagSet'
              @in_tag_set = true
            when 'ipv6CidrBlockAssociationSet'
              @in_ipv6_cidr_block_association_set = true
            when 'ipv6CidrBlockState'
              @in_cidr_block_state = true
            end
          end

          def end_element(name)
            if @in_tag_set
              case name
              when 'item'
                @subnet['tagSet'][@tag['key']] = @tag['value']
                @tag = {}
              when 'key', 'value'
                @tag[name] = value
              when 'tagSet'
                @in_tag_set = false
              end
            elsif @in_ipv6_cidr_block_association_set
              if @in_cidr_block_state
                case name
                when 'state'
                  @ipv6_cidr_block_association['ipv6CidrBlockState'] = { name => value }
                when 'ipv6CidrBlockState'
                  @in_cidr_block_state = false
                end
              else
                case name
                when 'item'
                  @subnet['ipv6CidrBlockAssociationSet'] = @ipv6_cidr_block_association
                  @ipv6_cidr_block_association = {}
                when 'ipv6CidrBlock', 'associationId'
                  @ipv6_cidr_block_association[name] = value
                when 'ipv6CidrBlockAssociationSet'
                  @in_ipv6_cidr_block_association_set = false
                end
              end
            else
              case name
              when 'subnetId', 'state', 'vpcId', 'cidrBlock', 'availableIpAddressCount', 'availabilityZone'
                @subnet[name] = value
              when 'mapPublicIpOnLaunch', 'defaultForAz'
                @subnet[name] = value == 'true' ? true : false
              when 'item'
                @response['subnetSet'] << @subnet
                @subnet = { 'tagSet' => {} }
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
