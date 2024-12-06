module Fog
  module Parsers
    module AWS
      module AutoScaling
        class DescribeScheduledActions < Fog::Parsers::Base
          def reset
            reset_scheduled_update_group_action
            @results = { 'ScheduledUpdateGroupActions' => [] }
            @response = { 'DescribeScheduledActionsResult' => {}, 'ResponseMetadata' => {} }
          end

          def reset_scheduled_update_group_action
            @scheduled_update_group_action = {}
          end

          def end_element(name)
            case name
            when 'member'
              @results['ScheduledUpdateGroupActions'] << @scheduled_update_group_action
              reset_scheduled_update_group_action

            when 'AutoScalingGroupName', 'ScheduledActionARN', 'ScheduledActionName', 'Recurrence'
              @scheduled_update_group_action[name] = value
            when 'DesiredCapacity', 'MaxSize', 'MinSize'
              @scheduled_update_group_action[name] = value.to_i
            when 'Time', 'StartTime', 'EndTime'
              @scheduled_update_group_action[name] = Time.parse(value)

            when 'NextToken'
              @results[name] = value

            when 'RequestId'
              @response['ResponseMetadata'][name] = value

            when 'DescribeScheduledActionsResponse'
              @response['DescribeScheduledActionsResult'] = @results
            end
          end
        end
      end
    end
  end
end
