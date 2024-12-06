module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/basic'

        # Creates a scheduled scaling action for a Auto Scaling group. If you
        # leave a parameter unspecified, the corresponding value remains
        # unchanged in the affected Auto Scaling group.
        #
        # ==== Parameters
        # * auto_scaling_group_name<~String> - The name or ARN of the Auto
        #   Scaling Group.
        # * scheduled_action_name<~String> - Name of this scaling action.
        # * time<~Datetime> - The time for this action to start (deprecated:
        #   use StartTime, EndTime and Recurrence).
        # * options<~Hash>:
        #   * 'DesiredCapacity'<~Integer> - The number of EC2 instances that
        #     should be running in this group.
        #   * 'EndTime'<~DateTime> - The time for this action to end.
        #   * 'MaxSize'<~Integer> - The maximum size for the Auto Scaling
        #     group.
        #   * 'MinSize'<~Integer> - The minimum size for the Auto Scaling
        #     group.
        #   * 'Recurrence'<~String> - The time when recurring future actions
        #     will start. Start time is specified by the user following the
        #     Unix cron syntax format. When StartTime and EndTime are specified
        #     with Recurrence, they form the boundaries of when the recurring
        #     action will start and stop.
        #   * 'StartTime'<~DateTime> - The time for this action to start
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_PutScheduledUpdateGroupAction.html
        #
        def put_scheduled_update_group_action(auto_scaling_group_name, scheduled_action_name, time=nil, options = {})
          # The 'Time' paramenter is now an alias for StartTime and needs to be identical if specified.
          time = options['StartTime'].nil? ? time : options['StartTime']
          if !time.nil?
            time = time.class == Time ? time.utc.iso8601 : Time.parse(time).utc.iso8601
          end
          request({
            'Action'               => 'PutScheduledUpdateGroupAction',
            'AutoScalingGroupName' => auto_scaling_group_name,
            'ScheduledActionName'  => scheduled_action_name,
            'Time'                 => time,
            :parser                => Fog::Parsers::AWS::AutoScaling::Basic.new
          }.merge!(options))
        end
      end

      class Mock
        def put_scheduled_update_group_action(auto_scaling_group_name, scheduled_policy_name, time, options = {})
          Fog::Mock.not_implemented
        end
      end
    end
  end
end
