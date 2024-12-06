module Fog
  module AWS
    class CloudWatch
      class AlarmDatum < Fog::Model
        attribute :alarm_name, :aliases => 'AlarmName'
        attribute :metric_name, :aliases => 'MetricName'
        attribute :namespace, :aliases => 'Namespace'
        attribute :dimensions, :aliases => 'Dimensions'
        attribute :alarm_description, :aliases => 'AlarmDescription'
        attribute :alarm_arn, :aliases => 'AlarmArn'
        attribute :state_value, :aliases => 'StateValue'
        attribute :statistic, :aliases => 'Statistic'
        attribute :comparison_operator, :aliases => 'ComparisonOperator'
        attribute :state_reason, :aliases => 'StateReason'
        attribute :action_enabled, :aliases => 'ActionsEnabled'
        attribute :period, :aliases => 'Period'
        attribute :evaluation_periods, :aliases => 'EvaluationPeriods'
        attribute :threshold, :aliases => 'Threshold'
        attribute :alarm_actions, :aliases => 'AlarmActions'
        attribute :ok_actions, :aliases => 'OKActions'
        attribute :insufficient_actions, :aliases => 'InsufficientDataActions'
        attribute :unit, :aliases => 'Unit'
        attribute :state_updated_timestamp, :aliases => 'StateUpdatedTimestamp'
        attribute :alarm_configuration_updated_timestamp, :aliases => 'AlarmConfigurationUpdatedTimestamp'

        def save
          requires :alarm_name
          requires :comparison_operator
          requires :evaluation_periods
          requires :metric_name
          requires :namespace
          requires :period
          requires :statistic
          requires :threshold

          alarm_definition = {
              'AlarmName' => alarm_name,
              'ComparisonOperator' => comparison_operator,
              'EvaluationPeriods' => evaluation_periods,
              'MetricName' => metric_name,
              'Namespace' => namespace,
              'Period' => period,
              'Statistic' => statistic,
              'Threshold' => threshold
              }

          alarm_definition.merge!('ActionsEnabled' => action_enabled) if action_enabled
          alarm_definition.merge!('AlarmActions' => alarm_actions) if alarm_actions
          alarm_definition.merge!('AlarmDescription' => alarm_description) if alarm_description

          #dimension is an array of Name/Value pairs, ex. [{'Name'=>'host', 'Value'=>'localhost'},{'Name'=>'version', 'Value'=>'0.11.0'}]
          alarm_definition.merge!('Dimensions' => dimensions) if dimensions
          alarm_definition.merge!('InsufficientDataActions' => insufficient_actions) if insufficient_actions
          alarm_definition.merge!('OKActions' => ok_actions) if ok_actions
          alarm_definition.merge!('Unit' => unit) if unit

          service.put_metric_alarm(alarm_definition)
          true
        end
      end
    end
  end
end
