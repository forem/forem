module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/basic'

        # Remove a user from a group
        #
        # ==== Parameters
        # * policy_arn<~String>: arn of the policy
        # * version_id<~String>: version of policy to delete
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/IAM/latest/APIReference/API_SetDefaultPolicyVersion.html
        #
        def set_default_policy_version(policy_arn, version_id)
          request(
            'Action'    => 'SetDefaultPolicyVersion',
            'PolicyArn' => policy_arn,
            'VersionId' => version_id,
            :parser     => Fog::Parsers::AWS::IAM::Basic.new
          )
        end
      end
      
      class Mock
        def set_default_policy_version(policy_arn, version_id)
          Excon::Response.new.tap do |response|
            response.body = { 'RequestId' => Fog::AWS::Mock.request_id }
            response.status = 200
          end
        end
      end

    end
  end
end
