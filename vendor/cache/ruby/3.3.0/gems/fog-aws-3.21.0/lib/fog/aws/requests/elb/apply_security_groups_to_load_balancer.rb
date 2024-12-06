module Fog
  module AWS
    class ELB
      class Real
        require 'fog/aws/parsers/elb/apply_security_groups_to_load_balancer'

        # Sets the security groups for an ELB in VPC
        #
        # ==== Parameters
        # * security_group_ids<~Array> - List of security group ids to enable on ELB
        # * lb_name<~String> - Load balancer to disable availability zones on
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #     * 'ApplySecurityGroupsToLoadBalancer'<~Hash>:
        #       * 'SecurityGroups'<~Array> - array of strings describing the security group ids currently enabled
        def apply_security_groups_to_load_balancer(security_group_ids, lb_name)
          params = Fog::AWS.indexed_param('SecurityGroups.member', [*security_group_ids])
          request({
            'Action'           => 'ApplySecurityGroupsToLoadBalancer',
            'LoadBalancerName' => lb_name,
            :parser            => Fog::Parsers::AWS::ELB::ApplySecurityGroupsToLoadBalancer.new
          }.merge!(params))
        end

        alias_method :apply_security_groups, :apply_security_groups_to_load_balancer
      end

      class Mock
        def apply_security_groups_to_load_balancer(security_group_ids, lb_name)
          raise Fog::AWS::ELB::NotFound unless load_balancer = self.data[:load_balancers][lb_name]

          response = Excon::Response.new
          response.status = 200

          load_balancer['SecurityGroups'] << security_group_ids
          load_balancer['SecurityGroups'].flatten!.uniq!

          response.body = {
            'ResponseMetadata' => {
              'RequestId' => Fog::AWS::Mock.request_id
            },
            'DetachLoadBalancerFromSubnetsResult' => {
              'SecurityGroups' => load_balancer['SecurityGroups']
            }
          }

          response
        end

      alias_method :apply_security_groups, :apply_security_groups_to_load_balancer
      end
    end
  end
end
