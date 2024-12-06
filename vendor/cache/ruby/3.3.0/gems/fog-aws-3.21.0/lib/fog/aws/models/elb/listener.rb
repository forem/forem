module Fog
  module AWS
    class ELB
      class Listener < Fog::Model
        attribute :policy_names,      :aliases => 'PolicyNames'
        attribute :instance_port,     :aliases => 'InstancePort'
        attribute :instance_protocol, :aliases => 'InstanceProtocol'
        attribute :lb_port,           :aliases => 'LoadBalancerPort'
        attribute :protocol,          :aliases => 'Protocol'
        attribute :ssl_id,            :aliases => 'SSLCertificateId'

        def initialize(attributes={})
          # set defaults, which may be overridden in super
          merge_attributes(:policy_names => [], :instance_port => 80, :instance_protocol => 'HTTP', :lb_port => 80, :protocol => 'HTTP')
          super
        end

        def save
          requires :load_balancer, :instance_port, :lb_port, :protocol, :instance_protocol
          service.create_load_balancer_listeners(load_balancer.id, [to_params])
          reload
        end

        def destroy
          requires :load_balancer, :lb_port
          service.delete_load_balancer_listeners(load_balancer.id, [lb_port])
          reload
        end

        # Return the policy associated with this load balancer
        def policy
          load_balancer.policies.get(policy_names.first)
        end

        def reload
          load_balancer.reload
        end

        def load_balancer
          collection.load_balancer
        end

        def to_params
          {
            'InstancePort'     => instance_port,
            'InstanceProtocol' => instance_protocol,
            'LoadBalancerPort' => lb_port,
            'Protocol'         => protocol,
            'SSLCertificateId' => ssl_id
          }
        end
      end
    end
  end
end
