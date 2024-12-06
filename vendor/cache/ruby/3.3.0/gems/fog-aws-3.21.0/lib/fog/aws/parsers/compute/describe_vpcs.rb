module Fog
  module Parsers
    module AWS
      module Compute
        class DescribeVpcs < Fog::Parsers::Base
          def reset
            @response = { 'vpcSet' => [] }
            @context = []
          end

          def start_element(name, attrs = [])
            super
            @context.push(name)

            case @context[1 .. -1].join('.')
              when 'vpcSet.item'
                @current_vpc = { 'tagSet' => {}, 'cidrBlockAssociationSet' => [], 'ipv6CidrBlockAssociationSet' => [] }

              when 'vpcSet.item.tagSet.item'
                @current_tag_key = @current_tag_value = nil

              when 'vpcSet.item.cidrBlockAssociationSet.item'
                @current_cidr_block = {}

              when 'vpcSet.item.ipv6CidrBlockAssociationSet.item'
                @current_ipv6_block = {}
            end
          end

          def end_element(name)
            case @context[1 .. -1].join('.')
              # tagSet

              when 'vpcSet.item.tagSet.item'
                @current_vpc['tagSet'][@current_tag_key] = @current_tag_value
                @current_tag_key = @current_tag_value = nil

              when 'vpcSet.item.tagSet.item.key'
                @current_tag_key = value

              when 'vpcSet.item.tagSet.item.value'
                @current_tag_value = value

              # cidrBlockAssociationSet

              when 'vpcSet.item.cidrBlockAssociationSet.item.cidrBlock',
                   'vpcSet.item.cidrBlockAssociationSet.item.associationId'
                @current_cidr_block[name] = value

              when 'vpcSet.item.cidrBlockAssociationSet.item.cidrBlockState'
                @current_cidr_block['state'] = value.strip

              when 'vpcSet.item.cidrBlockAssociationSet.item'
                @current_vpc['cidrBlockAssociationSet'] << @current_cidr_block

              # ipv6CidrBlockAssociationSet

              when 'vpcSet.item.ipv6CidrBlockAssociationSet.item.ipv6CidrBlock',
                   'vpcSet.item.ipv6CidrBlockAssociationSet.item.associationId'
                @current_ipv6_block[name] = value

              when 'vpcSet.item.ipv6CidrBlockAssociationSet.item.ipv6CidrBlockState'
                @current_ipv6_block['state'] = value.strip

              when 'vpcSet.item.ipv6CidrBlockAssociationSet.item'
                @current_vpc['ipv6CidrBlockAssociationSet'] << @current_ipv6_block

              # vpc

              when 'vpcSet.item.vpcId',
                   'vpcSet.item.state',
                   'vpcSet.item.cidrBlock',
                   'vpcSet.item.dhcpOptionsId',
                   'vpcSet.item.instanceTenancy'
                @current_vpc[name] = value

              when 'vpcSet.item.isDefault'
                @current_vpc['isDefault'] = value == 'true'

              when 'vpcSet.item'
                @response['vpcSet'] << @current_vpc

              # root

              when 'requestId'
                @response[name] = value
            end

            @context.pop
          end
        end
      end
    end
  end
end
