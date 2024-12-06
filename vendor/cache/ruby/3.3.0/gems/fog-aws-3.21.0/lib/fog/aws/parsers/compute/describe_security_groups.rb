module Fog
  module Parsers
    module AWS
      module Compute
        class DescribeSecurityGroups < Fog::Parsers::Base
          def reset
            @group = {}
            @ip_permission = { 'groups' => [], 'ipRanges' => [], 'ipv6Ranges' => []}
            @ip_permission_egress = { 'groups' => [], 'ipRanges' => [], 'ipv6Ranges' => []}
            @ip_range = {}
            @ipv6_range = {}
            @security_group = { 'ipPermissions' => [], 'ipPermissionsEgress' => [], 'tagSet' => {} }
            @response = { 'securityGroupInfo' => [] }
            @tag = {}
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'groups'
              @in_groups = true
            when 'ipPermissions'
              @in_ip_permissions = true
            when 'ipPermissionsEgress'
              @in_ip_permissions_egress = true
            when 'ipRanges'
              @in_ip_ranges = true
            when 'ipv6Ranges'
              @in_ipv6_ranges = true
            when 'tagSet'
              @in_tag_set = true
            end
          end

          def end_element(name)
            if @in_tag_set
              case name
                when 'item'
                  @security_group['tagSet'][@tag['key']] = @tag['value']
                  @tag = {}
                when 'key', 'value'
                  @tag[name] = value
                when 'tagSet'
                  @in_tag_set = false
              end
            else
              case name
              when 'cidrIp'
                @ip_range[name] = value
              when 'cidrIpv6'
                @ipv6_range[name] = value
              when 'fromPort', 'toPort'
                if @in_ip_permissions_egress
                  @ip_permission_egress[name] = value.to_i
                else
                  @ip_permission[name] = value.to_i
                end
              when 'groups'
                @in_groups = false
              when 'groupDescription', 'ownerId', 'vpcId'
                @security_group[name] = value
              when 'groupId','groupName'
                if @in_groups
                  @group[name] = value
                else
                  @security_group[name] = value
                end
              when 'ipPermissions'
                @in_ip_permissions = false
              when 'ipPermissionsEgress'
                @in_ip_permissions_egress = false
              when 'ipProtocol'
                if @in_ip_permissions_egress
                  @ip_permission_egress[name] = value
                else
                  @ip_permission[name] = value
                end
              when 'ipRanges'
                @in_ip_ranges = false
              when 'ipv6Ranges'
                @in_ipv6_ranges = false
              when 'item'
                if @in_groups
                  if @in_ip_permissions_egress
                    @ip_permission_egress['groups'] << @group
                  else
                    @ip_permission['groups'] << @group
                  end
                  @group = {}
                elsif @in_ip_ranges
                  if @in_ip_permissions_egress
                    @ip_permission_egress['ipRanges'] << @ip_range
                  else
                    @ip_permission['ipRanges'] << @ip_range
                  end
                  @ip_range = {}
                elsif @in_ipv6_ranges
                  if @in_ip_permissions_egress
                    @ip_permission_egress['ipv6Ranges'] << @ipv6_range
                  else
                    @ip_permission['ipv6Ranges'] << @ipv6_range
                  end
                  @ipv6_range = {}
                elsif @in_ip_permissions
                  @security_group['ipPermissions'] << @ip_permission
                  @ip_permission = { 'groups' => [], 'ipRanges' => [], 'ipv6Ranges' => []}
                elsif @in_ip_permissions_egress
                  @security_group['ipPermissionsEgress'] << @ip_permission_egress
                  @ip_permission_egress = { 'groups' => [], 'ipRanges' => [], 'ipv6Ranges' => []}
                else
                  @response['securityGroupInfo'] << @security_group
                  @security_group = { 'ipPermissions' => [], 'ipPermissionsEgress' => [], 'tagSet' => {} }
                end
              when 'requestId', 'nextToken'
                @response[name] = value
              when 'userId'
                @group[name] = value
              end
            end
          end
        end
      end
    end
  end
end
