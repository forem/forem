module Fog
  module AWS
    class ELB
      class Real
        require 'fog/aws/parsers/elb/deregister_instances_from_load_balancer'

        # Deregister an instance from an existing ELB
        #
        # ==== Parameters
        # * instance_ids<~Array> - List of instance IDs to remove from ELB
        # * lb_name<~String> - Load balancer to remove instances from
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #     * 'DeregisterInstancesFromLoadBalancerResult'<~Hash>:
        #       * 'Instances'<~Array> - array of hashes describing instances currently enabled
        #         * 'InstanceId'<~String>
        def deregister_instances_from_load_balancer(instance_ids, lb_name)
          params = Fog::AWS.indexed_param('Instances.member.%d.InstanceId', [*instance_ids])
          request({
            'Action'           => 'DeregisterInstancesFromLoadBalancer',
            'LoadBalancerName' => lb_name,
            :parser            => Fog::Parsers::AWS::ELB::DeregisterInstancesFromLoadBalancer.new
          }.merge!(params))
        end

        alias_method :deregister_instances, :deregister_instances_from_load_balancer
      end

      class Mock
        def deregister_instances_from_load_balancer(instance_ids, lb_name)
          raise Fog::AWS::ELB::NotFound unless load_balancer = self.data[:load_balancers][lb_name]
          instance_ids = [*instance_ids]
          instance_ids.each do |instance|
            raise Fog::AWS::ELB::InvalidInstance unless Fog::AWS::Compute::Mock.data[@region][@aws_access_key_id][:instances][instance]
          end

          response = Excon::Response.new
          response.status = 200

          load_balancer['Instances'].delete_if { |i| instance_ids.include? i['InstanceId'] }

          response.body = {
            'ResponseMetadata' => {
              'RequestId' => Fog::AWS::Mock.request_id
            },
            'DeregisterInstancesFromLoadBalancerResult' => {
              'Instances' => load_balancer['Instances'].dup
            }
          }

          response
        end
        alias_method :deregister_instances, :deregister_instances_from_load_balancer
      end
    end
  end
end
