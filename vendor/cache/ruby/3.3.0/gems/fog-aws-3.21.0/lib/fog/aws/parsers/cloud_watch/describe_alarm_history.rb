module Fog
  module Parsers
    module AWS
      module CloudWatch
        class DescribeAlarmHistory < Fog::Parsers::Base
          def reset
            @response = { 'DescribeAlarmHistoryResult' => {'AlarmHistoryItems' => []}, 'ResponseMetadata' => {} }
            reset_alarm_history_item
          end

          def reset_alarm_history_item
            @alarm_history_item = {}
          end

          def start_element(name, attrs = [])
            super
          end

          def end_element(name)
            case name
            when 'AlarmName', 'HistoryItemType', 'HistorySummary'
              @alarm_history_item[name] = value
            when 'Timestamp'
              @alarm_history_item[name] = Time.parse value
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            when 'NextToken'
              @response['ResponseMetadata'][name] = value
            when 'member'
              @response['DescribeAlarmHistoryResult']['AlarmHistoryItems']  << @alarm_history_item
              reset_alarm_history_item
            end
          end
        end
      end
    end
  end
end
