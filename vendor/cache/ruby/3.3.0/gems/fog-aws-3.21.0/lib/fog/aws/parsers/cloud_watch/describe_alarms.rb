module Fog
  module Parsers
    module AWS
      module CloudWatch
        class DescribeAlarms < Fog::Parsers::Base
          def reset
            @response = { 'DescribeAlarmsResult' => {'MetricAlarms' => []}, 'ResponseMetadata' => {} }
            reset_metric_alarms
          end

          def reset_metric_alarms
            @metric_alarms = {
              'Dimensions' => [],
              'AlarmActions' => [],
              'OKActions' => [],
              'InsufficientDataActions' => []
            }
          end

          def reset_dimension
            @dimension = {}
          end

          def reset_alarm_actions
            @alarm_actions = {}
          end

          def reset_ok_actions
            @ok_actions = {}
          end

          def reset_insufficient_data_actions
            @insufficient_data_actions = {}
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'Dimensions'
              @in_dimensions = true
            when 'AlarmActions'
              @in_alarm_actions = true
            when 'OKActions'
              @in_ok_actions = true
            when 'InsufficientDataActions'
              @in_insufficient_data_actions = true
            when 'member'
              reset_dimension if @in_dimensions
              reset_alarm_actions if @in_alarm_actions
              reset_ok_actions if @in_ok_actions
              reset_insufficient_data_actions if @in_insufficient_data_actions
            end
          end

          def end_element(name)
            case name
            when 'Name', 'Value'
              @dimension[name] = value
            when 'AlarmConfigurationUpdatedTimestamp', 'StateUpdatedTimestamp'
              @metric_alarms[name] = Time.parse value
            when 'Period', 'EvaluationPeriods'
              @metric_alarms[name] = value.to_i
            when 'Threshold'
              @metric_alarms[name] = value.to_f
            when 'AlarmActions'
              @in_alarm_actions = false
            when 'OKActions'
              @in_ok_actions = false
            when 'InsufficientDataActions'
              @in_insufficient_data_actions = false
            when 'AlarmName', 'Namespace', 'MetricName', 'AlarmDescription', 'AlarmArn', 'Unit',
              'StateValue', 'Statistic', 'ComparisonOperator', 'StateReason', 'ActionsEnabled'
              @metric_alarms[name] = value
            when 'StateUpdatedTimestamp', 'AlarmConfigurationUpdatedTimestamp'
              @metric_alarms[name] = Time.parse value
            when 'Dimensions'
              @in_dimensions = false
            when 'RequestId'
              @response['ResponseMetadata'][name] = value
            when 'NextToken'
              @response['ResponseMetadata'][name] = value
            when 'member'
              if @in_dimensions
                @metric_alarms['Dimensions'] << @dimension
              elsif @in_alarm_actions
                @metric_alarms['AlarmActions'] << value.to_s.strip
              elsif @in_ok_actions
                @metric_alarms['OKActions'] << value.to_s.strip
              elsif @in_insufficient_data_actions
                @metric_alarms['InsufficientDataActions'] << value.to_s.strip
              elsif @metric_alarms.key?('AlarmName')
                @response['DescribeAlarmsResult']['MetricAlarms']  << @metric_alarms
                reset_metric_alarms
              elsif @response['DescribeAlarmsResult']['MetricAlarms'].last != nil
                @response['DescribeAlarmsResult']['MetricAlarms'].last.merge!( @metric_alarms)
              end
            end
          end
        end
      end
    end
  end
end
