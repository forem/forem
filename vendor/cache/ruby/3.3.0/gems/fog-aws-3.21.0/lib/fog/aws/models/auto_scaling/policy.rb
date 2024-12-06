module Fog
  module AWS
    class AutoScaling
      class Policy < Fog::Model
        identity :id,                       :aliases => 'PolicyName'
        attribute :arn,                     :aliases => 'PolicyARN'
        attribute :adjustment_type,         :aliases => 'AdjustmentType'
        attribute :alarms,                  :aliases => 'Alarms'
        attribute :auto_scaling_group_name, :aliases => 'AutoScalingGroupName'
        attribute :cooldown,                :aliases => 'Cooldown'
        attribute :min_adjustment_step,     :aliases => 'MinAdjustmentStep'
        attribute :scaling_adjustment,      :aliases => 'ScalingAdjustment'

        def initialize(attributes)
          attributes['AdjustmentType']    ||= 'ChangeInCapacity'
          attributes['ScalingAdjustment'] ||= 1
          super
        end

        # TODO: implement #alarms
        # TODO: implement #auto_scaling_group

        def save
          requires :id
          requires :adjustment_type
          requires :auto_scaling_group_name
          requires :scaling_adjustment

          options = Hash[self.class.aliases.map { |key, value| [key, send(value)] }]
          options.delete_if { |key, value| value.nil? }

          service.put_scaling_policy(adjustment_type, auto_scaling_group_name, id, scaling_adjustment, options)
          reload
        end

        def destroy
          requires :id
          requires :auto_scaling_group_name
          service.delete_policy(auto_scaling_group_name, id)
        end
      end
    end
  end
end
