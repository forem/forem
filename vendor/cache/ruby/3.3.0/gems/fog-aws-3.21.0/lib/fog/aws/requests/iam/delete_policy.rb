module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/basic'

        # Deletes a manged policy
        #
        # ==== Parameters
        # * policy_arn<~String>: arn of the policy
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.aws.amazon.com/IAM/latest/APIReference/API_DeletePolicy.html
        #
        def delete_policy(policy_arn)
          request(
            'Action'          => 'DeletePolicy',
            'PolicyArn'       => policy_arn,
            :parser           => Fog::Parsers::AWS::IAM::Basic.new
          )
        end
      end

      class Mock
        def delete_policy(policy_arn)
          response = Excon::Response.new
          policy = self.data[:managed_policies][policy_arn]

          if policy.nil?
            raise Fog::AWS::IAM::NotFound.new("Policy #{policy_arn} does not exist or is not attachable.")
          end

          self.data[:managed_policies].delete(policy_arn)
          response.body = {"RequestId" => Fog::AWS::Mock.request_id}
          response
        end
      end
    end
  end
end
