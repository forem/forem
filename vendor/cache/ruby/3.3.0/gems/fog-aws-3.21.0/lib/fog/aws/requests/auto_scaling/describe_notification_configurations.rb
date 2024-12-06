module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/describe_notification_configurations'

        # Returns a list of notification actions associated with Auto Scaling
        # groups for specified events.
        #
        # ==== Parameters
        # * options<~Hash>:
        #   * 'AutoScalingGroupNames'<~String> - The name of the Auto Scaling
        #     group.
        #   * 'MaxRecords'<~Integer> - The maximum number of records to return.
        #   * 'NextToken'<~String> - A string that is used to mark the start of
        #     the next batch of returned results for pagination.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #     * 'DescribeNotificationConfigurationsResult'<~Hash>:
        #       * 'NotificationConfigurations'<~Array>:
        #         * notificationConfiguration<~Hash>:
        #           * 'AutoScalingGroupName'<~String> - Specifies the Auto
        #             Scaling group name.
        #           * 'NotificationType'<~String> - The types of events for an
        #             action to start.
        #         * 'TopicARN'<~String> - The Amazon Resource Name (ARN) of the
        #           Amazon Simple Notification Service (SNS) topic.
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DescribeNotificationConfigurations.html
        #
        def describe_notification_configurations(options = {})
          if auto_scaling_group_names = options.delete('AutoScalingGroupNames')
            options.merge!(AWS.indexed_param('AutoScalingGroupNames.member.%d', [*auto_scaling_group_names]))
          end
          request({
            'Action' => 'DescribeNotificationConfigurations',
            :parser  => Fog::Parsers::AWS::AutoScaling::DescribeNotificationConfigurations.new
          }.merge!(options))
        end
      end

      class Mock
        def describe_notification_configurations(options = {})
          results = { 'NotificationConfigurations' => [] }
          (options['AutoScalingGroupNames']||self.data[:notification_configurations].keys).each do |asg_name|
            (self.data[:notification_configurations][asg_name]||{}).each do |topic_arn, notification_types|
              notification_types.each do |notification_type|
                results['NotificationConfigurations'] << {
                  'AutoScalingGroupName' => asg_name,
                  'NotificationType'     => notification_type,
                  'TopicARN'             => topic_arn,
                }
              end
            end
          end

          response = Excon::Response.new
          response.status = 200
          response.body = {
            'DescribeNotificationConfigurationsResult' => results,
            'ResponseMetadata' => { 'RequestId' => Fog::AWS::Mock.request_id }
          }
          response
        end
      end
    end
  end
end
