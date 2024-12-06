module Fog
  module AWS
    class CloudWatch
      class Real
        require 'fog/aws/parsers/cloud_watch/describe_alarm_history'

        # Retrieves history for the specified alarm
        # ==== Options
        # * AlarmName<~String>: The name of the alarm
        # * EndDate<~DateTime>: The ending date to retrieve alarm history
        # * HistoryItemType<~String>: The type of alarm histories to retrieve
        # * MaxRecords<~Integer>: The maximum number of alarm history records to retrieve
        # * NextToken<~String> The token returned by a previous call to indicate that there is more data available
        # * StartData<~DateTime>: The starting date to retrieve alarm history
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AmazonCloudWatch/latest/APIReference/index.html?API_DescribeAlarmHistory.html
        #

        def describe_alarm_history(options={})
          request({
              'Action'    => 'DescribeAlarmHistory',
              :parser     => Fog::Parsers::AWS::CloudWatch::DescribeAlarmHistory.new
            }.merge(options))
        end
      end
    end
  end
end
