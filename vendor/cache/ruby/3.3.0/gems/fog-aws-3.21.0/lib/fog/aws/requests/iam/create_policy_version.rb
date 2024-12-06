module Fog
  module AWS
    class IAM
      class Real
        require 'fog/aws/parsers/iam/policy_version'

        # Creates a managed policy
        #
        # ==== Parameters
        # * policy_arn<~String>: arn of the policy
        # * policy_document<~Hash>: policy document, see: http://docs.amazonwebservices.com/IAM/latest/UserGuide/PoliciesOverview.html
        # * set_as_default<~Boolean>: sets policy to default version
        #
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
        # http://docs.aws.amazon.com/IAM/latest/APIReference/API_CreatePolicyVersion.html
        #
        def create_policy_version(policy_arn, policy_document, set_as_default=true)
          request({
            'Action'          => 'CreatePolicyVersion',
            'PolicyArn'       => policy_arn,
            'PolicyDocument'  => Fog::JSON.encode(policy_document),
            'SetAsDefault'    => set_as_default,
            :parser           => Fog::Parsers::AWS::IAM::PolicyVersion.new
          }.reject {|_, value| value.nil?})
        end
      end

      class Mock
        def create_policy_version(policy_arn, policy_document, set_as_default=true)
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
