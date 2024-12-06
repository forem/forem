module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/describe_scaling_process_types'

        # Returns scaling process types for use in the resume_processes and
        # suspend_processes actions.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #     * 'DescribeScalingProcessTypesResult'<~Hash>:
        #       * 'Processes'<~Array>:
        #         * processtype<~Hash>:
        #           * 'ProcessName'<~String> - The name of a process.
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DescribeScalingProcessTypes.html
        #
        def describe_scaling_process_types()
          request({
            'Action'    => 'DescribeScalingProcessTypes',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::AutoScaling::DescribeScalingProcessTypes.new
          })
        end
      end

      class Mock
        def describe_scaling_process_types()
          results = { 'Processes' => [] }
          self.data[:process_types].each do |process_type|
            results['Processes'] << { 'ProcessName' => process_type }
          end
          response = Excon::Response.new
          response.status = 200
          response.body = {
            'DescribeScalingProcessTypesResult' => results,
            'ResponseMetadata' => { 'RequestId' => Fog::AWS::Mock.request_id }
          }
          response
        end
      end
    end
  end
end
