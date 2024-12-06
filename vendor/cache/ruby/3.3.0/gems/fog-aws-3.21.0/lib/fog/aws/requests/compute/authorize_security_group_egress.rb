module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'

        # Add permissions to a security group
        #
        # ==== Parameters
        # * group_name<~String> - Name of group, optional (can also be specifed as GroupName in options)
        # * options<~Hash>:
        #   * 'GroupName'<~String> - Name of security group to modify
        #   * 'GroupId'<~String> - Id of security group to modify
        #   * 'SourceSecurityGroupName'<~String> - Name of security group to authorize
        #   * 'SourceSecurityGroupOwnerId'<~String> - Name of owner to authorize
        #   or
        #   * 'CidrIp'<~String> - CIDR range
        #   * 'FromPort'<~Integer> - Start of port range (or -1 for ICMP wildcard)
        #   * 'IpProtocol'<~String> - Ip protocol, must be in ['tcp', 'udp', 'icmp']
        #   * 'ToPort'<~Integer> - End of port range (or -1 for ICMP wildcard)
        #   or
        #   * 'IpPermissions'<~Array>:
        #     * permission<~Hash>:
        #       * 'FromPort'<~Integer> - Start of port range (or -1 for ICMP wildcard)
        #       * 'Groups'<~Array>:
        #         * group<~Hash>:
        #           * 'GroupName'<~String> - Name of security group to authorize
        #           * 'UserId'<~String> - Name of owner to authorize
        #       * 'IpProtocol'<~String> - Ip protocol, must be in ['tcp', 'udp', 'icmp']
        #       * 'IpRanges'<~Array>:
        #         * ip_range<~Hash>:
        #           * 'CidrIp'<~String> - CIDR range
        #       * 'ToPort'<~Integer> - End of port range (or -1 for ICMP wildcard)
        #
        # === Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'return'<~Boolean> - success?
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-AuthorizeSecurityGroupEgress.html]
        def authorize_security_group_egress(group_name, options = {})
          options = Fog::AWS.parse_security_group_options(group_name, options)

          if ip_permissions = options.delete('IpPermissions')
            options.merge!(indexed_ip_permissions_params(ip_permissions))
          end

          request({
            'Action'    => 'AuthorizeSecurityGroupEgress',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::Basic.new
          }.merge!(options))
        end
      end

      class Mock
        def authorize_security_group_egress(group_name, options = {})
          options = Fog::AWS.parse_security_group_options(group_name, options)

          group = if options.key?('GroupName')
                    self.data[:security_groups].values.find { |v| v['groupName'] == options['GroupName'] }
                  else
                    self.data[:security_groups][options.fetch('GroupId')]
                  end

          response = Excon::Response.new
          group ||
            raise(Fog::AWS::Compute::NotFound.new("The security group '#{group_name}' does not exist"))

          verify_permission_options(options, group['vpcId'] != nil)

          normalized_permissions = normalize_permissions(options)

          normalized_permissions.each do |permission|
            if matching_group_permission = find_matching_permission_egress(group, permission)
              if permission['groups'].any? {|pg| matching_group_permission['groups'].include?(pg) }
                raise Fog::AWS::Compute::Error, "InvalidPermission.Duplicate => The permission '123' has already been authorized in the specified group"
              end

              if permission['ipRanges'].any? {|pr| matching_group_permission['ipRanges'].include?(pr) }
                raise Fog::AWS::Compute::Error, "InvalidPermission.Duplicate => The permission '123' has already been authorized in the specified group"
              end
            end
          end

          normalized_permissions.each do |permission|
            if matching_group_permission = find_matching_permission_egress(group, permission)
              matching_group_permission['groups'] += permission['groups']
              matching_group_permission['ipRanges'] += permission['ipRanges']
            else
              group['ipPermissionsEgress'] << permission
            end
          end

          response.status = 200
          response.body = {
            'requestId' => Fog::AWS::Mock.request_id,
            'return'    => true
          }
          response
        end

        def find_matching_permission_egress(group, permission)
          group['ipPermissionsEgress'].find do |group_permission|
            permission['ipProtocol'] == group_permission['ipProtocol'] &&
              permission['fromPort'] == group_permission['fromPort'] &&
              permission['toPort'] == group_permission['toPort']
          end
        end
      end
    end
  end
end
