module Fog
  module AWS
    class AutoScaling
      class Group < Fog::Model
        identity  :id,                        :aliases => 'AutoScalingGroupName'
        attribute :arn,                       :aliases => 'AutoScalingGroupARN'
        attribute :availability_zones,        :aliases => 'AvailabilityZones'
        attribute :created_at,                :aliases => 'CreatedTime'
        attribute :default_cooldown,          :aliases => 'DefaultCooldown'
        attribute :desired_capacity,          :aliases => 'DesiredCapacity'
        attribute :enabled_metrics,           :aliases => 'EnabledMetrics'
        attribute :health_check_grace_period, :aliases => 'HealthCheckGracePeriod'
        attribute :health_check_type,         :aliases => 'HealthCheckType'
        attribute :instances,                 :aliases => 'Instances'
        attribute :launch_configuration_name, :aliases => 'LaunchConfigurationName'
        attribute :load_balancer_names,       :aliases => 'LoadBalancerNames'
        attribute :max_size,                  :aliases => 'MaxSize'
        attribute :min_size,                  :aliases => 'MinSize'
        attribute :placement_group,           :aliases => 'PlacementGroup'
        attribute :suspended_processes,       :aliases => 'SuspendedProcesses'
        attribute :tags,                      :aliases => 'Tags'
        attribute :termination_policies,      :aliases => 'TerminationPolicies'
        attribute :vpc_zone_identifier,       :aliases => 'VPCZoneIdentifier'
        attribute :target_group_arns,         :aliases => 'TargetGroupARNs'

        def initialize(attributes={})
          self.instances = []
          self.default_cooldown = 300
          self.desired_capacity = 0
          self.enabled_metrics = []
          self.health_check_grace_period = 0
          self.health_check_type = 'EC2'
          self.load_balancer_names = []
          self.max_size = 0
          self.min_size = 0
          self.suspended_processes = []
          self.tags = {}
          self.termination_policies = ['Default']
          self.target_group_arns = []
          super
        end

        def activities
          requires :id

          activities = Fog::AWS::AutoScaling::Activities.new(:service => service, :filters => {'AutoScalingGroupName' => id})
        end

        def attach_load_balancers(*load_balancer_names)
          requires :id
          service.attach_load_balancers(id, 'LoadBalancerNames' => load_balancer_names)
          reload
        end

        def configuration
          requires :launch_configuration_name
          service.configurations.get(launch_configuration_name)
        end

        def detach_load_balancers(*load_balancer_names)
          requires :id
          service.detach_load_balancers(id, 'LoadBalancerNames' => load_balancer_names)
          reload
        end

        def detach_instances(*instance_ids)
          requires :id
          service.detach_instances(id, 'InstanceIds' => instance_ids)
          reload
        end

        def attach_instances(*instance_ids)
          requires :id
          service.attach_instances(id, 'InstanceIds' => instance_ids)
          reload
        end

        def attach_load_balancer_target_groups(*target_group_arns)
          requires :id
          service.attach_load_balancer_target_groups(id, 'TargetGroupARNs' => target_group_arns)
          reload
        end

        def detach_load_balancer_target_groups(*target_group_arns)
          requires :id
          service.detach_load_balancer_target_groups(id, 'TargetGroupARNs' => target_group_arns)
          reload
        end

        def disable_metrics_collection(metrics = {})
          requires :id
          service.disable_metrics_collection(id, 'Metrics' => metrics)
          reload
        end

        def enable_metrics_collection(granularity = '1Minute', metrics = {})
          requires :id
          service.enable_metrics_collection(id, granularity, 'Metrics' => metrics)
          reload
        end

        def set_instance_protection(instance_ids, protected_from_scale_in)
          requires :id
          service.set_instance_protection(
            id,
            'InstanceIds' => instance_ids,
            'ProtectedFromScaleIn' => protected_from_scale_in
          )
          reload
        end

        def instances
          Fog::AWS::AutoScaling::Instances.new(:service => service).load(attributes[:instances])
        end

        def instances_in_service
          attributes[:instances].select {|hash| hash['LifecycleState'] == 'InService'}.map {|hash| hash['InstanceId']}
        end

        def instances_out_service
          attributes[:instances].select {|hash| hash['LifecycleState'] == 'OutOfService'}.map {|hash| hash['InstanceId']}
        end

        def resume_processes(processes = [])
          requires :id
          service.resume_processes(id, 'ScalingProcesses' => processes)
          reload
        end

        def suspend_processes(processes = [])
          requires :id
          service.suspend_processes(id, 'ScalingProcesses' => processes)
          reload
        end

        def ready?
          # Is this useful?
          #instances_in_service.length == desired_capacity
          #instances_in_service.length >= min_size
          true
        end

        def save
          requires :id
          requires :availability_zones
          requires :launch_configuration_name
          requires :max_size
          requires :min_size
          service.create_auto_scaling_group(id, availability_zones, launch_configuration_name, max_size, min_size, filtered_options(:create_auto_scaling_group))
          reload
        end

        #def reload
        #  super
        #  self
        #end

        def destroy(options = { :force => false })
          requires :id

          opts = {}
          opts.merge!({'ForceDelete' => true}) if options[:force]

          service.delete_auto_scaling_group(id, opts)
        end

        def update
          requires :id
          service.update_auto_scaling_group(id, filtered_options(:update_auto_scaling_group) )
          reload
        end

        def filtered_options(method)
          Hash[options.select{|k,_| ExpectedOptions[method].include?(k)}]
        end

        def options
          ret = Hash[self.class.aliases.map { |key, value| [key, send(value)] }]
          ret.delete_if { |key, value| value.nil? }
          ret
        end
      end
    end
  end
end
