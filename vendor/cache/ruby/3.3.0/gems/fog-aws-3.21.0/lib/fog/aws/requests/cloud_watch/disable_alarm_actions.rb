module Fog
  module AWS
    class CloudWatch
      class Real
        require 'fog/aws/parsers/cloud_watch/disable_alarm_actions'

        # Disables actions for the specified alarms
        # ==== Options
        # * AlarmNames<~Array>: The names of the alarms to disable actions for
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AmazonCloudWatch/latest/APIReference/API_DisableAlarmActions.html
        #

        def disable_alarm_actions(alarm_names)
          options = {}
          options.merge!(AWS.indexed_param('AlarmNames.member.%d', [*alarm_names]))
          request({
              'Action'    => 'DisableAlarmActions',
              :parser     => Fog::Parsers::AWS::CloudWatch::DisableAlarmActions.new
            }.merge(options))
        end
      end
    end
  end
end
