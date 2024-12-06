module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/basic'

        # Updates the configuration for the specified AutoScalingGroup.
        #
        # The new settings are registered upon the completion of this call. Any
        # launch configuration settings take effect on any triggers after this
        # call returns. Triggers that are currently in progress aren't
        # affected.
        #
        # ==== Parameters
        # * auto_scaling_group_name<~String> - The name of the Auto Scaling
        #   group.
        # * options<~Hash>:
        #   * 'AvailabilityZones'<~Array> - Availability zones for the group.
        #   * 'DefaultCooldown'<~Integer> - The amount of time, in seconds,
        #     after a scaling activity completes before any further trigger-
        #     related scaling activities can start
        #   * 'DesiredCapacity'<~Integer> - The desired capacity for the Auto
        #     Scaling group.
        #   * 'HealthCheckGracePeriod'<~Integer> - The length of time that Auto
        #      Scaling waits before checking an instance's health status.The
        #      grace period begins when an instance comes into service.
        #   * 'HealthCheckType'<~String> - The service of interest for the
        #     health status check, either "EC2" for Amazon EC2 or "ELB" for
        #     Elastic Load Balancing.
        #   * 'LaunchConfigurationName'<~String> - The name of the launch
        #     configuration.
        #   * 'MaxSize'<~Integer> - The maximum size of the Auto Scaling group.
        #   * 'MinSize'<~Integer> - The minimum size of the Auto Scaling group.
        #   * 'PlacementGroup'<~String> - The name of the cluster placement
        #     group, if applicable.
        #   * 'TerminationPolicies'<~Array> - A standalone termination policy
        #     or a list of termination policies used to select the instance to
        #     terminate. The policies are executed in the order that they are
        #     listed.
        #   * 'VPCZoneIdentifier'<~String> - The subnet identifier for the
        #     Amazon VPC connection, if applicable. You can specify several
        #     subnets in a comma-separated list.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_UpdateAutoScalingGroup.html
        #

        ExpectedOptions[:update_auto_scaling_group] = %w[AvailabilityZones DefaultCooldown DesiredCapacity HealthCheckGracePeriod HealthCheckType LaunchConfigurationName MaxSize MinSize PlacementGroup TerminationPolicies VPCZoneIdentifier]

        def update_auto_scaling_group(auto_scaling_group_name, options = {})
          if availability_zones = options.delete('AvailabilityZones')
            options.merge!(AWS.indexed_param('AvailabilityZones.member.%d', [*availability_zones]))
          end
          if termination_policies = options.delete('TerminationPolicies')
            options.merge!(AWS.indexed_param('TerminationPolicies.member.%d', [*termination_policies]))
          end
          request({
            'Action'               => 'UpdateAutoScalingGroup',
            'AutoScalingGroupName' => auto_scaling_group_name,
            :parser                => Fog::Parsers::AWS::AutoScaling::Basic.new
          }.merge!(options))
        end
      end

      class Mock
        def update_auto_scaling_group(auto_scaling_group_name, options = {})
          unexpected_options = options.keys - ExpectedOptions[:update_auto_scaling_group]
          unless unexpected_options.empty?
            raise Fog::AWS::AutoScaling::ValidationError.new("Options #{unexpected_options.join(',')} should not be included in request")
          end

          unless self.data[:auto_scaling_groups].key?(auto_scaling_group_name)
            raise Fog::AWS::AutoScaling::ValidationError.new('AutoScalingGroup name not found - null')
          end
          self.data[:auto_scaling_groups][auto_scaling_group_name].merge!(options)

          response = Excon::Response.new
          response.status = 200
          response.body = {
            'ResponseMetadata' => { 'RequestId' => Fog::AWS::Mock.request_id }
          }
          response
        end
      end
    end
  end
end
