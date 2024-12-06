require 'fog/aws/models/cloud_watch/alarm_history'

module Fog
  module AWS
    class CloudWatch
      class AlarmHistories < Fog::Collection
        model Fog::AWS::CloudWatch::AlarmHistory

        def all(conditions={})
          data = service.describe_alarm_history(conditions).body['DescribeAlarmHistoryResult']['AlarmHistoryItems']
          load(data) # data is an array of attribute hashes
        end
      end
    end
  end
end
