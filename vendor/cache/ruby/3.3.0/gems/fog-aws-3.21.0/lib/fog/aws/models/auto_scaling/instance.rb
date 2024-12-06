module Fog
  module AWS
    class AutoScaling
      class Instance < Fog::Model
        identity  :id,                        :aliases => 'InstanceId'
        attribute :auto_scaling_group_name,   :aliases => 'AutoScalingGroupName'
        attribute :availability_zone,         :aliases => 'AvailabilityZone'
        attribute :health_status,             :aliases => 'HealthStatus'
        attribute :launch_configuration_name, :aliases => 'LaunchConfigurationName'
        attribute :life_cycle_state,          :aliases => 'LifecycleState'

        def initialize(attributes={})
          super
        end

        def group
          service.groups.get(attributes['AutoScalingGroupName'])
        end

        def configuration
          service.configurations.get(attributes['LaunchConfigurationName'])
        end

        def set_health(health_status, options)
          requires :id
          service.set_instance_health(health_status, id, options)
          reload
        end

        def terminate(should_decrement_desired_capacity)
          requires :id
          service.terminate_instance_in_auto_scaling_group(id, should_decrement_desired_capacity)
          reload
        end

        def healthy?
          health_status == 'Healthy'
        end

        def ready?
          life_cycle_state == 'InService'
        end

        def reload
          super
          self
        end

        #def destroy
        #  requires :id
        #  service.delete_auto_scaling_group(id)
        #end
      end
    end
  end
end
