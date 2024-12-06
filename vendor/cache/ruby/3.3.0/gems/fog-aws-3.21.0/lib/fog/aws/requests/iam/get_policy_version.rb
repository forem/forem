module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/policy_version'

        # Contains information about a version of a managed policy.
        #
        # ==== Parameters
        # * PolicyArn<~String>: The Amazon Resource Name (ARN). ARNs are unique identifiers for AWS resources.
        # * VersionId<~String>: Identifies the policy version to retrieve.
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'RequestId'<~String> - Id of the request
        #     * 'PolicyVersion'<~Array>:
        #       * CreateDate<~DateTime> The date and time, in ISO 8601 date-time format, when the policy version was created.
        #       * Document<~String> The policy document. Pattern: [\u0009\u000A\u000D\u0020-\u00FF]+
        #       * IsDefaultVersion<~String> Specifies whether the policy version is set as the policy's default version.
        #       * VersionId<~String> The identifier for the policy version.
        # ==== See Also
        # http://docs.aws.amazon.com/IAM/latest/APIReference/API_PolicyVersion.html
        #
        def get_policy_version(policy_arn, version_id)
          request({
            'Action'    => 'GetPolicyVersion',
            'PolicyArn' => policy_arn,
            'VersionId' => version_id,
            :parser     => Fog::Parsers::AWS::IAM::PolicyVersion.new
          })
        end
      end

      class Mock
        def get_policy_version(policy_arn, version_id)
          managed_policy_versions = self.data[:managed_policy_versions][policy_arn]

          unless managed_policy_versions
            raise Fog::AWS::IAM::NotFound, "Policy #{policy_arn} version #{version_id} does not exist."
          end

          version = managed_policy_versions[version_id]

          unless version
            raise Fog::AWS::IAM::NotFound, "Policy #{policy_arn} version #{version_id} does not exist."
          end

          Excon::Response.new.tap do |response|
            response.body = {
              'PolicyVersion' => version,
              'RequestId'     => Fog::AWS::Mock.request_id
            }
            response.status = 200
          end
        end
      end
    end
  end
end
