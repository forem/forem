module Fog
  module AWS
    class AutoScaling
      class Activity < Fog::Model
        identity  :id,                      :aliases => 'ActivityId'
        attribute :auto_scaling_group_name, :aliases => 'AutoScalingGroupName'
        attribute :cause,                   :aliases => 'Cause'
        attribute :description,             :aliases => 'Description'
        attribute :end_time,                :aliases => 'EndTime'
        attribute :progress,                :aliases => 'Progress'
        attribute :start_time,              :aliases => 'StartTime'
        attribute :status_code,             :aliases => 'StatusCode'
        attribute :status_message,          :aliases => 'StatusMessage'

        def group
          service.groups.get(attributes['AutoScalingGroupName'])
        end

        def save
          raise "Operation not supported"
        end
      end
    end
  end
end
