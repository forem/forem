module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/single_policy'

        # Get Policy
        #
        # ==== Parameters
        # * 'PolicyArn'<~String>: The Amazon Resource Name (ARN). ARNs are unique identifiers for AWS resources.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * Arn<~String> The Amazon Resource Name (ARN). ARNs are unique identifiers for AWS resources.
        #     * AttachmentCount<~Integer> The number of entities (users, groups, and roles) that the policy is attached to.
        #     * CreateDate<~DateTime> The date and time, in ISO 8601 date-time format, when the policy was created.
        #     * DefaultVersionId<~String> The identifier for the version of the policy that is set as the default version.
        #     * Description<~String> A friendly description of the policy.
        #     * IsAttachable<~Boolean> Specifies whether the policy can be attached to an IAM user, group, or role.
        #     * Path<~String> The path to the policy.
        #     * PolicyId<~String> The stable and unique string identifying the policy.
        #     * PolicyName<~String> The friendly name (not ARN) identifying the policy.
        #     * UpdateDate<~DateTime> The date and time, in ISO 8601 date-time format, when the policy was last updated.
        #
        # ==== See Also
        # http://docs.aws.amazon.com/IAM/latest/APIReference/API_GetPolicy.html
        #
        def get_policy(policy_arn)
          request({
            'Action'    => 'GetPolicy',
            'PolicyArn' => policy_arn,
            :parser     => Fog::Parsers::AWS::IAM::SinglePolicy.new
          })
        end
      end

      class Mock
        def get_policy(policy_arn)
          managed_policy = self.data[:managed_policies][policy_arn]

          unless managed_policy
            raise Fog::AWS::IAM::NotFound, "Policy #{policy_arn} does not exist."
          end

          Excon::Response.new.tap do |response|
            response.body = {
              'Policy'    => managed_policy,
              'RequestId' => Fog::AWS::Mock.request_id
            }
            response.status = 200
          end
        end
      end
    end
  end
end
