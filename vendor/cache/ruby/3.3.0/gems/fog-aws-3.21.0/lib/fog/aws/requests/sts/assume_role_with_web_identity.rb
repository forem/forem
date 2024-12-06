module Fog
  module AWS
    class STS
      class Real
        require 'fog/aws/parsers/sts/assume_role_with_web_identity'

        def assume_role_with_web_identity(role_arn, web_identity_token, role_session_name, options={})
          request_unsigned(
            'Action'            => 'AssumeRoleWithWebIdentity',
            'RoleArn'           => role_arn,
            'RoleSessionName'   => role_session_name,
            'WebIdentityToken'  => web_identity_token,
            'DurationSeconds'   => options[:duration] || 3600,
            :idempotent         => true,
            :parser             => Fog::Parsers::AWS::STS::AssumeRoleWithWebIdentity.new
          )
        end
      end

      class Mock
        def assume_role_with_web_identity(role_arn, web_identity_token, role_session_name, options={})
          role = options[:iam].data[:roles].values.detect { |r| r[:arn] == role_arn }

          Excon::Response.new.tap do |response|
            response.body = {
              'AssumedRoleUser' => {
                'Arn'           => role[:arn],
                'AssumedRoleId' => role[:role_id]
              },
              'Audience'    => 'fog',
              'Credentials' => {
                'AccessKeyId'     => Fog::AWS::Mock.key_id(20),
                'Expiration'      => options[:expiration] || Time.now + 3600,
                'SecretAccessKey' => Fog::AWS::Mock.key_id(40),
                'SessionToken'    => Fog::Mock.random_hex(8)
              },
              'Provider'                    => 'fog',
              'SubjectFromWebIdentityToken' => Fog::Mock.random_hex(8)
            }
            response.status = 200
          end
        end
      end
    end
  end
end
