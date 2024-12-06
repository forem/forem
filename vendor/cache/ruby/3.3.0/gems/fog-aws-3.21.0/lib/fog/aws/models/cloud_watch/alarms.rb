require 'fog/aws/models/cloud_watch/alarm'

module Fog
  module AWS
    class CloudWatch
      class Alarms < Fog::Collection
        model Fog::AWS::CloudWatch::Alarm

        def all
          data = []
          next_token = nil
          loop do
            body = service.describe_alarms('NextToken' => next_token).body
            data += body['DescribeAlarmsResult']['MetricAlarms']
            next_token = body['ResponseMetadata']['NextToken']
            break if next_token.nil?
          end
          load(data)
        end

        def get(identity)
          data = service.describe_alarms('AlarmNames' => identity).body['DescribeAlarmsResult']['MetricAlarms'].first
          new(data) unless data.nil?
        end

        #alarm_names is an array of alarm names
        def delete(alarm_names)
          service.delete_alarms(alarm_names)
          true
        end

        def disable(alarm_names)
          service.disable_alarm_actions(alarm_names)
          true
        end

        def enable(alarm_names)
          service.enable_alarm_actions(alarm_names)
          true
        end
      end
    end
  end
end
