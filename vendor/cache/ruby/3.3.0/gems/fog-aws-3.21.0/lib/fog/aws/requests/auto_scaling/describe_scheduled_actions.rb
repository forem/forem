module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/describe_scheduled_actions'

        # List all the actions scheduled for your Auto Scaling group that
        # haven't been executed. To see a list of action already executed, see
        # the activity record returned in describe_scaling_activities.
        #
        # ==== Parameters
        # * options<~Hash>:
        #   * 'AutoScalingGroupName'<~String> - The name of the Auto Scaling
        #     group.
        #   * 'EndTime'<~Time> - The latest scheduled start time to return. If
        #     scheduled action names are provided, this field will be ignored.
        #   * 'MaxRecords'<~Integer> - The maximum number of scheduled actions
        #     to return.
        #   * 'NextToken'<~String> - The token returned by a previous call to
        #     indicate that there is more data available.
        #   * 'ScheduledActionNames'<~Array> - A list of scheduled actions to
        #     be described. If this list is omitted, all scheduled actions are
        #     described. The list of requested scheduled actions cannot contain
        #     more than 50 items. If an auto scaling group name is provided,
        #     the results are limited to that group. If unknown scheduled
        #     actions are requested, they are ignored with no error.
        #   * 'StartTime'<~Time> - The earliest scheduled start time to return.
        #     If scheduled action names are provided, this field will be
        #     ignored.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #     * 'DescribeScheduledActionsResponse'<~Hash>:
        #       * 'ScheduledUpdateGroupActions'<~Array>:
        #         * scheduledupdatesroupAction<~Hash>:
        #           * 'AutoScalingGroupName'<~String> - The name of the Auto
        #             Scaling group to be updated.
        #         * 'DesiredCapacity'<~Integer> -The number of instances you
        #           prefer to maintain in your Auto Scaling group.
        #         * 'EndTime'<~Time> - The time for this action to end.
        #         * 'MaxSize'<~Integer> - The maximum size of the Auto Scaling
        #           group.
        #         * 'MinSize'<~Integer> - The minimum size of the Auto Scaling
        #           group.
        #         * 'Recurrence'<~String> - The time when recurring future
        #           actions will start. Start time is specified by the user
        #           following the Unix cron syntax format.
        #         * 'ScheduledActionARN'<~String> - The Amazon Resource Name
        #           (ARN) of this scheduled action.
        #         * 'StartTime'<~Time> - The time for this action to start.
        #         * 'Time'<~Time> - The time that the action is scheduled to
        #           occur. This value can be up to one month in the future.
        #       * 'NextToken'<~String> - Acts as a paging mechanism for large
        #         result sets. Set to a non-empty string if there are
        #         additional results waiting to be returned. Pass this in to
        #         subsequent calls to return additional results.
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DescribeScheduledActions.html
        #
        def describe_scheduled_actions(options = {})
          if scheduled_action_names = options.delete('ScheduledActionNames')
            options.merge!(AWS.indexed_param('ScheduledActionNames.member.%d', [*scheduled_action_names]))
          end
          request({
            'Action' => 'DescribeScheduledActions',
            :parser  => Fog::Parsers::AWS::AutoScaling::DescribeScheduledActions.new
          }.merge!(options))
        end
      end

      class Mock
        def describe_scheduled_actions(options = {})
          Fog::Mock.not_implemented
        end
      end
    end
  end
end
