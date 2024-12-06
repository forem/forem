module Fog
  module AWS
    class ELB
      class Real
        require 'fog/aws/parsers/elb/register_instances_with_load_balancer'

        # Register an instance with an existing ELB
        #
        # ==== Parameters
        # * instance_ids<~Array> - List of instance IDs to associate with ELB
        # * lb_name<~String> - Load balancer to assign instances to
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #     * 'RegisterInstancesWithLoadBalancerResult'<~Hash>:
        #       * 'Instances'<~Array> - array of hashes describing instances currently enabled
        #         * 'InstanceId'<~String>
        def register_instances_with_load_balancer(instance_ids, lb_name)
          params = Fog::AWS.indexed_param('Instances.member.%d.InstanceId', [*instance_ids])
          request({
            'Action'           => 'RegisterInstancesWithLoadBalancer',
            'LoadBalancerName' => lb_name,
            :parser            => Fog::Parsers::AWS::ELB::RegisterInstancesWithLoadBalancer.new
          }.merge!(params))
        end

        alias_method :register_instances, :register_instances_with_load_balancer
      end

      class Mock
        def register_instances_with_load_balancer(instance_ids, lb_name)
          raise Fog::AWS::ELB::NotFound unless load_balancer = self.data[:load_balancers][lb_name]
          instance_ids = [*instance_ids]
          instances = instance_ids.map do |instance|
            raise Fog::AWS::ELB::InvalidInstance unless Fog::AWS::Compute::Mock.data[@region][@aws_access_key_id][:instances][instance]
            {'InstanceId' => instance}
          end

          response = Excon::Response.new
          response.status = 200

          load_balancer['Instances'] = load_balancer['Instances'] | instances.dup

          response.body = {
            'ResponseMetadata' => {
              'RequestId' => Fog::AWS::Mock.request_id
            },
            'RegisterInstancesWithLoadBalancerResult' => {
              'Instances' => instances
            }
          }

          response
        end
        alias_method :register_instances, :register_instances_with_load_balancer
      end
    end
  end
end
