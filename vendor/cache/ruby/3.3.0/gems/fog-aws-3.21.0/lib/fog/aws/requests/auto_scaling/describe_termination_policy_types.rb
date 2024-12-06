module Fog
  module AWS
    class AutoScaling
      class Real
        require 'fog/aws/parsers/auto_scaling/describe_termination_policy_types'

        # Returns a list of all termination policies supported by Auto Scaling.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #     * 'DescribeTerminationPolicyTypesResult'<~Hash>:
        #       * 'TerminationPolicyTypes'<~Array>:
        #         * terminationtype<~String>:
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DescribeTerminationPolicyTypes.html
        #
        def describe_termination_policy_types()
          request({
            'Action'    => 'DescribeTerminationPolicyTypes',
            :idempotent => true,
            :parser     => Fog::Parsers::AWS::AutoScaling::DescribeTerminationPolicyTypes.new
          })
        end
      end

      class Mock
        def describe_termination_policy_types()
          results = { 'TerminationPolicyTypes' => [] }
          self.data[:termination_policy_types].each do |termination_policy_type|
            results['TerminationPolicyTypes'] << termination_policy_type
          end
          response = Excon::Response.new
          response.status = 200
          response.body = {
            'DescribeTerminationPolicyTypesResult' => results,
            'ResponseMetadata' => { 'RequestId' => Fog::AWS::Mock.request_id }
          }
          response
        end
      end
    end
  end
end
