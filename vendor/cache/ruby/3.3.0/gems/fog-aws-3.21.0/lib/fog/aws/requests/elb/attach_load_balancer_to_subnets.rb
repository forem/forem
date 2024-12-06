module Fog
  module AWS
    class ELB
      class Real
        require 'fog/aws/parsers/elb/attach_load_balancer_to_subnets'

        # Enable a subnet for an existing ELB
        #
        # ==== Parameters
        # * subnet_ids<~Array> - List of subnet ids to enable on ELB
        # * lb_name<~String> - Load balancer to enable availability zones on
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #     * 'AttachLoadBalancerToSubnetsResult'<~Hash>:
        #       * 'Subnets'<~Array> - array of strings describing the subnet ids currently enabled
        def attach_load_balancer_to_subnets(subnet_ids, lb_name)
          params = Fog::AWS.indexed_param('Subnets.member', [*subnet_ids])
          request({
            'Action'           => 'AttachLoadBalancerToSubnets',
            'LoadBalancerName' => lb_name,
            :parser            => Fog::Parsers::AWS::ELB::AttachLoadBalancerToSubnets.new
          }.merge!(params))
        end

        alias_method :enable_subnets, :attach_load_balancer_to_subnets
      end

      class Mock
        def attach_load_balancer_to_subnets(subnet_ids, lb_name)
          raise Fog::AWS::ELB::NotFound unless load_balancer = self.data[:load_balancers][lb_name]

          response = Excon::Response.new
          response.status = 200

          load_balancer['Subnets'] << subnet_ids
          load_balancer['Subnets'].flatten!.uniq!

          response.body = {
            'ResponseMetadata' => {
              'RequestId' => Fog::AWS::Mock.request_id
            },
            'AttachLoadBalancerToSubnetsResult' => {
              'Subnets' => load_balancer['Subnets']
            }
          }

          response
        end

        alias_method :enable_subnets, :attach_load_balancer_to_subnets
      end
    end
  end
end
