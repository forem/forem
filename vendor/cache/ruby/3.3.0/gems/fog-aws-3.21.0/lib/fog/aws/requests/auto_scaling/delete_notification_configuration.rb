module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/basic'

        # Deletes notifications created by put_notification_configuration.
        #
        # ==== Parameters
        # * auto_scaling_group_name<~String> - The name of the Auto Scaling
        #   group.
        # * topic_arn<~String> - The Amazon Resource Name (ARN) of the Amazon
        #   Simple Notification Service (SNS) topic.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DeleteNotificationConfiguration.html
        #
        def delete_notification_configuration(auto_scaling_group_name, topic_arn)
          request({
            'Action'               => 'DeleteNotificationConfiguration',
            'AutoScalingGroupName' => auto_scaling_group_name,
            'TopicARN'             => topic_arn,
            :parser                => Fog::Parsers::AWS::AutoScaling::Basic.new
          })
        end
      end

      class Mock
        def delete_notification_configuration(auto_scaling_group_name, topic_arn)
          unless self.data[:notification_configurations].key?(auto_scaling_group_name)
            raise Fog::AWS::AutoScaling::ValidationError.new('AutoScalingGroup name not found - %s' % auto_scaling_group_name)
          end
          unless self.data[:notification_configurations][auto_scaling_group_name].key?(topic_arn)
            raise Fog::AWS::AutoScaling::ValidationError.new("Notification Topic '#{topic_arn}' doesn't exist for '#{self.data[:owner_id]}'")
          end

          self.data[:notification_configurations][auto_scaling_group_name].delete(topic_arn)
          if self.data[:notification_configurations][auto_scaling_group_name].empty?
            self.data[:notification_configurations].delete(auto_scaling_group_name)
          end

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
