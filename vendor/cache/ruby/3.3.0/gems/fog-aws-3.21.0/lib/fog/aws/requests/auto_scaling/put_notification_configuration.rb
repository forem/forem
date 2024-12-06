module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/put_notification_configuration'

        # Creates a notification configuration for an Auto Scaling group. To
        # update an existing policy, overwrite the existing notification
        # configuration name  and set the parameter(s) you want to change.
        #
        # ==== Parameters
        # * auto_scaling_group_name<~String> - The name of the Auto Scaling
        #   group.
        # * notification_types<~Array> - The type of events that will trigger
        #   the notification.
        # * topic_arn<~String> - The Amazon Resource Name (ARN) of the Amazon
        #   Simple Notification Service (SNS) topic.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_PutNotificationConfiguration.html
        #
        def put_notification_configuration(auto_scaling_group_name, notification_types, topic_arn)
          params = AWS.indexed_param('NotificationTypes.member.%d', [*notification_types])
          request({
            'Action'               => 'PutNotificationConfiguration',
            'AutoScalingGroupName' => auto_scaling_group_name,
            'TopicARN'             => topic_arn,
            :parser                => Fog::Parsers::AWS::AutoScaling::PutNotificationConfiguration.new
          }.merge!(params))
        end
      end

      class Mock
        def put_notification_configuration(auto_scaling_group_name, notification_types, topic_arn)
          unless self.data[:auto_scaling_groups].key?(auto_scaling_group_name)
            raise Fog::AWS::AutoScaling::ValidationError.new("AutoScalingGroup name not found - #{auto_scaling_group_name}")
          end
          if notification_types.to_a.empty?
            raise Fog::AWS::AutoScaling::ValidationError.new("1 validation error detected: Value null at 'notificationTypes' failed to satisfy constraint: Member must not be null")
          end
          invalid_types = notification_types.to_a - self.data[:notification_types]
          unless invalid_types.empty?
            raise Fog::AWS::AutoScaling::ValidationError.new("&quot;#{invalid_types.first}&quot; is not a valid Notification Type.")
          end

          self.data[:notification_configurations][auto_scaling_group_name] ||= {}
          self.data[:notification_configurations][auto_scaling_group_name][topic_arn] = notification_types.to_a.uniq

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
