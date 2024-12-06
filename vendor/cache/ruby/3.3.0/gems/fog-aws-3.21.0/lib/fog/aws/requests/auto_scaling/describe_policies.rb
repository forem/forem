module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/describe_policies'

        # Returns descriptions of what each policy does. This action supports
        # pagination. If the response includes a token, there are more records
        # available. To get the additional records, repeat the request with the
        # response token as the NextToken parameter.
        #
        # ==== Parameters
        # * options<~Hash>:
        #   * 'AutoScalingGroupName'<~String> - The name of the Auto Scaling
        #     group.
        #   * 'MaxRecords'<~Integer> - The maximum number of policies that will
        #     be described with each call.
        #   * 'NextToken'<~String> - The token returned by a previous call to
        #     indicate that there is more data available.
        #   * PolicyNames<~Array> - A list of policy names or policy ARNs to be
        #     described. If this list is omitted, all policy names are
        #     described. If an auto scaling group name is provided, the results
        #     are limited to that group.The list of requested policy names
        #     cannot contain more than 50 items. If unknown policy names are
        #     requested, they are ignored with no error.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #     * 'DescribePoliciesResult'<~Hash>:
        #       * 'ScalingPolicies'<~Array>:
        #         * 'AdjustmentType'<~String> - Specifies whether the
        #           adjustment is an absolute number or a percentage of the
        #           current capacity.
        #         * 'Alarms'<~Array>:
        #           * 'AlarmARN'<~String> - The Amazon Resource Name (ARN) of
        #             the alarm.
        #           * 'AlarmName'<~String> - The name of the alarm.
        #         * 'AutoScalingGroupName'<~String> - The name of the Auto
        #           Scaling group associated with this scaling policy.
        #         * 'Cooldown'<~Integer> - The amount of time, in seconds,
        #           after a scaling activity completes before any further
        #           trigger-related scaling activities can start.
        #         * 'PolicyARN'<~String> - The Amazon Resource Name (ARN) of
        #           the policy.
        #         * 'PolicyName'<~String> - The name of the scaling policy.
        #         * 'ScalingAdjustment'<~Integer> - The number associated with
        #           the specified AdjustmentType. A positive value adds to the
        #           current capacity and a negative value removes from the
        #           current capacity.
        #       * 'NextToken'<~String> - Acts as a paging mechanism for large
        #         result sets. Set to a non-empty string if there are
        #         additional results waiting to be returned. Pass this in to
        #         subsequent calls to return additional results.
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DescribePolicies.html
        #
        def describe_policies(options = {})
          if policy_names = options.delete('PolicyNames')
            options.merge!(AWS.indexed_param('PolicyNames.member.%d', [*policy_names]))
          end
          request({
            'Action' => 'DescribePolicies',
            :parser  => Fog::Parsers::AWS::AutoScaling::DescribePolicies.new
          }.merge!(options))
        end
      end

      class Mock
        def describe_policies(options = {})
          results = { 'ScalingPolicies' => [] }
          policy_set = self.data[:scaling_policies]

          for opt_key, opt_value in options
            if opt_key == "PolicyNames" && opt_value != nil && opt_value != ""
              policy_set = policy_set.reject do |asp_name, asp_data|
                ![*options["PolicyNames"]].include?(asp_name)
              end
            elsif opt_key == "AutoScalingGroupName" && opt_value != nil && opt_value != ""
              policy_set = policy_set.reject do |asp_name, asp_data|
                options["AutoScalingGroupName"] != asp_data["AutoScalingGroupName"]
              end
            end
          end

          policy_set.each do |asp_name, asp_data|
            results['ScalingPolicies'] << {
              'PolicyName' => asp_name
            }.merge!(asp_data)
          end
          response = Excon::Response.new
          response.status = 200
          response.body = {
            'DescribePoliciesResult' => results,
            'ResponseMetadata' => { 'RequestId' => Fog::AWS::Mock.request_id }
          }
          response
        end
      end
    end
  end
end
