module Fog
  module AWS
    class CloudWatch
      class Real
        require 'fog/aws/parsers/cloud_watch/enable_alarm_actions'

        # Enables actions for the specified alarms
        # ==== Options
        # * AlarmNames<~Array>: The names of the alarms to enable actions for
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AmazonCloudWatch/latest/APIReference/API_EnableAlarmActions.html
        #

        def enable_alarm_actions(alarm_names)
          options = {}
          options.merge!(AWS.indexed_param('AlarmNames.member.%d', [*alarm_names]))
          request({
              'Action'    => 'EnableAlarmActions',
              :parser     => Fog::Parsers::AWS::CloudWatch::EnableAlarmActions.new
            }.merge(options))
        end
      end
    end
  end
end
