module Fog
  module Parsers
    module AWS
      module AutoScaling
        class DescribeNotificationConfigurations < Fog::Parsers::Base
          def reset
            reset_notification_configuration
            @results = { 'NotificationConfigurations' => [] }
            @response = { 'DescribeNotificationConfigurationsResult' => {}, 'ResponseMetadata' => {} }
          end

          def reset_notification_configuration
            @notification_configuration = {}
          end

          def end_element(name)
            case name
            when 'member'
              @results['NotificationConfigurations'] << @notification_configuration
              reset_notification_configuration

            when 'AutoScalingGroupName','NotificationType', 'TopicARN'
              @notification_configuration[name] = value

            when 'NextToken'
              @results[name] = value

            when 'RequestId'
              @response['ResponseMetadata'][name] = value

            when 'DescribeNotificationConfigurationsResponse'
              @response['DescribeNotificationConfigurationsResult'] = @results
            end
          end
        end
      end
    end
  end
end
