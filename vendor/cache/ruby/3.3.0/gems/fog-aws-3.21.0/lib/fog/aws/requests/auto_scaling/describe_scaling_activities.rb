module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/describe_scaling_activities'

        # Returns the scaling activities for the specified Auto Scaling group.
        #
        # If the specified activity_ids list is empty, all the activities from
        # the past six weeks are returned. Activities are sorted by completion
        # time. Activities still in progress appear first on the list.
        #
        # This action supports pagination. If the response includes a token,
        # there are more records available. To get the additional records,
        # repeat the request with the response token as the NextToken
        # parameter.
        #
        # ==== Parameters
        # * options<~Hash>:
        #   * 'ActivityIds'<~Array> - A list containing the activity IDs of the
        #     desired scaling activities. If this list is omitted, all
        #     activities are described. If an AutoScalingGroupName is provided,
        #     the results are limited to that group. The list of requested
        #     activities cannot contain more than 50 items. If unknown
        #     activities are requested, they are ignored with no error.
        #   * 'AutoScalingGroupName'<~String> - The name of the Auto Scaling
        #     group.
        #   * 'MaxRecords'<~Integer> - The maximum number of scaling activities
        #     to return.
        #   * 'NextToken'<~String> - The token returned by a previous call to
        #     indicate that there is more data available.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #     * 'DescribeScalingActivitiesResponse'<~Hash>:
        #       * 'Activities'<~Array>:
        #         * 'ActivityId'<~String> - Specifies the ID of the activity.
        #         * 'AutoScalingGroupName'<~String> - The name of the Auto
        #           Scaling group.
        #         * 'Cause'<~String> - Contins the reason the activity was
        #           begun.
        #         * 'Description'<~String> - Contains a friendly, more verbose
        #           description of the scaling activity.
        #         * 'EndTime'<~Time> - Provides the end time of this activity.
        #         * 'Progress'<~Integer> - Specifies a value between 0 and 100
        #           that indicates the progress of the activity.
        #         * 'StartTime'<~Time> - Provides the start time of this
        #           activity.
        #         * 'StatusCode'<~String> - Contains the current status of the
        #           activity.
        #         * 'StatusMessage'<~String> - Contains a friendly, more
        #           verbose description of the activity status.
        #       * 'NextToken'<~String> - Acts as a paging mechanism for large
        #         result sets. Set to a non-empty string if there are
        #         additional results waiting to be returned. Pass this in to
        #         subsequent calls to return additional results.
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DescribeScalingActivities.html
        #
        def describe_scaling_activities(options = {})
          if activity_ids = options.delete('ActivityIds')
            options.merge!(AWS.indexed_param('ActivityIds.member.%d', [*activity_ids]))
          end
          request({
            'Action' => 'DescribeScalingActivities',
            :parser  => Fog::Parsers::AWS::AutoScaling::DescribeScalingActivities.new
          }.merge!(options))
        end
      end

      class Mock
        def describe_scaling_activities(options = {})
          Fog::Mock.not_implemented
        end
      end
    end
  end
end
