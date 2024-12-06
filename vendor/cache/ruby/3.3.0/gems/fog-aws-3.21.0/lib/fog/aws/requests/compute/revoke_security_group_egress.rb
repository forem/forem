module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/basic'

        # Remove permissions from a security group
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
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-RevokeSecurityGroupEgress.html]
        def revoke_security_group_egress(group_name, options = {})
          options = Fog::AWS.parse_security_group_options(group_name, options)

          if ip_permissions = options.delete('IpPermissions')
            options.merge!(indexed_ip_permissions_params(ip_permissions))
          end

          request({
            'Action'    => 'RevokeSecurityGroupEgress',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::Basic.new
          }.merge!(options))
        end
      end

      class Mock
        def revoke_security_group_egress(group_name, options = {})
          options = Fog::AWS.parse_security_group_options(group_name, options)

          group = self.data[:security_groups].values.find { |v| v['groupName'] == group_name }

          group ||
            raise(Fog::AWS::Compute::NotFound.new("The security group '#{group_name}' does not exist"))
          response = Excon::Response.new

          verify_permission_options(options, group['vpcId'] != nil)

          normalized_permissions = normalize_permissions(options)

          normalized_permissions.each do |permission|
            if matching_permission = find_matching_permission_egress(group, permission)
              matching_permission['ipRanges'] -= permission['ipRanges']
              matching_permission['groups'] -= permission['groups']

              if matching_permission['ipRanges'].empty? && matching_permission['groups'].empty?
                group['ipPermissionsEgress'].delete(matching_permission)
              end
            end
          end

          response.status = 200
          response.body = {
            'requestId' => Fog::AWS::Mock.request_id,
            'return'    => true
          }
          response
        end
      end
    end
  end
end
