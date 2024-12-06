module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/describe_auto_scaling_groups'

        # Returns a full description of each Auto Scaling group in the given
        # list. This includes all Amazon EC2 instances that are members of the
        # group. If a list of names is not provided, the service returns the
        # full details of all Auto Scaling groups.
        #
        # This action supports pagination by returning a token if there are
        # more pages to retrieve. To get the next page, call this action again
        # with the returned token as the NextToken parameter.
        #
        # ==== Parameters
        # * options<~Hash>:
        #   * 'AutoScalingGroupNames'<~Array> - A list of Auto Scaling group
        #     names.
        #   * 'MaxRecords'<~Integer> - The maximum number of records to return.
        #   * 'NextToken'<~String> - A string that marks the start of the next
        #     batch of returned results.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #     * 'DescribeAutoScalingGroupsResponse'<~Hash>:
        #       * 'AutoScalingGroups'<~Array>:
        #         * 'AutoScalingGroup'<~Hash>:
        #           * 'AutoScalingGroupARN'<~String> - The Amazon Resource Name
        #              (ARN) of the Auto Scaling group.
        #           * 'AutoScalingGroupName'<~String> - Specifies the name of
        #             the group.
        #           * 'AvailabilityZones'<~Array> - Contains a list of
        #             availability zones for the group.
        #           * 'CreatedTime'<~Time> - Specifies the date and time the
        #             Auto Scaling group was created.
        #           * 'DefaultCooldown'<~Integer> - The number of seconds after
        #             a scaling activity completes before any further scaling
        #             activities can start.
        #           * 'DesiredCapacity'<~Integer> - Specifies the desired
        #             capacity of the Auto Scaling group.
        #           * 'EnabledMetrics'<~Array>:
        #             * enabledmetric<~Hash>:
        #               * 'Granularity'<~String> - The granularity of the
        #                 enabled metric.
        #               * 'Metrics'<~String> - The name of the enabled metric.
        #           * 'HealthCheckGracePeriod'<~Integer>: The length of time
        #             that Auto Scaling waits before checking an instance's
        #             health status. The grace period begins when an instance
        #             comes into service.
        #           * 'HealthCheckType'<~String>: The service of interest for
        #             the health status check, either "EC2" for Amazon EC2 or
        #             "ELB" for Elastic Load Balancing.
        #           * 'Instances'<~Array>:
        #             * instance<~Hash>:
        #               * 'AvailabilityZone'<~String>: Availability zone
        #                 associated with this instance.
        #               * 'HealthStatus'<~String>: The instance's health
        #                 status.
        #               * 'InstanceId'<~String>: Specifies the EC2 instance ID.
        #               * 'LaunchConfigurationName'<~String>: The launch
        #                 configuration associated with this instance.
        #               * 'LifecycleState'<~String>: Contains a description of
        #                 the current lifecycle state.
        #           * 'LaunchConfigurationName'<~String> - Specifies the name
        #             of the associated launch configuration.
        #           * 'LoadBalancerNames'<~Array> - A list of load balancers
        #             associated with this Auto Scaling group.
        #           * 'MaxSize'<~Integer> - The maximum size of the Auto
        #             Scaling group.
        #           * 'MinSize'<~Integer> - The minimum size of the Auto
        #             Scaling group.
        #           * 'PlacementGroup'<~String> - The name of the cluster
        #             placement group, if applicable.
        #           * 'SuspendedProcesses'<~Array>:
        #             * suspendedprocess'<~Hash>:
        #               * 'ProcessName'<~String> - The name of the suspended
        #                 process.
        #               * 'SuspensionReason'<~String> - The reason that the
        #                 process was suspended.
        #           * 'TerminationPolicies'<~Array> - A standalone termination
        #             policy or a list of termination policies for this Auto
        #             Scaling group.
        #           * 'VPCZoneIdentifier'<~String> - The subnet identifier for
        #             the Amazon VPC connection, if applicable. You can specify
        #             several subnets in a comma-separated list.
        #       * 'NextToken'<~String> - A string that marks the start of the
        #         next batch of returned results.
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DescribeAutoScalingGroups.html
        #
        def describe_auto_scaling_groups(options = {})
          if auto_scaling_group_names = options.delete('AutoScalingGroupNames')
            options.merge!(AWS.indexed_param('AutoScalingGroupNames.member.%d', [*auto_scaling_group_names]))
          end
          request({
            'Action' => 'DescribeAutoScalingGroups',
            :parser  => Fog::Parsers::AWS::AutoScaling::DescribeAutoScalingGroups.new
          }.merge!(options))
        end
      end

      class Mock
        def describe_auto_scaling_groups(options = {})
          results = { 'AutoScalingGroups' => [] }
          asg_set = self.data[:auto_scaling_groups]

          if !options["AutoScalingGroupNames"].nil?
            asg_set = asg_set.reject do |asg_name, asg_data|
              ![*options["AutoScalingGroupNames"]].include?(asg_name)
            end
          end

          asg_set.each do |asg_name, asg_data|
            results['AutoScalingGroups'] << {
              'AutoScalingGroupName' => asg_name
            }.merge!(asg_data)
          end
          response = Excon::Response.new
          response.status = 200
          response.body = {
            'DescribeAutoScalingGroupsResult' => results,
            'ResponseMetadata' => { 'RequestId' => Fog::AWS::Mock.request_id }
          }
          response
        end
      end
    end
  end
end
