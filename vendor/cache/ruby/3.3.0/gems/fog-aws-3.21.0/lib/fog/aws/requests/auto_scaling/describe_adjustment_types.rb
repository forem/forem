module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/describe_adjustment_types'

        # Returns policy adjustment types for use in the put_scaling_policy
        # action.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #     * 'DescribeAdjustmentTypesResponse'<~Hash>:
        #       * 'AdjustmentTypes'<~Array>:
        #         * 'AdjustmentType'<~String> - A policy adjustment type.
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DescribeAdjustmentTypes.html
        #
        def describe_adjustment_types()
          request({
            'Action'    => 'DescribeAdjustmentTypes',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::AutoScaling::DescribeAdjustmentTypes.new
          })
        end
      end

      class Mock
        def describe_adjustment_types()
          results = { 'AdjustmentTypes' => [] }
          self.data[:adjustment_types].each do |adjustment_type|
            results['AdjustmentTypes'] << { 'AdjustmentType' => adjustment_type }
          end
          response = Excon::Response.new
          response.status = 200
          response.body = {
            'DescribeAdjustmentTypesResult' => results,
            'ResponseMetadata' => { 'RequestId' => Fog::AWS::Mock.request_id }
          }
          response
        end
      end
    end
  end
end
