module Fog
  module Parsers
    module AWS
      module AutoScaling
        class DescribeAutoScalingInstances < Fog::Parsers::Base
          def reset
            reset_auto_scaling_instance
            @results = { 'AutoScalingInstances' => [] }
            @response = { 'DescribeAutoScalingInstancesResult' => {}, 'ResponseMetadata' => {} }
          end

          def reset_auto_scaling_instance
            @auto_scaling_instance = {}
          end

          def end_element(name)
            case name
            when 'member'
              @results['AutoScalingInstances'] << @auto_scaling_instance
              reset_auto_scaling_instance

            when 'AutoScalingGroupName', 'AvailabilityZone', 'HealthStatus',
                 'InstanceId', 'LaunchConfigurationName', 'LifecycleState'
              @auto_scaling_instance[name] = value

            when 'NextToken'
              @results[name] = value

            when 'RequestId'
              @response['ResponseMetadata'][name] = value

            when 'DescribeAutoScalingInstancesResponse'
              @response['DescribeAutoScalingInstancesResult'] = @results
            end
          end
        end
      end
    end
  end
end
