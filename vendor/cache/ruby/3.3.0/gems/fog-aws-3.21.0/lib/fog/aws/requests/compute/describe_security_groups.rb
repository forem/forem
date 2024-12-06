module Fog
  module AWS
    class Compute
      class Real
        require 'fog/aws/parsers/compute/describe_security_groups'

        # Describe all or specified security groups
        #
        # ==== Parameters
        # * filters<~Hash> - List of filters to limit results with
        #   * 'MaxResults'<~Integer> - The maximum number of results to return for the request in a single page
        #   * 'NextToken'<~String> - The token to retrieve the next page of results
        #
        # === Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'requestId'<~String> - Id of request
        #     * 'securityGroupInfo'<~Array>:
        #       * 'groupDescription'<~String> - Description of security group
        #       * 'groupId'<~String> - ID of the security group.
        #       * 'groupName'<~String> - Name of security group
        #       * 'ipPermissions'<~Array>:
        #         * 'fromPort'<~Integer> - Start of port range (or -1 for ICMP wildcard)
        #         * 'groups'<~Array>:
        #           * 'groupName'<~String> - Name of security group
        #           * 'userId'<~String> - AWS User Id of account
        #         * 'ipProtocol'<~String> - Ip protocol, must be in ['tcp', 'udp', 'icmp']
        #         * 'ipRanges'<~Array>:
        #           * 'cidrIp'<~String> - CIDR range
        #         * 'ipv6Ranges'<~Array>:
        #           * 'cidrIpv6'<~String> - CIDR ipv6 range
        #         * 'toPort'<~Integer> - End of port range (or -1 for ICMP wildcard)
        #       * 'ownerId'<~String> - AWS Access Key Id of the owner of the security group
        #     * 'NextToken'<~String> - The token to retrieve the next page of results
        #
        # {Amazon API Reference}[http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/ApiReference-query-DescribeSecurityGroups.html]
        def describe_security_groups(filters = {})
          unless filters.is_a?(Hash)
            Fog::Logger.deprecation("describe_security_groups with #{filters.class} param is deprecated, use describe_security_groups('group-name' => []) instead [light_black](#{caller.first})[/]")
            filters = {'group-name' => [*filters]}
          end

          options = {}
          for key in %w[MaxResults NextToken]
            if filters.is_a?(Hash) && filters.key?(key)
              options[key] = filters.delete(key)
            end
          end

          params = Fog::AWS.indexed_filters(filters).merge!(options)
          request({
            'Action'    => 'DescribeSecurityGroups',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::Compute::DescribeSecurityGroups.new
          }.merge!(params))
        end
      end

      class Mock
        def describe_security_groups(filters = {})
          unless filters.is_a?(Hash)
            Fog::Logger.deprecation("describe_security_groups with #{filters.class} param is deprecated, use describe_security_groups('group-name' => []) instead [light_black](#{caller.first})[/]")
            filters = {'group-name' => [*filters]}
          end

          response = Excon::Response.new

          security_group_info = self.data[:security_groups].reject { |k,v| k['amazon-elb-sg'] }.values

          aliases = {
            'description' => 'groupDescription',
            'group-name'  => 'groupName',
            'group-id'    => 'groupId',
            'owner-id'    => 'ownerId'
          }
          permission_aliases = {
            'cidr'      => 'cidrIp',
            'from-port' => 'fromPort',
            'protocol'  => 'ipProtocol',
            'to-port'   => 'toPort'
          }

          security_group_groups = lambda do |security_group|
            (security_group['ipPermissions'] || []).map do |permission|
              permission['groups']
            end.flatten.compact.uniq
          end

          for filter_key, filter_value in filters
            if permission_key = filter_key.split('ip-permission.')[1]
              if permission_key == 'group-name'
                security_group_info = security_group_info.reject do |security_group|
                  !security_group_groups.call(security_group).find do |group|
                    [*filter_value].include?(group['groupName'])
                  end
                end
              elsif permission_key == 'group-id'
                security_group_info = security_group_info.reject do |security_group|
                  !security_group_groups.call(security_group).find do |group|
                    [*filter_value].include?(group['groupId'])
                  end
                end
              elsif permission_key == 'user-id'
                security_group_info = security_group_info.reject do |security_group|
                  !security_group_groups.call(security_group).find do |group|
                    [*filter_value].include?(group['userId'])
                  end
                end
              else
                aliased_key = permission_aliases[filter_key]
                security_group_info = security_group_info.reject do |security_group|
                  !security_group['ipPermissions'].find do |permission|
                    [*filter_value].include?(permission[aliased_key])
                  end
                end
              end
            else
              aliased_key = aliases[filter_key]
              security_group_info = security_group_info.reject do |security_group|
                ![*filter_value].include?(security_group[aliased_key])
              end
            end
          end

          response.status = 200
          response.body = {
            'requestId'         => Fog::AWS::Mock.request_id,
            'securityGroupInfo' => security_group_info
          }
          response
        end
      end
    end
  end
end
