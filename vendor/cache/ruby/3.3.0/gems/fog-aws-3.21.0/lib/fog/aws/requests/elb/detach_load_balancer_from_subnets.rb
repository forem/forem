module Fog
  module AWS
    class ELB
      class Real
        require 'fog/aws/parsers/elb/detach_load_balancer_from_subnets'

        # Disable a subnet for an existing ELB
        #
        # ==== Parameters
        # * subnet_ids<~Array> - List of subnet ids to enable on ELB
        # * lb_name<~String> - Load balancer to disable availability zones on
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #     * 'DetachLoadBalancerFromSubnetsResult'<~Hash>:
        #       * 'Subnets'<~Array> - array of strings describing the subnet ids currently enabled
        def detach_load_balancer_from_subnets(subnet_ids, lb_name)
          params = Fog::AWS.indexed_param('Subnets.member', [*subnet_ids])
          request({
            'Action'           => 'DetachLoadBalancerFromSubnets',
            'LoadBalancerName' => lb_name,
            :parser            => Fog::Parsers::AWS::ELB::DetachLoadBalancerFromSubnets.new
          }.merge!(params))
        end

        alias_method :disable_subnets, :detach_load_balancer_from_subnets
      end

      class Mock
        def detach_load_balancer_from_subnets(subnet_ids, lb_name)
          raise Fog::AWS::ELB::NotFound unless load_balancer = self.data[:load_balancers][lb_name]

          response = Excon::Response.new
          response.status = 200

          load_balancer['Subnets'] << subnet_ids
          load_balancer['Subnets'].flatten!.uniq!

          response.body = {
            'ResponseMetadata' => {
              'RequestId' => Fog::AWS::Mock.request_id
            },
            'DetachLoadBalancerFromSubnetsResult' => {
              'Subnets' => load_balancer['Subnets']
            }
          }

          response
        end

        alias_method :disable_subnets, :detach_load_balancer_from_subnets
      end
    end
  end
end
