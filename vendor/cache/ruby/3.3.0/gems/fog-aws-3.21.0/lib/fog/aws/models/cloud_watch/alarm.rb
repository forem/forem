module Fog
  module AWS
    class CloudWatch
      class Alarm < Fog::Model
        identity :id, :aliases => 'AlarmName'

        attribute :actions_enabled, :aliases => 'ActionsEnabled'
        attribute :alarm_actions, :aliases => 'AlarmActions'
        attribute :arn, :aliases => 'AlarmArn'
        attribute :alarm_configuration_updated_timestamp, :aliases => 'AlarmConfigurationUpdatedTimestamp'
        attribute :alarm_description, :aliases => 'AlarmDescription'
        attribute :comparison_operator, :aliases => 'ComparisonOperator'
        attribute :dimensions, :aliases => 'Dimensions'
        attribute :evaluation_periods, :aliases => 'EvaluationPeriods'
        attribute :insufficient_data_actions, :aliases => 'InsufficientDataActions'
        attribute :metric_name, :aliases => 'MetricName'
        attribute :namespace, :aliases => 'Namespace'
        attribute :ok_actions, :aliases => 'OKActions'
        attribute :period, :aliases => 'Period'
        attribute :state_reason, :aliases => 'StateReason'
        attribute :state_reason_data, :aliases => 'StateReasonData'
        attribute :state_updated_timestamp, :aliases => 'StateUpdatedTimestamp'
        attribute :state_value, :aliases => 'StateValue'
        attribute :statistic, :aliases => 'Statistic'
        attribute :threshold, :aliases => 'Threshold'
        attribute :unit, :aliases => 'Unit'

        def initialize(attributes)
          self.namespace ||= "AWS/EC2"
          self.evaluation_periods ||= 1
          super
        end

        def save
          requires :id
          requires :comparison_operator
          requires :metric_name
          requires :period
          requires :statistic
          requires :threshold
          requires :namespace
          requires :evaluation_periods


          options = Hash[self.class.aliases.map { |key, value| [key, send(value)] }]
          options.delete_if { |key, value| value.nil? }

          service.put_metric_alarm(options)
          reload
        end

        def destroy
          requires :id
          service.delete_alarms(id)
        end
      end
    end
  end
end
