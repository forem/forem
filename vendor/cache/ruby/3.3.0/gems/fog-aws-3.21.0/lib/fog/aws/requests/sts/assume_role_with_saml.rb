module Fog
  module AWS
    class STS
      class Real
        require 'fog/aws/parsers/sts/assume_role_with_saml'

        # Assume Role with SAML
        #
        # ==== Parameters
        # * role_arn<~String> - The ARN of the role the caller is assuming.
        # * principal_arn<~String> - The Amazon Resource Name (ARN) of the SAML provider in IAM that describes the IdP.
        # * saml_assertion<~String> - The base-64 encoded SAML authentication response provided by the IdP.
        # * policy<~String> - An optional JSON policy document
        # * duration<~Integer> - Duration (of seconds) for the assumed role credentials to be valid (default 3600)
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'Arn'<~String>: The ARN of the assumed role/user
        #     * 'AccessKeyId'<~String>: The AWS access key of the temporary credentials for the assumed role
        #     * 'SecretAccessKey'<~String>: The AWS secret key of the temporary credentials for the assumed role
        #     * 'SessionToken'<~String>: The AWS session token of the temporary credentials for the assumed role
        #     * 'Expiration'<~Time>: The expiration time of the temporary credentials for the assumed role
        #
        # ==== See Also
        # http://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRoleWithSAML.html
        #

        def assume_role_with_saml(role_arn, principal_arn, saml_assertion, policy=nil, duration=3600)
          request_unsigned({
            'Action'          => 'AssumeRoleWithSAML',
            'RoleArn'         => role_arn,  
            'PrincipalArn'    => principal_arn,
            'SAMLAssertion'   => saml_assertion,
            'Policy'          => policy && Fog::JSON.encode(policy),
            'DurationSeconds' => duration,
            :idempotent       => true,
            :parser           => Fog::Parsers::AWS::STS::AssumeRoleWithSAML.new
          })
        end
      end
    end
  end
end
