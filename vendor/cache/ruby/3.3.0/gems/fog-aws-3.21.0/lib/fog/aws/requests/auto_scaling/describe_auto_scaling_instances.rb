module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/describe_auto_scaling_instances'

        # Returns a description of each Auto Scaling instance in the
        # instance_ids list. If a list is not provided, the service returns the
        # full details of all instances.
        #
        # This action supports pagination by returning a token if there are
        # more pages to retrieve. To get the next page, call this action again
        # with the returned token as the NextToken parameter.
        #
        # ==== Parameters
        # * options<~Hash>:
        #   * 'InstanceIds'<~Array> - The list of Auto Scaling instances to
        #     describe. If this list is omitted, all auto scaling instances are
        #     described. The list of requested instances cannot contain more
        #     than 50 items. If unknown instances are requested, they are
        #     ignored with no error.
        #   * 'MaxRecords'<~Integer> - The aximum number of Auto Scaling
        #     instances to be described with each call.
        #   * 'NextToken'<~String> - The token returned by a previous call to
        #     indicate that there is more data available.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #     * 'DescribeAutoScalingInstancesResponse'<~Hash>:
        #       * 'AutoScalingInstances'<~Array>:
        #         * autoscalinginstancedetails<~Hash>:
        #           * 'AutoScalingGroupName'<~String> - The name of the Auto
        #             Scaling Group associated with this instance.
        #           * 'AvailabilityZone'<~String> - The availability zone in
        #             which this instance resides.
        #           * 'HealthStatus'<~String> - The health status of this
        #             instance. "Healthy" means that the instance is healthy
        #             and should remain in service. "Unhealthy" means that the
        #             instance is unhealthy. Auto Scaling should terminate and
        #             replace it.
        #           * 'InstanceId'<~String> - The instance's EC2 instance ID.
        #           * 'LaunchConfigurationName'<~String> - The launch
        #              configuration associated with this instance.
        #           * 'LifecycleState'<~String> - The life cycle state of this
        #             instance.
        #       * 'NextToken'<~String> - Acts as a paging mechanism for large
        #         result sets. Set to a non-empty string if there are
        #         additional results waiting to be returned. Pass this in to
        #         subsequent calls to return additional results.
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DescribeAutoScalingInstances.html
        #
        def describe_auto_scaling_instances(options = {})
          if instance_ids = options.delete('InstanceIds')
            options.merge!(AWS.indexed_param('InstanceIds.member.%d', [*instance_ids]))
          end
          request({
            'Action' => 'DescribeAutoScalingInstances',
            :parser  => Fog::Parsers::AWS::AutoScaling::DescribeAutoScalingInstances.new
          }.merge!(options))
        end
      end

      class Mock
        def describe_auto_scaling_instances(options = {})
          results = { 'AutoScalingInstances' => [] }
          self.data[:auto_scaling_groups].each do |asg_name, asg_data|
            asg_data['Instances'].each do |instance|
              results['AutoScalingInstances'] << {
                'AutoScalingGroupName' => asg_name
              }.merge!(instance)
            end
          end
          response = Excon::Response.new
          response.status = 200
          response.body = {
            'DescribeAutoScalingInstancesResult' => results,
            'ResponseMetadata' => { 'RequestId' => Fog::AWS::Mock.request_id }
          }
          response
        end
      end
    end
  end
end
