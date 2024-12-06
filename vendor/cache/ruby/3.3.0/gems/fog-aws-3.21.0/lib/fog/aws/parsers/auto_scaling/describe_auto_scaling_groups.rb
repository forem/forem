module Fog
  module Parsers
    module AWS
      module AutoScaling
        class DescribeAutoScalingGroups < Fog::Parsers::Base
          def reset
            reset_auto_scaling_group
            reset_enabled_metric
            reset_instance
            reset_suspended_process
            reset_tag
            @results = { 'AutoScalingGroups' => [] }
            @response = { 'DescribeAutoScalingGroupsResult' => {}, 'ResponseMetadata' => {} }
          end

          def reset_auto_scaling_group
            @auto_scaling_group = {
              'AvailabilityZones' => [],
              'EnabledMetrics' => [],
              'Instances' => [],
              'LoadBalancerNames' => [],
              'SuspendedProcesses' => [],
              'Tags' => [],
              'TargetGroupARNs' => [],
              'TerminationPolicies' => []
            }
          end

          def reset_enabled_metric
            @enabled_metric = {}
          end

          def reset_instance
            @instance = {}
          end

          def reset_suspended_process
            @suspended_process = {}
          end

          def reset_tag
            @tag = {}
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'member'
            when 'AvailabilityZones'
              @in_availability_zones = true
            when 'EnabledMetrics'
              @in_enabled_metrics = true
            when 'Instances'
              @in_instances = true
            when 'LoadBalancerNames'
              @in_load_balancer_names = true
            when 'SuspendedProcesses'
              @in_suspended_processes = true
            when 'Tags'
              @in_tags = true
            when 'TargetGroupARNs'
              @in_target_groups = true
            when 'TerminationPolicies'
              @in_termination_policies = true
            end
          end

          def end_element(name)
            case name
            when 'member'
              if @in_availability_zones
                @auto_scaling_group['AvailabilityZones'] << value
              elsif @in_enabled_metrics
                @auto_scaling_group['EnabledMetrics'] << @enabled_metric
                reset_enabled_metric
              elsif @in_instances
                @auto_scaling_group['Instances'] << @instance
                reset_instance
              elsif @in_load_balancer_names
                @auto_scaling_group['LoadBalancerNames'] << value
              elsif @in_suspended_processes
                @auto_scaling_group['SuspendedProcesses'] << @suspended_process
                reset_suspended_process
              elsif @in_tags
                @auto_scaling_group['Tags'] << @tag
                reset_tag
              elsif @in_target_groups
                @auto_scaling_group['TargetGroupARNs'] << value
              elsif @in_termination_policies
                @auto_scaling_group['TerminationPolicies'] << value
              else
                @results['AutoScalingGroups'] << @auto_scaling_group
                reset_auto_scaling_group
              end

            when 'AvailabilityZones'
              @in_availability_zones = false

            when 'Granularity', 'Metric'
              @enabled_metric[name] = value
            when 'EnabledMetrics'
              @in_enabled_metrics = false

            when 'AvailabilityZone', 'HealthStatus', 'InstanceId', 'LifecycleState'
              @instance[name] = value
            when 'Instances'
              @in_instances = false

            when 'LoadBalancerNames'
              @in_load_balancer_names = false

            when 'ProcessName', 'SuspensionReason'
              @suspended_process[name] = value
            when 'SuspendedProcesses'
              @in_suspended_processes = false

            when 'Key', 'ResourceId', 'ResourceType', 'Value'
              @tag[name] = value
            when 'PropagateAtLaunch'
              @tag[name] = (value == 'true')
            when 'Tags'
              @in_tags = false

            when 'TargetGroupARNs'
              @in_target_groups = false

            when 'TerminationPolicies'
              @in_termination_policies = false

            when 'LaunchConfigurationName'
              if @in_instances
                @instance[name] = value
              else
                @auto_scaling_group[name] = value
              end

            when 'AutoScalingGroupARN', 'AutoScalingGroupName'
              @auto_scaling_group[name] = value
            when 'CreatedTime'
              @auto_scaling_group[name] = Time.parse(value)
            when 'DefaultCooldown', 'DesiredCapacity', 'HealthCheckGracePeriod'
              @auto_scaling_group[name] = value.to_i
            when 'HealthCheckType'
              @auto_scaling_group[name] = value
            when 'MaxSize', 'MinSize'
              @auto_scaling_group[name] = value.to_i
            when 'PlacementGroup', 'VPCZoneIdentifier'
              @auto_scaling_group[name] = value

            when 'NextToken'
              @results[name] = value

            when 'RequestId'
              @response['ResponseMetadata'][name] = value

            when 'DescribeAutoScalingGroupsResponse'
              @response['DescribeAutoScalingGroupsResult'] = @results
            end
          end
        end
      end
    end
  end
end
