module Fog
  module Parsers
    module AWS
      module AutoScaling
        class DescribePolicies < Fog::Parsers::Base
          def reset
            reset_scaling_policy
            reset_alarm
            @results = { 'ScalingPolicies' => [] }
            @response = { 'DescribePoliciesResult' => {}, 'ResponseMetadata' => {} }
            @in_alarms = false
          end

          def reset_scaling_policy
            @scaling_policy = { 'Alarms' => [] }
          end

          def reset_alarm
            @alarm = {}
          end

          def start_element(name, attrs = [])
            super
            case name
            when 'Alarms'
              @in_alarms = true
            end
          end

          def end_element(name)
            case name
            when 'AlarmARN', 'AlarmName'
              @alarm[name] = value

            when 'AdjustmentType', 'AutoScalingGroupName', 'PolicyARN', 'PolicyName'
              @scaling_policy[name] = value
            when 'Cooldown', 'MinAdjustmentStep', 'ScalingAdjustment'
              @scaling_policy[name] = value.to_i

            when 'NextToken'
              @results[name] = value

            when 'RequestId'
              @response['ResponseMetadata'][name] = value

            when 'DescribePoliciesResponse'
              @response['DescribePoliciesResult'] = @results

            when 'Alarms'
              @in_alarms = false
            when 'member'
              if @in_alarms
                @scaling_policy['Alarms'] << @alarm
                reset_alarm
              else
                @results['ScalingPolicies'] << @scaling_policy
                reset_scaling_policy
              end
            end
          end
        end
      end
    end
  end
end
