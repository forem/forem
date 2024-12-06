module Fog
  module Parsers
    module AWS
      module AutoScaling
        class DescribeAutoScalingNotificationTypes < Fog::Parsers::Base
          def reset
            @results = { 'AutoScalingNotificationTypes' => [] }
            @response = { 'DescribeAutoScalingNotificationTypesResult' => {}, 'ResponseMetadata' => {} }
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'AutoScalingNotificationTypes'
              @in_auto_scaling_notification_types = true
            end
          end

          def end_element(name)
            case name
            when 'member'
              if @in_auto_scaling_notification_types
                @results['AutoScalingNotificationTypes'] << value
              end

            when 'AutoScalingNotificationTypes'
              @in_auto_scaling_notification_types = false

            when 'RequestId'
              @response['ResponseMetadata'][name] = value

            when 'DescribeAutoScalingNotificationTypesResponse'
              @response['DescribeAutoScalingNotificationTypesResult'] = @results
            end
          end
        end
      end
    end
  end
end
