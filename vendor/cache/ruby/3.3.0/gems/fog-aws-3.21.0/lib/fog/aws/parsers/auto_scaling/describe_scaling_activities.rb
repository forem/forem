module Fog
  module Parsers
    module AWS
      module AutoScaling
        class DescribeScalingActivities < Fog::Parsers::Base
          def reset
            reset_activity
            @results = { 'Activities' => [] }
            @response = { 'DescribeScalingActivitiesResult' => {}, 'ResponseMetadata' => {} }
          end

          def reset_activity
            @activity = {}
          end

          def end_element(name)
            case name
            when 'member'
              @results['Activities'] << @activity
              reset_activity

            when 'ActivityId', 'AutoScalingGroupName', 'Cause', 'Description',
                 'StatusCode', 'StatusMessage'
              @activity[name] = value
            when 'EndTime', 'StartTime'
              @activity[name] = Time.parse(value)
            when 'Progress'
              @activity[name] = value.to_i

            when 'NextToken'
              @results[name] = value

            when 'RequestId'
              @response['ResponseMetadata'][name] = value

            when 'DescribeScalingActivitiesResponse'
              @response['DescribeScalingActivitiesResult'] = @results
            end
          end
        end
      end
    end
  end
end
