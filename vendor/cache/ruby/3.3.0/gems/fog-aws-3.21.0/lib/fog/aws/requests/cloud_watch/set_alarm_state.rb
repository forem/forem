module Fog
  module AWS
    class CloudWatch
      class Real
        require 'fog/aws/parsers/cloud_watch/set_alarm_state'

        # Temporarily sets the state of an alarm
        # ==== Options
        # * AlarmName<~String>: The names of the alarm
        # * StateReason<~String>: The reason that this alarm is set to this specific state (in human-readable text format)
        # * StateReasonData<~String>: The reason that this alarm is set to this specific state (in machine-readable JSON format)
        # * StateValue<~String>: The value of the state
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AmazonCloudWatch/latest/APIReference/API_SetAlarmState.html
        #

        def set_alarm_state(options)
          request({
              'Action'    => 'SetAlarmState',
              :parser     => Fog::Parsers::AWS::CloudWatch::SetAlarmState.new
            }.merge(options))
        end
      end
    end
  end
end
