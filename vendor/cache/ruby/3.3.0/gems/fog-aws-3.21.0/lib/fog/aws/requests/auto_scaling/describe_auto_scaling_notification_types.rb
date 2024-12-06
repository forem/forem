module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/describe_auto_scaling_notification_types'

        # Returns a list of all notification types that are supported by Auto
        # Scaling.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #     * 'DescribeAutoScalingNotificationTypesResult'<~Hash>:
        #       * 'AutoScalingNotificationTypes'<~Array>:
        #         * 'notificationType'<~String> - A notification type.
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DescribeAutoScalingNotificationTypes.html
        #
        def describe_auto_scaling_notification_types()
          request({
            'Action'    => 'DescribeAutoScalingNotificationTypes',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::AutoScaling::DescribeAutoScalingNotificationTypes.new
          })
        end
      end

      class Mock
        def describe_auto_scaling_notification_types()
          results = {
            'AutoScalingNotificationTypes' => [],
          }
          self.data[:notification_types].each do |notification_type|
            results['AutoScalingNotificationTypes'] << notification_type
          end
          response = Excon::Response.new
          response.status = 200
          response.body = {
            'DescribeAutoScalingNotificationTypesResult' => results,
            'ResponseMetadata' => { 'RequestId' => Fog::AWS::Mock.request_id }
          }
          response
        end
      end
    end
  end
end
