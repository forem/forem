module Fog
  module Parsers
    module AWS
      module AutoScaling
        class TerminateInstanceInAutoScalingGroup < Fog::Parsers::Base
          def reset
            @results = { 'Activity' => {} }
            @response = { 'TerminateInstanceInAutoScalingGroupResult' => {}, 'ResponseMetadata' => {} }
          end

          def end_element(name)
            case name
            when 'ActivityId', 'AutoScalingGroupName', 'Cause',
                 'Description', 'StatusCode', 'StatusMessage'
              @results['Activity'][name] = value
            when 'EndTime', 'StartTime'
              @results['Activity'][name] = Time.parse(value)
            when 'Progress'
              @results['Activity'][name] = value.to_i

            when 'RequestId'
              @response['ResponseMetadata'][name] = value

            when 'TerminateInstanceInAutoScalingGroupResponse'
              @response['TerminateInstanceInAutoScalingGroupResult'] = @results
            end
          end
        end
      end
    end
  end
end
