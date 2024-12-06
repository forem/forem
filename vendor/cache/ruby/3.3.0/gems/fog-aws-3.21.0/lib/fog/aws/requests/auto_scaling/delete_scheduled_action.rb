module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/basic'

        # Deletes a scheduled action previously created using the
        # put_scheduled_update_group_action.
        #
        # ==== Parameters
        # * auto_scaling_group_name<~String> - The name of the Auto Scaling
        #   group.
        # * scheduled_action_name<~String> - The name of the action you want to
        #   delete.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DeleteScheduledAction.html
        #
        def delete_scheduled_action(auto_scaling_group_name, scheduled_action_name)
          request({
            'Action'               => 'DeleteScheduledAction',
            'AutoScalingGroupName' => auto_scaling_group_name,
            'ScheduledActionName'  => scheduled_action_name,
            :parser                => Fog::Parsers::AWS::AutoScaling::Basic.new
          })
        end
      end

      class Mock
        def delete_scheduled_action(auto_scaling_group_name, scheduled_action_name)
          Fog::Mock.not_implemented
        end
      end
    end
  end
end
